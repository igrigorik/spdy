require 'helper'

describe SPDY::Protocol do
  context "data frames" do
    describe "DATA" do
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
  end

  context "control frames" do
    describe "SYN_STREAM" do
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

    describe "SYN_REPLY" do
      describe "creating a packet" do
        before do
          @sr = SPDY::Protocol::Control::SynReply.new

          headers = {'Content-Type' => 'text/plain', 'status' => '200 OK', 'version' => 'HTTP/1.1'}
          @sr.create(:stream_id => 1, :headers => headers)
        end

        describe "common control frame fields" do
          it "is version 2" do
            @sr.header.version.should == 2
          end
          it "is type 2" do
            @sr.header.type.should == 2
          end
          it "has empty flags" do
            @sr.header.flags.should == 0
          end
        end

        describe "type specific frame fields" do
          it "has a stream id" do
            @sr.header.stream_id.should == 1
          end
          it "has data" do
            @sr.data.should_not be_nil
          end
          specify { @sr.header.len.should > 50 }
        end

        describe "assembled packet" do
          before do
            @packet = @sr.to_binary_s
          end

          specify "starts with a control bit" do
            @packet[0...1].should == "\x80"
          end
          specify "followed by the version" do
            @packet[1...2].should == "\x02"
          end
          specify "followed by the type" do
            @packet[2..3].should == "\x00\x02"
          end
          specify "followed by flags" do
            @packet[4...5].should == "\x00"
          end
          specify "followed by the length" do
            @packet[5..7].should == "\x00\x005"
          end
          specify "followed by the stream ID" do
            @packet[8..11].should == "\x00\x00\x00\x01"
          end
          specify "followed by unused space" do
            @packet[12..13].should == "\x00\x00"
          end
          specify "followed by compressed NV data" do
            data = SPDY::Zlib.inflate(@packet[14..-1].to_s)
            data.should =~ %r{\x00\x0cContent-Type}
          end
        end

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

    describe "RST_STREAM" do
      it "can parse a reset packet" do
        ping = SPDY::Protocol::Control::RstStream.new
        ping.parse(RST_STREAM)

        ping.stream_id.should == 1
        ping.type.should == 3

        ping.to_binary_s.should == RST_STREAM
      end

      describe "the assembled packet" do
        before do
          @rs = SPDY::Protocol::Control::RstStream.new
          @rs.create(:stream_id => 1, :status_code => 1)
          @frame = Array(@rs.to_binary_s.bytes)
        end
        specify "starts with a control bit" do
          @frame[0].should == 128
        end
        specify "followed by the version (2)" do
          @frame[1].should == 2
        end
        specify "followed by the type (3)" do
          @frame[2..3].should == [0,3]
        end
        specify "followed by flags (0)" do
          @frame[4].should == 0
        end
        specify "followed by the length (always 8)" do
          @frame[5..7].should == [0,0,8]
        end
        specify "followed by the status code" do
          @frame[8..11].should == [0,0,0,1]
        end
      end
    end

    describe "SETTINGS" do
      it "can parse a SETTINGS packet" do
        settings = SPDY::Protocol::Control::Settings.new
        settings.parse(SETTINGS)

        settings.type.should == 4
        settings.number_of_entries.should == 1

        settings.headers[0].id_data.should == SPDY::Protocol::SETTINGS_ROUND_TRIP_TIME
        settings.headers[0].value_data.should == 300

        settings.to_binary_s.should == SETTINGS
      end

      describe "the assembled packet" do
        before do
          @settings = SPDY::Protocol::Control::Settings.new
          @settings.create(
            :settings_round_trip_time => 300
          )
          @frame = Array(@settings.to_binary_s.bytes)
        end
        specify "starts with a control bit" do
          @frame[0].should == 128
        end
        specify "followed by the version (2)" do
          @frame[1].should == 2
        end
        specify "followed by the type (4)" do
          @frame[2..3].should == [0,4]
        end
        specify "followed by flags" do
          @frame[4].should == 0
        end
        specify "followed by the length (24 bits)" do
          @frame[5..7].should == [0,0,8]
        end
        specify "followed by the number of entries (32 bits)" do
          @frame[8..11].should == [0,0,0,1]
        end
        specify "followed by ID/Value Pairs (32 bits each)" do
          @frame[12..19].should == [0,0,0,3, 0,0,1,44]
        end
      end
    end

    describe "NOOP" do
      specify "not implemented (being dropped from protocol)" do
        # NOOP
      end
    end

    describe "PING" do
      it "can parse a PING packet" do
        ping = SPDY::Protocol::Control::Ping.new
        ping.parse(PING)

        ping.stream_id.should == 1
        ping.type.should == 6

        ping.to_binary_s.should == PING
      end

      describe "the assembled packet" do
        before do
          @ping = SPDY::Protocol::Control::Ping.new
          @ping.create(:stream_id => 1)
          @frame = Array(@ping.to_binary_s.bytes)
        end
        specify "starts with a control bit" do
          @frame[0].should == 128
        end
        specify "followed by the version (2)" do
          @frame[1].should == 2
        end
        specify "followed by the type (6)" do
          @frame[2..3].should == [0,6]
        end
        specify "followed by flags (0)" do
          @frame[4].should == 0
        end
        specify "followed by the length (always 4)" do
          @frame[5..7].should == [0,0,4]
        end
      end
    end

    describe "GOAWAY" do
      it "supports this frame"
    end

    describe "HEADERS" do
      it "supports this frame"
    end

    describe "NV" do
      describe "creating a packet" do
        before do
          nv = SPDY::Protocol::NV.new

          @name_values = {'version' => 'HTTP/1.1', 'status' => '200 OK', 'Content-Type' => 'text/plain'}
          nv.create(@name_values)

          @binary_string = nv.to_binary_s
        end

        it "begins with the number of name-value pairs" do
          @binary_string[0..1].should == "\x00\x03"
        end

        it "prefaces names with the length of the name" do
          @binary_string.should =~ %r{\x00\x0cContent-Type}
        end
        it "prefaces values with the length of the value" do
          @binary_string.should =~ %r{\x00\x08HTTP/1.1}
        end

        it "has 2 bytes (total number of name-value pairs) + 2 bytes for each name (length of name) + 2 bytes for each value (length of value) + names + values" do
          num_size_bytes = 2 + @name_values.size * (2 + 2)

          @binary_string.length.should ==
            @name_values.inject(num_size_bytes) {|sum, kv| sum + kv[0].length + kv[1].length}
        end
      end
    end
  end
end
