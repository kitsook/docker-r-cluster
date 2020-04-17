#!/bin/bash

# start a websocket tunnel listener.
# restrict connection to localhost on 6311, which is Rserve's QAP port
/root/wstunnel --server ws://0.0.0.0:8000 -r 127.0.0.1:6311 &

/usr/bin/R -e "Rserve::run.Rserve(remote=TRUE, auth=FALSE, daemon=FALSE)"

