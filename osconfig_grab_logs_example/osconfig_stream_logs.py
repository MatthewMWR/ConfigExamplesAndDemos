###
### This is a super naive example of ongoing streaming of the osconfig logs from
### device to Azure Monitor. Runs as an endless loop. Use Ctrl+C or similar 
### to stop if running interactively.
###
### In this example we are using the Azure Monitor Data Collection 
### REST API (rather than an existing agent like AMA) as agents might not be 
### available or appropriate for all devices.
###
### Someone could potentially build on this naive example to accomplish such 
### log streaming inside some larger more mature solution
###
### Adapted from Azure Monitor data ingestion example at
### https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api
###
### Usage: 
### sudo python3 osconfig_stream_logs.py "<your Azure Log Analytics workspace ID>" "<your data ingestion shared key>"
###
### Needs to run prvileged to access osconfig log files. 
###
### Tested on Ubuntu 20.04 with in-box Python 3.8 environment and pygtail 
### module installed. Pygtail claims to handle log rollover scenarios, but
### I have not stress tested that.
### 

import glob
import json
import os
from re import findall
from time import sleep
import requests
import datetime
import hashlib
import hmac
import base64
from pygtail import Pygtail
import sys
import platform

# Log Analytics workspace ID and ingestion key
customer_id = sys.argv[1]
shared_key = sys.argv[2]

# The name of the table in Log Analytics, will be created automatically 
# on first upload if not already existing. The finaly table name in
# Log Analytics will have "_CL" (means "custom log") appended by
# Azure Monitor service.
azure_monitor_log_table_name = 'OSConfigLogsExample'

# Build the API signature
def build_signature(customer_id, shared_key, date, content_length, method, content_type, resource):
    x_headers = 'x-ms-date:' + date
    string_to_hash = method + "\n" + str(content_length) + "\n" + content_type + "\n" + x_headers + "\n" + resource
    bytes_to_hash = bytes(string_to_hash, encoding="utf-8")  
    decoded_key = base64.b64decode(shared_key)
    encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()).decode()
    authorization = "SharedKey {}:{}".format(customer_id,encoded_hash)
    return authorization

# Build and send a request to the POST API
def post_data(customer_id, shared_key, body, azure_monitor_log_table_name):
    method = 'POST'
    content_type = 'application/json'
    resource = '/api/logs'
    rfc1123date = datetime.datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
    content_length = len(body)
    signature = build_signature(customer_id, shared_key, rfc1123date, content_length, method, content_type, resource)
    uri = 'https://' + customer_id + '.ods.opinsights.azure.com' + resource + '?api-version=2016-04-01'

    headers = {
        'content-type': content_type,
        'Authorization': signature,
        'Log-Type': azure_monitor_log_table_name,
        'x-ms-date': rfc1123date
    }

    response = requests.post(uri,data=body, headers=headers)
    if (response.status_code >= 200 and response.status_code <= 299):
        print('Accepted')
    else:
        print("Response code: {}".format(response.status_code))

# Parses the raw log line and returns a dictionary meant to be uploaded as a record
def construct_record(line, log_name, hostname):
    found = findall('^\[([^\]]*)\]\s\[([^\]]*)\]\s(.*)', line)
    if len(found) == 0 or len(found[0]) != 3:
        print(f'Could not parse: {line}')
        return {
            "log_line_raw": line,
            "Computer": hostname,
            "log_name": log_name
        }
    else:
        return {
            "log_line_raw": line,
            "TimeGenerated": found[0][0],
            "component_label": found[0][1],
            "message": found[0][2],
            "Computer": hostname,
            "log_name": log_name
        }

# The primary action for each pass. Detects if there are any new log lines since
# last check, and parses / uploads them.
def detect_and_send_new_records(log_path, hostname, azure_monitor_log_table_name):
    records = []
    path_leaf = os.path.basename(log_path)
    for line in Pygtail(log_path, full_lines=True):
        records.append(construct_record(line, path_leaf, hostname))
    print(f'{len(records)} records to send from {log_path}')
    if len(records) > 0:
        post_data(customer_id, shared_key, json.dumps(records), azure_monitor_log_table_name)

hostname = platform.node()

logs_in_scope = glob.glob("/var/log/osconfig_*.log")

for file_path in logs_in_scope:
# When the script is invoked, I don't want pygtail to remember where it left 
# off. I want the full files on the first pass of the main loop, followed by 
# deltas on subsequent passes through the main loop. I don't mind that this can result 
# in some redundant log entries uploaded when the script is stopped and started.
    pygtail_offset_path = f'{file_path}.offset'
    if os.path.exists(pygtail_offset_path):
        os.remove(f'{file_path}.offset')

# run until externally interrupted
while True:
    for file_path in logs_in_scope:
        detect_and_send_new_records(file_path, hostname, azure_monitor_log_table_name)
    sleep(5)
