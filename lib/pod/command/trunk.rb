# encoding: UTF-8

require 'json'
require 'rest'
require 'netrc'

module Pod
  class Command
    class Trunk < Command
      self.abstract_command = true
      self.summary = 'Interact with trunk.cocoapods.org'

      SCHEME_AND_HOST = ENV['TRUNK_SCHEME_AND_HOST'] || 'https://trunk.cocoapods.org'
      BASE_URL = "#{SCHEME_AND_HOST}/api/v1"

      class Register < Trunk
        self.summary = 'Manage sessions'
        self.description = <<-DESC
          Register a new account, or create a new session.

          If this is your first registration, both an email address and your
          name are required. If you've already registered with trunk, you may
          omit the name (unless you would like to change it).

          It is recommended that you provide a description of the session, so
          that it will be easier to identify later on. For instance, when you
          would like to clean-up your sessions. A common example is to specify
          the location where the machine, that you are using the session for, is
          physically located.
        DESC

        self.arguments = 'EMAIL [NAME]'

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
          puts '[!] Saved session token to ~/.netrc. Please verify the ' \
               'session by clicking the link in the verification email that ' \
               "has been sent to #{@email}".green
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

      class AddOwner < Trunk
        self.summary = 'Add an owner to a pod'

        self.arguments = '[POD] [EMAIL]'

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
            help! 'Specify the pod name and the new owner’s email address'
          end
        end

        def run
          body = { 'email' => @email }.to_json
          request_path(:patch, "pods/#{@pod}/owners", body, auth_headers)
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
          unless token
            help! 'You need to register a session first.'
          end
          unless @path
            help! 'Specify the path to the podspec file.'
          end
        end

        def run
          spec = Pod::Specification.from_file(@path)
          response = request_path(:post, "pods", spec.to_json, auth_headers)

          if (400...600).include?(response.status_code)
            return
          end

          status_url = response.headers['location'].first
          puts "Registered resource URL: #{status_url}"

          request_url(:get, status_url, default_headers)
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
        rescue JSON::ParseError
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
    end
  end
end
