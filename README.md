PERE
====

**P**ushed **E**vents with return **R**eceipt **E**ngine: a Ruby-Sinatra SSE Pub/Sub framework.

<img src="https://github.com/solyaris/PERE/blob/master/public/pere-logo.png" alt="PERE logo">

Here a simple *proof of concept* code, to show how to push events using flat HTTP SSE (down-stream) to clients devices with "delivery receipts" (up-stream feedbacks).


## Push notifications with return-receipt (problem)

For some business application purposes (rosposhop.com, pagosaldo.com), I need to delivery "events/messages" server-side published, to a multitude of devices, with garantee delivery.

- Devices: are possibly "anything": 
  - hosts clients
  - web browsers on PCs
  - mobile handset (via website or native app)

- Pub/sub: old fashioned publisher/subscriber is fine for the goal.


- Up-stream feedbacks: 
The server must have some *delivery receipt* aka *return receipt* from each client device that receive the events on a channel, with a *status update* of local elaborations.

- JSON for data transport is fine.

- Just HTTP, please! 


## A Ruby-Sinatra SSE Pub/Sub framework (solution)

The basic idea is to implement pub/sub using *Server-Sent Events* aka EventSource aka [SSE](http://www.w3.org/TR/eventsource/) HTML5 technology: just **HTTP streaming**.


```
                 .-------.
publish evt ->   | PERE  |--- HTTP SSE events (down-stream) --> channel 1 -> device 1 
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
- Ruby language 
- beloved [Sinatra](http://www.sinatrarb.com/) microframework 
- fast web server [Thin](https://github.com/macournoyer/thin/) with [EventMachine](https://github.com/eventmachine/eventmachine) event-driven I/O under thw woods.


### Main Endpoints

- PUSH AN EVENT TO A CHANNEL (PUBLISH)
```bash
post "/push/:channel" do
```

- LISTEN EVENTS FROM A CHANNEL (SUBSCRIBE & UP-STREAM)
```bash
get "/feed/:channel", provides: 'text/event-stream' do
```

- FEEDBACK FROM CLIENTS (WEBHOOK UP-STREAM)
```bash
post "/feedback/:channel" do
```

## run test stuff

above all:

```bash
$ bundle install
$ export HOSTNAME= yourhostname
```


### run the SSEserver engine

On the first terminal run the server, a Sinatra app doing the server-side job: 

```bash
$ ruby sseserver.rb -o yourhostname
```


### run a event *publisher*

 On a second terminal, the test publisher that emit / push some event every few seconds on a certain channel. An event here is a JSON containing chunk of random data as payload:

```bash
$ ruby publisher.rb
```


### run a *host listener*

On one or many terminal (devices), run a test client host that listen events on a certain channel, does some elaboration and feedback some status ack to server:

```bash
$ ruby hostlistener.rb
```


### run a *web listener*  

On (one or many) browser windows, open a web page that listen events events on a certain channel (using standard SSE HTML Javascript code), does some elaboration and feedback some status ack to server:

```bash
http://yourhostname/weblistener.html
```


<img src="https://github.com/solyaris/PERE/blob/master/public/screenshot.jpg" alt="server screenshot">


## To Do

- Manage SSE IDs! (client re-synch to last SSE ID).
- Add a queue system to store events pushed on a channel (I guess to use REDIS)
- less raugh weblistener.html
- think about some UUID to identify devices (serialnumber/IMEI/MAC?)


## Release Notes

### v.0.0.1 
- First release, 24 November 2014



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


## Thanks

- [Paolo Montrasio](https://github.com/pmontrasio), about the sentence "hey Giorgio, why don't you use SSE?".
- [Phil Leggetter](https://github.com/leggetter), for his [Real-Time Web Technologies Guide](http://www.leggetter.co.uk/real-time-web-technologies-guide)
- [Swanand Pagnis](https://github.com/swanandp), for his [Let's Get Real (time): Server-Sent Events, WebSockets and WebRTC for the soul](http://www.slideshare.net/swanandpagnis/lets-get-real-time-serversent-events-websockets-and-webrtc-for-the-soul)
- [Salvatore Sanfilippo](https://github.com/antirez) I do not (yet) used [REDIS](http://redis.io/) here, but there is always a good reason to thank-you him.


# Contacts

Please feel free to write an e-mail with your comments are more than welcome. BTW, a mention/feedback to me will be very welcome and STAR the project if you feel it useful!

E-mail: [giorgio.robino@gmail.com](mailto:giorgio.robino@gmail.com)
