from dataclasses import dataclass, field
from typing import List, Sequence

import numpy as np
import torchvision.transforms as transforms
from PIL import Image
from dior.models.dior_model import DIORModel

from aim.preview.data import InputImage


@dataclass
class Opt:
    isTrain: bool = False
    phase: str = "test"
    n_human_parts: int = 8
    n_kpts: int = 18
    style_nc: int = 64
    n_style_blocks: int = 4
    netG: str = "dior"
    netE: str = "adgan"
    ngf: int = 64
    norm_type: str = "instance"
    relu_type: str = "leakyrelu"
    init_type: str = "orthogonal"
    init_gain: float = 0.02
    gpu_ids: List[int] = field(
        default_factory=lambda: [0]
    )  # TODO: ability to custom gpu id
    frozen_flownet: bool = True
    random_rate: int = 1
    perturb: bool = False
    warmup: bool = False
    name: str = "dress_in_order"
    vgg_path: str = ""
    flownet_path: str = ""
    checkpoints_dir: str = "weights"
    frozen_enc: bool = True
    load_iter: int = 0
    epoch: str = "latest"
    verbose: bool = False


model = None
# PID: Background -> Face -> Arm -> Leg
PID = [0, 4, 6, 7]
# Order: Upper-clothes -> Pants -> Skirt -> Hair
Order = [5, 1, 3, 2]


def load():
    global model
    if model is not None:
        return
    opt = Opt()
    model = DIORModel(opt)
    model.setup(opt)
    print("model device:", model.device)


def predict(
    person_image: InputImage,
    garment_images: Sequence[InputImage] = [],
    overlay_garment_images: Sequence[InputImage] = [],
) -> Image.Image:
    load()

    assert not person_image.is_garment_image
    person_image.to(model.device)
    gsegs = model.encode_attr(
        person_image.image[None],
        person_image.mask[None],
        person_image.keypoints[None],
        person_image.keypoints[None],
    )

    # Replace base garment
    for garment_image in garment_images:
        garment_image.to(model.device)

        gsegs[garment_image.mask_id] = model.encode_single_attr(
            garment_image.image[None],
            garment_image.mask[None],
            garment_image.keypoints[None],
            person_image.keypoints[None],
            i=1 if garment_image.is_garment_image else garment_image.mask_id,
        )

    # Append overlay garment
    over_gsegs = []
    for garment_image in overlay_garment_images:
        garment_image.to(model.device)

        over_gsegs.append(
            model.encode_single_attr(
                garment_image.image[None],
                garment_image.mask[None],
                garment_image.keypoints[None],
                person_image.keypoints[None],
                i=(
                    1
                    if garment_image.is_garment_image
                    else garment_image.mask_id
                ),
            )
        )

    psegs = [gsegs[i] for i in PID]
    gsegs = [gsegs[i] for i in Order] + over_gsegs
    gen_img = model.netG(person_image.keypoints[None], psegs, gsegs)

    # postprocess
    gen_img = gen_img[0].float().cpu().detach()
    gen_img = (gen_img + 1) / 2
    gen_img = person_image.toPIL(gen_img)
    gen_img = person_image.parse_result(gen_img)

    return gen_img
