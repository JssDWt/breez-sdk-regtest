#!/bin/sh

# Latency: 70±20 ms
# Random packet loss: 2%
# Correlation: 25% (some packets are more likely to be dropped in bursts)
tc qdisc add dev eth0 root handle 1: netem delay 70ms 20ms distribution normal loss 2% 25%

# Bbandwidth: 20 Mbit/s
tc qdisc add dev eth0 parent 1:1 handle 10: tbf rate 20mbit burst 32kbit latency 400ms
