#!/bin/sh

# Latency: 150±30 ms
# Random packet loss: 10%
# Correlation: 25% (some packets are more likely to be dropped in bursts)
tc qdisc add dev eth0 root handle 1: netem delay 150ms 30ms distribution normal loss 10% 25%
# Bandwidth: 768 kbit/s (approx. typical 3G speed)
tc qdisc add dev eth0 parent 1:1 handle 10: tbf rate 768kbit buffer 1600 limit 3000
