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

        self.arguments = '[NAME SURNAME] [EMAIL]'

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

      class AddOwner < Trunk
        self.summary = 'Add an owner to a pod'

        self.arguments = '[POD] [EMAIL]'

        def initialize(argv)
          @pod, @email = argv.shift_argument, argv.shift_argument
          super
        end

        def validate!
          super
          help! 'You need to register a session first.' unless netrc['trunk.cocoapods.org']
          help! 'Specify the pod name and the new owner’s email address' unless @pod && @email
        end

        def run
          print_response REST.put("#{BASE_URL}/pods/#{@pod}/owners", { 'email' => @email }.to_yaml, 'Content-Type' => 'text/yaml', 'Authorization' => "Token #{token}")
        end
      end

      class Push < Trunk
        self.summary = 'Push a spec'
        self.arguments = '[PATH]'

        def initialize(argv)
          @path = argv.shift_argument
          super
        end

        def validate!
          super
          help! 'You need to register a session first.' unless netrc['trunk.cocoapods.org']
          help! 'Specify the path to the pod spec' unless @path
        end

        def run
          spec = Pod::Specification.from_file(@path)
          response = REST.post("#{BASE_URL}/pods", spec.to_yaml, 'Content-Type' => 'text/yaml', 'Authorization' => "Token #{token}")

          if (400...600).include?(response.status_code)
            print_response(response)
            return
          end

          status_url = response.headers['location'].first
          puts "Registered resource URL: #{status_url}"

          loop do
            response = REST.get(status_url, 'Content-Type' => 'text/yaml', 'Accept' => 'text/yaml')
            print_response(response)
            break if [200, 404].include?(response.status_code)
            sleep 2
          end
        end
      end
    end
  end
end
