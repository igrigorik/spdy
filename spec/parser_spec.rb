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
    xit "should create a SYN_REPLY packet" do
      sr = SPDY::Protocol::Control::SynReply.new
      sr.header.type = 2
      sr.header.flags = 0
      sr.header.len  = 6
      sr.header.stream_id = 1

      nv = SPDY::Protocol::NV.new
      nv.pairs = 2
      nv.headers[0].assign(:name_len => 'status'.size, :name_data => 'status', :value_len => '201'.size, :value_data => '201')
      nv.headers[1].assign(:name_len => 'version'.size, :name_data => 'version', :value_len => 'HTTP/1.1'.size, :value_data => 'HTTP/1.1')

      nv = SPDY::Zlib.deflate(nv.to_binary_s)
      p [:nv_compressed, nv, nv.size]

      sr.header.len  = sr.header.len.to_i + (nv.size)
      sr.data = nv

      p sr
      p sr.to_binary_s

    end

    it "should parse SYN_REPLY packet" do
      sr = SPDY::Protocol::Control::SynReply.new
      sr.parse(SYN_REPLY)

      sr.header.type.should == 2
      sr.uncompressed_data.to_h.class.should == Hash
      sr.uncompressed_data.to_h['status'].should == '200 OK'
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
