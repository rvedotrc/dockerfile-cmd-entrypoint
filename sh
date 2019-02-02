#!/usr/local/bin/ruby

require 'json'
puts JSON.generate([ $0, *ARGV ])
exec "/bin/sh.real", *ARGV
