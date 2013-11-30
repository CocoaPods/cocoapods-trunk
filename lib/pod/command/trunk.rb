require 'rest'
require 'netrc'

module Pod
  class Command
    class Trunk < Command
      self.abstract_command = true
      self.summary = 'Interact with trunk.cocoapods.org'

      private

      BASE_URL = 'https://trunk.cocoapods.org/api/v1'

      def print_response(response)
        puts "[HTTP: #{response.status_code}]"
        puts response.body
      end

      def netrc
        @@netrc ||= Netrc.read
      end

      def token
        netrc['trunk.cocoapods.org'].first
      end

      class Register < Trunk
        self.summary = 'Manage sessions'
        self.description = <<-DESC
          Register a new account or create a new session.
        DESC

        self.arguments = '[Name Surname] [Email]'

        def initialize(argv)
          @name, @email = argv.shift_argument, argv.shift_argument
          super
        end

        def validate!
          super
          help! 'Specify both your name and email address' unless @name && @email
        end

        def run
          response = REST.post("#{BASE_URL}/register", { 'email' => @email, 'name' => @name }.to_yaml, 'Content-Type' => 'text/yaml')
          token = YAML.load(response.body)['token']
          netrc['trunk.cocoapods.org'] = token, 'x'
          netrc.save
          print_response(response)
          puts 'Saved token to ~/.netrc, please verify session by clicking the link in the verification email that has been sent.'
        end
      end

      class Me < Trunk
        self.summary = 'Display information about your session.'

        def validate!
          super
          help! 'You need to register a session first.' unless netrc['trunk.cocoapods.org']
        end

        def run
          print_response REST.get("#{BASE_URL}/me", 'Content-Type' => 'text/yaml', 'Authorization' => "Token #{token}")
        end
      end
    end
  end
end
