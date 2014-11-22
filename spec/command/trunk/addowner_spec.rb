require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::AddOwner do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w( trunk add-owner )).should.be.instance_of Command::Trunk::AddOwner
      end
    end

    describe 'validation' do
      it "should error if we don't have a token" do
        Netrc.any_instance.stubs(:[]).returns(nil)
        command = Command.parse(%w( trunk push ))
        exception = lambda { command.validate! }.should.raise CLAide::Help
        exception.message.should.include 'register a session'
      end

      it 'should error if pod name is not supplied' do
        command = Command.parse(%w( trunk add-owner ))
        command.stubs(:token).returns('token')
        exception = lambda { command.validate! }.should.raise CLAide::Help
        exception.message.should.include 'pod name'
      end

      it 'should error if new owners email is not supplied' do
        command = Command.parse(%w( trunk add-owner QueryKit ))
        command.stubs(:token).returns('token')
        exception = lambda { command.validate! }.should.raise CLAide::Help
        exception.message.should.include 'email'
      end

      it 'should should validate with valid pod and email' do
        command = Command.parse(%w( trunk add-owner QueryKit kyle@cocoapods.org ))
        command.stubs(:token).returns('token')
        lambda { command.validate! }.should.not.raise CLAide::Help
      end
    end
  end
end
