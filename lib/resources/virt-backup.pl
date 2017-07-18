#!/usr/bin/perl -w

# AUTHOR
#   Daniel Berteaud <daniel@firewall-services.com>
#
# COPYRIGHT
#   Copyright (C) 2009-2015  Daniel Berteaud
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


# See README for documentation and examples

use XML::Simple;
use Sys::Virt;
use Getopt::Long;
use File::Copy;
use File::Spec;

# Set umask
umask(022);

# Some global vars
our %opts = ();
our @vms = ();
our @excludes = ();
our @disks = ();

# Sets some defaults values

# What to run. The default action is to dump
$opts{action} = 'dump';
# Where backups will be stored. This directory must already exists
$opts{backupdir} = '/var/lib/libvirt/backup';
# Lockdir is where locks will be held when backing up a VM. The default is to put the lock
# in the backup dir of the VM, but in some situations, you want to put it elsewhere
$opts{lockdir} = '';
# Size of LVM snapshots (which will be used to backup VM with minimum downtime
# if the VM is backed by LVM). If the LVM volume is thinly provisionned (thinp)
# this parameter will be ignored
$opts{snapsize} = '5G';
# If we should also dump the VM state (dump the memory, equivalent of virsh save)
$opts{state} = 0;
# Debug, if enabled, will print the different steps of the backup
$opts{debug} = 0;
# Let the lock file present after the dump is finisehd
# Usefull to prevent another backup until you run the script
# with --action=cleanup
$opts{keeplock} = 0;
# Should we try to create LVM snapshots during the dump ?
$opts{snapshot} = 1;
# Should we pause the VM during the backup if we cannot take a snapshot ?
$opts{offline} = 1;
# Libvirt URI to connect to
@connect = ();
# Compression used with the dump action (the compression is done on the fly)
$opts{compress} = 'none';
# lvcreate path
$opts{lvcreate} = '/sbin/lvcreate';
# lvremove path
$opts{lvremove} = '/sbin/lvremove';
# lvs path
$opts{lvs} = '/sbin/lvs';
# Override path to the LVM backend
# Usefull if you have a layer between the filesystem
# and the LVM volume, like GlusterFS
# otherwise, the LVM path should be auto detected
$opts{lvm} = '';
# chunkfs path
$opts{chunkfs} = '/usr/bin/chunkfs';
# Size of chunks to use with chunkfs or or blocks with dd in bytes (default to 256kB)
$opts{blocksize} = '262144';
# nice may be used to reduce CPU priority of compression processes
$opts{nice} = 'nice -n 19';
# ionice may be used to reduce disk access priority of dump/chunkfs processes
# which can be quite I/O intensive. This only works if your storage
# uses the CFQ scheduler (which is the default on EL)
$opts{ionice} = 'ionice -c 2 -n 7';
# if you want to shutdown the guest instead of suspending it
# you can pass the --shutdown flag (mutual exclusive with --state)
# in which case, this script will send an ACPI signal to the guest
# and wait for shutdowntimeout seconds for the guest to be off
$opts{shutdown} = 0;
$opts{shutdowntimeout} = 300;


# Those are internal variables, do not modify
$opts{livebackup} = 1;
$opts{wasrunning} = 1;
 
# get command line arguments
GetOptions(
    "debug"              => \$opts{debug},
    "keep-lock"          => \$opts{keeplock},
    "state"              => \$opts{state},
    "snapsize=s"         => \$opts{snapsize},
    "backupdir=s"        => \$opts{backupdir},
    "lockdir=s"          => \$opts{lockdir},
    "lvm=s"              => \$opts{lvm},
    "vm=s"               => \@vms,
    "action=s"           => \$opts{action},
    "cleanup"            => \$opts{cleanup},
    "dump"               => \$opts{dump},
    "unlock"             => \$opts{unlock},
    "connect=s"          => \@connect,
    "snapshot!"          => \$opts{snapshot},
    "offline!"           => \$opts{offline},
    "compress:s"         => \$opts{compress},
    "exclude=s"          => \@excludes,
    "blocksize=s"        => \$opts{blocksize},
    "shutdown"           => \$opts{shutdown},
    "shutdown-timeout=s" => \$opts{shutdowntimeout},
    "help"               => \$opts{help}
);


