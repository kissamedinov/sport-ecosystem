import urllib.request
import urllib.parse
import json

def translate(text, target_lang='kk', source_lang='ru'):
    url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl={source_lang}&tl={target_lang}&dt=t&q={urllib.parse.quote(text)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode('utf-8'))
            return "".join([item[0] for item in res[0] if item[0]])
    except Exception as e:
        print("Error: ", e)
        return None

def main():
    print(translate("Управление", 'kk', 'ru'))
    print(translate("МЕСТО", 'kk', 'ru'))
    print(translate("Настройка оплаты", 'kk', 'ru'))
    print(translate("Пожалуйста, сначала выберите тренера.", 'kk', 'ru'))

if __name__ == "__main__":
    main()
