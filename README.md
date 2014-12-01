PERE
====

PUSH EVENTS with RETURN-RECEIPT Engine: a Ruby-Sinatra SSE Pub/Sub demo framework.

<img src="https://github.com/solyaris/PERE/blob/master/public/pere-logo.png" alt="PERE logo">

Here a simple *proof of concept*/demo code, to show how to push events using flat HTTP SSE (down-stream) to clients devices with *delivery receipts* (up-stream feedbacks).

BTW, "PERE" is an acronym for "Push Events Receipt Engine" and my mother tongue language (Italian), "pere" means "pears" (the fruit) :-) 


## Push notifications with return-receipt (the problem)

For some business application purposes, I need to delivery events (=messages) server-side published, to a multitude of devices, with an (optional) garantee delivery receipt (return-receipt) of each message sent.

- Devices: are possibly "anything": 
  - hosts clients
  - web browsers on PCs
  - mobile handset (via website or native app)

- Pub/sub, channels: 
  - old fashioned publisher/subscriber fit the goal 
  - subscribers: are clients (devices) that listen events on a *channel*
  - publishers: are client (devices) that push some messages events on a *channel*

- Up-stream feedbacks: 
  - The server must have some *delivery-receipt* aka *return-receipt* from each client device subscribed to receive events on a channel, with a *status update* of local elaborations.
  - "Presence" of clients devices must be tarcked by server

- JSON for data transport is fine.

- Just HTTP as transport protocol ? 


## A Ruby-Sinatra SSE Pub/Sub framework (a solution)

