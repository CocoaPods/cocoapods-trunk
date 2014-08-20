require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Register do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w(        trunk register        )).should.be.instance_of Command::Trunk::Register
      end
    end
  end
end
