import random
from time import sleep
from azure.iot.device import IoTHubDeviceClient

conn_str_file = open("/var/tmp/DeviceConnectionString.txt", "r")
conn_str = conn_str_file.read()
conn_str_file.close()

temp_target = random.randint(101, 200)

# define behavior for receiving a twin patch
def twin_patch_handler(patch):
    global temp_target
    if 'tempTarget' in patch:
        temp_target = patch['tempTarget']

device_client = IoTHubDeviceClient.create_from_connection_string(conn_str)
device_client.on_twin_desired_properties_patch_received = twin_patch_handler
device_client.connect()

# Wait for user to indicate they are done listening for messages
while True:
    # send new reported properties
    reported_properties = {
        "tempLatest": random.randint(temp_target - 2, temp_target + 2),
        "tempTarget": temp_target
        }
    device_client.patch_twin_reported_properties(reported_properties)
    sleep(5)


# finally, shut down the client
device_client.shutdown()