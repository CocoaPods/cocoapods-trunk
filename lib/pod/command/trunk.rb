# encoding: UTF-8

require 'json'
require 'rest'
require 'netrc'

module Pod
  class Command
    class Trunk < Command
      self.abstract_command = true
      self.summary = 'Interact with the CocoaPods API (e.g. publishing new specs)'

      SCHEME_AND_HOST = ENV['TRUNK_SCHEME_AND_HOST'] || 'https://trunk.cocoapods.org'
      BASE_URL = "#{SCHEME_AND_HOST}/api/v1"

      class Register < Trunk
        self.summary = 'Manage sessions'
        self.description = <<-DESC
          Register a new account, or create a new session.

          If this is your first registration, both an `EMAIL` address and your
          `NAME` are required. If you've already registered with trunk, you may
          omit the `NAME` (unless you would like to change it).

          It is recommended that you provide a description of the session, so
          that it will be easier to identify later on. For instance, when you
          would like to clean-up your sessions. A common example is to specify
          the location where the machine, that you are using the session for, is
          physically located.

          Examples:

              $ pod trunk register eloy@example.com 'Eloy Durán' --description='Personal Laptop'
              $ pod trunk register eloy@example.com --description='Work Laptop'
              $ pod trunk register eloy@example.com
        DESC

        self.arguments = [
          CLAide::Argument.new('EMAIL', true),
          CLAide::Argument.new('NAME',  false),
        ]

        def self.options
          [
            ['--description=DESCRIPTION', 'An arbitrary description to ' \
                                          'easily identify your session ' \
                                          'later on.']
          ].concat(super)
        end

        def initialize(argv)
          @session_description = argv.option('description')
          @email, @name = argv.shift_argument, argv.shift_argument
          super
        end

        def validate!
          super
          unless @email
            help! 'Specify at least your email address.'
          end
        end

        def run
          body = {
            'email' => @email,
            'name' => @name,
            'description' => @session_description
          }.to_json
          json = json(request_path(:post, "sessions", body, default_headers))
          save_token(json['token'])
          # TODO UI.notice inserts an empty line :/
          puts '[!] Please verify the session by clicking the link in the ' \
               "verification email that has been sent to #{@email}".yellow
        end

        def save_token(token)
          netrc['trunk.cocoapods.org'] = @email, token
          netrc.save
        end
      end

      class Me < Trunk
        self.summary = 'Display information about your sessions'
        self.description = <<-DESC
          Includes information about your registration, followed by all your
          sessions.

          These are your current session, other valid sessions, unverified
          sessions, and expired sessions.
        DESC

        def validate!
          super
          unless token
            help! 'You need to register a session first.'
          end
        end

        def run
          json = json(request_path(:get, "sessions", auth_headers))
          UI.labeled 'Name', json['name']
          UI.labeled 'Email', json['email']
          UI.labeled 'Since', formatted_time(json['created_at'])

          pods = json['pods'] || []
          pods = pods.map { |pod| pod['name'] }
          pods = 'None' unless pods.any?
          UI.labeled 'Pods', pods

          sessions = json['sessions'].map do |session|
            hash = {
              :created_at => formatted_time(session['created_at']),
              :valid_until => formatted_time(session['valid_until']),
              :created_from_ip => session['created_from_ip'],
              :description => session['description']
            }
            if Time.parse(session['valid_until']) <= Time.now.utc
              hash[:color] = :red
            elsif session['verified']
              hash[:color] = session['current'] ? :cyan : :green
            else
              hash[:color] = :yellow
              hash[:valid_until] = 'Unverified'
            end
            hash
          end

          columns = [:created_at, :valid_until, :created_from_ip, :description].map do |key|
            find_max_size(sessions, key)
          end

          sessions = sessions.map do |session|
            created_at      = session[:created_at].ljust(columns[0])
            valid_until     = session[:valid_until].rjust(columns[1])
            created_from_ip = session[:created_from_ip].ljust(columns[2])
            description     = session[:description]
            msg = "#{created_at} - #{valid_until}. IP: #{created_from_ip}"
            msg << " Description: #{description}" if description
            msg.send(session[:color])
          end

          UI.labeled 'Sessions', sessions
        end

        private

        def find_max_size(sessions, key)
          sessions.map { |s| (s[key] || '').size }.max
        end

        class CleanSessions < Me
          self.summary = 'Remove sessions'
          self.description = <<-DESC
            By default this will clean-up your sessions by removing expired and
            unverified sessions.

            To remove all your sessions, except for the one you are currently
            using, specify the `--all` flag.
          DESC

          def self.options
            [
              ['--all', 'Removes all your sessions, except for the current one'],
            ].concat(super)
          end

          def initialize(argv)
            @remove_all = argv.flag?('all', false)
            super
          end

          def validate!
            super
            unless token
              help! 'You need to register a session first.'
            end
          end

          def run
            path = @remove_all ? 'sessions/all' : 'sessions'
            request_path(:delete, path, auth_headers)
          end
        end
      end

      class AddOwner < Trunk
        self.summary = 'Add an owner to a pod'
        self.description = <<-DESC
          Adds the registered user with specified `OWNER-EMAIL` as an owner
          of the given `POD`.
          An ‘owner’ is a registered user whom is allowed to make changes to a
          pod, such as pushing new versions and adding other ‘owners’.
        DESC

        self.arguments = [
          CLAide::Argument.new('POD', true),
          CLAide::Argument.new('OWNER-EMAIL', true)
        ]

        def initialize(argv)
          @pod, @email = argv.shift_argument, argv.shift_argument
          super
        end

        def validate!
          super
          unless token
            help! 'You need to register a session first.'
          end
          unless @pod && @email
            help! 'Specify the pod name and the new owner’s email address.'
          end
        end

        def run
          body = { 'email' => @email }.to_json
          json = json(request_path(:patch, "pods/#{@pod}/owners", body, auth_headers))
          UI.labeled 'Owners', json.map { |o| "#{o['name']} <#{o['email']}>" }
        end
      end

      class Push < Trunk
        self.summary = 'Publish a podspec'
        self.description = <<-DESC
          Publish the podspec at `PATH` to make it available to all users of
          the ‘master’ spec-repo. If `PATH` is not provided, defaults to the
          current directory.

          Before pushing the podspec to cocoapods.org, this will perform a local
          lint of the podspec, including a build of the library. However, it
          remains *your* responsibility to ensure that the published podspec
          will actually work for your users. Thus it is recommended that you
          *first* try to use the podspec to integrate the library into your demo
          and/or real application.

          If this is the first time you publish a spec for this pod, you will
          automatically be registered as the ‘owner’ of this pod. (Note that
          ‘owner’ in this case implies a person that is allowed to publish new
          versions and add other ‘owners’, not necessarily the library author.)
        DESC

        self.arguments = [
          CLAide::Argument.new('PATH', false)
        ]

        def self.options
          [
            ["--allow-warnings", "Allows push even if there are lint warnings"],
          ].concat(super)
        end

        def initialize(argv)
          @allow_warnings = argv.flag?('allow-warnings')
          @path = argv.shift_argument || '.'
          find_podspec_file if File.directory?(@path)
          super
        end

        def validate!
          super
          unless token
            help! 'You need to register a session first.'
          end
          unless @path
            help! 'Please specify the path to the podspec file.'
          end
          unless File.exist?(@path) && !File.directory?(@path)
            help! "The specified path `#{@path}` does not point to " \
              'an existing podspec file.'
          end
        end

        def run
          validate_podspec
          response = request_path(:post, "pods", spec.to_json, auth_headers)
          url = response.headers['location'].first
          json = json(request_url(:get, url, default_headers))

          # Using UI.labeled here is dangerous, as it wraps the URL and indents
          # it, which breaks the URL when you try to copy-paste it.
          $stdout.puts "  - Data URL: #{json['data_url']}"

          messages = json['messages'].map do |entry|
            at, message = entry.to_a.flatten
            "#{formatted_time(at)}: #{message}"
          end
          UI.labeled 'Log messages', messages
        end

        private

        def find_podspec_file
          podspecs = Dir[Pathname(@path) + '*.podspec{.json,}']
          case podspecs.count
            when 0
              UI.notice "No podspec found in directory `#{@path}`"
            when 1
              UI.notice "Found podspec `#{podspecs[0]}`"
            else
              UI.notice "Multiple podspec files in directory `#{@path}`. " \
                'You need to explicitly specify which one to use.'
          end
          @path = (podspecs.count == 1) ? podspecs[0] : nil
        end

        def spec
          @spec ||= Pod::Specification.from_file(@path)
        rescue Informative # TODO: this should be a more specific error
          raise Informative, 'Unable to interpret the specified path as a ' \
                             'podspec.'
        end

        # Performs a full lint against the podspecs.
        #
        # TODO: Currently copied verbatim from `pod push`.
        def validate_podspec
          UI.puts 'Validating podspec'.yellow
          validator = Validator.new(spec)
          validator.only_errors = @allow_warnings
          begin
            validator.validate
          rescue Exception
            # TODO: We should add `CLAide::InformativeError#wraps_exception`
            # which would include the original error message on `--verbose`.
            # https://github.com/CocoaPods/CLAide/issues/31
            raise Informative, "The podspec does not validate."
          end
          unless validator.validated?
            raise Informative, "The podspec does not validate."
          end
        end
      end

      private

      def request_url(action, url, *args)
        response = create_request(action, url, *args)
        if (400...600).include?(response.status_code)
          print_error(response.body)
        end
        response
      end

      def request_path(action, path, *args)
        request_url(action, "#{BASE_URL}/#{path}", *args)
      end

      def create_request(*args)
        if verbose?
          REST.send(*args) do |request|
            request.set_debug_output($stdout)
          end
        else
          REST.send(*args)
        end
      end

      def print_error(body)
        begin
          json = JSON.parse(body)
        rescue JSON::ParserError
          json = {}
        end

        case error = json['error']
        when Hash
          lines = error.sort_by(&:first).map do |attr, messages|
            attr = attr[0,1].upcase << attr[1..-1]
            messages.sort.map do |message|
              "- #{attr} #{message}."
            end
          end.flatten
          count = lines.size
          lines.unshift "The following #{'validation'.pluralize(count)} failed:"
          error = lines.join("\n")
        when nil
          error = "An unexpected error ocurred: #{body}"
        end

        raise Informative, error
      end

      def json(response)
        JSON.parse(response.body)
      end

      def netrc
        @@netrc ||= Netrc.read
      end

      def token
        netrc['trunk.cocoapods.org'] && netrc['trunk.cocoapods.org'].last
      end

      def default_headers
        {
          'Content-Type' => 'application/json; charset=utf-8',
          'Accept' => 'application/json; charset=utf-8'
        }
      end

      def auth_headers
        default_headers.merge('Authorization' => "Token #{token}")
      end

      def formatted_time(time_string)
        require 'active_support/time'
        @tz_offset ||= Time.zone_offset(`/bin/date +%Z`.strip)
        @current_year ||= Date.today.year

        time = Time.parse(time_string) + @tz_offset
        formatted = time.to_formatted_s(:long_ordinal)
        # No need to show the current year, the user will probably know.
        if time.year == @current_year
          formatted.sub!(" #{@current_year}", '')
        end
        formatted
      end
    end
  end
end
