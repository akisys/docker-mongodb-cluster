#!/usr/bin/env python

import time
import json
import subprocess
import os
import node_discovery


def getMongoNodes():
    exec_output = subprocess.check_output([
        'mongo',
        '--quiet',
        '--eval',
        'db.runCommand("ismaster").hosts'
    ], shell=False)
    exec_output = exec_output.translate(None, '\n\t')
    return json.loads(exec_output)


def addMongoNodes(nodes):
    for node in nodes:
        print("Adding node [{0}]".format(node))
        subprocess.call([
            'mongo',
            '--eval',
            "rs.add('{0}')".format(node)
        ])


if __name__ == "__main__":
    svc = os.environ.get('MONGO_SERVICE_ID')
    svc_port = os.environ.get('MONGO_PORT')
    if svc is not None and svc_port is not None:
        while True:
            replset_nodes = set(getMongoNodes())
            service_nodes = set(node_discovery.getNodesOfService(svc, svc_port))
            new_nodes = list(service_nodes.difference(replset_nodes))
            addMongoNodes(new_nodes)
            time.sleep(2)
