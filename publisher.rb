# encoding: utf-8

require 'time'
require 'colorize'
require 'multi_json'
require 'rest_client'

hostname = "#{ENV['HOSTNAME']}:4567"
channel = "CHANNEL_1"

#
# PUBLISHER DEVICE ID
# random number of 9 ciphers (like a cellphone number) 
# 'P' for publisher
#
device = ['P', '0039', rand(1..9), (1..8).map{rand(0..9)}].join


puts "PUBLISH (device: #{device}), channel: #{channel}, server: #{hostname}"

#
# PUSH EVENT (PUBLISH a message via HTTP POST)
#
def push_event(hostname, channel, json_msg, device) 
  url = "http://#{hostname}/push/#{channel}"    

  # message payload in JSON format, in HTTP body 
  # https://github.com/rest-client/rest-client

  begin
    response = RestClient.post url, json_msg, :content_type => :json, :accept => :json, device: device
    puts "PUSH EVT> event: #{json_msg}".cyan # , response: #{response.code}
  rescue => e
    puts "PUSH FAILED. #{e.message}".red
  end
end


#
# PUBLISH an event every N seconds
#
publisher_id = 0
loop do
  # prepare SSE event data, with random data

  # application message id
  publisher_id = publisher_id + 1

  # time now in ISO 8601
  time = Time.now.utc.iso8601
  
  # a chunk of random data 
  data = rand(36**(rand 15..128)).to_s(36)
  
  # crete the JSON payload
  json_msg = MultiJson.dump( { channel: channel, publisher_id: publisher_id, time: time, data: data } )

  # push event as HTTP POST
  push_event hostname, channel, json_msg, device

  # sleep for N seconds
  sleep ( rand 10..20 )
end