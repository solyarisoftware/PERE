PERE
====

PUSH EVENTS with RETURN-RECEIPT Engine: a Ruby-Sinatra SSE Pub/Sub demo framework.

<img src="https://github.com/solyaris/PERE/blob/master/public/pere-logo.png" alt="PERE logo">

Here a simple *proof of concept*/demo code, to show how to push events using flat HTTP SSE (down-stream) to clients devices with *delivery receipts* (up-stream feedbacks).

BTW, "PERE" is an acronym for "Push Events Receipt Engine" and my mother tongue language (Italian), "pere" means "pears" (the fruit) :-) 


## Push notifications with return-receipt (the problem)

For some business application purposes, I need to delivery events (= messages) server-side published, to a multitude of devices, with a **garantee delivery receipt (= return-receipt)** of each message sent.

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

- JSON for payload data transport is fine.

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

Publishers Devices   PERE server                                    Subscriber Devices
           |              |                                                    |
           v              v                                                    v
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
- Ruby language (v.2.1.5) as glue.
- Beloved [Sinatra](https://github.com/sinatra/sinatra) microframework 
- Fast [Thin](https://github.com/macournoyer/thin/) web server 
- Event-driven I/O under the woods [EventMachine](https://github.com/eventmachine/eventmachine)


### pere.rb: the API server engine

The backend is a Sinatra API server engine that accept three main endpoints:

- Publisher 
Device push events on a named channel (with an HTTP POST):

```ruby
post "/push/:channel" do
  ... 
end  
```

- Subscriber feed
Client device subscribe to listen on a channel and receive related events (SSE Down-stream):

```ruby
get "/feed/:channel", provides: 'text/event-stream' do
  ...
end  
```

- Subscriber return receipt feedback
Client previously subscribed, reply to each event (UP-stream with HTTP POST webhooks):

```ruby
post "/feedback/:channel" do
  ...
end  
```

## Run all

Above all install all gems:

```bash
$ bundle install
$ export HOSTNAME= yourhostname
```


### run the backend server: pere.rb 

On the first terminal run the server, a Sinatra engine do the back-end job: 

```bash
$ ruby pere.rb -o yourhostname

== Sinatra/1.4.5 has taken the stage on 4567 for development with backup from Thin
Thin web server (v1.6.3 codename Protein Powder)
Maximum connections set to 1024
Listening on yourhostname:4567, CTRL+C to stop
```


### run the *event publisher* test script: publisher.rb

 On a terminal, the test publisher that emit / push some event every few seconds on a certain channel. An event here is a JSON containing chunk of random data as payload:

```bash
$ ruby publisher.rb
PUSH EVENTS from device: P0039299345141, to channel: CHANNEL_1, at server: yourhostname:4567
PUSH EVT> event: {"device":"P0039299345141","time":"2014-12-02T15:45:51.626Z","id":1,"data":"s8uwedgsk5qf7jf52k"}
PUSH EVT> event: {"device":"P0039299345141","time":"2014-12-02T15:46:04.839Z","id":2,"data":"85levx6dfxzj9a2yn1nx1"}
PUSH EVT> event: {"device":"P0039299345141","time":"2014-12-02T15:46:22.896Z","id":3,"data":"t3ltjrdsehaweewib"}
PUSH EVT> event: {"device":"P0039299345141","time":"2014-12-02T15:46:37.935Z","id":4,"data":"wdjij9qrjfphlhzy7"}
```


### run an *host subscriber* test script: subscriber.rb 

On one or many terminal (devices), run a test client host that listen events on a certain channel, does some elaboration and feedback some status ack to server:

```bash
$ ruby subscriber.rb
SUBSCRIBER from device: H0039858702766, to channel: CHANNEL_1, at server: yourhostname:4567
RX EVT> id: 2014-12-02T15:45:51.766Z, data: {"device":"P0039299345141","time":"2014-12-02T15:45:51.626Z","id":1,"data":"s8uwedgsk5qq4ywuf7jf52k"}
RX EVT> id: 2014-12-02T15:46:04.861Z, data: {"device":"P0039299345141","time":"2014-12-02T15:46:04.839Z","id":2,"data":"85levx6dfxzj9a2yn1nx1"}
RX EVT> id: 2014-12-02T15:46:22.914Z, data: {"device":"P0039299345141","time":"2014-12-02T15:46:22.896Z","id":3,"data":"t3ltjrdsehaweewib"}
```


### run a *web subscriber* on a browser 

On (one or many) browser windows, open a web page that listen events events on a certain channel (using standard SSE HTML Javascript code), does some elaboration and feedback some status ack to server:

<img src="https://github.com/solyaris/PERE/blob/master/public/screenshot.jpg" alt="server screenshot">


### PERE logs

On the engine terminal you can watch what happen with stdout logs:

```bash
== Sinatra/1.4.5 has taken the stage on 4567 for development with backup from Thin
Thin web server (v1.6.3 codename Protein Powder)
Maximum connections set to 1024
Listening on yourhostname:4567, CTRL+C to stop
PUSH EVT> channel: CHANNEL_1, device: P0039457529090, Event-Id: 2014-12-02T15:37:42.243Z, data: {"device":"P0039457529090",", Event-Id: 2014-12-02T15:37:42.218Z","id":10,"data":"m9y72tw2nyeisgwanqu4"}
FEEDBACK> channel: CHANNEL_1, device: H0039529367750, Last-Event-Id: 2014-12-02T15:37:42.243Z, status: rx ok
PUSH EVT> channel: CHANNEL_1, device: P0039457529090, Event-Id: 2014-12-02T15:38:02.320Z, data: {"device":"P0039457529090",", Event-Id: 2014-12-02T15:38:02.281Z","id":11,"data":"nm7ntdod8l6y43ec135goxu4tltz"}
FEEDBACK> channel: CHANNEL_1, device: H0039529367750, Last-Event-Id: 2014-12-02T15:38:02.320Z, status: rx ok
PUSH EVT> channel: CHANNEL_1, device: P0039457529090, Event-Id: 2014-12-02T15:38:15.372Z, data: {"device":"P0039457529090",", Event-Id: 2014-12-02T15:38:15.345Z","id":12,"data":"y3enb9nio1othcq1i"}
FEEDBACK> channel: CHANNEL_1, device: H0039529367750, Last-Event-Id: 2014-12-02T15:38:15.372Z, status: rx ok
^CStopping ...
Stopping ...
== Sinatra has ended his set (crowd applauds)

```

### Monitor status API

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
  ...
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
  ...
}
```


## To Do

- Store to disk (persistence) events and status (with Marshal dump or any db, e.g. Redis)
- Less raugh subscriber.html
- Think about some UUID to identify devices (serialnumber/IMEI/MAC?)
- Better manage devices status ("presence")
- Add a bit of API endpoints security (token-ids)


## Release Notes

### v.0.0.5 - 2 December 2014
- Manage SSE ID re-synch/reconnection pushing out previously undelivered / lost events).
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
- [Darren Cook](http://stackoverflow.com/users/841830/darren-cook) for superb book (also avalialbl as ebook): [Data Push Apps with HTML5 SSE](http://shop.oreilly.com/product/0636920030928.do) 

<img src="http://akamaicovers.oreilly.com/images/0636920030928/lrg.jpg" width="40%" height="40%" alt="Data Push Apps with HTML5 SSE">


## Online readings about *realtime web and SSE*

- [Building Real-Time Web Applications with Server-Sent Events](http://tx.pignata.com/2012/10/building-real-time-web-applications-with-server-sent-events.html) by [John Pignata](http://tx.pignata.com/2012/10/building-real-time-web-applications-with-server-sent-events.html)
- [WebSockets vs. Server-Sent events/EventSource](http://stackoverflow.com/questions/5195452/websockets-vs-server-sent-events-eventsource)
- [Stream Updates with Server-Sent Events](http://www.html5rocks.com/en/tutorials/eventsource/basics/)
- [Real-Time Web Technologies Guide](http://www.leggetter.co.uk/real-time-web-technologies-guide) and [Web Browsers & the Realtime Web](http://www.leggetter.co.uk/2012/02/09/edinburgh-techmeetup-web-browsers-the-realtime-web.html) by [Phil Leggetter](https://github.com/leggetter) 
- [Let's Get Real (time): Server-Sent Events, WebSockets and WebRTC for the soul](http://www.slideshare.net/swanandpagnis/lets-get-real-time-serversent-events-websockets-and-webrtc-for-the-soul) by [Swanand Pagnis](https://github.com/swanandp)
- [Server-Sent Events and Javascript](http://www.sitepoint.com/server-sent-events/) by [Tiffany B. Brown](https://twitter.com/webinista)
- [Using server-sent events from a web application](https://developer.mozilla.org/en-US/docs/Server-sent_events/Using_server-sent_events)


# Contacts

Please feel free to write an e-mail with your comments are more than welcome. BTW, a mention/feedback to me will be very welcome and **STAR the project if you feel it useful**!

twitter: [@solyarisoftware](http://www.twitter.com/solyarisoftware)
e-mail: [giorgio.robino@gmail.com](mailto:giorgio.robino@gmail.com)