# Set compression settings
if ($opts{compress} eq 'lzop'){
    $opts{compext} = ".lzo";
    $opts{compcmd} = "lzop -c";
}
elsif ($opts{compress} eq 'bzip2'){
    $opts{compext} = ".bz2";
    $opts{compcmd} = "bzip2 -c";
}
elsif ($opts{compress} eq 'pbzip2'){
    $opts{compext} = ".bz2";
    $opts{compcmd} = "pbzip2 -c";
}
elsif ($opts{compress} eq 'xz'){
    $opts{compext} = ".xz";
    $opts{compcmd} = "xz -c";
}
elsif ($opts{compress} eq 'lzip'){
    $opts{compext} = ".lz";
    $opts{compcmd} = "lzip -c";
}
elsif ($opts{compress} eq 'plzip'){
    $opts{compext} = ".lz";
    $opts{compcmd} = "plzip -c";
}
# Default is gzip
elsif (($opts{compress} eq 'gzip') || ($opts{compress} eq '')) {
    $opts{compext} = ".gz";
    $opts{compcmd} = "gzip -c";
}
else{
    $opts{compext} = "";
    $opts{compcmd} = "cat";
}
 
# Allow comma separated multi-argument
@vms      = split(/,/, join(',',@vms));
@excludes = split(/,/, join(',',@excludes));
@connect  = split(/,/, join(',',@connect));

# Define a default libvirt URI
$connect[0] = "qemu:///system" unless (defined $connect[0]);

# Backward compatible with --dump --cleanup --unlock
$opts{action} = 'dump'    if ($opts{dump});
$opts{action} = 'cleanup' if ($opts{cleanup});
$opts{action} = 'unlock'  if ($opts{unlock});

# Stop here if we have no vm
# Or the help flag is present
if ((!@vms) || ($opts{help})){
    usage();
    exit 1;
}
# Or state and shutdown flags are used together
if (($opts{state}) && ($opts{shutdown})){
    print "State and shutdown flags cannot be used together\n";
    exit 1;
}
# Or if --no-offline and --no-snapshot are both passed
if (!$opts{offline} && !$opts{snapshot}){
    print "--no-offline and --no-snapshot flags cannot be used together\n";
    exit 1;
}

# Makes sur backupdir is an absolute path
$opts{backupdir} = File::Spec->rel2abs($opts{backupdir}, '/');
# Backup dir needs to be created first 
if (! -d $opts{backupdir} ){
    print "$opts{backupdir} doesn't exist\n";
    exit 1;
}

# Lockdir, if defined, must also exist
if ($opts{lockdir} ne '' && !-d $opts{lockdir}){
    print "$opts{lockdir} doesn't exist\n";
    exit 1;
}

# Connect to libvirt
print "\n\nConnecting to libvirt daemon using $connect[0] as URI\n" if ($opts{debug});
$libvirt1 = Sys::Virt->new( uri => $connect[0] ) || 
    die "Error connecting to libvirt on URI: $connect[0]";
$libvirt2 = '';

if (defined $connect[1]){
    eval { $libvirt2 = Sys::Virt->new( uri => $connect[1] ); };
    print "Error connecting to libvirt on URI: $connect[1], lets hope is out of order\n"
      if ($@ && $opts{debug});
}

our $libvirt = $libvirt1;

print "\n" if ($opts{debug});
 
foreach our $vm (@vms){
    # Create a new object representing the VM
    print "Checking $vm status\n\n" if ($opts{debug});
    our $dom = $libvirt1->get_domain_by_name($vm) ||
        die "Error opening $vm object";

    # If we've passed two connect URI, and our VM is not
    # running on the first one, check on the second one
    if (!$dom->is_active && $libvirt2 ne ''){
        $dom = $libvirt2->get_domain_by_name($vm) ||
            die "Error opening $vm object";

        if ($dom->is_active()){
            $libvirt = $libvirt2;
        }
        else{
            $dom = $libvirt1->get_domain_by_name($vm);
        }
    }
    our $backupdir = $opts{backupdir} . '/' . $vm;
    our $lockdir   = ($opts{lockdir} eq '') ? "$backupdir.meta" : $opts{lockdir};
    our $time      = "_".time();
    if ($opts{action} eq 'cleanup'){
        print "Running cleanup routine for $vm\n\n" if ($opts{debug});
        run_cleanup(1);
    }
    elsif ($opts{action} eq 'unlock'){
        print "Unlocking $vm\n\n" if ($opts{debug});
        unlock_vm();
    }
    elsif ($opts{action} eq 'dump'  || $opts{action} eq 'convert'){
        print "Running dump routine for $vm\n\n" if ($opts{debug});
        mkdir $backupdir            || die $!;
        mkdir $backupdir . '.meta'  || die $!;
        mkdir $backupdir . '.mount' || die $!;
        run_dump();
    }
    elsif ($opts{action} eq 'chunkmount'){
        print "Running chunkmount routine for $vm\n\n" if ($opts{debug});
        mkdir $backupdir || die $!;
        mkdir $backupdir . '.meta'  || die $!;
        mkdir $backupdir . '.mount' || die $!;
        run_chunkmount();
    }
    else {
        usage();
        exit 1;
    }
}


