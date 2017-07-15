### Project description

#### Automated MongoDB ReplicaSet setup
  - service nodes started with the same ReplicaSet name
  - automatic ReplicaSet setup
  - additional background tasks scan for new 
    or existing RelicaSet nodes and join the PRIMARY node
  - allows dynamic scaling of as many nodes as required

#### Automated MongoDB Sharded Cluster setup
  - service stack with 3 parts
  1. MongoDB ConfigNodes with dedicated ReplicaSet for configuration data collection
  2. Mongos ShardProxy with automatic attachement to ConfigNode service
  3. MongoDB ShardNodes with dedicated ReplicaSets for data collection with multiple shards and automatic attachment to Mongos service

### Examples

Service profile examples are available in

* [Simple MongoDB Service with ReplicaSet](mongo-service/docker-compose.yml)
* [Sharded MongoDB Service](mongo-service-sharded/docker-compose.yml)
