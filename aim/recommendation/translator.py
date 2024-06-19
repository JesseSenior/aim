import hashlib
import random
import json
from time import sleep
from urllib.parse import quote
from http.client import HTTPSConnection


class Translator:
    HOST = "api.fanyi.baidu.com"
    REQUEST_PATH = "/api/trans/vip/translate"

    def __init__(self, appid: str, secretKey: str, from_lang: str = "auto", to_lang: str = "zh"):
        self.appid = appid
        self.secretKey = secretKey
        self.httpClient = HTTPSConnection(self.HOST)
        self.to_lang = to_lang
        self.from_lang = from_lang
        self.salt = random.randint(32768, 65536)

    def build_request_url(self, q: str) -> str:
        sign = self.appid + q + str(self.salt) + self.secretKey
        sign = hashlib.md5(sign.encode()).hexdigest()
        return (
            f"{self.REQUEST_PATH}?appid={self.appid}&q={quote(q)}&from={self.from_lang}"
            + f"&to={self.to_lang}&salt={self.salt}&sign={sign}"
        )

    def translate(self, q: str, delay: float = 0.0):
        request_url = self.build_request_url(q)
        try:
            self.httpClient.request("GET", request_url)
            response = self.httpClient.getresponse()
            result_all = response.read().decode("utf-8")
            result = json.loads(result_all)
            if "error_code" in result:
                raise Exception(f"{result['error_code']} Error: {result['error_msg']}")
            result: list[str] = [line["dst"] for line in result["trans_result"]]
            result = "\n".join(result)
        except Exception as e:
            print(e)
            if delay > 0:
                sleep(delay)
            result = None
        if delay > 0:
            sleep(delay)
        return result

    def close(self):
        self.httpClient.close()

    def __del__(self):
        self.close()
