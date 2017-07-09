#!/usr/bin/env python
import node_discovery
import json
import os

def generateReplSetConfig(replset_name, service_name, service_port):
    replset = {
        '_id': replset_name
    }
    members = []
    discovered_nodes = node_discovery.getNodesOfService(service_name, service_port)
    for id in range(0, len(discovered_nodes)):
        members.append({
            '_id': id,
            'host': discovered_nodes[id]
        })
    replset['members'] = members
    replset_doc = json.dumps(replset)
    replset_init_call = "rs.initiate({0})".format(replset_doc)
    print replset_init_call

if __name__ == "__main__":
    svc = os.environ.get('MONGO_SERVICE_ID')
    svc_port = os.environ.get('MONGO_PORT')
    replset_name = os.environ.get('MONGO_REPLSET')
    if svc is not None \
            and svc_port is not None \
            and replset_name is not None:
        generateReplSetConfig(replset_name, svc, svc_port)