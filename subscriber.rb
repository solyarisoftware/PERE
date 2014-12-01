# encoding: utf-8

require 'time'
require 'colorize'
require 'multi_json'
require 'rest_client'
require 'em-eventsource'
require_relative 'lib/utilities'

hostname = "#{ENV['HOSTNAME']}:4567" 
channel = "CHANNEL_1"

# to subscribe (a down-stream)
channel_url = "http://#{hostname}/feed/#{channel}"    

# to feedback status (up-stream)
feedback_url =  "http://#{hostname}/feedback/#{channel}"

# SUBSCRIBER DEVICE ID. 'H' for Host client 
device =  device_random 'H'

puts "SUBSCRIBER from device: #{device}, to channel: #{channel}, at server: #{hostname}".yellow


#
# ELABORATE EVENT
# message event could be JSON data
#
def elaborate(event, last_event_id)

   puts "RX EVT> id: #{last_event_id}, data: #{event}".green
 
  # TODO: do something with event

  status = "rx ok"
end	


EM.run do
  
  query =  {}
  headers = {device: device}

  source = EventMachine::EventSource.new channel_url, query, headers

  source.message do |event|

    # get SSE last_event_id
    last_event_id = source.last_event_id

    # elaborate receive message event and set elaboration status
    status =  elaborate(event, last_event_id)

    # send back an HTTP POST /feedback/:channel with status info
    query = { status: status }
    headers = { device: device, last_event_id: last_event_id }

    response = RestClient.post feedback_url, query, headers                                

  end

  source.start # Start listening
end
