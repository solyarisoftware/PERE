# encoding: utf-8

require 'colorize'
require 'multi_json'
require 'sinatra'
require_relative 'lib/utilities'

# Sinatra confgurations
set debug: false

disable :logging

# a web server with a event machine engine
set server: 'thin' 

# Channel connections 
# global hash containing a list of connections (one list for every channel)
# each connection is inialized with a void list
#
#   connections[:channel_1] = [...]
#     ...
#   connections[:channel_N] = [...]
#
set connections:  Hash.new {|h, k| h[k] = [] }


# Channel sse_id Storage
#
# for each channel, Last-Event-Id (could be a timestamp)
#
#   sse_id[:channel_1] = timestamp
#   ...
#   sse_id[:channel_N] = timestamp
#
set sse_id: Hash.new


# Events Memory Storage 
#
# for each channel an hash contain all events pushed for the channel, 
# as a key=>value couple; the key is a timestamp (SSE id) and value is event data payload.
#
#   events[:channel_1] = {"2014-12-01T09:35:33.876Z"=> data, "2014-12-01T09:39:25.487Z"=> data, ...}
#   ...
#   events[:channel_N] = {...}
#
set events:  Hash.new {|h, k| h[k] = {} }


# Devices Memory Storage 
#
# for each channel an hash contain all subscribers of a channel, 
# as a key=>value couple; the key is a Device-Id and value is some data
# (presence status, last connection timestamp,etc.).
#
#   devices[:channel_1] = {"P0039696456814"=> data, "W0034606536600"=> data, ...}
#   ...
#   devices[:channel_N] = {...}
#
set devices:  Hash.new {|h, k| h[k] = {} }


#
# PUSH AN EVENT TO A CHANNEL (PUBLISH)
# SSE   ID: time_now 
# SSE DATA: (JSON) payload in HTTP request BODY
# 
post "/push/:channel" do

  # todo: check validity of channel value
  channel = params[:channel].intern

  # get device as param in HTTP request HEADER
  device = header 'device'

  # read message as (JSON) payload in HTTP request BODY 
  data = request.body.read

  # increment SSE ID data packet 
  #settings.sse_id[:channel] = settings.sse_id[:channel] + 1
  #id = settings.sse_id[:channel]

  # Set SSE ID data packet as timestamp
  id = settings.sse_id[channel] = time_now

  # store event
  settings.events[channel][id] = data

  # push out SSE event to open connections
  settings.connections[channel].each do |connection|
    sse_event = "id: #{id}\ndata: #{data}\n\n"
    connection << sse_event
  end

  # log event
  puts "PUSH EVT> channel: #{channel}, device: #{device}, Event-Id: #{id}, data: #{data}".cyan

  log_params if settings.debug

  status 204 # response without entity body 
end


#
# LISTEN EVENTS FROM A CHANNEL (SUBSCRIBE & UP-STREAM)
#
get "/feed/:channel", provides: 'text/event-stream' do
 
  cache_control :no_cache

  # TODO: check validity of channel value
  channel = params[:channel].intern

  # subscriber pass his identity with parameter 'device' 
  # TODO: check validity of device value
  device = header 'device' # params[:device]

  # get last event id from http header param
  last_event_id = header 'Last-Event-Id'

  status_update = { op: "feed", at: time_now, :'Last-Event-Id' => last_event_id } 

  # store device data (what/when/id)
  settings.devices[channel][device.intern] = status_update

  puts "FEED REQ> device: #{device}, channel: #{channel}, Last-Event-Id: #{last_event_id ? last_event_id : 'nil'}".yellow

  stream :keep_open do |out|
   settings.connections[channel] << out

   out.callback { settings.connections[channel].delete(out) }
  end
  
  log_params if settings.debug
end  


#
# FEEDBACK FROM CLIENTS (WEBHOOK UP-STREAM)
#
post "/feedback/:channel" do

  # TODO: check validity of channel value
  channel = params[:channel].intern

  # get status as HTTP POST param
  status = params[:status]

  # get params from HTTP header
  device = header 'device'
  last_event_id = header 'last_event_id'

  status_update = { op: "feedback", at: time_now, :'Last-Event-Id'=> last_event_id }

  # store device data (what/when/id)
  settings.devices[channel][device.intern] = status_update


  # todo: STORE feedback status
  puts "FEEDBACK> channel: #{channel}, device: #{device}, Last-Event-Id: #{last_event_id}, status: #{status}".green

  log_params if settings.debug

end


#
# ADMIN (MONITORING)
#

#
# return the number of connections (= number of subscribers)
#
get '/admin/connections' do

  t = 0
  c = {}

  settings.connections.each do |key,value|

    # number of subscribers listening on a channel
    c.merge! key.intern => value.size
  
    # total of open connections
    t = t + value.size
  end  
  
  MultiJson.dump (c.merge :'total number' => t), :pretty => true
end


#
# return the events list for a channel
#
get '/admin/events/:channel' do

  # todo: check validity of channel value
  channel = params[:channel].intern

  events = settings.events[channel].map { |k, v| MultiJson.load v}
  MultiJson.dump events, :pretty => true
end


#
# return the devices list for a channel
#
get '/admin/devices/:channel' do

  # todo: check validity of channel value
  channel = params[:channel].intern

  MultiJson.dump settings.devices[channel], :pretty => true
end


get '/' do
  MultiJson.dump :message => 'PERE server up and running\n', :pretty => true 
  # code = "<%= \"server up and running\n\" %>"
  #erb code
end


not_found do
  MultiJson.dump :message => 'This is nowhere to be found.', :pretty => true
end


error do
  MultiJson.dump :message => 'Sorry there was a nasty error - ' + env['sinatra.error'].name, :pretty => true
end