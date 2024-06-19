from aim.suggest import response


def test_suggestion():

    query = [{"image": "data/BeforeAfter-0603/image0/before/0.jpg"}, {"text": "分析一下照片中的人物特征及外表"}]
    # history = [
    #         {
    #             "role": "user",
    #             "content": "怎样才能穿得更加优雅自信一些呢？",
    #         },
    #         {
    #             "role": "assistant",
    #             "content": "黑色修身的衣服会显得优雅一些",
    #         },
    #         {
    #             "role": "user",
    #             "content": "你能给我推荐几款吗",
    #         },
    #     ]
    print(response(query))


if __name__ == "__main__":
    test_suggestion()
