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

        case type
          when CONTROL_BIT
            ch = Control::Header.new.read(@buffer[0,12])

            case ch.type.to_i
              when 1 then # SYN_STREAM
                sc = Control::SynStream.new
                sc.read(@buffer)
                ch = sc.header

                headers = {}
                if sc.data.size > 0
                  data = Zlib.inflate(sc.data.to_s)
                  headers = NV.new.read(data).to_h
                end

                if @on_headers_complete
                  @on_headers_complete.call(sc.header.stream_id.to_i,
                                            sc.associated_to_stream_id.to_i,
                                            sc.pri.to_i,
                                            headers)
                end

              when 2 then # SYN_REPLY
                raise 'SYN_REPLY not handled yet'
              else
                raise 'invalid control frame'
            end

            @on_message_complete.call(ch.stream_id) if @on_message_complete && fin?(ch)

          when DATA_BIT
            dp = Data::Frame.new.read(@buffer)
            @on_body.call(dp.stream_id, dp.data) if @on_body
            @on_message_complete.call(dp.stream_id) if @on_message_complete && fin?(dp)

          else
            raise 'uknown packet type'
        end
      end

    private

      def fin?(packet)
        (packet.flags == 1) rescue false
      end

  end
end
