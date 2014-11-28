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

# Channel connections 
# global hash containing a list of connections (one list for every channel)
# each connection is inialized with a void list
#
#   connections[:channel_1] = [...]
#     ...
#   connections[:channel_N] = [...]
#
set connections:  Hash.new {|h, k| h[k] = [] }

# Channel sse_id 
# global hash containing channel ID counter (one for every channel)
# each ID is initailized to 0
#
#   sse_id[:channel_1] = 0
#     ...
#   sse_id[:channel_N] = 0
#
set sse_id: Hash.new {|h, k| h[k] = 0 }

set debug: false


# for debug
def log_params
  puts "query params:"
  params.each {|key, value| puts "\t#{key} = #{value}"}
  puts "HTTP headers:"
  env.select { |key, value| key.to_s.match(/^HTTP_*/) }.each {|key, value| puts "\t#{key} = #{value}"}
end


#
# return the value of an HTTP header param 
# return nil of param doesn't exist
#
# Note: Sinatra add prefix HTTP_ an do some string upcase to any header param,
# e.g. 'Last-Event-ID' become 'HTTP_LAST_EVENT_ID'
#
def header(param)
  env[ "HTTP_#{param.gsub('-', '_').upcase}" ]
end


#
# PUSH AN EVENT TO A CHANNEL (PUBLISH)
# 
post "/push/:channel" do

  # todo: check validity of channel value
  channel = params[:channel].intern

  # get device as param in HTTP request HEADER
  device = header 'device'

  # read message as (JSON) payload in HTTP request BODY 
  data = request.body.read

  # increment SSE ID data packet 
  settings.sse_id[:channel] = settings.sse_id[:channel] + 1
  id = settings.sse_id[:channel]

  settings.connections[channel].each do |connection|
    sse_event = "id: #{id}\ndata: #{data}\n\n"
    connection << sse_event
  end

  # log event
  puts "PUSH EVT> channel: #{channel}, device: #{device}, id: #{id}, data: #{data}".cyan

  
  log_params if settings.debug

  # https://gist.github.com/rkh/1476463
  204 # response without entity body # status 200
end


#
# LISTEN EVENTS FROM A CHANNEL (SUBSCRIBE & UP-STREAM)
#
get "/feed/:channel", provides: 'text/event-stream' do
 
  # https://github.com/sinatra/sinatra/blob/master/lib/sinatra/base.rb#L441
  cache_control :no_cache

  # TODO: check validity of channel value
  channel = params[:channel].intern

  # subscriber pass his identity with parameter 'device' 
  # TODO: check validity of device value
  device = header 'device' # params[:device]

  # get last event id from http header param
  last_event_id = header 'Last-Event-Id'

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

  # get params from HTTP header
  device = header 'device'
  last_event_id = header 'last_event_id'

  # todo: STORE feedback status
  puts "FEEDBACK> channel: #{params[:channel]}, device: #{device}, last_event_id: #{last_event_id}, status: #{params[:status]}".green

  log_params if settings.debug

end


#
# ADMIN (MONITORING)
#

get '/' do
  MultiJson.dump :message => 'PERE server up and running\n' 
  # code = "<%= \"server up and running\n\" %>"
  #erb code
end

#
# return the number of connections (= number of subscribers)
#
get '/admin/connections' do

  t = 0
  c = {}

  # http://www.tutorialspoint.com/ruby/ruby_hashes.htm
  settings.connections.each do |key,value|

    # number of subscribers listening on a channel
    c.merge! key.intern => value.size
  
    # total of open connections
    t = t + value.size
  end  
  
  MultiJson.dump c.merge :'total number' => t
end


not_found do
  MultiJson.dump :message => 'This is nowhere to be found.'
end


error do
  MultiJson.dump :message => 'Sorry there was a nasty error - ' + env['sinatra.error'].name
end