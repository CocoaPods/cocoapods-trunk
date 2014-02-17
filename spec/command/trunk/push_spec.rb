require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Push do
    describe "CLAide" do
      it "registers it self" do
        Command.parse(%w{ trunk push }).should.be.instance_of Command::Trunk::Push
      end
    end
  end
end

