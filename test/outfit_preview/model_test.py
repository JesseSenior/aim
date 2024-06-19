from PIL import Image
import numpy as np
import matplotlib
import matplotlib.pyplot as plt

from aim.preview.model import predict
from aim.preview.data import InputImage


def get_input_image(image_path, mask_path=None, keypoints_path=None, *args, **kwargs):
    image = Image.open(image_path)
    mask = None if mask_path is None else Image.open(mask_path)
    keypoints = None if keypoints_path is None else np.loadtxt(keypoints_path)
    return InputImage(image, mask, keypoints, *args, **kwargs)


def test_predict(visualize=False):
    person_image = get_input_image(
        "asset/preview/example_image.jpg",
        "asset/preview/example_segm.png",
        "asset/preview/example_pose.txt",
    )

    images = [
        Image.open("asset/preview/example_image.jpg"),
        Image.open("asset/preview/example_garment.jpg"),
    ]

    garment_image = get_input_image(
        "asset/preview/example_garment.jpg",
        garment_type="Upper-clothes",
    )
    images.append(predict(person_image, overlay_garment_images=[garment_image]))

    garment_image = get_input_image(
        "asset/preview/example_garment.jpg",
        garment_type="Skirt",
    )
    images.append(predict(person_image, overlay_garment_images=[garment_image]))

    garment_image = get_input_image(
        "asset/preview/example_garment.jpg",
        garment_type="Pants",
    )
    images.append(predict(person_image, overlay_garment_images=[garment_image]))

    if visualize:
        for i, img in enumerate(images):
            plt.subplot(1, len(images), i + 1)
            plt.imshow(img)
            plt.axis("off")

        plt.show()


if __name__ == "__main__":
    matplotlib.use("TkAgg")

    test_predict(visualize=True)
