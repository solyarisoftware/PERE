# encoding: utf-8

require 'time'
require 'colorize'
require 'multi_json'
require 'rest_client'

hostname = "192.168.1.102:4567"
channel = "CHANNEL_1"

#
# DEVICE ID
# random number of 9 ciphers (like a cellphone number) 
#
device = ["0039", rand(1..9), (1..8).map{rand(0..9)}].join


puts "PUBLISHER. device: #{device}, server: #{hostname}, channel: #{channel}"

#
# PUSH EVENT (PUBLISH a message via HTTP POST)
#
def push_event(hostname, channel, json_msg) 
  url = "http://#{hostname}/push/#{channel}"    

  # message payload in JSON format, in HTTP body 
  # https://github.com/rest-client/rest-client

  begin
    response = RestClient.post url, json_msg, :content_type => :json, :accept => :json
    puts "PUSH EVT. event: #{json_msg}".cyan # , response: #{response.code}
  rescue => e
    puts "PUSH FAILED. #{e.message}".red
  end
end


#
# PUBLISH an event every N seconds
#
appmsg_id = 0
loop do
  # prepare SSE event data, with random data

  # application message id
  appmsg_id = appmsg_id + 1

  # time now in ISO 8601
  time = Time.now.utc.iso8601
  
  # a chunk of random data 
  data = rand(36**(rand 15..128)).to_s(36)
  
  # crete the JSON payload
  json_msg = MultiJson.dump( { channel: channel, device: device, id: appmsg_id, time: time, data: data } )

  # push event as HTTP POST
  push_event hostname, channel, json_msg

  # sleep for N seconds
  sleep ( rand 10..20 )
end