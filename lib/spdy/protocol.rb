module SPDY
  module Protocol

    CONTROL_BIT = 1
    DATA_BIT    = 0
    VERSION     = 2

    SETTINGS_UPLOAD_BANDWIDTH = 1
    SETTINGS_DOWNLOAD_BANDWIDTH = 2
    SETTINGS_ROUND_TRIP_TIME = 3
    SETTINGS_MAX_CONCURRENT_STREAMS = 4
    SETTINGS_CURRENT_CWND = 5

    module Control
      module Helpers
        def initialize_instance
          super
          @zlib_session = @params[:zlib_session]
        end

        def parse(chunk)
          head = Control::Header.new.read(chunk)
          self.read(chunk)

          if data.length > 0
            data = @zlib_session.inflate(self.data.to_s)
            self.uncompressed_data = NV.new.read(data)
          else
            self.uncompressed_data = NV.new
          end

          self
        end

        def build(opts = {})
          self.header.type  = opts[:type]
          self.header.len   = opts[:len]

          self.header.flags   = opts[:flags] || 0
          self.header.stream_id = opts[:stream_id]

          nv = SPDY::Protocol::NV.new
          nv.create(opts[:headers])

          nv = @zlib_session.deflate(nv.to_binary_s)
          self.header.len = self.header.len.to_i + nv.size

          self.data = nv

          self
        end
      end

      class Header < BinData::Record
        hide :u1

        bit1 :frame, :initial_value => CONTROL_BIT
        bit15 :version, :initial_value => VERSION
        bit16 :type

        bit8 :flags
        bit24 :len

        bit1 :u1
        bit31 :stream_id
      end

      class SynStream < BinData::Record
        attr_accessor :uncompressed_data
        include Helpers

        hide :u1, :u2

        header :header

        bit1  :u1
        bit31 :associated_to_stream_id

        bit2  :pri
        bit14 :u2

        string :data, :read_length => lambda { header.len - 10 }

        def create(opts = {})
          build({:type => 1, :len => 10}.merge(opts))
        end
      end

      class SynReply < BinData::Record
        attr_accessor :uncompressed_data
        include Helpers

        header :header
        bit16 :unused
        string :data, :read_length => lambda { header.len - 6 }

        def create(opts = {})
          build({:type => 2, :len => 6}.merge(opts))
        end
      end

      class RstStream < BinData::Record
        hide :u1

        bit1 :frame, :initial_value => CONTROL_BIT
        bit15 :version, :initial_value => VERSION
        bit16 :type, :value => 3

        bit8 :flags, :value => 0
        bit24 :len, :value => 8

        bit1  :u1
        bit31 :stream_id

        bit32 :status_code

        def parse(chunk)
          self.read(chunk)
          self
        end

        def create(opts = {})
          self.stream_id = opts.fetch(:stream_id, 1)
          self.status_code = opts.fetch(:status_code, 5)
          self
        end
      end

      class Settings < BinData::Record
        bit1 :frame, :initial_value => CONTROL_BIT
        bit15 :version, :initial_value => VERSION
        bit16 :type, :value => 4

        bit8 :flags
        bit24 :len, :value => lambda { pairs * 8 }
        bit32 :pairs

        array :headers, :initial_length => :pairs do
          bit32 :id_data
          bit32 :value_data
        end

        def parse(chunk)
          self.read(chunk)
          self
        end

        def create(opts = {})
          opts.each do |k, v|
            key = SPDY::Protocol.const_get(k.to_s.upcase)
            self.headers << { :id_data =>  key , :value_data => v }
          end
          self.pairs = opts.size
          self
        end
      end

      class Ping < BinData::Record
        bit1 :frame, :initial_value => CONTROL_BIT
        bit15 :version, :initial_value => VERSION
        bit16 :type, :value => 6

        bit8 :flags, :value => 0
        bit24 :len, :value => 4

        bit32 :ping_id

        def parse(chunk)
          self.read(chunk)
          self
        end

        def create(opts = {})
          self.ping_id = opts.fetch(:ping_id, 1)
          self
        end
      end

      class Goaway < BinData::Record
        hide :u1

        bit1 :frame, :initial_value => CONTROL_BIT
        bit15 :version, :initial_value => VERSION
        bit16 :type, :value => 7

        bit8 :flags, :value => 0
        bit24 :len, :value => 4

        bit1 :u1
        bit31 :stream_id

        def parse(chunk)
          self.read(chunk)
          self
        end

        def create(opts = {})
          self.stream_id = opts.fetch(:stream_id, 1)
          self
        end
      end


      class Headers < BinData::Record
        attr_accessor :uncompressed_data
        include Helpers

        header :header
        bit16 :unused
        string :data, :read_length => lambda { header.len - 6 }

        def create(opts = {})
          build({:type => 8, :len => 6}.merge(opts))
        end
      end
    end

    module Data
      class Frame < BinData::Record
        bit1 :frame, :initial_value => DATA_BIT
        bit31 :stream_id

        bit8 :flags, :initial_value => 0
        bit24 :len,  :initial_value => 0

        string :data, :read_length => :len

        def create(opts = {})
          self.stream_id = opts[:stream_id]
          self.flags     = opts[:flags] if opts[:flags]

          if opts[:data]
            self.len       = opts[:data].size
            self.data      = opts[:data]
          end

          self
        end
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

      def create(opts = {})
        opts.each do |k, v|
          self.headers << {:name_len => k.size, :name_data => k.downcase, :value_len => v.size, :value_data => v}
        end

        self.pairs = opts.size
        self
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
