require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Register do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w( trunk register )).should.be.instance_of Command::Trunk::Register
      end
    end

    it "should error if email is not supplied" do
      Netrc.any_instance.stubs(:[]).returns(nil)
      command = Command.parse(%w( trunk register ))
      exception = lambda { command.validate! }.should.raise CLAide::Help
      exception.message.should.include 'email address'
    end
  end
end
