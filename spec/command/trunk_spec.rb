require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Trunk do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w( trunk        )).should.be.instance_of Command::Trunk
      end
    end

    before do
      @command = Command.parse(%w(trunk))
    end

    describe 'authorization' do
      it 'will use the trunk token from ENV if present' do
        ENV.stubs(:[]).with('COCOAPODS_TRUNK_TOKEN').returns('token')

        @command.send(:token).should == 'token'
      end
    end

    describe '#netrc_path' do
      it 'uses the user home directory by default' do
        ENV.stubs(:[]).with('NETRC').returns(nil)
        Dir.stubs(:home).returns('/Users/testuser/')
        File.stubs(:exist?).returns(true)
        @command.send(:netrc_path).should == '/Users/testuser/.netrc.gpg'
      end

      it 'respects the NETRC environment variable' do
        ENV.stubs(:[]).with('NETRC').returns('/Users/testuser/.config/')
        File.stubs(:exist?).returns(true)
        @command.send(:netrc_path).should == '/Users/testuser/.config/.netrc.gpg'
      end

      it 'will use GPG netrc secrets when available' do
        ENV.stubs(:[]).with('NETRC').returns('/Users/testuser/')
        File.stubs(:exist?).with('/Users/testuser/.netrc.gpg').returns(true)
        @command.send(:netrc_path).should == '/Users/testuser/.netrc.gpg'
      end

      it 'will use plaintext netrc secrets when GPG is not available' do
        ENV.stubs(:[]).with('NETRC').returns('/Users/testuser/')
        File.stubs(:exist?).with('/Users/testuser/.netrc.gpg').returns(false)
        @command.send(:netrc_path).should == '/Users/testuser/.netrc'
      end
    end
  end
end
