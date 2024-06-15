import gdown
import os
import requests
from pathlib import Path
import shutil
from tqdm.auto import tqdm

import tyro


def download(url: str, filename: str):
    Path(filename).parent.mkdir(exist_ok=True, parents=True)
    Path(filename).unlink(missing_ok=True)

    with open(filename, "wb") as f:
        with requests.get(url, stream=True) as r:
            r.raise_for_status()
            total = int(r.headers.get("content-length", 0))

            # tqdm has many interesting parameters. Feel free to experiment!
            tqdm_params = {
                "desc": url,
                "total": total,
                "miniters": 1,
                "unit": "B",
                "unit_scale": True,
                "unit_divisor": 1024,
            }
            with tqdm(**tqdm_params) as pb:
                for chunk in r.iter_content(chunk_size=8192):
                    pb.update(len(chunk))
                    f.write(chunk)


def prepare_detectron2():
    download(
        "https://dl.fbaipublicfiles.com/detectron2/COCO-Keypoints/keypoint_rcnn_R_50_FPN_3x/137849621/model_final_a6e10b.pkl",
        "weights/detectron2/model_final_a6e10b.pkl",
    )


def prepare_ace2p():
    os.system("hub install ace2p")


def prepare_dress_in_order():
    Path(".cache").mkdir(exist_ok=True, parents=True)
    Path("weights/dress_in_order").mkdir(exist_ok=True, parents=True)

    gdown.download(
        id="1JvLu6RJ4QBAYf6ON9i_DWU3Jlj56vz5P",
        output=".cache/dress_in_order.zip",
        resume=True,
    )

    shutil.unpack_archive(".cache/dress_in_order.zip", "weights/dress_in_order")
    shutil.move(
        "weights/dress_in_order/DIOR_64/latest_net_E_attr.pth",
        "weights/dress_in_order/latest_net_E_attr.pth",
    )
    shutil.move(
        "weights/dress_in_order/DIOR_64/latest_net_Flow.pth",
        "weights/dress_in_order/latest_net_Flow.pth",
    )
    shutil.move(
        "weights/dress_in_order/DIOR_64/latest_net_G.pth",
        "weights/dress_in_order/latest_net_G.pth",
    )
    shutil.rmtree("weights/dress_in_order/DIOR_64")


def main(
    ace2p: bool = True,
    detectron2: bool = True,
    dress_in_order: bool = True,
):
    """Prepare required weights

    Args:
        ace2p: Prepare weights for person image segmentation.
        detectron2: Prepare weights for person keypoints detection.
        dress_in_order: Prepare weights for dress in order model.
    """
    prepare_ace2p() if ace2p else None
    prepare_detectron2() if detectron2 else None
    prepare_dress_in_order() if dress_in_order else None


if __name__ == "__main__":
    tyro.cli(main)
