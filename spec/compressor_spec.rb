require 'helper'

describe SPDY::Zlib do
  it "should inflate header with custom dictionary" do
    SPDY::Zlib.inflate(COMPRESSED_HEADER).should match('HTTP/1.1')
  end
end