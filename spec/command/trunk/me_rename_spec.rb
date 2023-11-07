require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Register do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w[trunk me rename]).should.be.instance_of Command::Trunk::Rename
      end
    end

    it 'should error if name is not supplied' do
      command = Command.parse(%w[trunk me rename])
      exception = lambda { command.validate! }.should.raise CLAide::Help
      exception.message.should.include 'name'
    end

    it 'should error if name is not supplied' do
      Netrc.any_instance.stubs(:[]).returns(nil)
      command = Command.parse(%w[trunk me rename orta])
      exception = lambda { command.validate! }.should.raise CLAide::Help
      exception.message.should.include 'You need to register a session'
    end

    it 'should send an API call to update the user' do
      url = 'https://trunk.cocoapods.org/api/v1/sessions'
      WebMock::API.stub_request(:post, url).
        with(:body => WebMock::API.hash_including('email' => 'kyle@cocoapods.org', 'name' => 'Kyle 2')).
        to_return(:status => 200, :body => '{"token": "acct"}')

      Netrc.any_instance.stubs(:[]).returns(stub('login' => 'kyle@cocoapods.org', 'password' => 'acct'))

      command = Command.parse(['trunk', 'me', 'rename', 'Kyle 2'])
      lambda { command.run }.should.not.raise
    end
  end
end
