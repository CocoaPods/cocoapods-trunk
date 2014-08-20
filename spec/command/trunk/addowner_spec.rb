require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::AddOwner do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w(        trunk add-owner        )).should.be.instance_of Command::Trunk::AddOwner
      end
    end
  end
end
