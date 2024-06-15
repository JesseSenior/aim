from typing import Optional, Tuple
from altair import Literal
import torch
import numpy as np
import torchvision.transforms as transforms
from PIL import Image, ImageOps
from dior.datasets.human_parse_labels import get_label_map, DF_LABEL

import aim.preview.pose as pose_model
import aim.preview.segment as segment_model


class InputImage:
    result_size = (176, 256)
    toTensor = transforms.ToTensor()
    toPIL = transforms.ToPILImage()
    normalize = transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))
    _, atr2aiyu = get_label_map()

    # fmt: off
    coco_fmt = ['Nose', 'Leye', 'Reye', 'Lear', 'Rear', 'Lsho', 'Rsho', 'Lelb',
    'Relb', 'Lwri', 'Rwri', 'Lhip', 'Rhip', 'Lkne', 'Rkne', 'Lank', 'Rank']

    openpose_fmt = ['Nose', 'Neck', 'Rsho', 'Relb', 'Rwri', 'Lsho', 'Lelb', 
    'Lwri', 'Rhip', 'Rkne', 'Rank', 'Lhip', 'Lkne', 'Lank', 'Reye', 'Leye', 
    'Rear', 'Lear']
    # fmt: on

    @classmethod
    def extract_keypoints(
        cls,
        keypoints: np.ndarray,
        bbox: Tuple[int, int, int, int],
        original_image_size: Tuple[int, int],
        sigma=6,
    ):
        if keypoints is None:
            return np.zeros((*cls.result_size[::-1], 18), dtype="float32")
        assert len(keypoints) in [17, 18]

        if len(keypoints) == 17:
            # COCO keypoints format, convert to OpenPose keypoints format
            new_keypoints = np.empty((18, 2))
            for i in range(17):
                ti = cls.openpose_fmt.index(cls.coco_fmt[i])
                new_keypoints[ti] = keypoints[i]

            lsho = keypoints[cls.coco_fmt.index("Lsho")]
            rsho = keypoints[cls.coco_fmt.index("Rsho")]
            if np.any(lsho == pose_model.MISSING_VALUE) or np.any(
                rsho == pose_model.MISSING_VALUE
            ):
                new_keypoints[cls.openpose_fmt.index("Neck")] = np.array(
                    [pose_model.MISSING_VALUE, pose_model.MISSING_VALUE]
                )
            else:
                new_keypoints[cls.openpose_fmt.index("Neck")] = (
                    lsho + rsho
                ) / 2
            keypoints = new_keypoints

        # Modified from dior.utils.pose_utils.coords_to_map
        result = np.zeros((*cls.result_size[::-1], 18), dtype="float32")
        for i, point in enumerate(keypoints):
            if (
                point[0] == pose_model.MISSING_VALUE
                or point[1] == pose_model.MISSING_VALUE
            ):
                continue
            point_0 = int(
                point[0] / original_image_size[0] * (bbox[2] - bbox[0])
                + bbox[0]
            )
            point_1 = int(
                point[1] / original_image_size[1] * (bbox[3] - bbox[1])
                + bbox[1]
            )
            xx, yy = np.meshgrid(
                np.arange(cls.result_size[0]), np.arange(cls.result_size[1])
            )
            result[..., i] = np.exp(
                -((yy - point_1) ** 2 + (xx - point_0) ** 2) / (2 * sigma**2)
            )
        result = np.transpose(result, (2, 0, 1))
        result = torch.Tensor(result)
        return result

    @classmethod
    def downsample_image(cls, image: Image.Image):
        scale_factor = min(
            [
                cls.result_size[0] / image.width,
                cls.result_size[1] / image.height,
                1,
            ]
        )
        image_size = (
            int(image.width * scale_factor),
            int(image.height * scale_factor),
        )
        image = image.resize(image_size)
        pad_width = cls.result_size[0] - image.width
        pad_height = cls.result_size[1] - image.height
        offset = (pad_width // 2, pad_height // 2)

        image = ImageOps.expand(
            image,
            (*offset, pad_width - offset[0], pad_height - offset[1]),
        )
        bbox = (*offset, offset[0] + image_size[0], offset[1] + image_size[1])

        return image, bbox

    def __init__(
        self,
        image: Image.Image,
        mask: Optional[Image.Image] = None,
        keypoints: Optional[np.ndarray] = None,
        garment_type: Optional[
            Literal["Upper-clothes"] | Literal["Pants"] | Literal["Skirt"]
        ] = None,
        is_garment_image: bool = False,
        resize_back: bool = True,
    ):
        self.original_image_size = image.size
        self.original_image = image.copy()
        self.is_garment_image = is_garment_image
        self.resize_back = resize_back
        self.mask_id = (
            None if garment_type is None else DF_LABEL.index(garment_type)
        )

        if is_garment_image:
            # TODO: GPT infer Garment type: Upper-clothes, Pants, Skirt
            assert mask is not None and mask.size == image.size
            assert garment_type is not None

            mask = mask.convert("L")
            bbox = mask.getbbox(alpha_only=False)

            self.image, _ = self.downsample_image(image.crop(bbox))
            mask, _ = self.downsample_image(mask.crop(bbox))
            self.keypoints = self.extract_keypoints(
                keypoints, bbox, self.original_image_size
            )

            mask = np.array(mask)
            self.mask = torch.Tensor(mask > 0, dtype=torch.uint8)

        else:
            if mask is None:
                mask = segment_model.predict(image)
            if keypoints is None:
                keypoints = pose_model.predict(image)

            self.image, self.bbox = self.downsample_image(image)
            self.keypoints = self.extract_keypoints(
                keypoints, self.bbox, self.original_image_size
            )

            mask, _ = self.downsample_image(mask)

            mask = torch.from_numpy(np.array(mask))
            texture_mask = torch.zeros_like(mask)
            for atr in self.atr2aiyu:
                aiyu = self.atr2aiyu[atr]
                texture_mask[mask == atr] = aiyu
            self.mask = texture_mask

        self.image = self.normalize(self.toTensor(self.image))

    def to(self, device):
        self.image = self.image.to(device)
        self.mask = self.mask.to(device)
        self.keypoints = self.keypoints.to(device)

    def parse_result(self, image: Image.Image):
        assert not self.is_garment_image
        print(self.bbox)
        image = image.crop(self.bbox)
        if self.resize_back:
            image = image.resize(self.original_image_size)
        return image