############################################################################
##############                FUNCTIONS                 ####################
############################################################################


# Common routine before backup. Will save the XML description, try to
# create a snapshot of the disks etc...
sub prepare_backup{
    # Create a new XML object
    my $xml = new XML::Simple ();
    my $data = $xml->XMLin( $dom->get_xml_description(), forcearray => ['disk'] );

    # Stop here if the lock file is present, another dump might be running
    die "Another backup is running\n" if ( -e "$lockdir/$vm.lock" );

    # Reset disks list
    @disks = ();

    # Lock VM: Create a lock file so only one dump process can run
    lock_vm();

    # Save the XML description
    save_xml();

    $opts{wasrunning} = 0 unless ($dom->is_active());

    if ($opts{wasrunning}){
        # Save the VM state if it's running and --state is present
        # (else, just suspend the VM)
        if ($opts{state}){
            save_vm_state();
        }
        elsif ($opts{shutdown}){
            shutdown_vm();
        }
        else{
            suspend_vm();
        }
    }

    # Create a list of disks used by the VM
    foreach $disk (@{$data->{devices}->{disk}}){
        my $source;
        if ($disk->{type} eq 'block'){
            $source = $disk->{source}->{dev};
        }
        elsif ($disk->{type} eq 'file'){
            $source = $disk->{source}->{file};
        }
        else{
            print "\nSkiping $source for vm $vm as it's type is $disk->{type}: " .
                " and only block and file are supported\n" if ($opts{debug});
            next;
        }
        my $target = $disk->{target}->{dev};

        # Check if the current disk is not excluded
        if (grep { $_ eq "$target" } @excludes){
            print "\nSkiping $source for vm $vm as it's matching one of the excludes: " .
                join(",", @excludes)."\n\n" if ($opts{debug});
            next;
        }

        # If the device is a disk (and not a cdrom) and the source dev exists
        if (($disk->{device} eq 'disk') && (-e $source)){

            print "\nAnalysing disk $source connected on $vm as $target\n\n" if ($opts{debug});

            # If it's a block device
            if ($disk->{type} eq 'block'){

                # Try to snapshot the source if snapshot is enabled
                if ( ($opts{snapshot}) && (create_snapshot($source,$time)) ){
                    print "$source seems to be a valid logical volume (LVM), a snapshot has been taken as " .
                        $source . $time ."\n" if ($opts{debug});
                    $source = $source . $time;
                    push @disks, {
                      source => $source,
                      target => $target,
                      type   => 'snapshot'
                    };
                }
                # Snapshot failed, or disabled: disabling live backups
                else{
                    if ($opts{snapshot}){
                        print "Snapshoting $source has failed (not managed by LVM, or already a snapshot ?)" .
                            ", live backup will be disabled\n" if ($opts{debug}) ;
                    }
                    else{
                        print "Not using LVM snapshots, live backups will be disabled\n" if ($opts{debug});
                    }
                    $opts{livebackup} = 0;
                    push @disks, {
                      source => $source,
                      target => $target,
                      type   => 'block'
                    };
                }
            }
            # If the disk is a file
            elsif ($disk->{type} eq 'file'){
                # Try to find the mount point, and the backing device
                my @df = `df -PT $source`;
                my ($dev, undef, undef, undef, undef, undef, $mount) = split /\s+/, $df[1];
                # Ok, we now have the backing device which probably looks like /dev/mapper/vg-lv
                # We cannot pass this arg to lvcreate to take a snapshot, we need to detect Volume Group
                # name and Logical Volume name
                my $lvm = '';
                if ($opts{lvm} eq '' and $dev =~ m!^/dev/!){
                    my (undef, $lv, $vg) = split (/\s+/, `$opts{lvs} --noheadings -o lv_name,vg_name $dev </dev/null`);
                    $lvm = '/dev/'. $vg . '/' . $lv;
                }
                # The backing device can be detected, but can also be overwritten with --lvm=/dev/vg/lv
                # This can be usefull for example when you use GlusterFS. Df will return something like
                # localhost:/vmstore as the device, but this GlusterFS volume might be backed by an LVM
                # volume, in which case, you can pass it as an argument to the script
                elsif ($opts{lvm} ne '' && -e "$opts{lvm}"){
                    $lvm = $opts{lvm};
                }
                else{
                    die "Couldn't detect the backing device for $source. You should pass it as argument like --lvm=/dev/vg/lv\n\n";
                }
                my $mp   = $lvm;
                $mp      =~ s!/!_!g;
                $mp      = "$backupdir.mount/$mp/";
                my $file = $source;
                # Try to snapshot this device
                if ( $opts{snapshot} ){
                    # Maybe the LVM is already snapshoted and mounted for a previous disk ?
                    my $is_mounted = 0;
                    if (open MOUNT, "<$backupdir.meta/mount"){
                        while (<MOUNT>){
                            $is_mounted = 1 if ($_ eq $lvm);
                        }
                        close MOUNT;
                    }
                    # Force the cache to be flushed before taking the snapshot
                    die "Couldn't call sync before taking the snapshot: $!\n" unless (system ("/bin/sync") == 0);
                    if ($is_mounted){
                        print "A snapshot of $lvm is already mounted on $backupdir.mount/$mp\n\n" if ($opts{debug});
                        $file =~ s|$mount|$mp|;
                    }
                    elsif (create_snapshot($lvm,$time)){
                        print "$lvm seems to be a valid logical volume (LVM), a snapshot has been taken as " .
                            $lvm . $time ."\n" if ($opts{debug});
                        my $snap = $lvm.$time;
                        mkdir $mp || die "Couldn't create $mp: $!";
                        my $type = `/sbin/blkid $lvm`;
                        $type    =~ m/TYPE=\"(\w+)\"/;
                        $type    = $1;
                        # -o nouuid is needed if XFS is used
                        # In some cases, mount cannot auto detect the XFS format, 
                        # so we have to pass the type explicitly
                        my $option = ($type eq 'xfs') ? '-t xfs -o nouuid': '';
                        print "Mounting $snap on $mp (as an $type filesystem)\n" if ($opts{debug});
                        system("/bin/mount $option $snap $mp");
                        open MOUNT, ">$backupdir.meta/mount";
                        print MOUNT $lvm;
                        close MOUNT;
                        $file =~ s|$mount|$mp|;
                    }
                    else {
                        print "An error occured while snapshoting $lvm, live backup will be disabled\n" if ($opts{debug});
                        $opts{livebackup} = 0;
                    }
                    $file =~ s|//|/|g;
                    push @disks, {
                        source => $file,
                        target => $target,
                        type   => 'file'
                    };
                }
                else {
                    $opts{livebackup} = 0;
                    push @disks, {
                      source => $source,
                      target => $target,
                      type   => 'file'
                    };
                }
            }
            if ($opts{debug} && ($opts{livebackup} || $opts{offline})){
              print "Adding $source to the list of disks to be backed up\n";
            }
        }
    }

    # Summarize the list of disk to be dumped
    if ($opts{debug} && ($opts{livebackup} || $opts{offline})){
        if ($opts{action} eq 'dump'){
            print "\n\nThe following disks will be dumped:\n\n";
            foreach $disk (@disks){
                print "Source: $disk->{source}\tDest: $backupdir/$vm" . '_' . $disk->{target} .
                    ".img$opts{compext}\n";
            }
        }
        elsif ($opts{action} eq 'convert'){
            $opts{compext} = ".qcow2";
            print "\n\nThe following disks will be converted to qcow2 format:\n\n";
            foreach $disk (@disks){
                print "Source: $disk->{source}\tDest: $backupdir/$vm" . '_' . $disk->{target} .
                    ".img$opts{compext}\n";
            }
        }
        elsif($opts{action} eq 'chunkmount'){
            print "\n\nThe following disks will be mounted as chunks:\n\n";
            foreach $disk (@disks){
                print "Source: $disk->{source}\tDest: $backupdir/$vm" . '_' . $disk->{target} . "\n";
            }
        }
    }

    # If livebackup is possible (every block devices can be snapshoted)
    # We can restore the VM now, in order to minimize the downtime
    if ($opts{livebackup}){
        print "\nWe can run a live backup\n" if ($opts{debug});
        if ($opts{wasrunning}){
            if ($opts{state}){
                # Prevent a race condition in libvirt
                sleep(1);
                restore_vm();
            }
            elsif ($opts{shutdown}){
                start_vm();
            }
            else{
                resume_vm();
            }
        }
    }
    # Are offline backups allowed ?
    elsif (!$opts{offline}){
      run_cleanup(1);
      die "Offline backups disabled, sorry, I cannot continue\n\n";
    }
}

