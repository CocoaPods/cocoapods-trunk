require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::AddOwner do
    describe 'CLAide' do
      it 'registers it self' do
        expect(Command.parse(%w( trunk add-owner ))).to be_an_instance_of(Command::Trunk::AddOwner)
      end
    end

    describe 'validation' do
      it "should error if we don't have a token" do
        Netrc.any_instance.stubs(:[]).returns(nil)
        command = Command.parse(%w( trunk push ))
        expect { command.validate! }.
          to raise_error(CLAide::Help, a_string_including('register a session'))
      end

      it 'should error if pod name is not supplied' do
        command = Command.parse(%w( trunk add-owner ))
        command.stubs(:token).returns('token')
        expect { command.validate! }.to raise_error(CLAide::Help, a_string_including('pod name'))
      end

      it 'should error if new owners email is not supplied' do
        command = Command.parse(%w( trunk add-owner QueryKit ))
        command.stubs(:token).returns('token')
        expect { command.validate! }.to raise_error(CLAide::Help, a_string_including('email'))
      end

      it 'should should validate with valid pod and email' do
        command = Command.parse(%w( trunk add-owner QueryKit kyle@cocoapods.org ))
        command.stubs(:token).returns('token')
        expect { command.validate! }.not_to raise_error
      end
    end

    it 'should successfully add an owner' do
      url = 'https://trunk.cocoapods.org/api/v1/pods/QueryKit/owners'
      stub_request(:patch, url).
        with(:body => '{"email":"kyle@cocoapods.org"}',
             :headers => { 'Authorization' => 'Token 527d11fe429f3426cb8dbeba183a0d80' }).
        to_return(:status => 200, :body => '[]', :headers => {})

      command = Command.parse(%w( trunk add-owner QueryKit kyle@cocoapods.org ))
      command.stubs(:token).returns('527d11fe429f3426cb8dbeba183a0d80')
      expect { command.run }.not_to raise_error
    end
  end
end
