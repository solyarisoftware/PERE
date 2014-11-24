PERE
====

P-ushed E-vents with return R-eceipt E-ngine: a Ruby-Sinatra SSE Pub/Sub architecture


Simple Ruby [Sinatra](http://www.sinatrarb.com/) pub/sub architecture, to show how to push events using flat HTTP [Server-Sent Events](http://www.w3.org/TR/eventsource/) to downstream (JSON) events to clients devices with delivery receipts (using HTTP webhooks).


## problem

blabla.


## solution

blabla.


```

                 .-------.
publish evt ->   | PERE  |---> channel 1 down-stream feed -> device 1
                 |       |<--------------------------------- feedback up-stream
                 |       |                
                 |       |---> channel 1 down-stream feed -> ...
                 |       |<---------------------------------
                 |       |                
                 |       |---> channel 1 down-stream feed -> device m
                 |       |<--------------------------------- feedback up-stream
                 |       |                
                 |       | 
                 |       |---> channel 2 -> ...
                 |       |
                 |       |               -> device d+1
                 |       |---> channel N -> ... 
                 .-------.               -> device d+D


```


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
SOFTWARE.


# Contacts

Please feel free to write an e-mail with your comments and jobs proposals are more than welcome. BTW, a mention/feedback to me will be very welcome and STAR the project if you feel it useful!

E-mail: [giorgio.robino@gmail.com](mailto:giorgio.robino@gmail.com)
