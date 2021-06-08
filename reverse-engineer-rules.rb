#!/usr/bin/env ruby
# vi: set sw=2 et :

require 'json'
require_relative 'docker_exec_predictor'

data = JSON.parse($stdin.read).map do |line|
  line["output"].chomp!
  predicted_output = DockerExecPredictor.new.predict(line["input"])

  output_json = begin
                  JSON.parse(line["output"])
                rescue
                  nil
                end

  ok = case predicted_output
       when :no_command_error
         line["output"].include?("No command specified")
       when :switch_to_inspect_mode
         line["output"].include?("Switch to inspect mode")
       else
         if output_json
           predicted_output == output_json
         else
           false
         end
       end

  if !ok
    puts "case #{line["input"].inspect}"
    puts "  predicted #{predicted_output.inspect}"
    puts "  actual    #{line["output"].inspect}"
    puts ""
  end
  line["ok"] = ok
  line
end

puts "#{data.count {|line| line["ok"]}} OK"

File.open('reverse-engineer-rules.json', 'w') do |f|
  f.puts JSON.pretty_generate(data)
end

exit 1 unless data.all? {|line| line["ok"]}
