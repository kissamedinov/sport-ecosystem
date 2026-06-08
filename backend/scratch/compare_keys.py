import json
import os

def load_json(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_by_path(d, path):
    parts = path.split('.')
    curr = d
    for p in parts:
        if isinstance(curr, dict) and p in curr:
            curr = curr[p]
        else:
            return None
    return curr

def find_missing_keys_paths(source, target, path=""):
    missing = []
    for k, v in source.items():
        current_path = f"{path}.{k}" if path else k
        if k not in target:
            missing.append(current_path)
        elif isinstance(v, dict):
            if not isinstance(target[k], dict):
                missing.append(current_path)
            else:
                missing.extend(find_missing_keys_paths(v, target[k], current_path))
    return missing

def main():
    workspace = r"c:\Users\Asus\Desktop\test\mobile"
    en_path = os.path.join(workspace, "assets", "translations", "en.json")
    ru_path = os.path.join(workspace, "assets", "translations", "ru.json")
    kk_path = os.path.join(workspace, "assets", "translations", "kk.json")
    
    en = load_json(en_path)
    ru = load_json(ru_path)
    kk = load_json(kk_path)
    
    missing_paths = find_missing_keys_paths(en, kk)
    
    missing_details = {}
    for p in missing_paths:
        en_val = get_by_path(en, p)
        ru_val = get_by_path(ru, p)
        missing_details[p] = {
            "en": en_val,
            "ru": ru_val,
            "kk": ""
        }
        
    out_path = os.path.join(workspace, "backend", "scratch", "missing_translations.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(missing_details, f, ensure_ascii=False, indent=2)
        
    print(f"Wrote {len(missing_paths)} missing keys to {out_path}")

if __name__ == "__main__":
    main()
