# encoding: utf-8

require 'time'

# return timestamp in ISO8601 with precision in milliseconds 
def time_now
  Time.now.utc.iso8601(3)
end


#
# RANDOM DEVICE ID
# random number of 9 ciphers (like a cellphone number) 
# 'P' for publisher
#
def device_random(prefix)
  [prefix, '0039', rand(1..9), (1..8).map{rand(0..9)}].join
end


def data_random(min, max)
  # a chunk of random data 
  rand(36**(rand min..max)).to_s(36)
end


#
# some helpers for Sinatra server
#


# for debug
def log_params
  puts "query params:"
  params.each {|key, value| puts "\t#{key} = #{value}"}
  puts "HTTP headers:"
  env.select { |key, value| key.to_s.match(/^HTTP_*/) }.each {|key, value| puts "\t#{key} = #{value}"}
end


#
# Server-Sent Events (SSE) text message format
# here just two attributes: 'id' and 'data'
# no 'event', etc. 
#
def sse_event(id, data)
  "id:#{id}\ndata:#{data}\n\n"
end


#
# return the value of an HTTP header param 
# return nil of param doesn't exist
#
# Note: Rack (under Sinatra) add prefix HTTP_ an do some string upcase to any header param,
# e.g. 'Last-Event-ID' become 'HTTP_LAST_EVENT_ID'
#
def header(param)
  env[ "HTTP_#{param.gsub('-', '_').upcase}" ]
end