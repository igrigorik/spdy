module SPDY
  module Protocol
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
  end
end
