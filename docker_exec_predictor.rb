#!/usr/bin/env ruby
# vi: set sw=2 et :

require 'json'

DockerParams = Data.define(
  :entrypoint_from_image,
  :entrypoint_override,
  :cmd_from_image,
  :cmdline_args
)

def DockerParams.from_input(input)
  new(
    entrypoint_from_image: input.fetch("entrypoint"),
    entrypoint_override: input.fetch("entrypoint_override"),
    cmd_from_image: input.fetch("cmd"),
    cmdline_args: input.fetch("cmdline_args"),
  )
end

class DockerExecPredictor

  def initialize(raw_params)
    # Both ENTRYPOINT and CMD in the Dockerfile may be a JSON array, or a plain string.
    # In the latter case, it's processed using the shell: ["sh", "-c", provided-string]
    @entrypoint_from_image = array_or_shell(raw_params.entrypoint_from_image)
    @cmd_from_image = array_or_shell(raw_params.cmd_from_image)

    @entrypoint_override = raw_params.entrypoint_override
    @cmdline_args = raw_params.cmdline_args
  end

  def predict
    cmd_and_args = resolve_exec

    if cmd_and_args.empty?
      ["no_command_specified"]
    else
      ["ok", resolve_arg0(cmd_and_args)]
    end
  end

  private

  attr_accessor :entrypoint_from_image
  attr_accessor :cmd_from_image
  attr_accessor :entrypoint_override
  attr_accessor :cmdline_args

  def resolve_exec
    if !entrypoint_override.nil?
      [
        # Use the override entrypoint, or none. Ignore ENTRYPOINT.
        (entrypoint_override if entrypoint_override != ""),
        # Use any cmdline_args. Ignore CMD.
        cmdline_args,
      ]
    else
      [
        # Use ENTRYPOINT (if any)
        entrypoint_from_image,
        # Use cmdline_args or (if that's empty) CMD
        if !cmdline_args.empty?
          cmdline_args
        else
          cmd_from_image
        end
      ]
    end.reject(&:nil?).flatten
  end

  def array_or_shell(s)
    return nil if s.nil?

    if s.start_with? '['
      JSON.parse s
    else
      ['/bin/sh', '-c', s]
    end
  end

  def resolve_arg0(arr)
    cmd, *args = arr

    if cmd.start_with?("/")
      [cmd, *args]
    else
      # In our test data, everything is in /usr/bin.  Normally,
      # The path used may vary depending on where things are installed.
      ["/usr/bin/#{cmd}", *args]
    end
  end

end