sub run_dump{

    # Pause VM, dump state, take snapshots etc..
    prepare_backup();
 
    # Now, it's time to actually dump the disks
    foreach $disk (@disks){

        my $source = $disk->{source};
        my $dest = "$backupdir/$vm" . '_' . $disk->{target} . ".img$opts{compext}";

        my $cmd = '';
        if ($opts{action} eq 'convert'){
            print "\nStarting conversion in qcow2 format of $source to $dest\n\n" if ($opts{debug});
            $cmd  = "$opts{nice} $opts{ionice} qemu-img convert -O qcow2";
            $cmd .= " -c" if ($opts{compress} ne 'none');
            $cmd .= " $source $dest 2>/dev/null 2>&1";
            print "Ignoring compression format, using the internal qcow2 compression\n"
                if ($opts{debug} && $opts{compress} ne 'none')
        }
        else {
            print "\nStarting dump of $source to $dest\n\n" if ($opts{debug});
            $cmd = "$opts{ionice} dd if=$source bs=$opts{blocksize} | $opts{nice} $opts{compcmd} > $dest 2>/dev/null";
        }
        unless( system("$cmd") == 0 ){
            die "Couldn't dump or convert $source to $dest\n";
        }
        # Remove the snapshot if the current dumped disk is a snapshot
        sleep(1);
        destroy_snapshot($source) if ($disk->{type} eq 'snapshot');
    }

    # If the VM was running before the dump, restore (or resume) it
    if ($opts{wasrunning}){
        if ($opts{state}){
            restore_vm();
        }
        else{
            resume_vm();
        }
    }
    # And remove the lock file, unless the --keep-lock flag is present
    unlock_vm() unless ($opts{keeplock});
    # Cleanup snapshot and other temp files
    # but don't remove the dumps themselves
    run_cleanup(0);
}

