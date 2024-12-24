#!/bin/sh
set -e

CONFIG_DIR=/config
CONFIG_FILE=$CONFIG_DIR/remoteengine.yml

escape_str () {
    sed 's/"/\\"/g' | sed 's/\$/\\\$/g'
}

if [ ! -f $CONFIG_FILE ]
then
    exit 0
fi

ROOT=$(yq ".remote-engine" $CONFIG_FILE)

if [ -z "$ROOT" ]
then
    echo "no remote-engine element"
    exit 1
fi

# password
PASSWORD=$(yq ".remote-engine.password // \"\"" $CONFIG_FILE)
if [ -z "$PASSWORD" ]
then
    PASSWORD=$REMOTEENGINE_PASSWORD
fi
if [ ! -z "$PASSWORD" ]
then
    orin3.remoteengine changepassword -n "$PASSWORD"
fi

# endpoints
ENDPOINT_COUNT=$(yq ".remote-engine.endpoints | length" $CONFIG_FILE)
i=0
while [ $i -lt $ENDPOINT_COUNT ]
do
    ep_ip=$(yq ".remote-engine.endpoints[$i].ip" $CONFIG_FILE)
    ep_port=$(yq ".remote-engine.endpoints[$i].port" $CONFIG_FILE)
    ep_pfx=$(yq ".remote-engine.endpoints[$i].pfx // \"\"" $CONFIG_FILE)
    ep_password=$(yq ".remote-engine.endpoints[$i].password // \"\"" $CONFIG_FILE)
    ep_client_auth=$(yq ".remote-engine.endpoints[$i].cleint-auth // \"\"" $CONFIG_FILE)

    command="orin3.remoteengine ep add $ep_ip --port $ep_port"
    if [ ! -z "$ep_pfx" ]
    then
        escaped_pfx=$(echo $ep_pfx | escape_str)
        escaped_password=$(echo $ep_password | escape_str)
        case $escaped_pfx in
            "/"*) pfx_path="$excaped_pfs";;
             *) pfx_path="$CONFIG_DIR/$escaped_pfx";;
        esac
        command="$command --pfx \"$pfx_path\" --password \"$escaped_password\""
        if [ "$ep_client_auth" = "true" ] || [ "$ep_client_auth" = "yes" ]
        then
            command="$command --client-auth"
        fi
    fi
    eval $command
    i=$(($i+1))
done

# opentelemetry
OPENTELEMETRY_COUNT=$(yq ".remote-engine.opentelemerties | length" $CONFIG_FILE)
i=0
while [ $i -lt $OPENTELEMETRY_COUNT ]
do
    ot_url=$(yq ".remote-engine.opentelemerties[$i].url" $CONFIG_FILE)
    ot_metric=$(yq ".remote-engine.opentelemerties[$i].metric" $CONFIG_FILE)
    ot_log=$(yq ".remote-engine.opentelemerties[$i].log" $CONFIG_FILE)
    ot_trace=$(yq ".remote-engine.opentelemerties[$i].trace" $CONFIG_FILE)
    ot_proxy=$(yq ".remote-engine.opentelemerties[$i].proxy // \"\"" $CONFIG_FILE)
    ot_protocol=$(yq ".remote-engine.opentelemerties[$i].protocol // \"\"" $CONFIG_FILE)

    command="orin3.remoteengine ot add $ot_url"
    if [ "$ot_metric" = "true" ] || [ "$ot_metric" = "yes" ]
    then
        command="$command -m"
    fi
    if [ "$ot_log" = "true" ] || [ "$ot_log" = "yes" ]
    then
        command="$command -l"
    fi
    if [ "$ot_trace" = "true" ] || [ "$ot_trace" = "yes" ]
    then
        command="$command -t"
    fi
    if [ ! -z "$ot_proxy" ]
    then
        case $ot_proxy in
	    "system") command="$command --use-system-proxy";;
	    "none") command="$command --no-proxy";;
	    *) command="$command --proxy \"$ot_proxy\"";;
        esac
    fi
    if [ ! -z "$ot_protocol" ]
    then
        command="$command --protocol $ot_protocol"
    fi
    eval $command
    i=$(($i+1))
done

# loglevel
LOGLEVEL=$(yq ".remote-engine.loglevel // \"\"" $CONFIG_FILE)
if [ ! -z "$LOGLEVEL" ]
then
    orin3.remoteengine ot setloglevel $LOGLEVEL
fi

# provider(install)
PROV_INSTALL_COUNT=$(yq ".remote-engine.provider.install-paths | length" $CONFIG_FILE)
i=0
while [ $i -lt $PROV_INSTALL_COUNT ]
do
    prov_install_file=$(yq ".remote-engine.provider.install-paths[$i]" $CONFIG_FILE)
    case $prov_install_file in
        "/"*) orin3.remoteengine prov install "$prov_install_file";;
       	*) orin3.remoteengine prov install "$CONFIG_DIR/$prov_install_file";;
    esac

    i=$(($i+1))
