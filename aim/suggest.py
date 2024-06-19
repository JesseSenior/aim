import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

tokenizer = None
model = None


def load():
    global tokenizer, model
    # Note: The default behavior now has injection attack prevention off.
    if tokenizer is None:
        tokenizer = AutoTokenizer.from_pretrained("./weights/qwemvl/Qwen_VL", trust_remote_code=True)

    if model is None:
        model = AutoModelForCausalLM.from_pretrained(
            "./weights/qwemvl/Qwen_VL", device_map="auto", trust_remote_code=True, fp16=True
        ).eval()

        model = PeftModel.from_pretrained(model, "/weights/qwemvl/LoRA-Weight")


def response(text_query, history=None):
    load()
    query = tokenizer.from_list_format(text_query)
    with torch.inference_mode():
        response, _ = model.chat(tokenizer, query=query, history=history)
    return response
