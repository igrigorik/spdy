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
    lambda { s << DATA }.should_not raise_error
  end

  it "should reassemble broken packets" do
    stream, data = nil
    s.on_body { |stream_id, d| stream, data = stream_id, d }

    lambda { s << DATA[0...DATA.size - 10] }.should_not raise_error
    lambda { s << DATA[DATA.size-10..DATA.size] }.should_not raise_error

    stream.should == 1
    data.should == 'This is SPDY.'

    fired = false
    s.on_headers_complete { fired = true }
    s << SYN_STREAM

    fired.should be_true
  end

  context "CONTROL" do
    it "should parse SYN_STREAM packet" do
      fired = false
      s.on_headers_complete { fired = true }
      s << SYN_STREAM

      fired.should be_true
    end

    it "should return parsed headers" do
      sid, asid, pri, headers = nil
      s.on_headers_complete do |stream, astream, priority, head|
        sid = stream; asid = astream; pri = priority; headers = head
      end

      s << SYN_STREAM

      sid.should == 1
      asid.should == 0
      pri.should == 0

      headers.class.should == Hash
      headers['version'].should == "HTTP/1.1"
    end
    
    it "should parse PING packet" do
      fired = false
      s.on_ping { |num| fired = num }
      s << PING

      fired.should == 1
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
      s.on_message_complete { |s| f2 = s }

      sr = SPDY::Protocol::Control::SynStream.new
      sr.header.stream_id = 3
      sr.header.type  = 1
      sr.header.flags = 0x01
      sr.header.len = 10

      s << sr.to_binary_s

      f1.should be_true
      f2.should == 3
    end

    it "should invoke message_complete on FIN flag in DATA packet" do
      f1, f2 = false
      s.on_body { f1 = true }
      s.on_message_complete { |s| f2 = s }

      s << DATA_FIN

      f1.should be_true
      f2.should == 1
    end

  end

end
