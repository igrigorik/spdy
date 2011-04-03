module SPDY
  module Zlib

    DICT = \
      "optionsgetheadpostputdeletetraceacceptaccept-charsetaccept-encodingaccept-" \
      "languageauthorizationexpectfromhostif-modified-sinceif-matchif-none-matchi" \
      "f-rangeif-unmodifiedsincemax-forwardsproxy-authorizationrangerefererteuser" \
      "-agent10010120020120220320420520630030130230330430530630740040140240340440" \
      "5406407408409410411412413414415416417500501502503504505accept-rangesageeta" \
      "glocationproxy-authenticatepublicretry-afterservervarywarningwww-authentic" \
      "ateallowcontent-basecontent-encodingcache-controlconnectiondatetrailertran" \
      "sfer-encodingupgradeviawarningcontent-languagecontent-lengthcontent-locati" \
      "oncontent-md5content-rangecontent-typeetagexpireslast-modifiedset-cookieMo" \
      "ndayTuesdayWednesdayThursdayFridaySaturdaySundayJanFebMarAprMayJunJulAugSe" \
      "pOctNovDecchunkedtext/htmlimage/pngimage/jpgimage/gifapplication/xmlapplic" \
      "ation/xhtmltext/plainpublicmax-agecharset=iso-8859-1utf-8gzipdeflateHTTP/1" \
      ".1statusversionurl\0"

    CHUNK = 10*1024 # this is silly, but it'll do for now

    def self.inflate(data)
      in_buf  = FFI::MemoryPointer.from_string(data)
      out_buf = FFI::MemoryPointer.new(CHUNK)

      zstream = FFI::Zlib::Z_stream.new
      zstream[:avail_in]  = in_buf.size
      zstream[:avail_out] = CHUNK
      zstream[:next_in]   = in_buf
      zstream[:next_out]  = out_buf

      result = FFI::Zlib.inflateInit(zstream)
      raise "invalid stream" if result != FFI::Zlib::Z_OK

      result = FFI::Zlib.inflate(zstream, FFI::Zlib::Z_SYNC_FLUSH)
      raise "invalid stream" if result != FFI::Zlib::Z_NEED_DICT

      result = FFI::Zlib.inflateSetDictionary(zstream, DICT, DICT.size)
      raise "invalid dictionary" if result != FFI::Zlib::Z_OK

      result = FFI::Zlib.inflate(zstream, FFI::Zlib::Z_SYNC_FLUSH)
      raise "cannot inflate" if result != FFI::Zlib::Z_OK

      out_buf.get_bytes(0, zstream[:total_out])
    end

    def self.deflate(data)
      in_buf  = FFI::MemoryPointer.from_string(data)
      out_buf = FFI::MemoryPointer.new(CHUNK)

      zstream = FFI::Zlib::Z_stream.new
      zstream[:avail_in]  = in_buf.size
      zstream[:avail_out] = CHUNK
      zstream[:next_in]   = in_buf
      zstream[:next_out]  = out_buf

      result = FFI::Zlib.deflateInit(zstream, 9)
      raise "invalid stream" if result != FFI::Zlib::Z_OK

      result = FFI::Zlib.deflateSetDictionary(zstream, DICT, DICT.size)
      raise "invalid dictionary" if result != FFI::Zlib::Z_OK

      result = FFI::Zlib.deflate(zstream, FFI::Zlib::Z_SYNC_FLUSH)
      raise "cannot deflate" if result != FFI::Zlib::Z_OK

      out_buf.get_bytes(0, zstream[:total_out])
    end
  end
end
