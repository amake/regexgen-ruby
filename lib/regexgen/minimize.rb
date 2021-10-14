# frozen_string_literal: true

require 'regexgen/set'

module Regexgen
  using SetUtil

  class << self
    # Hopcroft's DSA minimization algorithm
    # https://en.wikipedia.org/wiki/DFA_minimization#Hopcroft's_algorithm
    #
    # Largely ported from
    # https://github.com/devongovett/regexgen/blob/7ef10aef3a414b10554822cdf6e90389582b1890/src/minimize.js
    #
    #   P := {F, Q \ F};
    #   W := {F, Q \ F};
    #   while (W is not empty) do
    #        choose and remove a set A from W
    #        for each c in Σ do
    #             let X be the set of states for which a transition on c leads to a state in A
    #             for each set Y in P for which X ∩ Y is nonempty and Y \ X is nonempty do
    #                  replace Y in P by the two sets X ∩ Y and Y \ X
    #                  if Y is in W
    #                       replace Y in W by the same two sets
    #                  else
    #                       if |X ∩ Y| <= |Y \ X|
    #                            add X ∩ Y to W
    #                       else
    #                            add Y \ X to W
    #             end;
    #        end;
    #   end;
    #
    # Key:
    #
    # {...} is a Set (yes we have sets of sets here)
    # A \ B is complement (A - B)
    # Q is all states
    # F is final states
    # Σ is the DFA's alphabet
    # c is a letter of the alphabet
    # A ∩ B is intersection (A & B)
    # |A| is the cardinality of A (A.size)
    def minimize(root)
      states = root.visit
      final_states = states.select(&:accepting).to_set

      # Create a map of incoming transitions to each state, grouped by
      # character.
      transitions = Hash.new { |h, k| h[k] = Hash.new { |h_, k_| h_[k_] = Set.new } }
      states.each_with_object(transitions) do |s, acc|
        s.transitions.each do |t, st|
          acc[st][t] << s
        end
      end

      p = Set[states, final_states]
      w = Set.new(p)
      until w.empty?
        a = w.shift

        # Collect states that have transitions leading to states in a, grouped
        # by character.
        t = Hash.new { |h, k| h[k] = Set.new }
        a.each_with_object(t) do |s, acc|
          transitions[s].each do |t_, x|
            acc[t_].merge(x)
          end
        end

        t.each_value do |x|
          p.to_a.each do |y|
            intersection = x & y
            next if intersection.empty?

            complement = y - x
            next if complement.empty?

            p.replace_item(y, intersection, complement)
            if w.include?(y)
              w.replace_item(y, intersection, complement)
            elsif intersection.size <= complement.size
              w.add(intersection)
            else
              w.add(complement)
            end
          end
        end
      end

      new_states = Hash.new { |hash, key| hash[key] = State.new }
      initial = nil

      p.each do |s|
        first = s.first
        s_ = new_states[s]
        first.transitions.each do |c, old|
          s_.transitions[c] = new_states[p.find { |v| v.include?(old) }]
        end

        s_.accepting = first.accepting

        initial = s_ if s.include?(root)
      end

      initial
    end
  end
end
