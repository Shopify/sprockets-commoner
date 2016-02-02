$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'sprockets'
require 'sprockets/babel_node'
env = Sprockets::Environment.new('.')
env.append_path '.'
puts env[ARGV[0]].to_s
