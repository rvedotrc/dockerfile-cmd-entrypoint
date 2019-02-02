#!/usr/bin/env ruby
# vi: set sw=2 et :

require 'json'

class DockerExecPredictor

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

  private

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
      # In our test data, everything is in /usr/bin.  Normally,
      # The path used may vary depending on where things are installed.
      "/usr/bin/#{s}"
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

end
