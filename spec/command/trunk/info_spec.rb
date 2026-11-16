require File.expand_path('../../../spec_helper', __FILE__)
require 'tmpdir'

module Pod
  describe Command::Trunk::Info do
    describe 'CLAide' do
      it 'registers it self' do
        expect(Command.parse(%w( trunk info ))).to be_an_instance_of(Command::Trunk::Info)
      end
    end

    it 'should error without a pod name' do
      command = Command.parse(%w( trunk info ))
      expect { command.validate! }.to raise_error(CLAide::Help)
    end

    it 'should show information for a pod' do
      url = 'https://trunk.cocoapods.org/api/v1/pods/Stencil'
      stub_request(:get, url).to_return(:body => {
        'owners' => [
          {
            'name' => 'Kyle Fuller',
            'email' => 'kyle@example.com',
          },
        ],
      }.to_json)

      command = Command.parse(%w( trunk info Stencil ))
      expect { command.validate! }.not_to raise_error
      command.run

      expect(UI.output).to include('Owners')
      expect(UI.output).to include('Kyle Fuller <kyle@example.com>')
    end

    it 'reports network errors as an informative error' do
      stub_request(:get, "#{Command::Trunk::BASE_URL}/pods/Stencil").
        to_raise(OpenSSL::SSL::SSLError.new('certificate verify failed'))

      command = Command.parse(%w( trunk info Stencil ))
      expect { command.run }.to raise_error(Informative, a_string_including('certificate verify failed'))
    end
  end
end
