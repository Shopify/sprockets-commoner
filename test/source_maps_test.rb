require 'test_helper'

class SimpleTest < MiniTest::Test
  def setup
    skip('Source maps require sprockets 4+') unless Sprockets::Commoner.sprockets4?
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_no_rewire_sources
    assert asset = @env['no-rewire.js']
    map = asset.metadata[:map]
    assert_equal([
      'no-rewire/index.source-b79b14bd2584dd52b0f0ef042a2a4f104cda48330500e12237737cc51fbda43d.js'
    ], map.map { |m| m[:source] }.uniq.compact)
  end

  def test_scripts_map
    assert map = @env.find_asset('scripts/index', accept: 'application/js-sourcemap+json').source
    assert_equal(
      {"version"  => 3,
       "file"     => "scripts/index.js",
       "mappings" => ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAAA;;;;;;;iCACA;AACA,eAAA,CAAA;AACA;;;;;;oBAHA;;;;;;;;oBCEA,YAAA;AACA,QAAA,IAAA,sBAAA;;AAEA,WAAA,EAAA,QAAA,EAAA;AACA",
       "sources"  => ["module.source-008145d1ad2720f5c423286b2cea62cd314bb6397ac8840714b35558708f15c3.js", "index.source-922d567407bd225aa63b683b2be298596de2c307ee3205fce711320eefc00ec4.js"],
       "names"    => []
    }, JSON.parse(map))

  end
end
