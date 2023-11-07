module Pod
  class Command
    class Trunk
      # @CocoaPods 1.2.1+
      #
      class Rename < Me
        self.summary = 'Rename your account'
        self.description = <<-DESC
              Updates your username for your Trunk account.

              Examples:

                  $ pod trunk me rename 'Eloy Durán'
                  $ pod trunk me rename 'Orta Therox'
        DESC

        self.arguments = [
          CLAide::Argument.new('NAME', true),
        ]

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          unless @name
            help! 'Please specify a name.'
          end
        end

        def run
          email = netrc['trunk.cocoapods.org'] && netrc['trunk.cocoapods.org'].login
          body = { 'name' => @name, 'email' => email }.to_json
          json(request_path(:post, 'sessions', body, auth_headers))
        rescue REST::Error => e
          raise Informative, 'There was an error re-naming your account on trunk: ' \
                                 "#{e.message}"
        end
      end
    end
  end
end
