from PIL import Image
import matplotlib.pyplot as plt

from aim.preview.segment import predict


def test_predict(visualize=False):
    test_image = Image.open("asset/preview/example_garment2.jpg")
    test_image_ref = Image.open("asset/preview/example_segm.png")
    test_image_result = predict(
        test_image.resize((128, 128 * test_image.height // test_image.width))
    )

    if visualize:
        plt.subplot(1, 3, 1)
        plt.imshow(test_image)
        plt.axis("off")

        plt.subplot(1, 3, 2)
        plt.imshow(test_image_ref)
        plt.axis("off")

        plt.subplot(1, 3, 3)
        plt.imshow(test_image_result)
        plt.axis("off")

        plt.show()


if __name__ == "__main__":
    test_predict(visualize=True)
