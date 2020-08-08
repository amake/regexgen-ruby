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
  end
end
