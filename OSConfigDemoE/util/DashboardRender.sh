DEMO_NAME=$1
VIEW=$2

STYLE_STRONG="\033[1;92m"
STYLE_STRONG2="\033[1;97m"
STYLE_RESET="\033[0m"
STYLE_WEAK="\033[90m"

TABLE_COLUMNVALUEMAXLENGTH=24

CONFIGURATIONS_ALL=$(az iot hub configuration list -n $DEMO_NAME)

case "$VIEW" in
    1) 
        VIEW_DISPLAY_NAME="Temperature management"
        IOT_HUB_SELECT="deviceId, connectionState, properties.reported.tempLatest, properties.reported.tempTarget, properties.desired.tempTarget AS tempTarget_Desired"
        IOT_HUB_QUERY="select ${IOT_HUB_SELECT} from devices where properties.reported.tempLatest!=null"
        AZ_CLI_JMSE_QUERY="[]"
        JQ_PROGRAM="[.[] | {deviceId, connectionState, tempTarget_Desired, tempTarget, tempLatest}]"
        JQ_PROGRAM_FORMAT="."
        CONFIGURATION_NAMES=("temp_mgmt" "__ignore_temp_mgmt_noop")
    ;;
    2)
        VIEW_DISPLAY_NAME="Observe device network config" 
        IOT_HUB_SELECT="deviceId, tags.country, properties.reported.Networking.NetworkConfiguration.DnsServers"
        IOT_HUB_QUERY="select ${IOT_HUB_SELECT} from devices.modules where moduleId='osconfig'"
        AZ_CLI_JMSE_QUERY="[]"
        JQ_PROGRAM='[.[] | {deviceId, country, DnsServers:"eth0=10.86.249.1"}]'
        JQ_PROGRAM_FORMAT='.'
        CONFIGURATION_NAMES=("__ignore_osconfig_noop" "osconfig_everyone" "osconfig_sensitive")
    ;;
    3)
        VIEW_DISPLAY_NAME="Manage participation Azure Device Health Service (ADHS)" 
        IOT_HUB_SELECT_ITEMS=(
            "deviceId"
            "tags.country"
            "properties.reported.Networking.NetworkConfiguration.DnsServers"
            "properties.desired.Settings.DeviceHealthTelemetryConfiguration AS ADHSLevel_Desired"
            "properties.reported.Settings.DeviceHealthTelemetryConfiguration.value AS ADHSLevel"
        )
        IOT_HUB_SELECT=$(awk -v sep=, 'BEGIN{ORS=OFS="";for(i=1;i<ARGC;i++){print ARGV[i],ARGC-i-1?sep:""}}' "${IOT_HUB_SELECT_ITEMS[@]}")
        IOT_HUB_QUERY="select ${IOT_HUB_SELECT} from devices.modules where moduleId='osconfig'"
        AZ_CLI_JMSE_QUERY="[]"
        JQ_PROGRAM='[.[] | {deviceId, country, DnsServers:"eth0=10.86.249.1", ADHSLevel_Desired, ADHSLevel }]'
        JQ_PROGRAM_FORMAT='[.[] | if .ADHSLevel == 0 then .ADHSLevel |="0 (off)" elif .ADHSLevel == 2 then .ADHSLevel |= "2 (full)" else . end | if .ADHSLevel_Desired == 0 then .ADHSLevel_Desired |="0 (off)" elif .ADHSLevel_Desired == 2 then .ADHSLevel_Desired |= "2 (full)" else . end]'
        CONFIGURATION_NAMES=("__ignore_osconfig_noop" "osconfig_everyone" "osconfig_sensitive")
    ;;
    4)
        VIEW_DISPLAY_NAME="Custom config and reporting (time zone example)" 
        IOT_HUB_SELECT_ITEMS=(
            "deviceId"
            "tags.country"
            "properties.reported.Networking.NetworkConfiguration.DnsServers"
            "properties.desired.Settings.DeviceHealthTelemetryConfiguration AS ADHSLevel_Desired"
            "properties.reported.Settings.DeviceHealthTelemetryConfiguration.value AS ADHSLevel"
            "properties.reported.CommandRunner.CommandStatus.TextResult"
            "properties.desired.CommandRunner.CommandArguments.CommandId"
        )
        IOT_HUB_SELECT=$(awk -v sep=, 'BEGIN{ORS=OFS="";for(i=1;i<ARGC;i++){print ARGV[i],ARGC-i-1?sep:""}}' "${IOT_HUB_SELECT_ITEMS[@]}")
        IOT_HUB_QUERY="select ${IOT_HUB_SELECT} from devices.modules where moduleId='osconfig'"
        AZ_CLI_JMSE_QUERY="[]"
        JQ_PROGRAM='[.[] | {deviceId, country, DnsServers:"eth0=10.86.249.1", ADHSLevel_Desired, ADHSLevel, Custom_Desired: .CommandId, Custom_Reported: .TextResult}]'
        JQ_PROGRAM_FORMAT='[.[] | if .ADHSLevel == 0 then .ADHSLevel |="0 (off)" elif .ADHSLevel == 2 then .ADHSLevel |= "2 (full)" else . end | if .ADHSLevel_Desired == 0 then .ADHSLevel_Desired |="0 (off)" elif .ADHSLevel_Desired == 2 then .ADHSLevel_Desired |= "2 (full)" else . end]'
        CONFIGURATION_NAMES=("__ignore_osconfig_noop" "osconfig_everyone" "osconfig_sensitive")
    ;;
    5)
        VIEW_DISPLAY_NAME="My config and compliance view" 
        IOT_HUB_SELECT_ITEMS=(
            "deviceId"
            "connectionState"
            "properties.reported.Firewall.FirewallState"
            "properties.reported.Networking.NetworkConfiguration.DnsServers"
            "properties.reported.Settings.DeviceHealthTelemetryConfiguration.value AS ADHSLevel"
            "properties.reported.CommandRunner.CommandStatus.TextResult"
            "properties.desired.CommandRunner.CommandArguments.CommandId"
        )
        IOT_HUB_SELECT=$(awk -v sep=, 'BEGIN{ORS=OFS="";for(i=1;i<ARGC;i++){print ARGV[i],ARGC-i-1?sep:""}}' "${IOT_HUB_SELECT_ITEMS[@]}")
        IOT_HUB_QUERY="select ${IOT_HUB_SELECT} from devices.modules where moduleId='osconfig'"
        AZ_CLI_JMSE_QUERY="[]"
        JQ_PROGRAM='[.[] | {deviceId, connectionState, FirewallState, ADHSLevel, DnsServers, Custom: .TextResult}]'
        JQ_PROGRAM_FORMAT='[.[] | if .ADHSLevel == 0 then .ADHSLevel |="0 (off)" elif .ADHSLevel == 2 then .ADHSLevel |= "2 (full)" else . end | if .FirewallState == 0 then .FirewallState |="0 (unknown)" elif .FirewallState == 1 then .FirewallState |= "1 (enabled)" else .FirewallState |= "" end ]'
        CONFIGURATION_NAMES=("my_config_profile")
    ;;
    *)
        echo "VIEW is required"
   ;;
