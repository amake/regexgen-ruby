# frozen_string_literal: true

require 'regexgen/state'
require 'regexgen/minimize'

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

    def minimize
      Regexgen.minimize(@root, @alphabet)
    end
  end
end
