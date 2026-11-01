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

    describe 'network requests' do
      it 'rejects a server certificate that is not trusted' do
        key = OpenSSL::PKey::RSA.new(2048)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = 1
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=127.0.0.1')
        cert.public_key = key.public_key
        cert.not_before = Time.now - 60
        cert.not_after = Time.now + 60
        cert.sign(key, OpenSSL::Digest::SHA256.new)

        context = OpenSSL::SSL::SSLContext.new
        context.cert = cert
        context.key = key
        tcp_server = TCPServer.new('127.0.0.1', 0)
        server = OpenSSL::SSL::SSLServer.new(tcp_server, context)
        thread = Thread.new do
          begin
            server.accept.close
          rescue OpenSSL::SSL::SSLError
            nil
          end
        end

        WebMock.disable!
        begin
          url = "https://127.0.0.1:#{tcp_server.addr[1]}/"
          exception = should.raise(OpenSSL::SSL::SSLError) do
            @command.send(:create_request, :get, url, {})
          end
          exception.message.should.include 'certificate verify failed'
        ensure
          WebMock.enable!
          thread.kill
          thread.join
          server.close
        end
      end

      it 'uses the proxy configured for https' do
        proxy_env = %w(https_proxy HTTPS_PROXY no_proxy NO_PROXY).map { |k| [k, ENV.delete(k)] }
        ENV['https_proxy'] = 'http://user:pass@proxy.example:8080'
        Net::HTTP.expects(:new).
          with('trunk.cocoapods.org', 443, 'proxy.example', 8080, 'user', 'pass').
          raises(SocketError)

        begin
          should.raise(SocketError) do
            @command.send(:create_request, :get, 'https://trunk.cocoapods.org/api/v1/pods/Foo', {})
          end
        ensure
          proxy_env.each { |k, v| v ? ENV[k] = v : ENV.delete(k) }
        end
      end

      it 'reports network errors as an informative error' do
        stub_request(:delete, "#{Command::Trunk::BASE_URL}/sessions").
          to_raise(OpenSSL::SSL::SSLError.new('certificate verify failed'))
        Command::Trunk.any_instance.stubs(:token).returns('token')

        command = Command.parse(%w(trunk me clean-sessions))
        exception = lambda { command.run }.should.raise(Informative)
        exception.message.should.include 'certificate verify failed'
      end
    end
  end
end
