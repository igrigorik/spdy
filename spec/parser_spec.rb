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

  context "NV" do
    it "should create an NV packet" do
      nv = SPDY::Protocol::NV.new
      headers = {'Content-Type' => 'text/plain', 'status' => '200 OK', 'version' => 'HTTP/1.1'}

      headers.each do |k, v|
        nv.headers << {:name_len => k.size, :name_data => k, :value_len => v.size, :value_data => v}
      end

      nv.pairs = headers.size
      nv.to_binary_s.should == NV
    end
  end

  context "SYN_REPLY" do
    it "should create a SYN_REPLY packet" do
      sr = SPDY::Protocol::Control::SynReply.new

      headers = {'Content-Type' => 'text/plain', 'status' => '200 OK', 'version' => 'HTTP/1.1'}
      sr.create(:stream_id => 1, :headers => headers)

      sr.header.version.should == 2
      sr.header.stream_id.should == 1

      sr.header.len.should > 50
      sr.data.should_not be_nil

      sr.to_binary_s.should == SYN_REPLY
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
    it "should create a data frame" do
      data = "This is SPDY."

      d = SPDY::Protocol::Data::Frame.new
      d.create(:stream_id => 1, :data => data)

      d.to_binary_s.should == DATA
    end

    it "should create a FIN data frame" do
      d = SPDY::Protocol::Data::Frame.new
      d.create(:stream_id => 1, :flags => 1)

      d.to_binary_s.should == DATA_FIN
    end
  end

  # context "RST_STREAM" do
  #   it "should parse reset packet"
  # end
end
