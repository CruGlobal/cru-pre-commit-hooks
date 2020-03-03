#!/usr/bin/env ruby

require "awesome_print"

class S3BackendKey
  def initialize(args)
    @args = args.dup
  end

  def run
    ap @args
  end
end

S3BackendKey.new(ARGV).run
