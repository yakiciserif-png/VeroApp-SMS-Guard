import os, struct, json, hashlib

repo_root = r'C:\_STAGING_VEROAPP_SMSGUARD'

def check_spam_numbers():
    p = os.path.join(repo_root, 'assets', 'spam_db', 'spam_numbers.bin')
    size = os.path.getsize(p)
    # The file contains 8-byte big-endian integers (phone numbers)
    record_count = size // 8
    samples = []
    with open(p, 'rb') as f:
        for _ in range(5):
            chunk = f.read(8)
            if len(chunk) == 8:
                num = struct.unpack('>q', chunk)[0]
                s = str(num)
                if len(s) >= 4:
                    samples.append(f'+{s[:2]}***{s[-4:]}')
                else:
                    samples.append(s)
    print(f'2.1 spam_numbers.bin: Size: {size} bytes, Records: {record_count}, Samples: {samples}')
    return record_count > 0

def check_phishing_domains():
    p = os.path.join(repo_root, 'assets', 'spam_db', 'phishing_domains.bin')
    size = os.path.getsize(p)
    # The file contains length-prefixed UTF-8 domains (2 bytes len + domain)
    domains = []
    with open(p, 'rb') as f:
        while len(domains) < 5:
            len_bytes = f.read(2)
            if not len_bytes or len(len_bytes) < 2:
                break
            dlen = struct.unpack('>H', len_bytes)[0]
            domain = f.read(dlen).decode('utf-8', errors='ignore')
            domains.append(domain)
    # Count total domains
    total = 0
    with open(p, 'rb') as f:
        while True:
            len_bytes = f.read(2)
            if not len_bytes or len(len_bytes) < 2:
                break
            dlen = struct.unpack('>H', len_bytes)[0]
            f.seek(dlen, 1)
            total += 1
    print(f'2.2 phishing_domains.bin: Size: {size} bytes, Domains: {total}, Samples: {domains[:5]}')
    return total > 0

def check_turkey_spam():
    p = os.path.join(repo_root, 'assets', 'spam_db', 'turkey_spam.bin')
    size = os.path.getsize(p)
    record_count = size // 8
    samples = []
    with open(p, 'rb') as f:
        for _ in range(5):
            chunk = f.read(8)
            if len(chunk) == 8:
                num = struct.unpack('>q', chunk)[0]
                s = str(num)
                samples.append(f'+{s[:2]}***{s[-4:]}')
    print(f'2.3 turkey_spam.bin: Size: {size} bytes, Records: {record_count}, Samples: {samples}')
    return record_count > 0

def check_threat_db_v2():
    p = os.path.join(repo_root, 'assets', 'spam_db', 'threat_db_v2.bin')
    size = os.path.getsize(p)
    with open(p, 'rb') as f:
        header = f.read(16)
    print(f'2.4 threat_db_v2.bin: Size: {size} bytes, Header hex: {header.hex()}')
    return size > 0

def check_bloom_filter():
    p = os.path.join(repo_root, 'assets', 'breach_db', 'bloom_filter.bin')
    size = os.path.getsize(p)
    # 50,000,000 bits / 8 = 6,250,000 bytes
    print(f'2.5 bloom_filter.bin: Size: {size} bytes (Expected: 6,250,000 bytes = 50M bits)')
    return size == 6250000

def check_tflite():
    p = os.path.join(repo_root, 'assets', 'model', 'vero_semantic_intent_v1.tflite')
    size = os.path.getsize(p)
    with open(p, 'rb') as f:
        magic = f.read(8)
    magic_str = magic[4:8]
    print(f'2.6 vero_semantic_intent_v1.tflite: Size: {size} bytes, Magic offset 4: {magic_str}')
    return magic_str == b'TFL3'

def check_seed_corpus():
    p = os.path.join(repo_root, 'assets', 'model', 'seed_corpus.json')
    with open(p, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f'2.7 seed_corpus.json: Keys: {list(data.keys())}')
    counts = {}
    for k, v in data.items():
        if isinstance(v, list):
            counts[k] = len(v)
    print(f'    Examples per class: {counts}')
    return len(data) > 0

def check_locales():
    loc_dir = os.path.join(repo_root, 'assets', 'locales')
    files = sorted([f for f in os.listdir(loc_dir) if f.endswith('.json')])
    print(f'2.8 Locales ({len(files)} files):')
    for lf in files:
        with open(os.path.join(loc_dir, lf), 'r', encoding='utf-8') as f:
            d = json.load(f)
        empty = sum(1 for v in d.values() if not str(v).strip())
        print(f'    {lf:<8}: {len(d):<4} keys | {empty} empty values')
    return len(files) == 11

def check_audio():
    audio_dir = os.path.join(repo_root, 'assets', 'audio', 'bot_responses')
    files = sorted([f for f in os.listdir(audio_dir) if f.endswith('.mp3')])
    print(f'2.9 Audio files ({len(files)} files):')
    for af in files:
        p = os.path.join(audio_dir, af)
        size = os.path.getsize(p)
        with open(p, 'rb') as f:
            header = f.read(10)
        # Check ID3 or MPEG sync (0xFF 0xFB)
        is_id3 = header.startswith(b'ID3')
        is_mp3 = header[0] == 0xFF and (header[1] & 0xE0) == 0xE0
        print(f'    {af:<35}: {size:<6} bytes | ID3: {is_id3} | MP3 sync: {is_mp3}')
    return len(files) > 0

def check_branding():
    brand_dir = os.path.join(repo_root, 'assets', 'branding')
    files = sorted([f for f in os.listdir(brand_dir)])
    print(f'2.10 Branding files ({len(files)} files):')
    for bf in files:
        p = os.path.join(brand_dir, bf)
        size = os.path.getsize(p)
        with open(p, 'rb') as f:
            header = f.read(8)
        is_png = header.startswith(b'\x89PNG\r\n\x1a\n')
        print(f'    {bf:<30}: {size:<7} bytes | PNG valid: {is_png}')
    return len(files) > 0

print('=================== BINARY DATA INTEGRITY VERIFICATION ===================')
check_spam_numbers()
check_phishing_domains()
check_turkey_spam()
check_threat_db_v2()
check_bloom_filter()
check_tflite()
check_seed_corpus()
check_locales()
check_audio()
check_branding()
print('==========================================================================')
