require 'test_helper'

class SourceMapsTest < MiniTest::Test
  def setup
    skip('Source maps require sprockets 4+') unless Sprockets::Commoner.sprockets4?
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_no_rewire_sources
    assert asset = @env['no-rewire.js']
    map = asset.metadata[:map]
    assert_equal("no-rewire/index.js", map["sections"][0]["map"]["file"])
  end

  def test_scripts_map
    assert map = @env.find_asset('scripts/index', accept: 'application/js-sourcemap+json').source
    assert_equal({
      "version" => 3,
      "file" => "scripts/index.js",
      "sections"=> [{
        "offset" => {
          "line" => 34,
          "column" => 0
        },
        "map" => {
          "version" => 3,
          "file" => "scripts/module.js",
          "mappings" => ";;;;;;;MAAA;;;;;;;iCACA;AACA,eAAA,CAAA;AACA;;;;;;oBAHA",
          "sources" => ["module.source.js"],
          "names" => []
        }
      }, {
        "offset" => {
          "line" => 57,
          "column" => 0
        },
        "map" => {
          "version" => 3,
          "file" => "scripts/index.js",
          "mappings" => ";;;;;;;oBAEA,YAAA;AACA,QAAA,IAAA,sBAAA;;AAEA,WAAA,EAAA,QAAA,EAAA;AACA",
          "sources" => ["index.source.js"],
          "names" => []
        }
      }]
    }, JSON.parse(map))
  end
end
