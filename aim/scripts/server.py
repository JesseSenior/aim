import base64
from pathlib import Path

import tyro
import pandas as pd
from io import BytesIO
from PIL import Image
from flask import Flask, request, jsonify


import aim.suggest
import aim.recommendation.recommend
import aim.preview.preview

BAIDU_API_ID = None
BAIDU_API_KEY = None
image_index_data = None


prompt_suggestion = """
不要出现【】，下面是一些例子：
对于你的要求，我建议穿一些浅色调的衣服，可以营造清爽的感觉。
裤子要长，能够堆一点在鞋面上，裤子要阔腿，这样的目的是为了营造宽松慵懒的氛围感
经典黑白灰推荐颜色为如干枯绣球花色、豆绿色之类的，可以试一试这些颜色的卫衣
上衣可选择棉麻质地，或者v字领之类，再加上直筒或者微阔的牛仔裤
"""

prompt_recommendation = """
    你可以给出 1.正常建议 或 2.商品推荐。

    对于**正常建议**，不要出现【】，下面是一些例子：
    对于你的要求，我建议穿一些浅色调的衣服，可以营造清爽的感觉。
    裤子要长，能够堆一点在鞋面上，裤子要阔腿，这样的目的是为了营造宽松慵懒的氛围感
    经典黑白灰推荐颜色为如干枯绣球花色、豆绿色之类的，可以试一试这些颜色的卫衣
    上衣可选择棉麻质地，或者v字领之类，再加上直筒或者微阔的牛仔裤

    对于商品推荐，输出格式为‘建议您以【xxxx】为上衣，【xxxxx】为裤子，。。。。’。
    下面是一些例子：
    建议您以【白色衬衫】为上衣，【灰色西装裤】为裤子。白色衬衫是经典百搭单品，搭配灰色西装裤能够营造出商务休闲的氛围。
    建议您以【白色简约T恤】为上衣，【黑色休闲裤】为裤子。整体风格偏向于简约而不失格调的穿搭，白色T恤作为基础单品，搭配黑色休闲裤，既显得清新自然，又不失时尚感。
    建议您以【有活力的黄色T恤，颜色鲜艳】为上衣，【蓝色牛仔裤，休闲版型】为裤子。黄色T恤为整体造型增添了活力，同时也显得肤色更加白皙。蓝色牛仔裤是休闲穿搭的必备单品，不仅舒适度高，还能拉长腿部线条。
    建议您以【黑色夹克】为上衣，【深色牛仔裤】为裤子。黑色夹克，显得稳重又不失时尚感。搭配深色的牛仔裤，整体色彩和谐统一。可以考虑加入一些简约的金属饰品，如手表或项链。
    建议您以【粉色毛衣或甜美系针织衫】为上衣，【白色或浅色系的裙子（如A字裙、百褶裙等）】为裤子。穿搭风格明显更加甜美和活泼,这样可以营造出一种清新甜美的感觉。同时，白色靴子与整体风格非常搭配，可以延续这种搭配。
    建议您以【条纹衬衫,经典时尚】为上衣，【黑色或深色的A字裙或包臀裙】为裤子。在配饰方面，你可以尝试一些简约而有个性的项链、手链或耳环，这些都能为你的穿搭增添一些亮点。
    """

app = Flask(__name__)


def image_to_base64(image: Image.Image, fmt="png") -> str:
    output_buffer = BytesIO()
    image.save(output_buffer, format=fmt)
    byte_data = output_buffer.getvalue()
    base64_str = base64.b64encode(byte_data).decode("utf-8")
    return base64_str


def base64_to_image(base64_str: str) -> Image.Image:
    # base64_data = re.sub('^data:image/.+;base64,', '', base64_str)
    byte_data = base64.b64decode(base64_str)
    image_data = BytesIO(byte_data)
    img = Image.open(image_data)
    return img


