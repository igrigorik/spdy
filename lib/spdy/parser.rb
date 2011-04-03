module SPDY

  module Control
    class Header < BinData::Record
      hide :u1

      bit1 :frame
      bit15 :version
      bit16 :type

      bit8 :flags
      bit24 :len

      bit1 :u1
      bit31 :stream_id
    end

    class SynStream < BinData::Record
      hide :u1, :u2

      header :header

      bit1  :u1
      bit31 :associated_to_stream_id

      bit2  :pri
      bit14 :u2

      string :data, :read_length => lambda { header.len - 10 }
    end
  end

  class NV < BinData::Record
    bit16 :pairs
    array :headers, :initial_length => :pairs do
      bit16 :name_len
      string :name_data, :read_length => :name_len

      bit16 :value_len
      string :value_data, :read_length => :value_len
    end

    def to_h
      headers.inject({}) do |h, v|
        h[v.name_data] = v.value_data
        h
      end
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
        sc = Control::SynStream.new
        sc.read(@buffer)

        if sc.header.type == 1 # SYN_STREAM
          data = Zlib.inflate(sc.data.to_s)
          nv = NV.new
          nv.read(data)

          p nv.to_h

          @on_headers_complete.call(nv.to_h) if @on_headers_complete


        elsif c.type == 2 # SYN_REPLY
        else
          raise 'invalid control frame'
        end

      end
    end
  end
end
