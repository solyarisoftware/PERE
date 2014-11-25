PERE
====

Pushed-Events with return-Receipt Engine: a Ruby-Sinatra SSE Pub/Sub simple framework.

<img src="https://github.com/solyaris/PERE/blob/master/public/pere-logo.png" alt="PERE logo">

Here a simple *proof of concept* code, to show how to push events using flat HTTP SSE (down-stream) to clients devices with "delivery receipts" (up-stream feedbacks).


## Push notifications with return-receipt (the problem)

For some business application purposes, I need to delivery "events/messages" server-side published, to a multitude of devices, with "garantee delivery".

- Devices: are possibly "anything": 
  - hosts clients
  - web browsers on PCs
  - mobile handset (via website or native app)

- Pub/sub: 
  - old fashioned publisher/subscriber is fine for the goal 
  - subscribers: are clients (devices) that listen events on a "channel"
  - publishers: are client (devices) that push some messages events on a "channel"

- Up-stream feedbacks: 
- The server must have some *delivery-receipt* aka *return-receipt* from each client device subscribed to receive events on a channel, with a *status update* of local elaborations.
- "Presence" of clients devices must be tarcked by server

- JSON for data transport is fine.

- Just HTTP as transport protocol ? 


## A Ruby-Sinatra SSE Pub/Sub framework (a solution)

