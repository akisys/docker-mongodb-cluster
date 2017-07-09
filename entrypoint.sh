#!/usr/bin/env bash

function start_mongodb_node() {
    _MONGO_OPTS="--port ${MONGO_PORT:-27017} --smallfiles --oplogSize 16 --noauth"
    if [ -n "$MONGO_REPLSET" ]; then
        _MONGO_OPTS="$_MONGO_OPTS --replSet $MONGO_REPLSET"
    fi
    _MONGO_OPTS="$_MONGO_OPTS --dbpath ${MONGO_DBPATH:-/data/db}"
    if [ -n "$MONGO_SVR" ]; then
        case $MONGO_SVR in
            shardsvr|configsvr)
                _MONGO_OPTS="--$MONGO_SVR $_MONGO_OPTS"
                ;;
            *)
                echo "Invalid \$MONGO_SVR value" >&2; exit 1;
                ;;
        esac
        case $MONGO_SVR in
            shardsvr)
                _MONGO_OPTS="$_MONGO_OPTS --nojournal"
                ;;
        esac
    fi

    if [ -n "$MONGO_REPLSET" ]; then
        echo "REPLSET: $MONGO_REPLSET"
        # spawn a sub-shell to initialize mongodb replication set
        (
            sleep 5
            if [ `mongo --quiet --eval 'rs.status().ok'` == "0" ]; then
                if [ ! -f /data/replset.js ]; then
                    python /tools/mongo_replset_config.py > /data/replset.js
                    mongo < /data/replset.js
                fi
            fi
            sleep 5
            if [ `mongo --quiet --eval 'rs.status().set'` == "${MONGO_REPLSET}" ]; then
                if [ `mongo --quiet --eval 'db.runCommand("ismaster").ismaster'` == "true" ]; then
                    (
                        echo "INITIATING DYNAMIC REPLSET EXTENDER ON PRIMARY NODE"
                        python /tools/replset_extender.py
                    )&
                fi
            fi
        )&
    fi
    if [ -n "$MONGO_SHARDADD_SERVICE_ID" ] && [ -n "$MONGO_REPLSET" ]; then
        # spawn a sub-shell to add this mongodb replication set as a shard
        (
            sleep 5
            _retry_count=5
            _retry_sleep=5
            while [ $_retry_count -ne 0 ]; do
                if [ `mongo --quiet --eval 'rs.status().ok'` == "0" ]; then
                    echo "REPLSET NOT YET INITIALIZED - WAITING A LITTLE LONGER"
                    _retry_count=$(($_retry_count - 1))
                    if [ $_retry_count -eq 0 ]; then
                        echo "REACHED RETRY COUNT - BAILING OUT"
                        break
                    fi
                    sleep $_retry_sleep
                    continue
                fi
                echo "CHECKING IF I AM A PRIMARY REPLSET NODE"
                if [ `mongo --quiet --eval 'db.runCommand("ismaster").ismaster'` == "true" ]; then
                    # run a remote query to the SHARD cluster frontend mongos
                    _replset_nodes="$(python /tools/node_discovery.py)"
                    _mongos_node="$(MONGO_SERVICE_ID="${MONGO_SHARDADD_SERVICE_ID}" python /tools/node_discovery.py | cut -d, -f1)"
                    if [ -z "$_mongos_node" ]; then
                        _retry_count=$(($_retry_count - 1))
                        if [ $_retry_count -eq 0 ]; then
                            echo "REACHED RETRY COUNT - BAILING OUT"
                            break
                        fi
                        sleep $_retry_sleep
                        continue
                    fi
                    echo "REPLSET NODES: $_replset_nodes"
                    echo "MONGOS_NODES: $_mongos_node"
                    if [ `mongo --host $_mongos_node --eval 'db.getSiblingDB("admin").runCommand("listShards")' | grep -c "$MONGO_REPLSET"` -eq 0 ]; then
                        mongo --host $_mongos_node --eval "sh.addShard('${MONGO_REPLSET}/${_replset_nodes}')" && \
                        echo "ADDED THIS REPLSET:${MONGO_REPLSET} TO MONGOS-NODE: ${_mongos_node}"
                    else
                        echo "SHARD-ENTRY FOR:${MONGO_REPLSET} EXISTS - TERMINATING AUTO-ADD-SHARD-LOOP"
                        break
                    fi
                else
                    echo "I AM NOT A PRIMARY (YET?) - CONTINUING AUTO-ADD-SHARD-LOOP"
                    _retry_count=$(($_retry_count - 1))
                    if [ $_retry_count -eq 0 ]; then
                        echo "REACHED RETRY COUNT - BAILING OUT"
                        break
                    fi
                    sleep $_retry_sleep
                    continue
                fi
            done
        )&
    fi

    su mongodb -c "mongod $_MONGO_OPTS"
}

function start_mongos_frontend() {
    while true; do
        _MONGO_SERVICE_NODES="$(python /tools/node_discovery.py)"
        if [ -n "${_MONGO_SERVICE_NODES}" ]; then
            _MONGOS_OPTS="--configdb ${MONGO_REPLSET}/${_MONGO_SERVICE_NODES} --port ${MONGO_PORT}"
            break
        fi
    done
    su mongodb -c "mongos $_MONGOS_OPTS"
}

_STARTUP_MODE="${MONGO_STARTUP:-"mongodb"}"

case "$_STARTUP_MODE" in
    mongodb)
        start_mongodb_node
        ;;
    mongos)
        start_mongos_frontend
        ;;
    *)
        echo "\$MONGO_STARTUP=$_STARTUP_MODE not allowed" >&2
        exit 1
        ;;
esac

echo "Reaching end of service"
