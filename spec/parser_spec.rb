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

  xit "should accept incoming data" do
    lambda { s << 'data' }.should_not raise_error
  end

  context "CONTROL" do
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

  context "DATA" do
    it "should parse data packet" do
      stream, data = nil
      s.on_body { |stream_id, d| stream, data = stream_id, d }
      s << DATA

      stream.should == 1
      data.should == 'This is SPDY.'
    end
  end

  context "FIN" do
    it "should invoke message_complete on FIN flag in CONTROL packet" do
      f1, f2 = false
      s.on_headers_complete { f1 = true }
      s.on_message_complete { f2 = true }

      sr = SPDY::Protocol::Control::SynStream.new
      sr.header.type  = 1
      sr.header.flags = 0x01
      sr.header.len = 10

      s << sr.to_binary_s

      f1.should be_true
      f2.should be_true
    end

  end

end
