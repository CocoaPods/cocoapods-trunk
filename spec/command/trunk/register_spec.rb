require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Register do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w(        trunk register        )).should.be.instance_of Command::Trunk::Register
      end
    end

    it "shouldn't let a user register if they already have a session" do
      command = Pod::Command.parse(%w(trunk register kyle@example.com))
      command.stubs(:token).returns('valid token')
      lambda { command.validate! }.should.raise CLAide::Help
    end
  end
end
