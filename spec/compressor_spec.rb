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
end