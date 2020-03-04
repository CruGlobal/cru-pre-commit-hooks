#!/usr/bin/env ruby

require "tempfile"

S3_BACKEND_BLOCK_RE = /backend\s+"s3"\s+(?<block>{[^{}]*(&block)?[^{}]*})/x.freeze
BACKEND_KEY_RE = /key\s+=\s+"(.*)"/.freeze

class S3BackendKey
  def initialize(filename)
    @filename = filename
  end

  def enforce_backend_key
    return unless backend
    return if key == backend_key
    update_key
    {
      filename: @filename,
      expected: key,
      actual: backend_key
    }
  end

  def key
    @key ||= File.join(File.dirname(@filename), "terraform.tfstate")
  end

  def content
    @content ||= IO.read(@filename)
  end

  def backend
    @backend ||= S3_BACKEND_BLOCK_RE.match(content)&.named_captures&.dig("block")
  end

  def backend_key
    match = BACKEND_KEY_RE.match(backend)
    return if match.nil?
    match[1]
  end

  def update_key
    Tempfile.open(".#{File.basename(@filename)}", File.dirname(@filename)) do |tempfile|
      tempfile.puts content.gsub(backend_key, key)
      tempfile.close
      FileUtils.mv(tempfile.path, @filename)
    end
  end
end

results = ARGV.map { |filename| S3BackendKey.new(filename).enforce_backend_key }.compact
exit(0) if results.empty?

puts "The following files had incorrect S3 backend keys and were updated:"
results.each do |result|
  puts "  - #{result[:filename]}"
end
puts "If the state was initialized for any of these modules, you will need to re-run `terraform init` to move the state to the correct key."
exit(1)
