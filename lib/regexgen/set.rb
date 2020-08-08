# frozen_string_literal: true

module Regexgen
  module SetUtil
    refine Set do
      def shift
        item = first
        delete(first)
        item
      end

      def replace(search, *replacements)
        raise unless delete?(search)

        merge(replacements)
      end
    end
  end
end
