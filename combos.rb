#!/usr/bin/env ruby
# vi: set sw=2 et :

# CMD: none, string, array
# ENTRYPOINT: none, string, array
# --entrypoint: none, string
# args: none, some

require 'rosarium'
require 'tempfile'
require 'json'

m = Mutex.new

promises = []
[ nil, "cmd-string cmd-str1", '["cmd-array", "cmd-arr1"]' ].each do |cmd|
  [ nil, "ep-string ep-str1", '["ep-array", "ep-arr1"]' ].each do |entrypoint|
    [ nil, "ep-override ep-ov1" ].each do |entrypoint_override|
      [ [], ["some", "args"] ].each do |cmdline_args|

        promises << Rosarium::Promise.execute do

          image_id = Tempfile.open('Dockerfile', '.') do |dockerfile_f|
            dockerfile_f.puts "FROM ruby:alpine"
            dockerfile_f.puts "WORKDIR /usr/bin"
            dockerfile_f.puts "COPY show-invocation ./"
            dockerfile_f.puts "RUN ln -s show-invocation cmd-string"
            dockerfile_f.puts "RUN ln -s show-invocation cmd-array"
            dockerfile_f.puts "RUN ln -s show-invocation ep-string"
            dockerfile_f.puts "RUN ln -s show-invocation ep-array"
            dockerfile_f.puts "RUN ln -s show-invocation 'ep-override ep-ov1'"
            dockerfile_f.puts "RUN ln -s show-invocation some"
            # dockerfile_f.puts "RUN ln -s -f show-invocation /bin/sh"
            dockerfile_f.puts "RUN cd /bin && cp sh sh.real && cp /usr/bin/show-invocation sh"
            dockerfile_f.puts "WORKDIR /"
            dockerfile_f.puts "CMD #{cmd}" unless cmd.nil?
            dockerfile_f.puts "ENTRYPOINT #{entrypoint}" unless entrypoint.nil?
            dockerfile_f.flush

            build_log = Tempfile.open('build-log') do |log_f|
              m.synchronize do
                pid = Process.spawn(
                  "docker", "build", "--file", dockerfile_f.path, ".",
                  in: "/dev/null",
                  out: log_f.fileno,
                  err: log_f.fileno,
                )
                Process.wait pid
                unless $?.success?
                  log_f.rewind
                  raise "build failed: #{log_f.read}"
                end
              end
              log_f.rewind
              log_f.read
            end

            if build_log.lines.last.match /^Successfully built (\w+)$/
              $1
            else
              raise
            end
          end

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
            unless $?.success?
              log_f.rewind
              raise "run failed: #{log_f.read}"
            end

            log_f.rewind
            log_f.read
          end

          {
            input: {
              cmd: cmd,
              entrypoint: entrypoint,
              entrypoint_override: entrypoint_override,
              cmdline_args: cmdline_args,
            },
            output: log_output,
          }

        end # promise execute

      end
    end
  end
end

all = Rosarium::Promise.all(promises).value!
File.open('o.json', 'w') do |f|
  f.puts JSON.pretty_generate(all)
end

# Udtræksbruser 46857000
# Kontraventil t/ termostatbatterier 08565000
# Stråleregulator 13997000

