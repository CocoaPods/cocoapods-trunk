require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk::Me do
    describe 'CLAide' do
      it 'registers it self' do
        expect(Command.parse(%w( trunk me        ))).to be_an_instance_of(Command::Trunk::Me)
      end
    end

    it "should error if we don't have a token" do
      Netrc.any_instance.stubs(:[]).returns(nil)
      command = Command.parse(%w( trunk me      ))
      expect { command.validate! }.to raise_error(CLAide::Help)
    end
  end
end
