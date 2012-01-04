module SPDY
  class Parser
    include Protocol

    attr :zlib_session

    def initialize
      @buffer = ''
      @zlib_session = Zlib.new
    end

    def <<(data)
      @buffer << data
      try_parse
    end

    def on_headers_complete(&blk)
      @on_headers_complete = blk
    end

    def on_ping(&blk)
      @on_ping = blk
    end

    def on_body(&blk)
      @on_body = blk
    end

    def on_message_complete(&blk)
      @on_message_complete = blk
    end
    
    def on_reset(&blk)
      @on_reset = blk
    end

    private

      def unpack_control(pckt, data)
        pckt.parse(data)

        if @on_headers_complete
          @on_headers_complete.call(pckt.header.stream_id.to_i,
                                    (pckt.associated_to_stream_id.to_i rescue nil),
                                    (pckt.pri.to_i rescue nil),
                                    pckt.uncompressed_data.to_h)
        end
      end

      def try_parse
        return if @buffer.empty?
        type = @buffer[0,1].unpack('C').first >> 7 & 0x01
        pckt = nil

        case type
          when CONTROL_BIT
            return if @buffer.size < 12
            pckt = Control::Header.new.read(@buffer[0,12])

            case pckt.type.to_i
              when 1 then # SYN_STREAM
                pckt = Control::SynStream.new({:zlib_session => @zlib_session})
                unpack_control(pckt, @buffer)

                @on_message_complete.call(pckt.header.stream_id) if @on_message_complete && fin?(pckt.header)

              when 2 then # SYN_REPLY
                pckt = Control::SynReply.new({:zlib_session => @zlib_session})
                unpack_control(pckt, @buffer)

                @on_message_complete.call(pckt.header.stream_id) if @on_message_complete && fin?(pckt.header)
                
              when 6 then # PING
                pckt = Control::Ping.new({:zlib_session => @zlib_session})
                pckt.read(@buffer)

                @on_ping.call(pckt.ping_id) if @on_ping

              when 3 then # RST_STREAM
                return if @buffer.size < 16
                pckt = Control::RstStream.new({:zlib_session => @zlib_session})
                pckt.read(@buffer)

                @on_reset.call(pckt.stream_id, pckt.status_code) if @on_reset

              else
                raise 'invalid control frame'
            end

          when DATA_BIT
            return if @buffer.size < 8

            pckt = Data::Frame.new.read(@buffer)
            @on_body.call(pckt.stream_id, pckt.data) if @on_body
            @on_message_complete.call(pckt.stream_id) if @on_message_complete && fin?(pckt)

          else
            raise 'unknown packet type'
        end

        # remove parsed data from the buffer
        @buffer.slice!(0...pckt.num_bytes)
        
        # try parsing another frame
        try_parse

      rescue IOError => e
        # rescue partial parse and wait for more data
      end

    private

      def fin?(packet)
        (packet.flags == 1) rescue false
      end

  end
end