sub run_chunkmount{
    # Pause VM, dump state, take snapshots etc..
    prepare_backup();

    # Now, lets mount guest images with chunkfs
    foreach $disk (@disks){

        my $source = $disk->{source};
        my $dest   = "$backupdir/$vm" . '_' . $disk->{target};
        mkdir $dest || die $!;
        print "\nMounting $source on $dest with chunkfs\n\n" if ($opts{debug});
        my $cmd = "$opts{ionice} $opts{chunkfs} -o fsname=chunkfs-$vm $opts{blocksize} $source $dest 2>/dev/null";
        unless( system("$cmd") == 0 ){
            die "Couldn't mount $source on $dest\n";
        }
    }
}

# Remove the dumps
sub run_cleanup{
    my $rmDumps = shift;
    if ($rmDumps){
      print "\nRemoving backup files\n" if ($opts{debug});
    }
    else{
      print "\nRemoving snapshots and temporary files\n" if ($opts{debug});
    }
    my $cnt = 0;
    my $meta = 0;
    my $snap = 0;

    # If a state file is present, restore the VM
    if (-e "$backupdir/$vm.state"){
        restore_vm();
    }
    # Else, try to resume it
    else{
        resume_vm();
    }

    if (open MOUNTS, "</proc/mounts"){
        my @mounts = <MOUNTS>;
        # We first need to umount chunkfs mount points
        foreach (@mounts){
            my @info = split(/\s+/, $_);
            next unless ($info[0] eq "chunkfs-$vm");
            print "Found chunkfs mount point: $info[1]\n" if ($opts{debug});
            my $mp = $info[1];
            print "Unmounting $mp\n\n" if ($opts{debug});
            die "Couldn't unmount $mp\n" unless (
                system("/bin/umount $mp 2>/dev/null") == 0
            );
            rmdir $mp || die $!;
        }
        # Just wait 2 seconds to be sure all fuse resources has been released
        sleep(2);
        # Now, standard filesystems
        foreach (@mounts){
            my @info = split(/\s+/, $_);
            next unless ($info[1] =~ /^$backupdir.mount/);
            print "Found temporary mount point: $info[1]\n" if ($opts{debug});
            my $mp = $info[1];
            print "Unmounting $mp\n\n" if ($opts{debug});
            die "Couldn't unmount $mp\n" unless (
                system("/bin/umount $mp 2>/dev/null") == 0
            );
            rmdir $mp || die $!;
        }
        close MOUNTS;
    }

    if (open SNAPLIST, "<$backupdir.meta/snapshots"){
        sleep(1);
        foreach (<SNAPLIST>){
            # Destroy snapshot listed here is they exists
            # and only if the end with _ and 10 digits
            chomp;
            if ((-e $_) && ($_ =~ m/_\d{10}$/)){
               print "Found $_ in snapshot list file, will try to remove it\n" if ($opts{debug});
               if (destroy_snapshot($_)){
                   $snap++;
               }
               else{
                   print "An error occured while removing $_\n" if ($opts{debug});
               }
            }
        }
        close SNAPLIST;
    }
    unlock_vm();
    $meta = unlink <$backupdir.meta/*>;
    rmdir "$backupdir/";
    rmdir "$backupdir.meta";
    rmdir "$backupdir.mount";
    if ($rmDumps){
      $cnt = unlink <$backupdir/*>;
    }
    print "$cnt file(s) removed\n$snap LVM snapshots removed\n$meta metadata files removed\n\n" if $opts{debug};
}

# Print help 
sub usage{
    print "usage:\n$0 --action=[dump|cleanup|chunkmount|unlock] --vm=vm1[,vm2,vm3] [--debug] [--exclude=hda,hdb] [--compress] ".
        "[--state] [--shutdown] [--shutdown-timeout] [--no-offline] [--no-snapshot] [--snapsize=<size>] [--backupdir=/path/to/dir] [--connect=<URI>] ".
        "[--keep-lock] [--blocksize=<block size>]\n" .
    "\n\n" .
    "\t--action: What action the script will run. Valid actions are\n\n" .
    "\t\t- dump: Run the dump routine (dump disk image to temp dir, pausing the VM if needed). It's the default action\n" .
    "\t\t- convert: Works a bit like dump, but use qemu-img to convert the image to the qcow2 format in the backup dir\n" .
    "\t\t- cleanup: Run the cleanup routine, cleaning up the backup dir\n" .
    "\t\t- chunkmount: Mount each device as a chunkfs mount point directly in the backup dir\n" .
    "\t\t- unlock: just remove the lock file, but don't cleanup the backup dir\n\n" .
    "\t--vm=name: The VM you want to work on (as known by libvirt). You can backup several VMs in one shot " .
        "if you separate them with comma, or with multiple --vm argument. You have to use the name of the domain, ".
        "ID and UUID are not supported at the moment\n\n" .
    "\n\nOther options:\n\n" .
    "\t--state: Cleaner way to take backups. If this flag is present, the script will save the current state of " .
        "the VM (if running) instead of just suspending it. With this you should be able to restore the VM at " .
        "the exact state it was when the backup started. The reason this flag is optional is that some guests " .
        "crashes after restoration, especially when using the kvm-clock. Test this functionnality with" .
        "your environnement before using this flag on production. This flag is mutually exclusive with --shutdown\n\n" .
    "\t--no-offline: Abort the backup if live backup isn't possible (meaning snapshot failed). This is to prevent a VM " .
        "begin paused for the duration of the backup, in some cases, its better to just abort the backup. Of course " .
        "this flag is mutually exclusive with --no-snapshot\n\n" .
    "\t--no-snapshot: Do not attempt to use LVM snapshots. If not present, the script will try to take a snapshot " .
        "of each disk of type 'block'. If all disk can be snapshoted, the VM is resumed, or restored (depending " .
        "on the --state flag) immediatly after the snapshots have been taken, resulting in almost no downtime. " .
        "This is called a \"live backup\" in this script. " .
        "If at least one disk cannot be snapshoted, the VM is suspended (or stoped) for the time the disks are " .
        "dumped in the backup dir. That's why you should use a fast support for the backup dir (fast disks, RAID0 " .
        "or RAID10)\n\n" .
    "\t--snapsize=<snapsize>: The amount of space to use for snapshots. Use the same format as -L option of lvcreate. " .
        "eg: --snapsize=15G. Default is 5G. For thinly provisionned volumes, this will be ignored\n\n" .
    "\t--compress[=[gzip|bzip2|pbzip2|lzop|xz|lzip|plzip]]: On the fly compress the disks images during the dump. If you " .
        "don't specify a compression algo, gzip will be used. For the convert action, the compression uses " .
        "the internal qcow2 compression feature, and so, it ignores the compression format, in this case --compress " .
        "is just seen as a boolean flag\n\n" .
    "\t--exclude=hda,hdb: Prevent the disks listed from being dumped. The names are from the VM perspective, as " .
        "configured in livirt as the target element. It can be usefull for example if you want to dump the system " .
        "disk of a VM, but not the data one which can be backed up separatly, at the files level.\n\n" .
    "\t--backupdir=/path/to/backup: Use an alternate backup dir. The directory must exists and be writable. " .
        "The default is /var/lib/libvirt/backup\n\n" .
    "\t--lockdir=/path/to/locks: Use an alternate lock dir. The directory must exists and be writable. " .
        "The default is to put locks in the backup diretory, but you might want it elsewhere (on a shared storage for example)\n\n" .
    "\t--connect=<URI>: URI to connect to libvirt daemon (to suspend, resume, save, restore VM etc...). " .
        "The default is qemu:///system.\n\n" .
    "\t--keep-lock: Let the lock file present. This prevent another " .
        "dump to run while an third party backup software (BackupPC for example) saves the dumped files.\n\n" .
    "\t--shutdown: Shutdown the vm instead of suspending it. This uses ACPI to send the shutdown signal. " .
        "You should make sure your guest react to ACPI signals. This flag is mutual exclusive with --state\n\n" .
    "\t--shutdown-timeout=<seconds>: How long to wait, in seconds, for the vm to shutdown. If the VM isn't stopped " .
        "after that amount of time (in seconds), the backup will abort. The default timeout is 300 seconds\n\n" .
    "\t--blocksize=<blocksize>: Specify block size in bytes (for dd and chunkfs). Default to 262144 (256kB).\n";
}

# Save a running VM, if it's running
sub save_vm_state{
    if ($dom->is_active()){
        print "$vm is running, saving state....\n" if ($opts{debug});
        # if $libvirt2 is defined, you've passed several connections URI
        # This means that you're running a dual hypervisor cluster
        # And depending on the one running the current VM
        # $backupdir might not be available
        # whereas /var/lib/libvirt/qemu/save/ might
        # if you've mounted here a shared file system
        # (NFS, GlusterFS, GFS2, OCFS etc...)
        if ($libvirt2 ne ''){
            $dom->managed_save();
            move "/var/lib/libvirt/qemu/save/$vm.save", "$backupdir/$vm.state";
        }
        else{
            $dom->save("$backupdir/$vm.state");
        }
        print "$vm state saved as $backupdir/$vm.state\n" if ($opts{debug});
    }
    else{
        print "$vm is not running, nothing to do\n" if ($opts{debug});
    }
}

# Restore the state of a VM
sub restore_vm{
    if (! $dom->is_active()){
        if (-e "$backupdir/$vm.state"){
            # if $libvirt2 is defined, you've passed several connections URI
            # This means that you're running a dual hypervisor cluster
            # And depending on the one running the current VM
            # $backupdir might not be available
            # whereas /var/lib/libvirt/qemu/save/ might
            # if you've mounted here a shared file system
            # (NFS, GlusterFS, GFS2, OCFS etc...)
            if ($libvirt2){
                copy "$backupdir/$vm.state", "/var/lib/libvirt/qemu/save/$vm.save";
                start_vm();
            }
            else{
                print "\nTrying to restore $vm from $backupdir/$vm.state\n" if ($opts{debug});
                $libvirt->restore_domain("$backupdir/$vm.state");
                print "Waiting for restoration to complete\n" if ($opts{debug});
                my $i = 0;
                while ((!$dom->is_active()) && ($i < 120)){
                    sleep(5);
                    $i = $i+5;
                }
                print "Timeout while trying to restore $vm, aborting\n" 
                    if (($i > 120) && ($opts{debug}));
            }
        }
        else{
            print "\nRestoration impossible, $backupdir/$vm.state is missing\n" if ($opts{debug});
        }
    }
    else{
        print "\nCannot start domain restoration, $vm is running (maybe already restored after a live backup ?)\n"
            if ($opts{debug});
    }
}

# Suspend a VM
sub suspend_vm(){
    if ($dom->is_active()){
        print "$vm is running, suspending\n" if ($opts{debug});
        $dom->suspend();
        print "$vm now suspended\n" if ($opts{debug});
    }
    else{
        print "$vm is not running, nothing to do\n" if ($opts{debug});
    }
}

# Resume a VM if it's paused
sub resume_vm(){
    if ($dom->get_info->{state} == Sys::Virt::Domain::STATE_PAUSED){
        print "$vm is suspended, resuming\n" if ($opts{debug});
        $dom->resume();
        print "$vm now resumed\n" if ($opts{debug});
    }
    else{
        print "$vm is not suspended, nothing to do\n" if ($opts{debug});
    }
}

# Shutdown a VM via ACPI
sub shutdown_vm(){
    if ($dom->is_active()){
        print "$vm is running, shutting down\n" if ($opts{debug});
        $dom->shutdown();
        my $shutdown_counter = 0;
        # Wait $opts{shutdowntimeout} seconds for vm to shutdown
        while ($dom->get_info->{state} != Sys::Virt::Domain::STATE_SHUTOFF){
            if ($shutdown_counter >= $opts{shutdowntimeout}){
                die "Waited $opts{shutdowntimeout} seconds for $vm to shutdown.  Shutdown Failed\n";
            }
            $shutdown_counter++;
            sleep(1);
        }
    }
    else{
        print "$vm is not running, nothing to do\n" if ($opts{debug});
    }
}

sub start_vm(){
    if ($dom->get_info->{state} == Sys::Virt::Domain::STATE_SHUTOFF){
        print "$vm is shutoff, restarting\n" if ($opts{debug});
        $dom->create();
        print "$vm started\n" if ($opts{debug});
    }
    else{
        print "$vm is not in a shutdown state, nothing to do\n" if ($opts{debug});
    }
}

# Dump the domain description as XML
sub save_xml{
    print "\nSaving XML description for $vm to $backupdir/$vm.xml\n" if ($opts{debug});
    open(XML, ">$backupdir/$vm" . ".xml") || die $!;
    print XML $dom->get_xml_description();
    close XML;
}

# Create an LVM snapshot
# Pass the original logical volume and the suffix
# to be added to the snapshot name as arguments
sub create_snapshot{
    my ($blk,$suffix) = @_;
    my $ret  = 0;
    my $lock = $blk;
    $lock    =~ s/\//\-/g;
    $lock    = $opts{backupdir} . '/' . $lock . '.lock';
    my $cmd = "$opts{lvcreate} -s -n " . $blk . $suffix;
    my ($pool) = split (/\s+/, `$opts{lvs} --noheadings -o pool_lv $blk </dev/null`);
    # passing snapsize = 0 means don't allocate a fixed size, which will try to create a thin snapshot
    # we can also rely on thin detection
    if ($opts{snapsize} ne '0' || !defined $pool){
      $cmd .= " -L $opts{snapsize}";
    }
    else{
      # For thin snapshots, we need to tell LVM to enable the volume right away
      $cmd .= " -kn";
    }
    $cmd .= " $blk > /dev/null 2>&1 < /dev/null\n";
    for ($cnt = 0; $cnt < 10; $cnt++ ){
        print "Running: $cmd" if $opts{debug};
        if (-e "$lock" . '.lock'){
          print "Volume $blk is locked...\n" if $opts{debug};
        }
        else{
            open ( LOCK, ">$lock" );
            print LOCK "";
            close LOCK;
            if ( system("$cmd") == 0 ) {
                print "Snapshot taken\n" if $opts{debug};
                $ret = 1;
                open SNAPLIST, ">>$backupdir.meta/snapshots" or die "Error, couldn't open snapshot list file\n";
                print SNAPLIST $blk.$suffix ."\n";
                close SNAPLIST;
                # break the loop now
                $cnt = 10;
            }
            else{
                print "An error occured, couldn't create the snapshot\n" if $opts{debug};
            }
        }
        sleep(1);
    }
    # In any case, failed or not, remove our lock
    unlink $lock if (-e $lock);
    return $ret;
}

# Remove an LVM snapshot
sub destroy_snapshot{
    my $ret = 0;
    my ($snap) = @_;
    print "Removing snapshot $snap\n" if $opts{debug};
    if (system ("$opts{lvremove} -f $snap > /dev/null 2>&1 < /dev/null") == 0 ){
        $ret = 1;
    }
    return $ret;
}

# Lock a VM backup dir
# Just creates an empty lock file
sub lock_vm{
    print "Locking $vm\n" if $opts{debug};
    open ( LOCK, ">$lockdir/$vm.lock" ) || die $!;
    print LOCK "";
    close LOCK;
}

# Unlock the VM backup dir
# Just removes the lock file
sub unlock_vm{
    print "Removing lock file for $vm\n\n" if $opts{debug};
    unlink <$lockdir/$vm.lock>;
}

