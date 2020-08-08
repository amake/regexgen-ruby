# frozen_string_literal: true

require 'test_helper'

module Regexgen
  class RegexgenTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Regexgen::VERSION
    end

    def test_trie
      sut = Trie.new
      %w[foo foobar fool flake fo].each(&sut.method(:add))

      expected = { 'f' => { 'o' => { 'o' => { 'b' => { 'a' => { 'r' => { '' => nil } } },
                                              'l' => { '' => nil }, '' => nil }, '' => nil },
                            'l' => { 'a' => { 'k' => { 'e' => { '' => nil } } } } } }
      assert_equal(expected, sut.root.to_h)
    end

    def test_minimize
      sut = Trie.new
      %w[foo foobar fool flake fo].each(&sut.method(:add))
      # TODO: Real test
      refute_nil sut.minimize
    end

    def test_trie_to_regex
      strings = %w[foo foobar fool flake fo]
      sut = Trie.new
      strings.each(&sut.method(:add))

      assert_equal('f(?:o(?:o(?:bar|l)?)?|lake)', sut.to_s)
      regex = sut.to_regex
      assert(strings.all?(&regex.method(:match?)))
    end

    def test_regex
      strings = %w[foo foobar fool flake fo]
      regex = Regexgen.generate(*strings)
      assert(strings.all?(&regex.method(:match?)))
    end
  end
end
