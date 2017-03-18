#!/usr/bin/env ruby

require "./lib/VmCreationTask"

VmCreationTask.new().destroy_existing_vm
