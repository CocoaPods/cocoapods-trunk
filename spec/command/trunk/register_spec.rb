require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Register do
    describe 'CLAide' do
      it 'registers it self' do
        expect(Command.parse(%w( trunk register ))).to be_an_instance_of(Command::Trunk::Register)
      end
    end

    it 'should error if email is not supplied' do
      Netrc.any_instance.stubs(:[]).returns(nil)
      command = Command.parse(%w( trunk register ))
      expect { command.validate! }.to raise_error(CLAide::Help, a_string_including('email address'))
    end

    it 'should register user' do
      url = 'https://trunk.cocoapods.org/api/v1/sessions'
      stub_request(:post, url).
        with(:body => hash_including('email' => 'kyle@cocoapods.org')).
        to_return(:status => 200, :body => '{"token": "acct"}')
      Netrc.any_instance.stubs(:[]).returns(nil)
      Netrc.any_instance.expects(:[]=).with('trunk.cocoapods.org', ['kyle@cocoapods.org', 'acct'])
      Netrc.any_instance.expects(:save)

      command = Command.parse(%w( trunk register kyle@cocoapods.org ))
      expect { command.run }.not_to raise_error
    end
  end
end
