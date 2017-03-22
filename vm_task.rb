task_name = ARGV[0]

puts "Running #{task_name} ..."

task_filename = "./lib/#{task_name}"

puts "Loading #{task_filename} ..."

require task_filename

puts "Task Loaded"

class_metadata = Object.const_get(task_name)
task_instance = class_metadata.new

puts "Executing task..."

task_instance.run

puts "Task Complete"
