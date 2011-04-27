require 'helper'

describe SPDY::Protocol do

  context "NV" do
    describe "creating a packet" do
      before do
        nv = SPDY::Protocol::NV.new

        @key_values = {'version' => 'HTTP/1.1', 'status' => '200 OK', 'Content-Type' => 'text/plain'}
        nv.create(@key_values)

        @binary_string = nv.to_binary_s
      end

      it "begins with the number of key-value pairs" do
        @binary_string[0..1].should == "\x00\x03"
      end

      it "prefaces keys with the length of the key" do
        @binary_string.should =~ %r{\x00\x0cContent-Type}
      end
      it "prefaces values with the length of the value" do
        @binary_string.should =~ %r{\x00\x08HTTP/1.1}
      end

      it "has 2 bytes (total number of key-value pairs) + 2 bytes for each key (length of key) + 2 bytes for each value (length of value) + keys + values" do
        num_size_bytes = 2 + @key_values.size * (2 + 2)

        @binary_string.length.should ==
          @key_values.inject(num_size_bytes) {|sum, kv| sum + kv[0].length + kv[1].length}
      end
    end
  end

  context "SYN_STREAM" do
    it "should create a SYN_STREAM packet" do
      sr = SPDY::Protocol::Control::SynStream.new

      headers = {
        "accept"=>"application/xml", "host"=>"127.0.0.1:9000",
        "method"=>"GET", "scheme"=>"https",
        "url"=>"/?echo=a&format=json","version"=>"HTTP/1.1"
      }

      sr.create(:stream_id => 1, :headers => headers)
      sr.header.version.should == 2
      sr.pri.should == 0

      sr.header.len.should > 50
      sr.data.should_not be_nil

      st = SPDY::Protocol::Control::SynStream.new
      st.parse(sr.to_binary_s)
      st.num_bytes.should == sr.to_binary_s.size
    end

    it "should parse SYN_STREAM packet" do
      sr = SPDY::Protocol::Control::SynStream.new
      sr.parse(SYN_STREAM)

      sr.num_bytes.should == SYN_STREAM.size

      sr.header.type.should == 1
      sr.uncompressed_data.to_h.class.should == Hash
      sr.uncompressed_data.to_h['method'].should == 'GET'

      sr.to_binary_s.should == SYN_STREAM
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

    it "should read a FIN data frame" do
      d = SPDY::Protocol::Data::Frame.new
      d.create(:stream_id => 1, :flags => 1)

      d.to_binary_s.should == DATA_FIN
      pckt = SPDY::Protocol::Data::Frame.new.read(d.to_binary_s)
      pckt.flags.should == 1
    end

  end

  # context "RST_STREAM" do
  #   it "should parse reset packet"
  # end
end
