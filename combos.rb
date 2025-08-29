#!/usr/bin/env ruby
# vi: set sw=2 et :

# CMD: none, string, array
# ENTRYPOINT: none, string, array
# --entrypoint: none, string
# args: none, some

require 'rosarium'
require 'tempfile'
require 'json'

def puts_dockerfile(cmd, entrypoint, dockerfile_f)
  dockerfile_f.puts "FROM bare-image"
  dockerfile_f.puts "CMD #{cmd}" unless cmd.nil?
  dockerfile_f.puts "ENTRYPOINT #{entrypoint}" unless entrypoint.nil?
  dockerfile_f.flush
end

def docker_build_log(dockerfile_path)
  Tempfile.open('build-log') do |log_f|
    pid = Process.spawn(
      "docker", "build", "-q", "--file", dockerfile_path, ".",
      in: "/dev/null",
      out: log_f.fileno,
      err: log_f.fileno,
    )
    Process.wait pid
    unless $?.success?
      log_f.rewind
      raise "build failed: #{log_f.read}"
    end

    log_f.rewind
    log_f.read
  end
end

def build_image(cmd, entrypoint)
  Tempfile.open('Dockerfile', '.') do |dockerfile_f|
    puts_dockerfile(cmd, entrypoint, dockerfile_f)

    build_log = docker_build_log(dockerfile_f.path)

    if build_log.lines.last.match(/^(sha256:\w+)$/)
      $1
    else
      puts build_log
      raise "Failed to build: #{build_log.inspect}"
    end
  end
end

promises = []

[ nil, "cmd-string cmd-str1", '["cmd-array", "cmd-arr1"]' ].each do |cmd|
  [ nil, "ep-string ep-str1", '["ep-array", "ep-arr1"]' ].each do |entrypoint|
    image_id_promise = Rosarium::Promise.execute { build_image(cmd, entrypoint) }

    [ nil, "", "ep-override ep-ov1" ].each do |entrypoint_override|
      [ [], ["some", "args"] ].each do |cmdline_args|

        promises << image_id_promise.then do |image_id|
          entrypoint_args = if entrypoint_override
                              [ "--entrypoint", entrypoint_override ]
                            else
                              []
                            end

          log_output = Tempfile.open('log') do |log_f|
            pid = Process.spawn(
              "docker", "run", "--rm", *entrypoint_args, image_id, *cmdline_args,
              in: "/dev/null",
              out: log_f.fileno,
              err: log_f.fileno,
            )
            Process.wait pid
            log_f.rewind

            unless $?.success?
              "run failed: #{log_f.read}"
            else
              log_f.read
            end
          end

          output = if log_output.start_with?("exec-json=")
            ["ok", JSON.parse(log_output.sub("exec-json=", ""))]
          elsif log_output.downcase.include?("no command specified")
            ["no_command_specified"]
          else
            ["unknown", log_output]
          end

          r = {
            input: {
              cmd: cmd,
              entrypoint: entrypoint,
              entrypoint_override: entrypoint_override,
              cmdline_args: cmdline_args,
            },
            output:,
          }
          p r
          r

        end # promise execute
      end
    end
  end
end

all = Rosarium::Promise.all(promises).value!

File.open('actuals.json', 'w') do |f|
  f.puts JSON.pretty_generate(all)
end
