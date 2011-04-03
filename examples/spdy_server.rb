$: << 'lib' << '../lib'

require 'eventmachine'
require 'spdy'

class SPDYHandler < EM::Connection
  def post_init
    @parser = SPDY::Parser.new
    @parser.on_headers_complete do |h|
      p [:SPDY_HEADERS, h]

      sr = SPDY::Protocol::Control::SynReply.new
      h = {'Content-Type' => 'text/plain', 'status' => '200 OK', 'version' => 'HTTP/1.1'}
      sr.create(:stream_id => 1, :headers => h)
      send_data sr.to_binary_s

      p [:SPDY, :sent, :SYN_REPLY]

      d = SPDY::Protocol::Data::Frame.new
      d.create(:stream_id => 1, :data => "This is SPDY.")
      send_data d.to_binary_s

      p [:SPDY, :sent, :DATA]

      d = SPDY::Protocol::Data::Frame.new
      d.create(:stream_id => 1, :flags => 1)
      send_data d.to_binary_s

      p [:SPDY, :sent, :DATA_FIN]
    end

    start_tls
  end

  def receive_data(data)
    @parser << data
  end

  def unbind
    p [:SPDY, :connection_closed]
  end
end

EM.run do
  EM.start_server '0.0.0.0', ARGV[0], SPDYHandler
end

# > ruby spdy_server.rb 10001