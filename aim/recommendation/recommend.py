import time
import re

import torch
import torch.nn.functional as F
import fashion_clip.fashion_clip
import pandas as pd
from fashion_clip.fashion_clip import FashionCLIP
from aim.recommendation.translator import Translator

fashion_clip.fashion_clip._MODELS["fashion-clip"] = "weights/fashion-clip"

clip_model = None
goods_image_embeddings = None
goods_text_embeddings = None
data = None


def load():
    global clip_model, goods_image_embeddings, goods_text_embeddings, data

    with torch.inference_mode():
        clip_model = clip_model if clip_model is not None else FashionCLIP("fashion-clip")

    if goods_image_embeddings is None or goods_text_embeddings is None:
        goods_image_embeddings, goods_text_embeddings = torch.load("goods_embeddings.pt")

    if data is None:
        data = pd.read_excel("data/recommend_data/image_index.xlsx")


def query_id(input_embedding: torch.Tensor, goods_embeddings: torch.Tensor) -> int:
    similarity = input_embedding @ goods_embeddings.T
    return torch.argmax(similarity, dim=-1)


def translate(baidu_api_id, baidu_api_key, text: str, sex="男"):
    translator = Translator(baidu_api_id, baidu_api_key, "zh", "en")
    suggestions = re.findall(r"【(.*?)】", text)
    response_en = []
    for res in suggestions:
        response_en.append(translator.translate(res + sex, delay=1))
    print(response_en)
    return response_en


def query(text: list):
    print(text)
    load()
    suggestion_embedding = torch.tensor(clip_model.encode_text(text, batch_size=32))
    suggestion_embedding = F.normalize(suggestion_embedding, dim=-1)
    suggestion_id = query_id(suggestion_embedding, goods_image_embeddings)
    return suggestion_id


def response(baidu_api_id, baidu_api_key, text, sex=""):
    load()
    for i in range(3):
        try:
            index = query(translate(baidu_api_id, baidu_api_key, text, sex))
            images, links = [], []
            for i in index:
                images.append(int(i))
                links.append(str(data["Link_url"][int(i)]))
            return images, links
        except:
            time.sleep(1)
    return [], []
