# frozen_string_literal: true

require 'set'

module Regexgen
  module SetUtil
    refine Set do
      def shift
        item = first
        delete(first)
        item
      end

      def replace_item(search, *replacements)
        raise("Failed to delete #{search}") unless delete?(search)

        merge(replacements)
      end
    end
  end
end
