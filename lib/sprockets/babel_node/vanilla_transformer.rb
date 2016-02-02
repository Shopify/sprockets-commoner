module Sprockets
  class BabelNode
    class VanillaTransformer < BabelNode
      private
        def options(input)
          super.merge('babelrc' => false)
        end
    end
  end
end
