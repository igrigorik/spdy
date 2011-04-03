module SPDY
  module Protocol

    CONTROL_BIT = 1
    DATA_BIT    = 0

    module Control
      class Header < BinData::Record
        hide :u1, :u2

        bit1 :frame, :initial_value => 1
        bit15 :version, :initial_value => 2
        bit16 :type

        bit8 :flags
        bit24 :len

        bit1 :u1
        bit31 :stream_id

        bit1  :u2
        bit31 :associated_to_stream_id
      end

      class SynStream < BinData::Record
        hide :u1

        header :header

        bit2  :pri
        bit14 :u1

        string :data, :read_length => lambda { header.len - 10 }
      end

      class SynReply < BinData::Record
        header :header
        bit16 :unused
        string :data
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
          h[v.name_data.to_s] = v.value_data.to_s
          h
        end
      end
    end
  end
end
