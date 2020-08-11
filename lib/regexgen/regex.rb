# frozen_string_literal: true

require 'regexgen/ast'

module Regexgen
  class<<self
    # Brzozowski algebraic method
    # https://cs.stackexchange.com/a/2392
    #
    # Largely ported from
    # https://github.com/devongovett/regexgen/blob/7ef10aef3a414b10554822cdf6e90389582b1890/src/regex.js
    #
    # Initialize B
    #
    #   for i = 1 to m:
    #     if final(i):
    #       B[i] := ε
    #     else:
    #       B[i] := ∅
    #
    # Initialize A
    #
    #   for i = 1 to m:
    #     for j = 1 to m:
    #       for a in Σ:
    #         if trans(i, a, j):
    #           A[i,j] := a
    #         else:
    #           A[i,j] := ∅
    #
    # Solve
    #
    #   for n = m decreasing to 1:
    #     B[n] := star(A[n,n]) . B[n]
    #     for j = 1 to n:
    #       A[n,j] := star(A[n,n]) . A[n,j];
    #     for i = 1 to n:
    #       B[i] += A[i,n] . B[n]
    #       for j = 1 to n:
    #         A[i,j] += A[i,n] . A[n,j]
    #
    # Result is e := B[1]
    def to_regex(root)
      states = root.visit.to_a

      a = []
      b = []

      states.each_with_index do |a_, i|
        b[i] = Ast::Literal.new('') if a_.accepting

        a[i] = []
        a_.transitions.each do |t, s|
          j = states.index(s)
          a[i][j] = a[i][j] ? union(a[i][j], Ast::Literal.new(t)) : Ast::Literal.new(t)
        end
      end

      (states.length - 1).downto(0) do |n|
        if a[n][n]
          b[n] = concat(star(a[n][n]), b[n])
          (0...n).each do |j|
            a[n][j] = concat(star(a[n][n]), a[n][j])
          end
        end

        (0...n).each do |i|
          next unless a[i][n]

          b[i] = union(b[i], concat(a[i][n], b[n]))
          (0...n).each do |j|
            a[i][j] = union(a[i][j], concat(a[i][n], a[n][j]))
          end
        end
      end

      b[0].to_s
    end

    def star(exp)
      Ast::Repetition.new(exp, '*') if exp
    end

    def union(a, b)
      if a && b && a != b
        res = nil
        a, b, start = remove_common_substring(a, b, :start)
        a, b, end_ = remove_common_substring(a, b, :end)

        if (a.respond_to?(:empty?) && a.empty?) || (b.respond_to?(:empty?) && b.empty?)
          res = Ast::Repetition.new(a.empty? ? b : a, '?')
        elsif a.is_a?(Ast::Repetition) && a.type == '?'
          res = Ast::Repetition.new(Ast::Alternation.new(a.expr, b), '?')
        elsif b.is_a?(Ast::Repetition) && b.type == '?'
          res = Ast::Repetition.new(Ast::Alternation.new(a, b.expr), '?')
        else
          ac = a.char_class if a.respond_to?(:char_class)
          bc = b.char_class if b.respond_to?(:char_class)
          res = if ac && bc
                  Ast::CharClass.new(ac, bc)
                else
                  Ast::Alternation.new(a, b)
                end
        end

        res = Ast::Concatenation.new(Ast::Literal.new(start), res) unless start.nil? || start.empty?

        res = Ast::Concatenation.new(res, Ast::Literal.new(end_)) unless end_.nil? || end_.empty?

        return res
      end

      a || b
    end

    def remove_common_substring(a, b, side)
      al = a.literal(side) if a.respond_to?(:literal)
      bl = b.literal(side) if b.respond_to?(:literal)
      return [a, b, nil] if al.nil? || bl.nil? || al.empty? || bl.empty?

      s = common_substring(al, bl, side)
      return [a, b, ''] if s.empty?

      a = a.remove_substring(side, s.length)
      b = b.remove_substring(side, s.length)

      [a, b, s]
    end

    def common_substring(a, b, side)
      dir = side == :start ? 1 : -1
      a = a.chars
      b = b.chars
      ai = dir == 1 ? 0 : a.length - 1
      ae = dir == 1 ? a.length : -1
      bi = dir == 1 ? 0 : b.length - 1
      be = dir == 1 ? b.length : -1
      res = ''

      while ai != ae && bi != be && a[ai] == b[bi]
        if dir == 1
          res += a[ai]
        else
          res = a[ai] + res
        end
        ai += dir
        bi += dir
      end

      res
    end

    def concat(a, b)
      return unless a && b

      return b if a.respond_to?(:empty?) && a.empty?
      return a if b.respond_to?(:empty?) && b.empty?

      return Ast::Literal.new(a.value + b.value) if a.is_a?(Ast::Literal) && b.is_a?(Ast::Literal)

      if a.is_a?(Ast::Literal) && b.is_a?(Ast::Concatenation) && b.a.is_a?(Ast::Literal)
        return Ast::Concatenation.new(Ast::Literal.new(a.value + b.a.value), b.b)
      end

      if b.is_a?(Ast::Literal) && a.is_a?(Ast::Concatenation) && a.b.is_a?(Ast::Literal)
        return Ast::Concatenation.new(a.a, Ast::Literal.new(a.b.value + b.value))
      end

      Ast::Concatenation.new(a, b)
    end
  end
end
