# frozen_string_literal: true

require 'regexgen/version'
require 'regexgen/trie'

# Generate regular expressions that match a set of strings
module Regexgen
  class << self
    def generate(strings, flags = nil)
      Trie.new.tap { |t| strings.each { |s| t.add(s) } }
          .to_regex(flags)
    end
  end
end
