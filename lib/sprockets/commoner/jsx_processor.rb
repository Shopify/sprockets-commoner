module Sprockets
  module Commoner
    class JSXProcessor
      def self.call(input)
        { data: input[:data] }
      end
    end
  end
end
