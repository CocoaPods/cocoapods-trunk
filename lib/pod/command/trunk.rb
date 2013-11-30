require 'rest'

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
          print_response REST.post("#{BASE_URL}/register", { 'email' => @email, 'name' => @name }.to_yaml, 'Content-Type' => 'text/yaml')
        end
      end
    end
  end
end
