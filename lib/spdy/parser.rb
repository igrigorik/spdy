module SPDY
  class Parser
    include Protocol

    def initialize
      @buffer = ''
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

      def try_parse
        type = @buffer[0,1].unpack('C').first >> 7 & 0x01
        pckt = nil

        case type
          when CONTROL_BIT
            return if @buffer.size < 12
            pckt = Control::Header.new.read(@buffer[0,12])

            case pckt.type.to_i
              when 1 then # SYN_STREAM
                pckt = Control::SynStream.new
                pckt.read(@buffer)

                headers = {}
                if pckt.data.size > 0
                  data = Zlib.inflate(pckt.data.to_s)
                  headers = NV.new.read(data).to_h
                end

                if @on_headers_complete
                  @on_headers_complete.call(pckt.header.stream_id.to_i,
                                            pckt.associated_to_stream_id.to_i,
                                            pckt.pri.to_i,
                                            headers)
                end

              when 2 then # SYN_REPLY
                raise 'SYN_REPLY not handled yet'
              else
                raise 'invalid control frame'
            end

            @on_message_complete.call(pckt.header.stream_id) if @on_message_complete && fin?(pckt.header)

          when DATA_BIT
            return if @buffer.size < 8

            pckt = Data::Frame.new.read(@buffer)
            @on_body.call(pckt.stream_id, pckt.data) if @on_body
            @on_message_complete.call(pckt.stream_id) if @on_message_complete && fin?(pckt)

          else
            raise 'unknown packet type'
        end

        # remove parsed data from the buffer
        @buffer.slice!(0..pckt.num_bytes)

      rescue IOError
        # rescue partial parse and wait for more data
      end

    private

      def fin?(packet)
        (packet.flags == 1) rescue false
      end

  end
end
