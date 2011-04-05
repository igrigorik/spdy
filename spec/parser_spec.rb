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

end
