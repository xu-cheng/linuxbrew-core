class Inlets < Formula
  desc "Expose your local endpoints to the Internet"
  homepage "https://github.com/inlets/inlets"
  url "https://github.com/inlets/inlets.git",
      :tag      => "2.6.1",
      :revision => "5a1abcf24dcd30dc4a251902aa6cc7cb981ef0ae"

  bottle do
    cellar :any_skip_relocation
    sha256 "ab879c3612195a1229a424c44fbc238239058b475da8795d618fce8176874bae" => :catalina
    sha256 "1f4fe93d4582e86f348ab9e1b52ed9fa90f799d73ae90e7bf79ea30d7617cd0c" => :mojave
    sha256 "0550e3d07c29db12fcc3de100273c582bb2cd7fe0f2e9b665021fa9e7572bdbe" => :high_sierra
    sha256 "7aa505665af1c93789247ef837d0c2ce882e450dacb0f7bc028545a88a99808f" => :x86_64_linux
  end

  depends_on "go" => :build
  depends_on "ruby" => :test unless OS.mac?

  def install
    ENV["GOPATH"] = buildpath
    (buildpath/"src/github.com/inlets/inlets").install buildpath.children
    cd "src/github.com/inlets/inlets" do
      commit = Utils.popen_read("git", "rev-parse", "HEAD").chomp
      system "go", "build", "-ldflags",
             "-s -w -X main.GitCommit=#{commit} -X main.Version=#{version}",
             "-a",
             "-installsuffix", "cgo", "-o", bin/"inlets"
      prefix.install_metafiles
    end
  end

  def cleanup(name, pid)
    puts "Tearing down #{name} on PID #{pid}"
    Process.kill("TERM", pid)
    Process.wait(pid)
  end

  MOCK_RESPONSE = "INLETS OK".freeze
  SECRET_TOKEN = "itsasecret-sssshhhhh".freeze

  test do
    upstream_server = TCPServer.new(0)
    upstream_port = upstream_server.addr[1]
    remote_server = TCPServer.new(0)
    remote_port = remote_server.addr[1]
    upstream_server.close
    remote_server.close

    puts "Starting mock server on: localhost:#{upstream_port}"

    (testpath/"mock_upstream_server.rb").write <<~EOS
      require 'socket'

      server = TCPServer.new('localhost', #{upstream_port})

      loop do
        socket = server.accept
        request = socket.gets
        STDERR.puts request

        response = "OK\\n"
        shutdown = false

        if request.include? "inlets-test"
          response = "#{MOCK_RESPONSE}\\n"
          shutdown = true
        end

        socket.print "HTTP/1.1 200 OK\\r\\n" +
                    "Host: localhost:#{upstream_port}\\r\\n" +
                    "Content-Type: text/plain\\r\\n" +
                    "Content-Length: \#\{response.bytesize\}\\r\\n" +
                    "Connection: close\\r\\n"

        socket.print "\\r\\n"
        socket.print response
        socket.close

        if shutdown
          puts "Exiting test server"
          exit 0
        end
      end
    EOS

    mock_upstream_server_pid = fork do
      exec "ruby mock_upstream_server.rb" if OS.mac?
      exec "#{Formula["ruby"].opt_bin}/ruby mock_upstream_server.rb" unless OS.mac?
    end

    begin
      require "uri"
      require "net/http"

      stable_resource = stable.instance_variable_get(:@resource)
      commit = stable_resource.instance_variable_get(:@specs)[:revision]

      # Basic --version test
      inlets_version = shell_output("#{bin}/inlets version")
      assert_match /\s#{commit}$/, inlets_version
      assert_match /\s#{version}$/, inlets_version

      # Client/Server e2e test
      # This test involves establishing a client-server inlets tunnel on the
      # remote_port, running a mock server on the upstream_port and then
      # testing that we can hit the mock server upstream_port via the tunnel remote_port
      puts "Waiting for mock server"
      sleep 3
      server_pid = fork do
        puts "Starting inlets server with port #{remote_port}"
        exec "#{bin}/inlets server --port #{remote_port} --token #{SECRET_TOKEN}"
      end

      client_pid = fork do
        puts "Starting inlets client with remote localhost:#{remote_port}, upstream localhost:#{upstream_port}, token: #{SECRET_TOKEN}"
        exec "#{bin}/inlets client --remote localhost:#{remote_port} --upstream localhost:#{upstream_port} --token #{SECRET_TOKEN}"
      end

      puts "Waiting for inlets websocket tunnel"
      sleep 3

      uri = URI("http://localhost:#{remote_port}/inlets-test")
      puts "Querying upstream endpoint via inlets remote: #{uri}"
      response = Net::HTTP.get_response(uri)
      assert_match MOCK_RESPONSE, response.body
      assert_equal response.code, "200"
    ensure
      cleanup("Mock Server", mock_upstream_server_pid)
      cleanup("Inlets Server", server_pid)
      cleanup("Inlets Client", client_pid)
    end
  end
end
