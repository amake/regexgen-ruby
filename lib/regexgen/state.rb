# frozen_string_literal: true

module Regexgen
  class State
    attr_accessor :accepting
    attr_reader :transitions

    def initialize
      @accepting = false
      @transitions = Hash.new { |hash, key| hash[key] = State.new }
    end

    def visit(visited = Set.new)
      return visited if visited.include?(self)

      visited.add(self)
      @transitions.each_value { |state| state.visit(visited) }
      visited
    end

    def to_h
      @transitions.transform_values(&:to_h).tap do |h|
        h[''] = nil if @accepting
      end
    end

    def to_s
      sigil = @accepting ? '*' : ''
      "#{sigil}#{to_h}"
    end

    alias inspect to_s
  end
end
