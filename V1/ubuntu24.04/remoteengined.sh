#!/bin/sh

dotnet /usr/lib/orin3.remoteengine/ORiN3.RemoteEngined.dll &
REMOTE_ENGINE_PID=$!

_term() {
    kill -s TERM $REMOTE_ENGINE_PID
}

trap _term INT
trap _term TERM

GET_VER_RESULT=1
while [ $GET_VER_RESULT -ne 0 ]
do
    orin3.remoteengine version > /dev/null 2>&1
    GET_VER_RESULT=$?
    sleep 1
done

set -e

setup_remoteengine.sh

if [ -z "$@" ]
then
    orin3.remoteengine start
else
    $@
fi

wait $REMOTE_ENGINE_PID

while [ $(ps aux -q $REMOTE_ENGINE_PID | wc -l) -eq 2 ]
do
    sleep 1
done

