module Pod
  class Command
    class Trunk
      class Delete < Trunk
        self.summary = 'Deletes a version of a pod.'
        self.description = <<-DESC
              Deletes the specified pod version from trunk and the master specs
              repo. Once deleted, this version can never be pushed again.
        DESC

        self.arguments = [
          CLAide::Argument.new('NAME', true),
          CLAide::Argument.new('VERSION', true),
        ]

        def initialize(argv)
          @name = argv.shift_argument
          @version = argv.shift_argument
          super
        end

        def validate!
          super
          help! 'Please specify a pod name.' unless @name
          help! 'Please specify a version.' unless @version
        end

        def run
          json = delete
          print_messages(json['data_url'], json['messages'])
        end

        def delete
          response = request_path(:delete, "pods/#{@name}/#{@version}", auth_headers)
          url = response.headers['location'].first
          json(request_url(:get, url, default_headers))
        rescue REST::Error => e
          raise Informative, 'There was an error deleting the pod version ' \
                                   "from trunk: #{e.message}"
        end
      end
    end
  end
end
