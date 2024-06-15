from PIL import Image
import numpy as np
import matplotlib
import matplotlib.pyplot as plt

from aim.preview.pose import predict
from aim.preview.data import InputImage


def test_predict(visualize=False):
    test_image = Image.open("asset/preview/example_image.jpg")
    test_pose_ref = np.loadtxt("asset/preview/example_pose.txt")
    test_pose_result = predict(test_image)

    if visualize:
        matplotlib.use("TkAgg")
        plt.subplot(1, 3, 1)
        plt.imshow(test_image)
        plt.axis("off")

        plt.subplot(1, 3, 2)
        x = test_pose_ref[:, 0]
        y = test_pose_ref[:, 1]
        plt.imshow(test_image)
        plt.scatter(x, y)

        plt.axis("off")

        for i, txt in enumerate(InputImage.openpose_fmt):
            plt.annotate(txt, (x[i], y[i]), color="cyan")

        plt.subplot(1, 3, 3)
        x = test_pose_result[:, 0]
        y = test_pose_result[:, 1]
        plt.imshow(test_image)
        plt.scatter(x, y)

        plt.axis("off")

        for i, txt in enumerate(InputImage.coco_fmt):
            plt.annotate(txt, (x[i], y[i]), color="cyan")

        plt.show()


if __name__ == "__main__":
    test_predict(visualize=True)
