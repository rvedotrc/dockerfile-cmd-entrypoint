#!/usr/bin/env ruby
# vi: set sw=2 et :

require 'json'
require_relative 'docker_exec_predictor'

data = JSON.parse($stdin.read).map do |line|
  actual = line["output"]
  params = DockerParams.from_input(line["input"])
  predicted = DockerExecPredictor.new(params).predict

  ok = predicted == actual

  if !ok
    puts "case #{line["input"].inspect}"
    puts "  predicted #{JSON.generate(predicted)}"
    puts "  actual    #{JSON.generate(actual)}"
    puts ""
  end
  line["ok"] = ok
  line
end

puts "#{data.count {|line| line["ok"]}} OK"
puts "#{data.count {|line| !line["ok"]}} FAILED"

File.open('reverse-engineer-rules.json', 'w') do |f|
  f.puts JSON.pretty_generate(data)
end

exit 1 unless data.all? {|line| line["ok"]}
