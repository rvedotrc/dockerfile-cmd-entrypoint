#!/usr/bin/env ruby
# vi: set sw=2 et :

require 'json'

def array_or_shell(s)
  s or raise

  if s.start_with? '['
    JSON.parse s
  else
    ['/bin/sh', '-c', s]
  end
end

def resolve(s)
  if s.start_with? '/'
    s
  else
    "/usr/bin/#{s}" # dummy
  end
end

def resolve_arg0(arr)
  [ resolve(arr[0]), *arr[1..-1] ]
end

def effective_command(input)
  if not input["cmdline_args"].empty?
    input["cmdline_args"]
  elsif input["cmd"]
    array_or_shell input["cmd"]
  else
    []
  end
end

def predict(input)
  if input["entrypoint_override"]
    # effective_command is ignored
    [ *resolve_arg0([input["entrypoint_override"]]), *input["cmdline_args"] ]
  elsif input["entrypoint"]
    [ *resolve_arg0(array_or_shell(input["entrypoint"])), *effective_command(input) ]
  else
    command = effective_command(input)
    if not command.empty?
      resolve_arg0(command)
    end
  end
end

data = JSON.parse($stdin.read).map do |line|
  line["output"].chomp!
  predicted_output = predict(line["input"])
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