done

# provider(attach)
PROV_ATTACH_COUNT=$(yq ".remote-engine.provider.attach-paths | length" $CONFIG_FILE)
i=0
while [ $i -lt $PROV_ATTACH_COUNT ]
do
    prov_attach_path=$(yq ".remote-engine.provider.attach-paths[$i]" $CONFIG_FILE)
    case $prov_attach_path in
       "/"*) orin3.remoteengine prov attach "$prov_attach_path";;
       *) orin3.remoteengine prov attach "$CONFIG_DIR/$prov_attach_path";;
    esac

    i=$(($i+1))
done

# provider(pfx)
PROV_PFX_COUNT=$(yq ".remote-engine.provider.pfxes | length" $CONFIG_FILE)
i=0
while [ $i -lt $PROV_PFX_COUNT ]
do
    prov_pfx_file=$(yq ".remote-engine.provider.pfxes[$i].file" $CONFIG_FILE)
    prov_pfx_ip=$(yq ".remote-engine.provider.pfxes[$i].ip" $CONFIG_FILE)
    prov_pfx_password=$(yq ".remote-engine.provider.pfxes[$i].password // \"\"" $CONFIG_FILE)
    escaped_pfx=$(echo $prov_pfx_file | escape_str)
    command="orin3.remoteengine prov addpfx $prov_pfx_ip --pfx \"$CONFIG_DIR/$escaped_pfx\""
    if [ ! -z "$prov_pfx_password" ]
    then
        escaped_password=$(echo $prov_pfx_password | escape_str)
        command="$command --password \"$escaped_password\""
    fi
    eval $command
    i=$(($i+1))
done

# manual endpoints
ENDPOINT_COUNT=$(yq ".remote-engine.manual-endpoints | length" $CONFIG_FILE)
i=0
while [ $i -lt $ENDPOINT_COUNT ]
do
    manep_ip=$(yq ".remote-engine.manual-endpoints[$i].ip" $CONFIG_FILE)
    manep_port=$(yq ".remote-engine.manual-endpoints[$i].port" $CONFIG_FILE)
    manep_pfx=$(yq ".remote-engine.manual-endpoints[$i].pfx // \"\"" $CONFIG_FILE)
    manep_password=$(yq ".remote-engine.manual-endpoints[$i].password // \"\"" $CONFIG_FILE)

    command="orin3.remoteengine manep add $manep_ip --port $manep_port"
    if [ ! -z "$manep_pfx" ]
    then
        escaped_pfx=$(echo $manep_pfx | escape_str)
        escaped_password=$(echo $manep_password | escape_str)
	case $escaped_pfx in
            "/"*) pfx_path="$escaped_pfx";;
            *) pfx_path="$CONFIG_DIR/$escaped_pfx";;
        esac
        command="$command --pfx \"$pfx_path\" --password \"$escaped_password\""
        if [ "$manep_client_auth" = "true" ] || [ "$manep_client_auth" = "yes" ]
        then
            command="$command --client-auth"
        fi
    fi
    eval $command
    i=$(($i+1))
done

# authorities
AUTHORITY_COUNT=$(yq ".remote-engine.authorities | length" $CONFIG_FILE)
if [ $AUTHORITY_COUNT -gt 0 ]
then
    lines=$(expr $(orin3.remoteengine auth ls --password $PASSWORD | sed '/^\s*$/d' | wc -l) - 1)
    i=0
    while [ $i -lt $lines ]
    do
        orin3.remoteengine auth delete --password $PASSWORD --index 0 -y
        i=$(($i+1))
    done
    i=0
    while [ $i -lt $AUTHORITY_COUNT ]
    do
        auth_name=$(yq ".remote-engine.authorities[$i].name" $CONFIG_FILE)
        auth_effect=$(yq ".remote-engine.authorities[$i].effect" $CONFIG_FILE)
        auth_condition=$(yq ".remote-engine.authorities[$i].condition // \"\"" $CONFIG_FILE)
        auth_target=$(yq ".remote-engine.authorities[$i].target // \"\"" $CONFIG_FILE)

        escaped_password=$(echo $PASSWORD | escape_str)
        command="orin3.remoteengine auth add --password \"$escaped_password\" --name $auth_name --effect $auth_effect"
        if [ ! -z "$auth_condition" ]
        then
            command="$command --condition \"$auth_condition\""
        fi
        if [ ! -z "$auth_target" ]
        then
            command="$command --target \"$auth_target\""
        fi
        eval $command
        i=$(($i+1))
    done
fi

# licenses
LICENSE_COUNT=$(yq ".remote-engine.licenses | length" $CONFIG_FILE)
i=0
while [ $i -lt $LICENSE_COUNT ]
do
    lic_key=$(yq ".remote-engine.authorities[$i].key" $CONFIG_FILE)

    orin3.remoteengine lic activate $lic_key
    i=$(($i+1))
done
