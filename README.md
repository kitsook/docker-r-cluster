# Rserve Cluster

A load balancing [Rserve](https://www.rforge.net/Rserve/) cluster supporting QAP protocol.

## Quick Start
Edit the `.env` file and set `RSERVE_NODE_NUM` to the number of Rserve nodes to run.  If this value is changed later, load balancer docker image needs to be rebuilt.  Refer to the technical details below.

Start the cluster with: 
```
docker-compose --compatibility up -d
```

The started `rcloud` container is the entry point to the cluster. It acts like a Rserv node listening on port 6311.  Add it to your docker network that needs to access Rserve, e.g.
 ```
 docker network connect webwork2_default rcloud
 ```


## Technical Details
### Why this setup?

There is no load balancing setup available for the Rserve default protocol QAP.

Note that newer version of Rserve supports http and WebSocket protocol which makes load balancing easier.  However, that requires appropriate clients to support the protocol. 

### How does it work?
The cluster wrap QAP traffic within WebSocket tunnel for load balancing. The tunnel accept incoming connections and route them through a nginx load balancer to Rserve nodes.

Within each RServe node, the WebSocket tunnel forwards the payload to the RServe QAP port on localhost.

### Details of each service as defined in `docker-compose.yml`

#### wstunnel (the rcloud container)
This container is the entry point.  It runs the WebSocker tunnel program [wstunnel](https://github.com/erebe/wstunnel) and listen for incoming traffic on port `6133`.  The tunnel is connected to the proxy / load balancer.

#### proxy (the load_balancer container)
This container runs nginx as reverse proxy.  Connections are routed to upstream Rserve nodes.

Note that the docker file `Dockerfile-proxy` has steps to add appropriate entries of upstream nodes into nginx config file. To build the docker image, edit `.env` and set the variable `RSERVE_NODE_NUM` for the number of nodes.  Then run
```
docker-compose build --no-cache proxy
```
#### rserve
These are the Rserve nodes.  Each container, besides the Rserve server, also runs the `wstunnel` to handle incoming WebSocket traffic and forward the data to Rserve QAP port.

To run multiple Rserve nodes with `docker-compose`, run it with `--compatibility` flag:
```
docker-compose --compatibility up
```
The number of nodes to run is determined by the environment variable `RSERVE_NODE_NUM` as defined in `.env`

## Known issues / TODO
- When testing this cluster with [WebWork](https://webwork.maa.org/), seems that some WebWork questions [do not close the connection explicitly](https://github.com/ubc/webwork-open-problem-library/blob/4a70698b65db0d3de862c9eda68a49c23da5e39d/OpenProblemLibrary/macros/UBC/RserveClient.pl#L135-L144).  This may cause dangling connections not cleared
- Make the load balance image to take environment variables and setup upstream servers at runtime instead of hard-coded in the image
- Make the tunneling port etc configurable at runtime via environment variables
