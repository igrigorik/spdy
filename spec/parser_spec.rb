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
      sr.header.type = 2
      sr.header.len  = 6
      sr.header.stream_id = 1

      nv = SPDY::Protocol::NV.new
      nv.pairs = 2
      nv.headers[0].assign(:name_len => 'status'.size, :name_data => 'status', :value_len => '200'.size, :value_data => '200')
      nv.headers[1].assign(:name_len => 'version'.size, :name_data => 'version', :value_len => 'HTTP/1.1'.size, :value_data => 'HTTP/1.1')

      p sr
      nv = SPDY::Zlib.deflate(nv.to_binary_s)
      p [:nv_compressed, nv, nv.size]

      sr.header.len  = sr.header.len.to_i + (nv.size*4)
      sr.data = nv
      p [sr.to_binary_s]

      p sr.to_binary_s << nv
    end
  end

  context "RST_STREAM" do
    it "should parse reset packet"
  end
end