- Just HTTP! for Server Push Notifications (Down-stream):
The basic idea is to implement pub/sub using *Server-Sent Events* aka EventSource aka [SSE](http://www.w3.org/TR/eventsource/) HTML5 technology: just HTTP streaming.

  SSE pros: 
    - it's just HTTP (avoiding possible nightmares with websockets on some 3G/mobile data networks)
    - it's an HTML5 standard now (few lines of javascript on almost any modern web browser)

  SEE cons:
    - it's simplex (on-way down-streaming from a server to clients), instead websockets are full duplex. Nevertheless in the scenario of the problem, webhooks (HTTP POST from each client to the server) could be used for the up-stream communication. See the sketch: 

- Just HTTP! for Events Feedbacks (Up-stream): 
Client devices reply to events notification using standard HTTP req/res (HTTP POST) to trace presence and/or feedback status of a local elaboration. On a web browser JS/AJAX is fine for the purpose. 


```

Publishers Devices   PERE server                                         Subscriber Devices
          |               |                                                    |
          v               v                                                    v
                   .-------------.
  HTTP POST evt -> | -> queue -> |--- HTTP SSE events  --> channel 1 -> device 1 
                   |   status <- |<-- HTTP POST status <---------------
                   |             |
                   | -> queue -> |--- HTTP SSE events  --> channel 1 -> device 2
                   |   status <- |<-- HTTP POST status <--------------- 
                   |             |           
                   | -> queue -> |--- HTTP SSE events  --> channel 1 -> device N
                   |   status <- |<-- HTTP POST status <---------------
                   |             |
                   | -> queue -> |--- HTTP SSE events  --> channel N ->
                   .-------------.                                              
                          ^
                          |
                    admin queries    

```


Usual tools: 
- Ruby language as glue.
- Beloved [Sinatra](https://github.com/sinatra/sinatra) microframework 
- Fast [Thin](https://github.com/macournoyer/thin/) web server 
- Event-driven I/O under the woods [EventMachine](https://github.com/eventmachine/eventmachine)


### SSEserver: Sinatra API Server

The backend is an API server that accept three main endpoints:

- Publisher push events on a channel
SSEserver push an event to a channel (with an HTTP POST):

```bash
post "/push/:channel" do
  ... 
end  
```

- Subscriber and receive events from the channel
Client device subscribe to a channel and receive events (SSE Down-stream):

```bash
get "/feed/:channel", provides: 'text/event-stream' do
  ...
end  
```

- Subscriber reply Feedbacks
Client previously Subscribed, reply to each event (UP-stream with HTTP POST webhooks):

```bash
post "/feedback/:channel" do
  ...
end  
```

## Enjoy tests scripts

Above all install all gems:

```bash
$ bundle install
$ export HOSTNAME= yourhostname
```


### run PERE API server!

On the first terminal run the server, a Sinatra engine doing the back-end job: 

```bash
$ ruby pere.rb -o yourhostname

== Sinatra/1.4.5 has taken the stage on 4567 for development with backup from Thin
Thin web server (v1.6.3 codename Protein Powder)
Maximum connections set to 1024
Listening on yourhostname:4567, CTRL+C to stop
```


### run the *event publisher* test script

 On a terminal, the test publisher that emit / push some event every few seconds on a certain channel. An event here is a JSON containing chunk of random data as payload:

```bash
$ ruby publisher.rb

PUBLISH (device: P0039696456814), channel: CHANNEL_1, server: yourhostname:4567

PUSH EVT> event: {"channel":"CHANNEL_1","device":"P0039696456814","id":1,"time":"2014-11-25T08:12:09Z","data":"jvg2dchijlkob1afuauaohtbzzhd7ayp"}
PUSH EVT> event: {"channel":"CHANNEL_1","device":"P0039696456814","id":2,"time":"2014-11-25T08:12:25Z","data":"fa8keuulgef63154oqdo8fwcbiysha6qsd414fsf5i3phbhe0lokdyymjlwxcc3zqwt1"}
```


### run a *host subscriber* script

On one or many terminal (devices), run a test client host that listen events on a certain channel, does some elaboration and feedback some status ack to server:

```bash
$ ruby subscriber.rb

LISTEN (device: H0039350488701), channel: CHANNEL_1, server: yourhostname:4567

RX EVT> {"channel":"CHANNEL_1","device":"P0039696456814","id":1,"time":"2014-11-25T08:12:09Z","data":"jvg2dchijlkob1afuauaohtbzzhd7ayp"}
RX EVT> {"channel":"CHANNEL_1","device":"P0039696456814","id":2,"time":"2014-11-25T08:12:25Z","data":"fa8keuulgef63154oqdo8fwcbiysha6qsd414fsf5i3phbhe0lokdyymjlwxcc3zqwt1"}
```


### run a *web subscriber*  

On (one or many) browser windows, open a web page that listen events events on a certain channel (using standard SSE HTML Javascript code), does some elaboration and feedback some status ack to server:

<img src="https://github.com/solyaris/PERE/blob/master/public/screenshot.jpg" alt="server screenshot">


### PERE logs

On the engine terminal you can watch what happen with stdout logs:


```bash
== Sinatra/1.4.5 has taken the stage on 4567 for development with backup from Thin
Thin web server (v1.6.3 codename Protein Powder)
Maximum connections set to 1024
Listening on 192.168.1.103:4567, CTRL+C to stop
FEED REQ> device: H0039526449233, channel: CHANNEL_1, Last-Event-Id: 2014-12-01T15:01:45.025Z
FEED REQ> device: H0039701836021, channel: CHANNEL_1, Last-Event-Id: 2014-12-01T15:01:45.025Z
PUSH EVT> channel: CHANNEL_1, device: P0039440629675, Event-Id: 2014-12-01T15:02:07.066Z, data: {"channel":"CHANNEL_1","pub_id":179,"data":"kypcav3np07xdoq9yj91798dofm"}
FEEDBACK> channel: CHANNEL_1, device: H0039526449233, Last-Event-Id: 2014-12-01T15:02:07.066Z, status: rx ok
FEEDBACK> channel: CHANNEL_1, device: H0039701836021, Last-Event-Id: 2014-12-01T15:02:07.066Z, status: rx ok
PUSH EVT> channel: CHANNEL_1, device: P0039440629675, Event-Id: 2014-12-01T15:02:25.104Z, data: {"channel":"CHANNEL_1","pub_id":180,"data":"90su3d2zs5iaen"}
FEEDBACK> channel: CHANNEL_1, device: H0039701836021, Last-Event-Id: 2014-12-01T15:02:25.104Z, status: rx ok
FEEDBACK> channel: CHANNEL_1, device: H0039526449233, Last-Event-Id: 2014-12-01T15:02:25.104Z, status: rx ok
PUSH EVT> channel: CHANNEL_1, device: P0039440629675, Event-Id: 2014-12-01T15:02:35.151Z, data: {"channel":"CHANNEL_1","pub_id":181,"data":"vssis31pylxz0dx"}
FEEDBACK> channel: CHANNEL_1, device: H0039701836021, Last-Event-Id: 2014-12-01T15:02:35.151Z, status: rx ok
FEEDBACK> channel: CHANNEL_1, device: H0039526449233, Last-Event-Id: 2014-12-01T15:02:35.151Z, status: rx ok
^CStopping ...
Stopping ...
== Sinatra has ended his set (crowd applauds)

```

### Monitor status

Some endpoints are available to monitor internal status / memory

To know how many open connections there are for each channel:

```
$ curl yourhost:4567/admin/connections
{
  "CHANNEL_1":4,
  "CHANNEL_3":2,
  "total number":6
}
```

Events list for each channel:

```
$ curl yourhost:4567/admin/events/CHANNEL_1
[
  {
    "device":"P0039163746978",
    "time":"2014-12-01T15:09:15.691Z",
    "id":1,
    "data":"l6rqih112by5hl7z21"
  },
  {
    "device":"P0039163746978",
    "time":"2014-12-01T15:09:35.751Z",
    "id":2,
    "data":"3hxolcaxf5buax6nou9"
  },
  {
    "device":"P0039163746978",
    "time":"2014-12-01T15:09:55.812Z",
    "id":3,
    "data":"6ovkzc0dxr4ypge9t"
  }
]
```

Devices (subscribers) list (status & presence) on a channel:

```
$ curl yourhost:4567/admin/devices/CHANNEL_1
{
  "H0039258085863":{
    "op":"feedback",
    "at":"2014-12-01T14:28:30.993Z",
    "Last-Event-Id":"2014-12-01T14:28:30.969Z"
  },
  "H0039526449233":{
    "op":"feedback",
    "at":"2014-12-01T14:36:04.910Z",
    "Last-Event-Id":"2014-12-01T14:36:04.877Z"
  },
  "H0039701836021":{
    "op":"feedback",
    "at":"2014-12-01T14:36:04.904Z",
    "Last-Event-Id":"2014-12-01T14:36:04.877Z"
  }
}
```


## To Do

- Manage SSE IDs! (client re-synch/reconnection an get events from last SSE ID).
- Store to disk (persistence) events and status!
- Less raugh subscriber.html
- Think about some UUID to identify devices (serialnumber/IMEI/MAC?)
- Manage PRESENCE of devices
- Add a bit of security (token-ids for each publisher/subscriber devices)


## Release Notes

### v.0.0.4 - 1 December 2014
- timestamps used as SSE IDs
- understood how to manage Last-Event-ID (as http header param)
- /admin/* for a bit of status monitoring

### v.0.0.1 - 24 November 2014
- First release. 



## License (MIT)

Copyright (c) 2014 Giorgio Robino

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.Real-Time Web Technologies Guide


## Credits to people / software makers

- [Paolo Montrasio](https://github.com/pmontrasio), for the remind "*hey Giorgio, why don't you use SSE?*"
- [François de Metz](https://github.com/francois2metz), for [em-eventsource](https://github.com/AF83/em-eventsource)
- [Peter Ohler](https://github.com/ohler55) for [oj](https://github.com/ohler55/oj) JSON optimizer.
- [Marc-André Cournoyer](https://github.com/macournoyer) for [Thin](https://github.com/macournoyer/thin) superfast Tiny, fast & funny HTTP server
- [Kenichi Nakamura](https://github.com/kenichi) for [Angelo](https://github.com/kenichi/angelo)
- [Salvatore Sanfilippo](https://github.com/antirez) I do not (yet) used [REDIS](http://redis.io/) here, but there is always a good reason to thank-you him


## Readings about *realtime web and SSE*

The book!
- [Data Push Apps with HTML5 SSE](http://shop.oreilly.com/product/0636920030928.do) superb book (also avalialbl as ebook) by [Darren Cook](http://stackoverflow.com/users/841830/darren-cook)

<img src="http://akamaicovers.oreilly.com/images/0636920030928/lrg.jpg" width="40%" height="40%" alt="Data Push Apps with HTML5 SSE">

Online readings:
- [Building Real-Time Web Applications with Server-Sent Events](http://tx.pignata.com/2012/10/building-real-time-web-applications-with-server-sent-events.html) by [John Pignata](http://tx.pignata.com/2012/10/building-real-time-web-applications-with-server-sent-events.html)
- [WebSockets vs. Server-Sent events/EventSource](http://stackoverflow.com/questions/5195452/websockets-vs-server-sent-events-eventsource)
- [Stream Updates with Server-Sent Events](http://www.html5rocks.com/en/tutorials/eventsource/basics/)
- [Real-Time Web Technologies Guide](http://www.leggetter.co.uk/real-time-web-technologies-guide) and [Web Browsers & the Realtime Web](http://www.leggetter.co.uk/2012/02/09/edinburgh-techmeetup-web-browsers-the-realtime-web.html) by [Phil Leggetter](https://github.com/leggetter) 
- [Let's Get Real (time): Server-Sent Events, WebSockets and WebRTC for the soul](http://www.slideshare.net/swanandpagnis/lets-get-real-time-serversent-events-websockets-and-webrtc-for-the-soul) by [Swanand Pagnis](https://github.com/swanandp)
- [Server-Sent Events and Javascript](http://www.sitepoint.com/server-sent-events/) by [Tiffany B. Brown](https://twitter.com/webinista)
- [Using server-sent events from a web application](https://developer.mozilla.org/en-US/docs/Server-sent_events/Using_server-sent_events)
- [EventMachine](https://github.com/eventmachine/eventmachine/wiki)


# Contacts

Please feel free to write an e-mail with your comments are more than welcome. BTW, a mention/feedback to me will be very welcome and STAR the project if you feel it useful!

twitter: [@solyarisoftware](http://www.twitter.com/solyarisoftware)
e-mail: [giorgio.robino@gmail.com](mailto:giorgio.robino@gmail.com)
