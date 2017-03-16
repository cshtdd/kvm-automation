def sh(command)
    puts "sh #{command}"
    command_output = `#{command}`
    puts command_output
    raise "Error Running Command" unless $?.success?
    command_output
end