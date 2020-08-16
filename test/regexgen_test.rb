# frozen_string_literal: true

require 'test_helper'

module Regexgen
  class RegexgenTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Regexgen::VERSION
    end

    def test_generates_char_class
      assert_equal(/[a-c]/, Regexgen.generate(%w[a b c]))
    end

    def test_generates_char_class_without_range
      assert_equal(/[acd]/, Regexgen.generate(%w[a d c]))
    end

    def test_generates_alternation
      assert_equal(/123|abc/, Regexgen.generate(%w[abc 123]))
    end

    def test_extracts_common_prefixes_at_start
      assert_equal(/foo(?:zap|bar)/, Regexgen.generate(%w[foobar foozap]))
    end

    def test_extracts_common_prefixes_at_end
      assert_equal(/(?:zap|bar)foo/, Regexgen.generate(%w[barfoo zapfoo]))
    end

    def test_extracts_common_prefixes_at_start_and_end
      assert_equal(/foo(?:zap|bar)foo/, Regexgen.generate(%w[foobarfoo foozapfoo]))
    end

    def test_generates_optional_group
      assert_equal(/foo(?:bar)?/, Regexgen.generate(%w[foo foobar]))
    end

    def test_generates_multiple_optional_groups
      assert_equal(/f(?:ox?)?/, Regexgen.generate(%w[f fo fox]))
    end

    def test_escapes_meta_characters
      assert_equal(/foo\|bar\[test\]\+/, Regexgen.generate(['foo|bar[test]+']))
    end

    def test_handles_non_ascii_characters
      # Differs from JavaScript implementation: Ruby assumed to handle arbitrary
      # characters in regex
      assert_equal(/🎉/, Regexgen.generate(['🎉']))
    end

    def test_supports_regex_flags
      # Differs from JavaScript implementation: Ruby Regexp supports different
      # flags
      assert_equal(/foo/i, Regexgen.generate(['foo'], 'i'))
    end

    def test_trie
      sut = Trie.new
      %w[foobar foobaz].each(&sut.method(:add))

      assert_equal('fooba[rz]', sut.to_s)
      assert_equal(/fooba[rz]/, sut.to_regex)

      sut2 = Trie.new
      sut2.add_all(%w[foobar foobaz])

      assert_equal('fooba[rz]', sut2.to_s)
      assert_equal(/fooba[rz]/, sut2.to_regex)
    end

    def test_works_with_optional_groups
      assert_equal(/a(?:bc)?/, Regexgen.generate(%w[a abc]))
    end

    def test_handles_non_bmp_codepoint_ranges_correctly
      assert_equal(/[🌑-🌘]/, Regexgen.generate(['🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘']))
    end

    def test_correctly_extracts_common_prefix_from_multiple_alternations
      assert_equal(/ab(?:ze|yd|xc)?jv/, Regexgen.generate(%w[abjv abxcjv abydjv abzejv]))
    end

    def test_sorts_alternations_of_alternations_correctly
      r = Regexgen.generate(%w[aef aghz ayz abcdz abcd])
      s = 'abcdz'
      assert_equal(s, r.match(s)[0])
      assert_equal(/a(?:(?:bcd|gh|y)z|bcd|ef)/, r)
    end

    def test_prefectures
      strings = %w[北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県 茨城県 栃木県
                   群馬県 埼玉県 千葉県 東京都 神奈川県 新潟県 富山県 石川県
                   福井県 山梨県 長野県 岐阜県 静岡県 愛知県 三重県 滋賀県 京都府
                   大阪府 兵庫県 奈良県 和歌山県 鳥取県 島根県 岡山県 広島県
                   山口県 徳島県 香川県 愛媛県 高知県 福岡県 佐賀県 長崎県 熊本県
                   大分県 宮崎県 鹿児島県 沖縄県]
      sut = Trie.new
      sut.add_all(strings)

      expected = '(?:(?:鹿児|[広徳])島|神奈川|(?:和歌|[富岡])山|兵庫|大分|群馬'\
                 '|[佐滋]賀|三重|栃木|愛[媛知]|静岡|茨城|岐阜|長[崎野]'\
                 '|福[井岡島]|熊本|新潟|山[口形梨]|沖縄|[石香]川|秋田|高知|鳥取'\
                 '|宮[城崎]|千葉|島根|岩手|奈良|埼玉)県|(?:大阪|京都)府|東京都'\
                 '|青森県|北海道'
      assert_equal(expected, sut.to_s)
      regex = sut.to_regex
      assert(strings.all?(&regex.method(:match?)))
    end
  end
end
