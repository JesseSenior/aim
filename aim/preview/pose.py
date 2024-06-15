import numpy as np
from PIL import Image
import cv2

from detectron2 import model_zoo
from detectron2.engine import DefaultPredictor
from detectron2.config import get_cfg

MISSING_VALUE = -1
predictor = None


def load():
    global predictor
    if predictor is not None:
        return

    cfg = get_cfg()
    cfg.merge_from_file(
        model_zoo.get_config_file(
            "COCO-Keypoints/keypoint_rcnn_R_50_FPN_3x.yaml"
        )
    )
    cfg.MODEL.WEIGHTS = "./weights/detectron2/model_final_a6e10b.pkl"

    predictor = DefaultPredictor(cfg)


def predict(image: Image.Image, threshold=0.1):
    load()

    image = cv2.cvtColor(np.array(image.convert("RGB")), cv2.COLOR_RGB2BGR)
    output = predictor(image)
    output = output["instances"].pred_keypoints.cpu().numpy()[0]

    result = np.full((len(output), 2), MISSING_VALUE)
    for i in range(len(output)):
        if output[i, 2] >= threshold:
            result[i] = output[i, :2]
    return result
