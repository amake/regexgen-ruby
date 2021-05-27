# frozen_string_literal: true

module Regexgen
  # Classes in the abstract syntax tree representation
  module Ast
    # Represents an alternation (e.g. `foo|bar`)
    class Alternation
      attr_reader :precedence, :options

      def initialize(*options)
        @precedence = 1
        @options = flatten(options).sort { |a, b| b.length - a.length }
      end

      def length
        @options[0].length
      end

      def to_s
        @options.map { |o| Ast.parens(o, self) }.join('|')
      end

      private

      def flatten(options)
        options.map { |option| option.is_a?(Alternation) ? flatten(option.options) : option }
               .flatten
      end
    end

    # Represents a character class (e.g. [0-9a-z])
    class CharClass
      attr_reader :precedence

      def initialize(a, b)
        @precedence = 1
        @set = [a, b].flatten
      end

      def length
        1
      end

      def single_character?
        @set.none? { |c| c.ord > 0xffff }
      end

      def single_codepoint?
        true
      end

      def to_s
        "[#{to_ranges_string}]"
      end

      def char_class
        @set
      end

      private

      def to_ranges_string
        to_ranges.map do |first, last|
          if first == last
            first
          elsif first.ord.next == last.ord
            "#{first}#{last}"
          else
            "#{first}-#{last}"
          end
        end.join
      end

      def to_ranges
        set = @set.sort
        ranges = [[set.first, set.first]]
        set.drop(1).each_with_object(ranges) do |c, acc|
          if acc.last.last.ord.next == c.ord
            acc.last[-1] = c
          else
            acc << [c, c]
          end
        end
      end
    end

    # Represents a concatenation (e.g. `foo`)
    class Concatenation
      attr_reader :precedence, :a, :b

      def initialize(a, b)
        @precedence = 2
        @a = a
        @b = b
      end

      def length
        @a.length + @b.length
      end

      def to_s
        Ast.parens(@a, self) + Ast.parens(@b, self)
      end

      def literal(side)
        return @a.literal(side) if side == :start && @a.respond_to?(:literal)

        @b.literal(side) if side == :end && @b.respond_to?(:literal)
      end

      def remove_substring(side, len)
        a = @a
        b = @b
        a = @a.remove_substring(side, len) if side == :start && @a.respond_to?(:remove_substring)
        b = @b.remove_substring(side, len) if side == :end && @b.respond_to?(:remove_substring)

        return b if a.respond_to?(:empty?) && a.empty?
        return a if b.respond_to?(:empty?) && b.empty?

        Concatenation.new(a, b)
      end
    end

    # Represents a repetition (e.g. `a*` or `a?`)
    class Repetition
      attr_reader :precedence, :expr, :type

      def initialize(expr, type)
        @precedence = 3
        @expr = expr
        @type = type
      end

      def length
        @expr.length
      end

      def to_s
        Ast.parens(@expr, self) + @type
      end
    end

    # Represents a literal (e.g. a string)
    class Literal
      attr_reader :precedence, :value

      def initialize(value)
        @precedence = 2
        @value = value
      end

      def empty?
        @value.empty?
      end

      def single_character?
        length == 1
      end

      def single_codepoint?
        @value.codepoints.length == 1
      end

      def length
        @value.length
      end

      def to_s
        Regexp.escape(@value)
      end

      def char_class
        @value if single_codepoint?
      end

      def literal(_side = nil)
        @value
      end

      def remove_substring(side, len)
        return Literal.new(@value[len...@value.length]) if side == :start
        return Literal.new(@value[0...(@value.length - len)]) if side == :end
      end
    end

    class<<self
      def parens(exp, parent)
        str = exp.to_s
        if exp.precedence < parent.precedence
          unless exp.respond_to?(:single_character?) && exp.single_character?
            return "(?:#{str})" unless exp.respond_to?(:single_codepoint?) && exp.single_codepoint?
          end
        end

        str
      end
    end
  end
end
