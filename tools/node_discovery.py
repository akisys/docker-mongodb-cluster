#!/usr/bin/env python
import os
import DNS

def getNodesOfService(svc, port):
    # get A-records for current service
    q = DNS.dnslookup(svc, 'A')
    service_nodes = [ "{0}:{1}".format(item, port) for item in q ]
    return service_nodes

if __name__ == "__main__":
    svc = os.environ.get('MONGO_SERVICE_ID')
    svc_port = os.environ.get('MONGO_PORT')
    if svc is not None and svc_port is not None:
        q = getNodesOfService(svc, svc_port)
        print ",".join(q)