- Just HTTP! 
The basic idea is to implement pub/sub using *Server-Sent Events* aka EventSource aka [SSE](http://www.w3.org/TR/eventsource/) HTML5 technology: just **HTTP streaming**.

SSE pros: 
- it's just HTTP
- it's a HTML5 standard

SEE cons:
- it's simplex (on-way down-streaming from a server to clients), instead Websockets are full duplex. nevertheless in the scenario of the problem, webhooks (HTTP POST from each client to the server) could be used for the up-stream communication. See the sketch: 


```
                 .-------.
HTTP POST evt -> | PERE  |--- HTTP SSE events (down-stream) --> channel 1 -> device 1 
                 |       |<-- HTTP POST (up-stream) status  <---------------
                 |       | 
                 |       |--- HTTP SSE events (down-stream) --> channel 1 -> device 2
                 |       |<-- HTTP POST (up-stream) status  <--------------- 
                 |       |                
                 |       |--- HTTP SSE events (down-stream) --> channel 1 -> device N
                 |       |<-- HTTP POST (up-stream) status  <---------------
                 |       | 
                 |       |--- HTTP SSE events (down-stream) --> channel N ->
                 .-------.                                              

```


Usual tools: 
- Ruby language as glue.
- beloved [Sinatra](http://www.sinatrarb.com/) microframework 
- fast web server [Thin](https://github.com/macournoyer/thin/) with [EventMachine](https://github.com/eventmachine/eventmachine) event-driven I/O under thw woods.


### Main Endpoints

- PUBLISHER PUSH EVENTS ON A CHANNEL
Push an event to a channel:

```bash
post "/push/:channel" do
```

- SUBSCRIBER RECEIVE EVENTS FROM A CHANNEL
Client device subscribe to a channel and receive events (SSE DOWN-stream):

```bash
get "/feed/:channel", provides: 'text/event-stream' do
```

- SUBSCRIBER REPLY FEEDBACKS
Client previously Subscribed, reply to each event (webhooks UP-stream):

```bash
post "/feedback/:channel" do
```

## Enjoy tests scripts

Above all install all gems:

```bash
$ bundle install
$ export HOSTNAME= yourhostname
```


### run the *event publisher*

 On a terminal, the test publisher that emit / push some event every few seconds on a certain channel. An event here is a JSON containing chunk of random data as payload:

```bash
$ ruby publisher.rb

PUBLISH (device: P0039696456814), channel: CHANNEL_1, server: 192.168.1.102:4567

PUSH EVT. event: {"channel":"CHANNEL_1","device":"P0039696456814","id":1,"time":"2014-11-25T08:12:09Z","data":"jvg2dchijlkob1afuauaohtbzzhd7ayp"}
PUSH EVT. event: {"channel":"CHANNEL_1","device":"P0039696456814","id":2,"time":"2014-11-25T08:12:25Z","data":"fa8keuulgef63154oqdo8fwcbiysha6qsd414fsf5i3phbhe0lokdyymjlwxcc3zqwt1"}
```


### run a *host listener*

On one or many terminal (devices), run a test client host that listen events on a certain channel, does some elaboration and feedback some status ack to server:

```bash
$ ruby hostlistener.rb

LISTEN (device: H0039350488701), channel: CHANNEL_1, server: 192.168.1.102:4567

RX EVT: {"channel":"CHANNEL_1","device":"P0039696456814","id":1,"time":"2014-11-25T08:12:09Z","data":"jvg2dchijlkob1afuauaohtbzzhd7ayp"}
RX EVT: {"channel":"CHANNEL_1","device":"P0039696456814","id":2,"time":"2014-11-25T08:12:25Z","data":"fa8keuulgef63154oqdo8fwcbiysha6qsd414fsf5i3phbhe0lokdyymjlwxcc3zqwt1"}
```


### run a *web listener*  

On (one or many) browser windows, open a web page that listen events events on a certain channel (using standard SSE HTML Javascript code), does some elaboration and feedback some status ack to server:

<img src="https://github.com/solyaris/PERE/blob/master/public/screenshot.jpg" alt="server screenshot">


### run the SSEserver engine

On the first terminal run the server, a Sinatra app doing the server-side job: 

```bash
$ ruby sseserver.rb -o yourhostname

== Sinatra/1.4.5 has taken the stage on 4567 for development with backup from Thin
Thin web server (v1.6.3 codename Protein Powder)
Maximum connections set to 1024
Listening on 192.168.1.102:4567, CTRL+C to stop
FEED REQ from device: W0039344485231, channel: CHANNEL_1
FEED REQ from device: H0039350488701, channel: CHANNEL_1
PUSH EVT. channel: CHANNEL_1, data: {"channel":"CHANNEL_1","device":"P0039696456814","id":4,"time":"2014-11-25T08:12:50Z","data":"jwfbl6kvwy23g5ek4dotjgbmg1icivk4n6t3pjue5yabsyzfzrvhtncc9uabljwetwzk3604agcxmwoymb4bv494c0qwtbq"}
FEED BACK for channel: CHANNEL_1, device: H0039350488701, evtid: 1, status: ok
FEED BACK for channel: CHANNEL_1, device: W0039344485231, evtid: 1, status: ok
PUSH EVT. channel: CHANNEL_1, data: {"channel":"CHANNEL_1","device":"P0039696456814","id":5,"time":"2014-11-25T08:13:01Z","data":"752a0mv6u6qbcbe6ohooc09zu4a78fljwkq1llkgdna6jnkllchcr51f0k42covgbymxkuo980to85q3h0rsbbygrzxt38sgvngx3w5ewb3dymx1le4itf"}
FEED BACK for channel: CHANNEL_1, device: W0039344485231, evtid: 2, status: ok
FEED BACK for channel: CHANNEL_1, device: H0039350488701, evtid: 2, status: ok
^CStopping ...
Stopping ...
== Sinatra has ended his set (crowd applauds)

```


## To Do

- Manage SSE IDs! (client re-synch to last SSE ID).
- Add a queue system to store events pushed on each channel (I guess to use REDIS)
- Less raugh weblistener.html
- Think about some UUID to identify devices (serialnumber/IMEI/MAC?)
- Add some Admin endpoints (to monitor connections number / devices listening)
- Manage PRESENCE of devices 


## Release Notes

### v.0.0.2  - 25 November 2014
- weblistener.html: supply correctly the "device id"

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


## Credits, People to Thanks and some references about *realtime web*

### People & software makers

- [Paolo Montrasio](https://github.com/pmontrasio), for the remind "*hey Giorgio, why don't you use SSE?*"
- [François de Metz](https://github.com/francois2metz), for [em-eventsource](https://github.com/AF83/em-eventsource)
- [Kenichi Nakamura](https://github.com/kenichi) for [Angelo](https://github.com/kenichi/angelo)
- [Salvatore Sanfilippo](https://github.com/antirez) I do not (yet) used [REDIS](http://redis.io/) here, but there is always a good reason to thank-you him
- [Peter Ohler](https://github.com/ohler55) for [oj](https://github.com/ohler55/oj) JSON optimizer.
- [Marc-André Cournoyer](https://github.com/macournoyer) for [Thin](https://github.com/macournoyer/thin) superfast Tiny, fast & funny HTTP server


### Readings

- [John Pignata](http://tx.pignata.com/2012/10/building-real-time-web-applications-with-server-sent-events.html) for [Building Real-Time Web Applications with Server-Sent Events](http://tx.pignata.com/2012/10/building-real-time-web-applications-with-server-sent-events.html)

- [WebSockets vs. Server-Sent events/EventSource](http://stackoverflow.com/questions/5195452/websockets-vs-server-sent-events-eventsource)
- [Stream Updates with Server-Sent Events](http://www.html5rocks.com/en/tutorials/eventsource/basics/)

- [Phil Leggetter](https://github.com/leggetter), for [Real-Time Web Technologies Guide](http://www.leggetter.co.uk/real-time-web-technologies-guide) and [Web Browsers & the Realtime Web](http://www.leggetter.co.uk/2012/02/09/edinburgh-techmeetup-web-browsers-the-realtime-web.html)
- [Swanand Pagnis](https://github.com/swanandp), for [Let's Get Real (time): Server-Sent Events, WebSockets and WebRTC for the soul](http://www.slideshare.net/swanandpagnis/lets-get-real-time-serversent-events-websockets-and-webrtc-for-the-soul)

- [Server-Sent Events and Javascript](http://www.sitepoint.com/server-sent-events/)
- [Using server-sent events from a web application](https://developer.mozilla.org/en-US/docs/Server-sent_events/Using_server-sent_events)

- [EventMachine](https://github.com/eventmachine/eventmachine/wiki)


# Contacts

Please feel free to write an e-mail with your comments are more than welcome. BTW, a mention/feedback to me will be very welcome and STAR the project if you feel it useful!

twitter: [@solyarisoftware](twitter.com/solyarisoftware)
e-mail: [giorgio.robino@gmail.com](mailto:giorgio.robino@gmail.com)
