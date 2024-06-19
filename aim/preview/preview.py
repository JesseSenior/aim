from PIL import Image

from aim.preview.model import predict
from aim.preview.data import InputImage


def predict_preview(person_image: Image.Image, garment_image: list, garment_type: list):
    person_image = InputImage(person_image)
    garment_images = []
    for img, typ in zip(garment_image, garment_type):
        garment_images.append(InputImage(img, garment_type=typ))
    return predict(person_image, garment_images=garment_images)
