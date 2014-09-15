require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Logout do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w(trunk logout)).should.be.instance_of Command::Trunk::Logout
      end
    end

    it "shouldn't validate if the user doesn't have a session" do
      command = Pod::Command.parse(%w(trunk logout))
      command.stubs(:token)
      lambda { command.validate! }.should.raise CLAide::Help
    end

    it 'should log the user out if they have a session' do
      Netrc.any_instance.expects(:delete).with('trunk.cocoapods.org')
      Netrc.any_instance.expects(:save)

      command = Pod::Command.parse(%w(trunk logout))
      command.stubs(:token).returns('real token')
      command.run
    end
  end
end
