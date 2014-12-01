# encoding: utf-8

require 'time'
require 'colorize'
require 'multi_json'
require 'rest_client'
require_relative 'lib/utilities'


hostname = "#{ENV['HOSTNAME']}:4567"
channel = "CHANNEL_1"

#
# PUBLISHER DEVICE ID
# 'P' for publisher
#
device = device_random 'P'

puts "PUSH EVENTS from device: #{device}, to channel: #{channel}, at server: #{hostname}\n"

#
# PUSH EVENT (PUBLISH a message via HTTP POST)
#
def push_event(hostname, channel, json_msg, device) 

  url = "http://#{hostname}/push/#{channel}"    

  # message payload in JSON format, in HTTP body
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
id = 0
loop do
  # prepare SSE event data, with random data

  # application message id
  id = id + 1

  time = time_now
  
  data = data_random(15,32)
  
  event = { device: device, time: time, id: id, data: data } # channel: channel, 

  # create the JSON payload
  json_event = MultiJson.dump event

  # push event as HTTP POST
  push_event hostname, channel, json_event, device

  # sleep for N seconds
  sleep ( rand 10..20 )
end