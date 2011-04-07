# SPDY: An experimental protocol for a faster web

SPDY was developed at Google as part of the "let's make the web faster" initiative. SPDY ("SPeeDY") is an application-layer protocol for transporting content over the web, designed specifically for minimal latency. In lab tests, SPDY shows 64% reduction in page load times! For more details, check out the [official site](https://sites.google.com/a/chromium.org/dev/spdy).

Today, SPDY is built into Chrome + Google web-server infrastructure and is currently serving over 90% of all the SSL traffic. Yes, you read that right.. If you're using Chrome, and you're using Google products, chances are, you are fetching the content from Google servers over SPDY, not HTTP.

See: [Life beyond HTTP 1.1: Google's SPDY](http://www.igvita.com/2011/04/07/life-beyond-http-11-googles-spdy)

## Protocol Parser

SPDY specification (Draft 2) defines its own framing and message exchange protocol which is layered on top of a raw TCP/SSL connection. This gem implements a basic, pure Ruby parser for the SPDY protocol:

    s = SPDY::Parser.new

    s.on_headers_complete { |stream_id, associated_stream, priority, headers| ... }
    s.on_body             { |stream_id, data| ... }
    s.on_message_complete { |stream_id| ... }

    s << recieved_data

However, parsing the data is not enough, to do the full exchange you also have to respond to a SPDY client with appropriate 'control' and 'data' frames:

    sr = SPDY::Protocol::Control::SynReply.new
    headers = {'Content-Type' => 'text/plain', 'status' => '200 OK', 'version' => 'HTTP/1.1'}
    sr.create(:stream_id => 1, :headers => headers)
    send_data sr.to_binary_s

    # or, to send a data frame

    d = SPDY::Protocol::Data::Frame.new
    d.create(:stream_id => 1, :data => "This is SPDY.")
    send_data d.to_binary_s

See example eventmachine server in *examples/spdy_server.rb* for a minimal SPDY "hello world" server.

## Todo:

- implement support for all [control frames](https://sites.google.com/a/chromium.org/dev/spdy/spdy-protocol/spdy-protocol-draft2#TOC-Control-frames1)

### License

(MIT License) - Copyright (c) 2011 Ilya Grigorik