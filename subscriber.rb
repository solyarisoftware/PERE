# encoding: utf-8

require 'time'
require 'colorize'
require 'multi_json'
require 'rest_client'
require "em-eventsource"

# http://dev.af83.com/2011/08/03/em-eventsource-an-eventmachine-client-for-server-sent-events.html
# https://github.com/AF83/em-eventsource

# random id
# http://stackoverflow.com/questions/6021372/best-way-to-create-unique-token-in-rails
# raspberrypi.stackexchange.com/questions/2086/how-do-i-get-the-serial-number
# http://www.sitepoint.com/tour-random-ruby/

hostname = "#{ENV['HOSTNAME']}:4567" 
channel = "CHANNEL_1"

# to subscribe (a down-stream)
channel_url = "http://#{hostname}/feed/#{channel}"    

# to feedback status (up-stream)
feedback_url =  "http://#{hostname}/feedback/#{channel}"


#
# SUBSCRIBER DEVICE ID
# random number of 9 ciphers (a cellphone) 
# 'H' for Host client 
#
device = ["H", "0039", rand(1..9), (1..8).map{rand(0..9)}].join

puts "LISTEN (device: #{device}), channel: #{channel}, server: #{hostname}".yellow


#
# ELABORATE EVENT
# message event could be JSON data
#
def elaborate(event)

   puts "RX EVT> #{event}".green
 
  # do something with event

  status = "ok"
end	


EM.run do
  
  query =  {}
  headers = {device: device}

  source = EventMachine::EventSource.new channel_url, query, headers

  source.message do |event|
 
    # elaborate receive message event and set elaboration status
    status =  elaborate event

    last_event_id = source.last_event_id

    # send back an HTTP POST /feedback/:channel with status info
    #
    # http://stackoverflow.com/questions/12161640/setting-request-headers-in-ruby
    # http://stackoverflow.com/questions/20511661/accessing-header-params-in-restclient-api-get-call
    query = { status: status }
    headers = { device: device, last_event_id: last_event_id }

    response = RestClient.post feedback_url, query, headers 
                               
  end

  source.start # Start listening
end
