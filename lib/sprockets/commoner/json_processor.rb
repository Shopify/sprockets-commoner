module Sprockets
  module Commoner
    class JSONProcessor
      def self.call(input)
        { data: "module.exports = #{input[:data]};" }
      end
    end
  end
end
