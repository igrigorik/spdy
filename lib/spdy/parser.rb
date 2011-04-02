
module SPDY

  module Control
    class Header < BinData::Record
      hide :unused

      bit1 :frame
      bit15 :version
      bit16 :type

      bit8 :flags
      bit24 :len

      bit1 :unused
      bit31 :stream_id
    end

    class Stream < BinData::Record
      hide :unused

      bit1 :unused2
      bit31 :associated_to_stream_id
    end
  end

  class Packet
    attr_accessor :header
    attr_accessor :stream_id
    attr_accessor :associated_to_stream_id

  end

  class Parser
    CONTROL_BIT = 1
    DATA_BIT    = 0

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

    def try_parse
      type = @buffer[0,1].unpack('C').first >> 7 & 0x01
      sp = Packet.new

      if type == CONTROL_BIT
        c = Control::Header.new
        c.read(@buffer[0,12])
        sp.header = c
        p sp

        if c.type == 1 # SYN_STREAM
          s = Control::Stream.new
          s.read(@buffer[12,4])

          sp.associated_to_stream_id = s.associated_to_stream_id

        elsif c.type == 2 # SYN_REPLY
        else
          raise 'invalid control frame'
        end

      end
    end
  end
end
