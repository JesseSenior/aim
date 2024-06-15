from PIL import Image
import numpy as np
import torch
import matplotlib
import matplotlib.pyplot as plt

from aim.preview.data import InputImage


def visualize_result(
    image: torch.Tensor,
    mask: torch.Tensor,
    keypoints: torch.Tensor,
    fig_id: int,
):
    plt.figure(fig_id)
    plt.subplot(1, 3, 1)
    image = InputImage.toPIL((image.cpu() + 1) / 2)
    plt.imshow(image)
    plt.axis("off")

    plt.subplot(1, 3, 2)
    mask = InputImage.toPIL(mask.cpu())
    plt.imshow(mask)
    plt.axis("off")

    plt.subplot(1, 3, 3)
    keypoints = InputImage.toPIL(
        keypoints.sum(dim=0, keepdim=True).clamp(max=1).cpu()
    )
    plt.imshow(keypoints)
    plt.axis("off")


class TestInputImage:
    def test_image1(self, visualize=False):
        test_image = Image.open("asset/preview/example_image.jpg")
        test_segm = Image.open("asset/preview/example_segm.png")
        test_pose = np.loadtxt("asset/preview/example_pose.txt")

        data = InputImage(test_image, test_segm, test_pose)
        if visualize:
            visualize_result(data.image, data.mask, data.keypoints, 1)

    def test_image2(self, visualize=False):
        test_image = Image.open("asset/preview/example_image.jpg")

        data = InputImage(test_image)
        if visualize:
            visualize_result(data.image, data.mask, data.keypoints, 2)

    # TODO: Add garment image test.


if __name__ == "__main__":
    matplotlib.use("TkAgg")

    TestInputImage().test_image1(visualize=True)
    TestInputImage().test_image2(visualize=True)

    plt.show()
