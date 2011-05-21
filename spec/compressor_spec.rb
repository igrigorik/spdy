require 'helper'

describe SPDY::Zlib do
  it "should inflate header with custom dictionary" do
    SPDY::Zlib.inflate(COMPRESSED_HEADER).should match('HTTP/1.1')
  end

  it "should deflate header with custom dictionary" do
    orig = SPDY::Zlib.inflate(COMPRESSED_HEADER)
    rinse = SPDY::Zlib.inflate(SPDY::Zlib.deflate(orig))

    orig.should == rinse
  end

  it "can deflate multiple packets" do
    pending "How to re-use deflate stream"
    # see also https://gist.github.com/982287
    SPDY::Zlib.inflate(COMPRESSED_HEADER_1)

    SPDY::Zlib.inflate(COMPRESSED_HEADER_2).
      should == UNCOMPRESSED_HEADER_2
  end
end
