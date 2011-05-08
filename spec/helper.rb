require 'rspec'
require 'spdy'

COMPRESSED_HEADER = "8\xEA\xDF\xA2Q\xB2b\xE0f`\x83\xA4\x17\x86(4\xDBu0\xAC\xD7\x06\x89\xC2\xFDa]hk\xA0g\xA9\x83p\x13X\xC0B\a\xEE?\x1D-}-\xB0\x98)\x03\x1Fjff\x90\xF3\f\xF6\x87:U\a\xECV\xB0:s\x1D\x88zc\x06~\xB4\xEC\xCE \b\xF2\x8C\x0E\xD47:\xC5)\xC9\x19p5\xB0\x14\xC2\xC0\x97\x9A\xA7\e\x1A\xAC\x93\nu\b\x03\e$V\x19Z\x8A\x8D\x8C\xD3\xD2u\x8D\v\x8C\xCC\x8D\x92\v,\xCB\r\xE2\x8Bl\xCD\xAD\x15\f\xB3\xCD\v\xCDu3\rR\xCC\xD3\x8B\v\r-\xCC\x81\xA2\x06\xD6\n\xF1 '\x96$\xA5&\x96\x18\x01d[\x9Cj\x9CUQ\x92dT\x99e\x9C\x9A\x93\x93j\f\x94\x8D//)\x8F/\xCB,\x8E\afy[k\x85\xB2\xC4\xBC\xCC\x92\xCA\xF8\xCC\x14\xDB4c#\x8B\xE4$3\x13c\x93d`\xFEM12N154OI32O\x03\x16\x04\xA6\x96I\f,\xA0\xC2\x88\x81\x0F\x94bs@L+K\x03\x03\x03\x06\xB6\\`!\x98\x9F\xC2\xC0\xEC\xEE\x1A\xC2\xC0V\f\xCC7\xB9\xA9\f\xAC\x19%%\x05\xC5\f\xCC\xA0\bb\xD4g\xE0B\x94*\fe\xBE\xF9U\x9999\x89\xFA\xA6z\x06\x00)h\xF8&&g\xE6\x95\xE4\x17gX+x\x02\x13z\x8E\x02P@\xC1?X!B\xC1\xD0 \xDE,\xDE\\S\xC1\x11\x18\x87\xA9\xE1\xA9I\xDE\x99%\xFA\xA6\xC6&zF&\n\x1A\xDE\x1E!\xBE>:\n9\x99\xD9\xA9\n\xEE\xA9\xC9\xD9\xF9\x9A\n\xCE\x19\xC0\xD22U\xDF\xD0P\xCF@\xCF\xCC\xD2L\xCF\xC8B!81-\xB1(\x13\xAA\x89\x81\x1D\x9Af\x188`I\t\x00\x00\x00\xFF\xFF"

SYN_STREAM = "\x80\x02\x00\x01\x01\x00\x01E\x00\x00\x00\x01\x00\x00\x00\x00\x00\x008\xEA\xDF\xA2Q\xB2b\xE0f`\x83\xA4\x17\x86(4\xDBu0\xAC\xD7\x06\x89\xC2\xFDa]hk\xA0g\xA9\x83p\x13X\xC0B\a\xEE?\x1D-}-\xB0\x98)\x03\x1Fjff\x90\xF3\f\xF6\x87:U\a\xECV\xB0:s\x1D\x88zc\x06~\xB4\xEC\xCE \b\xF2\x8C\x0E\xD47:\xC5)\xC9\x19p5\xB0\x14\xC2\xC0\x97\x9A\xA7\e\x1A\xAC\x93\nu\b\x03/J:d\xE0\x84\x86\x96\xAD\x01\x03\v\xA8``\xE0342\xD73\x00BC+K\x03\x03\x03\x06\xB6\\`\x81\x94\x9F\xC2\xC0\xEC\xEE\x1A\xC2\xC0V\f\xD4\x9B\x9B\xCA\xC0\x9AQRRP\xCC\xC0\f\n,\x11}{\x80\x80a\x9Do\x9B\xA8\x06,\x10\x80\xC5\x86mVq~\x1E\x03\x17\"\xD33\x94\xF9\xE6We\xE6\xE4$\xEA\x9B\xEA\x19(h\xF8&&g\xE6\x95\xE4\x17gX+x\x02\xD3a\x8E\x02P@\xC1?X!B\xC1\xD0 \xDE,\xDE\\S\xC1\x11\x18\xC4\xA9\xE1\xA9I\xDE\x99%\xFA\xA6\xC6&zF&\n\x1A\xDE\x1E!\xBE>:\n9\x99\xD9\xA9\n\xEE\xA9\xC9\xD9\xF9\x9A\n\xCE\x19\xC0\xC2,U\xDF\xD0\x10\xE8X3K3=#\v\x85\xE0\xC4\xB4\xC4\xA2L\xA8&\x06vh\x942p\xC0b\x1A\x00\x00\x00\xFF\xFF"

SYN_REPLY = "\x80\x02\x00\x02\x00\x00\x005\x00\x00\x00\x01\x00\x00x\xbb\xdf\xa2Q\xb2b`f\xe0q\x86\x06R\x080\x90\x18\xb8\x10v0\xb0A\x943\xb0\x01\x93\xb1\x82\xbf7\x03;T#\x03\x07\xcc<\x00\x00\x00\x00\xff\xff"

RST_STREAM = "\x80\x02\x00\x03\x00\x00\x00\b\x00\x00\x00\x01\x00\x00\x00\x01"

SETTINGS = "\x80\x02\x00\x04\x00\x00\x00\b\x00\x00\x00\x01\x00\x00\x00\x03\x00\x00\x01,"

DATA = "\x00\x00\x00\x01\x00\x00\x00\rThis is SPDY."
DATA_FIN = "\x00\x00\x00\x01\x01\x00\x00\x00"

NV = "\x00\x03\x00\x0cContent-Type\x00\ntext/plain\x00\x06status\x00\x06200 OK\x00\x07version\x00\x08HTTP/1.1"

PING = "\x80\x01\x00\x06\x00\x00\x00\x04\x00\x00\x00\x01"

GOAWAY = "\x80\x01\x00\x07\x00\x00\x00\x04\x00\x00\x00\x01"
