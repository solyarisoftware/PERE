# encoding: utf-8

require 'colorize'
require 'multi_json'
require 'sinatra'

# some documentation
# http://www.sinatrarb.com/contrib/streaming.html
# http://tx.pignata.com/2012/10/building-real-time-web-applications-with-server-sent-events.html
# http://html5hacks.com/blog/2013/04/21/push-notifications-to-the-browser-with-server-sent-events/

disable :logging

# a web server with a event machine engine
set server: 'thin' 

# connections 
# global hash containing a list of connections (one list for every channel)
# each connection is inialized with a void list
#
#   connections[:channel_1] = [...]
#     ...
#   connections[:channel_N] = [...]
#
set connections:  Hash.new {|h, k| h[k] = [] }

# sse_id 
# global hash containing channel ID counter (one for every channel)
# each ID is initailized to 0
#
#   sse_id[:channel_1] = 0
#     ...
#   sse_id[:channel_N] = 0
#
set sse_id: Hash.new {|h, k| h[k] = 0 }


#
# PUSH AN EVENT TO A CHANNEL (PUBLISH)
# 
post "/push/:channel" do

  # todo: check validity of channel value
  channel = params[:channel].intern

  # read message as (JSON) payload in HTTP request BODY 
  data = request.body.read

  # log event
  puts "PUSH EVT. channel: #{channel}, data: #{data}".cyan

  # increment SSE ID data packet 
  settings.sse_id[:channel] = settings.sse_id[:channel] + 1
  id = settings.sse_id[:channel]

  settings.connections[channel].each do |connection|
    sse_event = "id: #{id}\ndata: #{data}\n\n"
    connection << sse_event
  end

  status 200
end


#
# LISTEN EVENTS FROM A CHANNEL (SUBSCRIBE & UP-STREAM)
#
get "/feed/:channel", provides: 'text/event-stream' do

  # todo: check validity of channel value
  channel = params[:channel].intern

  puts "FEED REQ. channel: #{channel}".yellow

  stream :keep_open do |out|
   settings.connections[channel] << out
   out.callback { settings.connections[channel].delete(out) }
  end
end  


#
# FEEDBACK FROM CLIENTS (WEBHOOK UP-STREAM)
#
post "/feedback/:channel" do
  
  # todo: STORE feedback status

  puts "FEED ACK. channel: #{params[:channel]}, evtid: #{params[:id]}, \
        device: #{params[:device]}, status: #{params[:status]}".green
end


get '/' do
  MultiJson.dump :message => 'server up and running\n' 
  # code = "<%= \"server up and running\n\" %>"
  #erb code
end


#
# ADMIN
#

# http://www.tutorialspoint.com/ruby/ruby_hashes.htm
get '/admin/connections' do
  MultiJson.dump :connections => settings.connections  
end


not_found do
  MultiJson.dump :message => 'This is nowhere to be found.'
end


error do
  MultiJson.dump :message => 'Sorry there was a nasty error - ' + env['sinatra.error'].name
end