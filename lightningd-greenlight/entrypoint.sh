#!/bin/bash

until [ -f /data/.scheduler/init/nodeid ]
do
     sleep 1
done

until [ -f /data/.scheduler/init/init ]
do
     sleep 1
done

export GL_NODE_ID="$(cat /data/.scheduler/init/nodeid)"
export GL_NODE_INIT="$(cat /data/.scheduler/init/init)"

lightningd "$@"
