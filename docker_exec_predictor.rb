#!/usr/bin/env ruby
# vi: set sw=2 et :

require 'json'

class DockerExecPredictor

  def predict(input)
    entrypoint_from_image = array_or_shell(input.fetch("entrypoint"))
    entrypoint_override = input.fetch("entrypoint_override")
    cmd_from_image = array_or_shell(input.fetch("cmd"))
    cmdline_args = input.fetch("cmdline_args")

    ec = effective_command(cmd_from_image, cmdline_args)

    if non_empty_string?(entrypoint_override)
      # entrypoint_override and cmdline_args are used;
      # ENTRYPOINT and CMD are ignored
      return ["ok", resolve_arg0([ entrypoint_override, *cmdline_args ])]
    end

    if entrypoint_override.nil? && !entrypoint_from_image.nil?
      # Use the entry point from the image, plus either the cmdline args or CMD
      return ["ok", resolve_arg0([ *entrypoint_from_image, *ec ])]
    end

    if (entrypoint_override == "" && cmdline_args == []) || ec.empty?
      return ["no_command_specified"]
    end

    ["ok", resolve_arg0(ec)]
  end

  private

  def non_empty_string?(s)
    !s.nil? && !s.empty?
  end

  def array_or_shell(s)
    return nil if s.nil?

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
    return [] if arr.empty?

    [ resolve(arr[0]), *arr[1..-1] ]
  end

  def effective_command(cmd_from_image, cmdline_args)
    if !cmdline_args.empty?
      cmdline_args
    elsif cmd_from_image
      cmd_from_image
    else
      []
    end
  end

end