@app.route("/chat", methods=["POST"])
def suggest():
    Path(".cache").mkdir(exist_ok=True)

    data = request.get_json()
    # 在这里处理接收到的数据
    text = ""
    sex = ""
    image_text = ""
    if "message" in data.keys():
        text = data["message"][-1]["content"]
        history = data["message"].copy()
        history.pop()
    else:
        history = None
    query = []
    if "person_image" in data.keys():
        base64_to_image(data["person_image"]).save(".cache/image_selfie.png")
        query.append({"image": ".cache/image_selfie.png"})
        sex_ans = aim.suggest.response([{"image": ".cache/image_selfie.png"}, {"text": "判断图中人物的性别"}])
        if "男" in sex_ans:
            sex = "男"
        if "女" in sex_ans:
            sex = "女"
        image_text = (
            aim.suggest.response([{"image": ".cache/image_selfie.png"}, {"text": "分析一下照片中的人物特征及外表"}])
            + sex
        )
    if "person_image_text" in data.keys():
        image_text = data["person_image_text"]
        if "男" in data["person_image_text"]:
            sex = "男"
        if "女" in data["person_image_text"]:
            sex = "女"
    if history is None or len(history) == 0:
        text = text + prompt_suggestion
    else:
        text = text + prompt_recommendation
    query.append({"text": text})
    print(query)
    res = aim.suggest.response(query, history)
    print(history)
    if history is None or len(data["message"]) == 0:
        answer_type = 0
    else:
        if "推荐" in data["message"][-1]["content"]:
            answer_type = "【" in res
        else:
            answer_type = 0

    if answer_type == 0:
        return jsonify({"answer": res, "answer_type": answer_type, "person_image_text": image_text})
    else:
        print(sex)
        images, links = aim.recommendation.recommend.response(BAIDU_API_ID, BAIDU_API_KEY, res, sex)
        answer = "".join(str(x) + "_" for x in images)[:-1]
        return jsonify({"answer": answer, "answer_type": int(answer_type), "person_image_text": image_text})


@app.route("/garment", methods=["POST"])
def garment():
    data = request.get_json()
    id = data["gid"]
    image_root = "data/recommend_data/Image/"
    img = Image.open(image_root + image_index_data["Image_url"][id])
    w, h = img.size
    img = img.resize((int(w / 2), int(h / 2)))
    img = image_to_base64(img)
    if "裤" in image_index_data["Type"][id]:
        type = "下衣"
    else:
        type = "上衣"
    url = image_index_data["Link_url"][id]
    return jsonify({"gid": id, "image": str(img), "type": type, "url": url})


@app.route("/preview", methods=["POST"])
def generate():
    data = request.get_json()
    person_image = base64_to_image(data["person_image"])

    garment_images, garment_type = [], []
    image_root = "data/recommend_data/Image/"
    for id in data["gids"]:
        garment_images.append(Image.open(image_root + image_index_data["Image_url"][id]))
        if "裤" in image_index_data["Type"][id]:
            type = "Pants"
        else:
            type = "Upper-clothes"
        garment_type.append(type)
    img = aim.preview.preview.predict_preview(person_image, garment_images, garment_type)
    result = {"tryon_image": str(image_to_base64(img))}
    return jsonify(result)


@app.route("/")
def hello_world():
    return "Server started!"


def main(
    baidu_api_id,
    baidu_api_key,
    host: str = "10.32.128.41",
    port: int = 11451,
    processes: bool = True,
):
    """Run aim server.

    Args:
        baidu_api_id: API ID for baidu translator.
        baidu_api_key: API Key for baidu translator.
        host: server listen host.
        port: server listen port.
        processes: whether use process.
    """
    global BAIDU_API_ID, BAIDU_API_KEY, image_index_data
    image_index_data = pd.read_excel("data/recommend_data/image_index.xlsx")
    BAIDU_API_ID = baidu_api_id
    BAIDU_API_KEY = baidu_api_key
    app.run(host=host, port=port, processes=processes)


if __name__ == "__main__":
    tyro.cli(main)
