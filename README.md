# ElRedis

ElRedis is a distributed and parallel in-memory key value store built with [Elixir][elixir]. ElRedis uses the Redis Serialization Protocol for communications over TCP to ensure compatibility with existing Redis client libraries. 

## Installation

To compile and run this project [install elixir][install-elixir] and then:
```bash
git clone git@github.com:SidakM/ElRedis.git
cd ElRedis
mix run --no-halt
```
Note that the above runs only a single ElRedis node. 

To run multiple ElRedis nodes in a cluster edit [hosts.exs][host-config]. By default the cluster is configured to run with two nodes and each can be started with:
```
cd ElRedis
elixir --name host1@127.0.0.1 --cookie cookie -S mix run --no-halt
```
and in another terminal on the same network or computer
```
cd ElRedis
elixir --name host2@127.0.0.1 --cookie cookie -S mix run --no-halt
```
Here `host1@127.0.0.1` is the unique identifier of the first node and `cookie` is the shared secret each node utilizes for authentication to join the cluster.

## Overview and Design

I built this project as I was learning Elixir and wanted to create a distributed application. This project was inspired by [CurioDb] a similar but more developed project which uses Scala and Akka.

Every key/value pair in the cluster is an actor. Thus,the state of any key/value pair is stored in its actor and manipulated when it receives a message from another process. These key/value actors are distributed (sharded) across multiple ElRedis Nodes so that they can be manipulated concurrently.


##### LifeCycle of a Connection

- A client connects to the tcp_server actor ([tcp_server.ex][tcp-server]). There must be atleast one node in the cluster which runs this actor (By default all nodes run a tcp_server)
- The tcp_server creates a handler actor([handler.ex][connection-handler]) for the client connection. The handler manages the client connection while also decoding incoming messages and encoding outgoing messages with the Redis Serialization Protocol.
- When a client sends a valid command the handler forwards the command to the appropriate node_manager ([node_manager.ex][node-manager]). There is a node-manager running on every ElRedis Node and is responsible for managing a portion of the entire cluster's keyspace. 
- The node-manager CRUDs keys by messaging the individual key/value actor.
- The Key/Value actor ([key_value.ex][key-value]) manipulates its own state andresponds to the node-manager. This response propagates to the connection handler and is encoded before being sent to the client

Note: Keys are allocated to ElRedis Nodes using consistent hashing. The ring_manager actor([ring_manager.ex][ring-manager]) runs on each ElRedis Node and decides the ElRedis Node on which the key should be allocated. The ring_manager uses [libring][libring] to form the hash ring for key distribution across ElRedis Nodes.

## Usage and Testing

_Note: This project is very alpha so use with much needed caution._

Clients can connect to the tcp_server and send commands encoded in the Redis Serialization Protocol. The tcp_server can be configured in [tcp_server.exs][server-config]. The list of currently supported Redis commands can be found in [command.ex][commands]. A command is queued to a ElRedis Node based on the key associated with the command and the chosen Node's position on the hash_ring. Since ElRedis Nodes process commands in parallel, introducing more nodes(across different machines) allows for keys (which are sharded across different ElRedis Nodes) to be manipulated simultaneously. 

##### Testing
To run the project tests:
```bash
cd ElRedis
mix test
```

## Next Steps
- [ ] supporting additional Redis datatypes
- [ ] data persistence
- [ ] automatic cluster resizing
- [ ] benchmarking 





[tcp-server]: https://github.com/SidakM/ElRedis/blob/master/lib/server/tcp_server.ex
[connection-handler]: https://github.com/SidakM/ElRedis/blob/master/lib/server/handler.ex
[node-manager]: https://github.com/SidakM/ElRedis/blob/master/lib/node_manager/node_manager.ex
[key-value]: https://github.com/SidakM/ElRedis/blob/master/lib/keyspace/key_value.ex
[ring-manager]: https://github.com/SidakM/ElRedis/blob/master/lib/node_manager/ring_manager.ex
[libring]: https://github.com/bitwalker/libring
[install-elixir]: https://elixir-lang.org/install.html
[server-config]: https://github.com/SidakM/ElRedis/blob/master/config/tcp_server.exs
[commands]: https://github.com/SidakM/ElRedis/blob/master/lib/server/command.ex
[elixir]: https://elixir-lang.org/
[host-config]: https://github.com/SidakM/ElRedis/blob/master/config/hosts.exs
[curiodb]: https://github.com/stephenmcd/curiodb