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

        if type == CONTROL_BIT
          ch = Control::Header.new.read(@buffer[0,16])

          if ch.type == 1 # SYN_STREAM
            sc = Control::SynStream.new
            sc.read(@buffer)

            data = Zlib.inflate(sc.data.to_s)
            nv = NV.new.read(data).to_h

            nv['x-spdy-version']    = ch.version
            nv['x-spdy-stream_id']  = ch.stream_id

            @on_headers_complete.call(nv) if @on_headers_complete

          elsif c.type == 2 # SYN_REPLY
            raise 'SYN_REPLY not handled yet'
          else
            raise 'invalid control frame'
          end

        end
      end
  end
end