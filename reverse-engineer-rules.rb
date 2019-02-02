#!/usr/bin/env ruby
# vi: set sw=2 et :

require 'json'
require_relative 'docker_exec_predictor'

data = JSON.parse($stdin.read).map do |line|
  line["output"].chomp!
  predicted_output = DockerExecPredictor.new.predict(line["input"])
  predicted_output = predicted_output.to_json unless predicted_output.nil?
  ok = (predicted_output == line["output"])
  if !ok
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
