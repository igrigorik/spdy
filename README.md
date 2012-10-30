# SPDY

SPDY is an experimental protocol designed to reduce latency of web pages. The SPDY v2 draft is the foundation for the HTTP 2.0 initiative led by the HTTPbis working group. In lab tests, SPDY shows 64% reduction in page load times! For more details, check out the [official site](https://sites.google.com/a/chromium.org/dev/spdy).

Today, SPDY support is available in Chrome, Firefox, and Opera on the client, and on Apache, Nginx, Jetty, node.js and others on the server. All of Google web services, when running over SSL, are available through SPDY! In other words, if you are using Google products over SSL, chances are, you are fetching the content from Google servers over SPDY, not HTTP.

* [HTTPBis - HTTP 2.0 Charter](http://datatracker.ietf.org/wg/httpbis/charter/)
* [Life beyond HTTP 1.1: Google's SPDY](http://www.igvita.com/2011/04/07/life-beyond-http-11-googles-spdy)

## Protocol Parser

SPDY specification (draft 2) defines its own framing and message exchange protocol which is layered on top of a raw TCP connection. This gem implements a basic, pure Ruby parser for the SPDY v2 protocol:

```ruby
s = SPDY::Parser.new

s.on_headers_complete { |stream_id, headers| ... }
s.on_body             { |stream_id, data| ... }
s.on_message_complete { |stream_id| ... }

s << recieved_data
```

However, parsing the data is not enough, to do the full exchange you also have to respond to a SPDY client with appropriate 'control' and 'data' frames:

```ruby
sr = SPDY::Protocol::Control::SynReply.new
headers = {'Content-Type' => 'text/plain', 'status' => '200 OK', 'version' => 'HTTP/1.1'}
sr.create(:stream_id => 1, :headers => headers)
send_data sr.to_binary_s

# or, to send a data frame

d = SPDY::Protocol::Data::Frame.new
d.create(:stream_id => 1, :data => "This is SPDY.")
send_data d.to_binary_s
```

See example eventmachine server in *examples/spdy_server.rb* for a minimal SPDY "hello world" server.

### License

MIT License - Copyright (c) 2011 Ilya Grigorik
