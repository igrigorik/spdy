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

    def on_body(&blk)
      @on_body = blk
    end

    def on_message_complete(&blk)
      @on_message_complete = blk
    end

    private

      def unpack_control(pckt, data)
        pckt.read(data)

        headers = {}
        if pckt.data.size > 0
          data = @zlib_session.inflate(pckt.data.to_s)
          headers = NV.new.read(data).to_h
        end

        if @on_headers_complete
          @on_headers_complete.call(pckt.header.stream_id.to_i,
                                    (pckt.associated_to_stream_id.to_i rescue nil),
                                    (pckt.pri.to_i rescue nil),
                                    headers)
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
