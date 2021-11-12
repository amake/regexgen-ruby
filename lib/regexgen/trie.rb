# frozen_string_literal: true

require 'regexgen/state'
require 'regexgen/minimize'
require 'regexgen/regex'

module Regexgen
  class Trie
    attr_reader :root, :alphabet

    def initialize
      @alphabet = Set.new
      @root = State.new
    end

    def add(str)
      node = @root
      str.each_char do |char|
        @alphabet.add(char)
        node = node.transitions[char]
      end
      node.accepting = true
    end

    def add_all(strs)
      strs.each { |s| add(s) }
    end

    def minimize
      Regexgen.minimize(@root)
    end

    def to_s
      Regexgen.to_regex(minimize)
    end

    def to_regex(flags = nil)
      flags_i = 0
      flags_i |= Regexp::EXTENDED if flags&.include?('x')
      flags_i |= Regexp::IGNORECASE if flags&.include?('i')
      flags_i |= Regexp::MULTILINE if flags&.include?('m')
      Regexp.new(to_s, flags_i)
    end
  end
end
