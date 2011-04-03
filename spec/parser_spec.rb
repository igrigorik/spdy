require 'helper'

describe SPDY::Parser do
  let(:s) { SPDY::Parser.new }

  context "callbacks" do
    it "should accept header callback" do
      lambda do
        s.on_headers_complete {}
      end.should_not raise_error
    end

    it "should accept body callback" do
      lambda do
        s.on_body {}
      end.should_not raise_error
    end

    it "should accept message complete callback" do
      lambda do
        s.on_message_complete {}
      end.should_not raise_error
    end
  end

  it "should accept incoming data" do
    lambda { s << 'data' }.should_not raise_error
  end

  context "SYN_STREAM" do
    it "should parse SYN_STREAM packet" do
      fired = false
      s.on_headers_complete { fired = true }
      s << SYN_STREAM

      fired.should be_true
    end

    it "should return parsed headers" do
      headers = nil
      s.on_headers_complete { |h| headers = h }
      s << SYN_STREAM

      headers.class.should == Hash
      headers['version'].should == "HTTP/1.1"
      headers['x-spdy-version'].should == 2
      headers['x-spdy-stream_id'].should == 1
    end
  end

  context "SYN_REPLY" do
    it "should create a SYN_REPLY packet" do
      sr = SPDY::Protocol::Control::SynReply.new

      headers = {'Content-Type' => 'text/plain', 'status' => '200', 'version' => 'HTTP/1.1'}
      sr.create(:stream_id => 1, :headers => headers)

      sr.header.version.should == 2
      sr.header.stream_id.should == 1

      sr.header.len.should > 50
      sr.data.should_not be_nil

      # sr.to_binary_s.should == SYN_REPLY
    end

    it "should parse SYN_REPLY packet" do
      sr = SPDY::Protocol::Control::SynReply.new
      sr.parse(SYN_REPLY)

      sr.header.type.should == 2
      sr.uncompressed_data.to_h.class.should == Hash
      sr.uncompressed_data.to_h['status'].should == '200 OK'

      sr.to_binary_s.should == SYN_REPLY
    end
  end

  context "DATA" do
    xit "should create a data frame" do
      data = "Hello SPDY!"

      d = SPDY::Protocol::Data::Frame.new
      d.stream_id = 1
      d.flags = 0x01
      d.len = data.size
      d.data = data

      p d
      p d.to_binary_s
    end
  end

  context "RST_STREAM" do
    it "should parse reset packet"
  end
end