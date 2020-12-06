import json
from typing import Any

class Utils(object):

    @staticmethod
    def load_json_resource_file(path: str) -> Any:
        retval = ""
        with open(path, "r") as f:
            retVal = json.load(f)
        return retVal

    @staticmethod
    def load_plain_resource_file(path: str) -> str:
        retval = ""
        with open(path, "r") as f:
            retval = "\n".join(f.readlines())
        return retval
            
