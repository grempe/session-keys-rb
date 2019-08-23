# coveralls.io
if ENV['TRAVIS'] || ENV['CI'] || ENV['JENKINS_URL'] || ENV['TDDIUM'] || ENV['COVERALLS_RUN_LOCALLY']
  # coveralls.io : web based code coverage
  require 'coveralls'
  Coveralls.wear!
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'session_keys'

require 'minitest/autorun'
require 'minitest/pride'
require 'securerandom'
