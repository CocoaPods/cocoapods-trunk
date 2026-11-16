# Set up coverage analysis
#-----------------------------------------------------------------------------#

# if RUBY_VERSION >= '1.9.3'
#   require 'codeclimate-test-reporter'
#   CodeClimate::TestReporter.configure do |config|
#     config.logger.level = Logger::WARN
#   end
#   CodeClimate::TestReporter.start
# end

# Set up
#-----------------------------------------------------------------------------#

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
$:.unshift((ROOT + 'spec').to_s)

require 'bundler/setup'
require 'rspec'
require 'mocha/api'
require 'webmock'

include WebMock::API
WebMock.enable!
WebMock.disable_net_connect!(:allow => ['codeclimate.com', 'cdn.cocoapods.org'])

require 'cocoapods'

require 'cocoapods_plugin'

# Helpers
#-----------------------------------------------------------------------------#

module Pod
  # Disable the wrapping so the output is deterministic in the tests.
  #
  UI.disable_wrap = true

  # Redirects the messages to an internal store.
  #
  module UI
    @output = ''
    @warnings = ''

    class << self
      attr_accessor :output
      attr_accessor :warnings
      attr_accessor :inputs

      def gets
        inputs.shift
      end

      def puts(message = '')
        @output << "#{message}\n"
      end

      def warn(message = '', _actions = [])
        @warnings << "#{message}\n"
      end

      def print(message)
        @output << message
      end
    end
  end

  class Command::Trunk
    def time_zone
      'UTC'
    end
  end
end

RSpec.configure do |config|
  config.mock_with :mocha
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.before do
    ::Pod::Config.instance = nil
    ::Pod::UI.output = ''
    ::Pod::UI.warnings = ''
    ::Pod::UI.inputs = []
    # The following prevents a nasty behaviour where the increments are not
    # balanced when testing informative which might lead to sections not
    # being printed to the output as they are too nested.
    ::Pod::UI.indentation_level = 0
    ::Pod::UI.title_level = 0

    WebMock.reset!
  end
end
