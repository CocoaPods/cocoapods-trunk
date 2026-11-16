require File.expand_path('../../../spec_helper', __FILE__)
require 'tmpdir'

module Pod
  describe Command::Trunk::Deprecate do
    describe 'CLAide' do
      it 'registers it self' do
        expect(Command.parse(%w( trunk deprecate ))).to be_an_instance_of(Command::Trunk::Deprecate)
      end
    end

    it 'should error without a pod name' do
      command = Command.parse(%w( trunk deprecate ))
      expect { command.validate! }.to raise_error(CLAide::Help)
    end

    before do
      @push_response = {
        'messages' => [
          {
            '2015-12-05 02:00:25 UTC' => 'Push for `Stencil 0.96.3` initiated.',
          },
          {
            '2015-12-05 02:00:26 UTC' => 'Push for `Stencil 0.96.3` has been pushed (1.02409270 s).',
          },
        ],
        'data_url' => 'https://raw.githubusercontent.com/CocoaPods/Specs/ce4efe9f986d297008e8c61010a4b0d5881c50d0/Specs/Stencil/0.96.3/Stencil.podspec.json',
      }
    end

    it 'should show information for a pod' do
      Command::Trunk::Deprecate.any_instance.expects(:deprecate).returns(@push_response)
      Command::Trunk::Deprecate.invoke(%w(Stencil))

      expect(UI.output).to include('Data URL: https://raw.githubusercontent')
      expect(UI.output).to include('Push for `Stencil 0.96.3` initiated')
    end

    it 'should send the proper network request' do
      redirect = 'http://redirected.com'
      stub_request(:patch, 'https://trunk.cocoapods.org/api/v1/pods/Stencil/deprecated').
        with(:body => hash_including('in_favor_of' => 'Stamp')).
        to_return(:status => 201, :headers => { :location => redirect })

      stub_request(:get, redirect).
        to_return(:status => 200, :body => @push_response.to_json)

      Command::Trunk::Deprecate.invoke(%w(Stencil --in-favor-of=Stamp))

      expect(UI.output).to eq(<<-EOS)
  - Data URL: https://raw.githubusercontent.com/CocoaPods/Specs/ce4efe9f986d297008e8c61010a4b0d5881c50d0/Specs/Stencil/0.96.3/Stencil.podspec.json
- Log messages:
  - December 5th, 2015 02:00: Push for `Stencil 0.96.3` initiated.
  - December 5th, 2015 02:00: Push for `Stencil 0.96.3` has been pushed (1.02409270 s).
      EOS
    end
  end
end
