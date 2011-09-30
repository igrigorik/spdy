require 'helper'

describe SPDY::Zlib do
  it "should inflate header with custom dictionary" do
    zlib_session = SPDY::Zlib.new

    zlib_session.inflate(COMPRESSED_HEADER).should match('HTTP/1.1')
  end

  it "should deflate header with custom dictionary" do
    zlib_session = SPDY::Zlib.new

    orig = zlib_session.inflate(COMPRESSED_HEADER)

    zlib_session.reset

    rinse = zlib_session.inflate(zlib_session.deflate(orig))

    orig.should == rinse
  end

  it "can deflate multiple packets" do
    zlib_session = SPDY::Zlib.new

    zlib_session.inflate(COMPRESSED_HEADER_1)

    zlib_session.inflate(COMPRESSED_HEADER_2).should == UNCOMPRESSED_HEADER_2
  end
end
