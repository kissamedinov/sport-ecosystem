import json
import os
import urllib.request
import urllib.parse
import re
import time

def load_json(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(filepath, data):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def translate(text, target_lang='kk', source_lang='ru'):
    url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl={source_lang}&tl={target_lang}&dt=t&q={urllib.parse.quote(text)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode('utf-8'))
            return "".join([item[0] for item in res[0] if item[0]])
    except Exception as e:
        print(f"Error translating '{text}': {e}")
        return None

def restore_placeholders(original, translated):
    placeholders = re.findall(r'\{[a-zA-Z0-9_]+\}', original)
    translated_placeholders = re.findall(r'\{[^\}]+\}', translated)
    if len(placeholders) == len(translated_placeholders):
        for orig_p, trans_p in zip(placeholders, translated_placeholders):
            translated = translated.replace(trans_p, orig_p)
    return translated

def set_by_path(d, path, value):
    parts = path.split('.')
    curr = d
    for p in parts[:-1]:
        if p not in curr:
            curr[p] = {}
        curr = curr[p]
    curr[parts[-1]] = value

def main():
    workspace = r"c:\Users\Asus\Desktop\test\mobile"
    missing_path = os.path.join(workspace, "backend", "scratch", "missing_translations.json")
    kk_path = os.path.join(workspace, "assets", "translations", "kk.json")
    
    missing = load_json(missing_path)
    kk = load_json(kk_path)
    
    print(f"Translating {len(missing)} keys...")
    translated_count = 0
    for path, info in missing.items():
        ru_val = info['ru']
        en_val = info['en']
        
        # Translate from Russian
        source_val = ru_val if ru_val else en_val
        source_lang = 'ru' if ru_val else 'en'
        
        translated_val = translate(source_val, 'kk', source_lang)
        if translated_val:
            translated_val = restore_placeholders(source_val, translated_val)
            # Some manual cleanups if needed
            # e.g., if there's trailing space in original but not in translated
            if source_val.endswith(' ') and not translated_val.endswith(' '):
                translated_val += ' '
            if source_val.startswith(' ') and not translated_val.startswith(' '):
                translated_val = ' ' + translated_val
                
            info['kk'] = translated_val
            set_by_path(kk, path, translated_val)
            translated_count += 1
        else:
            print(f"Failed to translate: {path}")
            
        time.sleep(0.1) # Be polite
        
    print(f"Successfully translated {translated_count} / {len(missing)} keys.")
    
    # Save updated kk.json
    save_json(kk_path, kk)
    # Also save missing details for reference
    save_json(missing_path, missing)
    print("Saved updated translations.")

if __name__ == "__main__":
    main()
