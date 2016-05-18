Teaspoon.configure do |config|
  config.suite do |suite|
    suite.boot_partial = 'bundle_boot'
    suite.use_framework :jasmine, '2.3.4'
  end
end