esac

TITLE_BAR="
$STYLE_WEAK╔═════════════════════════════════════════════════════════════$STYLE_RESET
$STYLE_STRONG   Contoso Manufacturing$STYLE_RESET 
   $VIEW_DISPLAY_NAME $STYLE_RESET
$STYLE_WEAK   $(date) $STYLE_RESET"

echo -e "$TITLE_BAR"

for CONFIG_NAME in ${CONFIGURATION_NAMES[@]}
do
    CONFIG_JSON=$(echo "$CONFIGURATIONS_ALL" | jq -r ".[] | select(.id == \"$CONFIG_NAME\")")
    if [ -z "$CONFIG_JSON" ]
    then
        continue
    fi
    CONFIG_DISPLAY_NAME=$(echo "$CONFIGURATIONS_ALL" | jq -r ".[] | select(.id == \"$CONFIG_NAME\").labels.displayName")
    IOT_HUB_QUERY_SCOPED="$IOT_HUB_QUERY and configurations.[[$CONFIG_NAME]].status = 'Applied'"
    CONFIG_HAS_COMPLIANCE_METRIC=$(echo "$CONFIGURATIONS_ALL" | jq "map(select(.id==\"$CONFIG_NAME\")) | .[] | .metrics.queries | has(\"compliant\")")
    CONFIG_METRIC_APPLIEDCOUNT=$(
        az iot hub configuration show-metric --metric-type "system" --metric-id appliedCount -c $CONFIG_NAME --hub-name Contoso99  | jq '.result | length'
    )
    CONFIG_METRIC_COMPLIANTCOUNT=$(
        if [ "$CONFIG_HAS_COMPLIANCE_METRIC" == "true" ]
        then
            az iot hub configuration show-metric --metric-id compliant -c $CONFIG_NAME --hub-name Contoso99 | jq '.result | length'
        else
            echo "-1"
        fi
    )

    if [ -z $CONFIG_METRIC_APPLIEDCOUNT ] || [ $CONFIG_METRIC_APPLIEDCOUNT -eq 0 ] || [ $CONFIG_METRIC_APPLIEDCOUNT == "null" ]
    then
        continue
    fi

    if [ $CONFIG_METRIC_COMPLIANTCOUNT -eq $CONFIG_METRIC_APPLIEDCOUNT ]
    then
        COMPIANCE_SUMMARY_CHAR='✅'
    else
        COMPIANCE_SUMMARY_CHAR='❌'
    fi

    DEVICES_TABLE_JSON=$(
        az iot hub query -n $DEMO_NAME -q "$IOT_HUB_QUERY_SCOPED" --query "$AZ_CLI_JMSE_QUERY" \
        | jq "$JQ_PROGRAM")

    DEVICES_TABLE_FORMATTED=$(
        echo "$DEVICES_TABLE_JSON" \
        | jq "$JQ_PROGRAM_FORMAT" \
        | util/Json2Table.sh $TABLE_COLUMNVALUEMAXLENGTH
    )

    SCOPE_AND_COMPLIANCE_SUMMARY=$(
        if [ $CONFIG_METRIC_COMPLIANTCOUNT -lt 0 ]
        then 
            echo "($CONFIG_METRIC_APPLIEDCOUNT)"
        else
            echo "($COMPIANCE_SUMMARY_CHAR  $CONFIG_METRIC_COMPLIANTCOUNT of $CONFIG_METRIC_APPLIEDCOUNT are compliant)"
        fi
    )

    SECTION_BAR="
$STYLE_WEAK  ╔═══════════════════════════════════════════════════════════$STYLE_RESET
$STYLE_STRONG    $CONFIG_DISPLAY_NAME$STYLE_RESET $SCOPE_AND_COMPLIANCE_SUMMARY
"
    echo -e "$SECTION_BAR"
    echo "$DEVICES_TABLE_FORMATTED" | awk '{ print "    " $0 }'
    set -
done