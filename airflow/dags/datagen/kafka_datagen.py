import requests
from utils.utils import Utils

class TriggerKafkaDataGen(object):
    def __init__(self) -> None:
        pass
    
    def trigger_execution(self, url: str, resource_file: str)-> bool:
        if not url or not resource_file:
            raise Exception("missing parameters for triggering producer")

        json_body = Utils.load_json_resource_file(resource_file)
        resp = requests.post(url, json=json_body,headers={"Content-Type": "application/json"})
        return resp.ok