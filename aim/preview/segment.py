import os
import warnings

import cv2
import numpy as np
from PIL import Image
import paddlehub as hub

human_parser = None


def load():
    global human_parser
    if human_parser is not None:
        return
    if "CUDA_VISIBLE_DEVICES" not in os.environ:
        warnings.warn("CUDA_VISIBLE_DEVICES not set, set it to 0.")
        os.environ["CUDA_VISIBLE_DEVICES"] = "0"
    human_parser = hub.Module(name="ace2p")


def predict(image: Image.Image):
    load()

    image = cv2.cvtColor(np.array(image.convert("RGB")), cv2.COLOR_RGB2BGR)
    result = human_parser.segmentation(images=[image], use_gpu=True)
    result_image = result[0]["data"]
    return Image.fromarray(np.uint8(result_image), "L")
