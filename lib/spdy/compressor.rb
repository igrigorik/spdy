module SPDY
  class Zlib

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

    def initialize
      @inflate_zstream = FFI::Zlib::Z_stream.new
      result = FFI::Zlib.inflateInit(@inflate_zstream)
      raise "invalid stream" if result != FFI::Zlib::Z_OK

      @deflate_zstream = FFI::Zlib::Z_stream.new
      result = FFI::Zlib.deflateInit(@deflate_zstream, FFI::Zlib::Z_DEFAULT_COMPRESSION)
      raise "invalid stream" if result != FFI::Zlib::Z_OK

      result = FFI::Zlib.deflateSetDictionary(@deflate_zstream, DICT, DICT.size)
      raise "invalid dictionary" if result != FFI::Zlib::Z_OK
    end

    def reset
      result = FFI::Zlib.inflateReset(@inflate_zstream)
      raise "invalid stream" if result != FFI::Zlib::Z_OK

      result = FFI::Zlib.deflateReset(@deflate_zstream)
      raise "invalid stream" if result != FFI::Zlib::Z_OK
    end

    def inflate(data)
      in_buf  = FFI::MemoryPointer.from_string(data)
      out_buf = FFI::MemoryPointer.new(CHUNK)

      @inflate_zstream[:avail_in]  = in_buf.size-1
      @inflate_zstream[:avail_out] = CHUNK
      @inflate_zstream[:next_in]   = in_buf
      @inflate_zstream[:next_out]  = out_buf

      result = FFI::Zlib.inflate(@inflate_zstream, FFI::Zlib::Z_SYNC_FLUSH)
      if result == FFI::Zlib::Z_NEED_DICT
        result = FFI::Zlib.inflateSetDictionary(@inflate_zstream, DICT, DICT.size)
        raise "invalid dictionary" if result != FFI::Zlib::Z_OK
  
        result = FFI::Zlib.inflate(@inflate_zstream, FFI::Zlib::Z_SYNC_FLUSH)
      end

      raise "cannot inflate" if result != FFI::Zlib::Z_OK && result != FFI::Zlib::Z_STREAM_END

      out_buf.get_bytes(0, CHUNK - @inflate_zstream[:avail_out])
    end

    def deflate(data)
      in_buf  = FFI::MemoryPointer.from_string(data)
      out_buf = FFI::MemoryPointer.new(CHUNK)

      @deflate_zstream[:avail_in]  = in_buf.size-1
      @deflate_zstream[:avail_out] = CHUNK
      @deflate_zstream[:next_in]   = in_buf
      @deflate_zstream[:next_out]  = out_buf

      result = FFI::Zlib.deflate(@deflate_zstream, FFI::Zlib::Z_SYNC_FLUSH)
      raise "cannot deflate" if result != FFI::Zlib::Z_OK

      out_buf.get_bytes(0, CHUNK - @deflate_zstream[:avail_out])
    end
  end
end
