from aim.recommendation.translator import Translator


def test_translator():
    appid = ""
    secretKey = ""
    translator = Translator(appid, secretKey, "en", "zh")
    result = translator.translate("apple\npen", 1)
    print(result)
    result2 = translator.translate("pen", 1)
    print(result2)
    translator.close()
