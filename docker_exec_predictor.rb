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
    if non_empty_string?(entrypoint_override)
      # `--entrypoint SOMETHING` means:
      # - ignore ENTRYPOINT
      # - ignore CMD
      # - exec the given entrypoint_override, passing any cmdline_args as arguments
      ["ok", resolve_arg0([ entrypoint_override, *cmdline_args ])]

    elsif entrypoint_override == ""
      # `--entrypoint ""` means:
      # - ignore ENTRYPOINT
      # - ignore CMD
      # - exec cmdline_args[0], passing the rest as arguments
      #   (fail with "no command specified") if no cmdline_args were given
      if cmdline_args.empty?
        ["no_command_specified"]
      else
        ["ok", resolve_arg0(cmdline_args)]
      end

    else # entrypoint_override.nil?
      if entrypoint_from_image.nil?
        # No `--entrypoint` and no ENTRYPOINT means:
        # - use either cmdline_args or (if that's empty) CMD,
        #   exec'ing the 0'th item and passing the rest as arguments
        #   (fail with "no command specified") if neither cmdline_args nor CMD were given
        if effective_command.empty?
          ["no_command_specified"]
        else
          ["ok", resolve_arg0(effective_command)]
        end
      else
        # No `--entrypoint` but with an ENTRYPOINT means:
        # - exec the ENTRYPOINT, passing cmdline_args or (if that's empty) CMD as arguments
        ["ok", resolve_arg0([ *entrypoint_from_image, *effective_command ])]
      end
    end
  end

  private

  attr_accessor :entrypoint_from_image
  attr_accessor :cmd_from_image
  attr_accessor :entrypoint_override
  attr_accessor :cmdline_args

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

  def effective_command
    @effective_command ||=
      begin
        if !cmdline_args.empty?
          cmdline_args
        elsif cmd_from_image
          cmd_from_image
        else
          []
        end
      end
  end

end
