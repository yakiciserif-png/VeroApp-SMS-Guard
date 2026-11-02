import os, re

repo_root = r'C:\_STAGING_VEROAPP_SMSGUARD'

# Scan Dart files
dart_channels = set()
dart_methods = {}
for root, _, files in os.walk(os.path.join(repo_root, 'lib')):
    for f in files:
        if f.endswith('.dart'):
            with open(os.path.join(root, f), 'r', encoding='utf-8', errors='ignore') as df:
                c = df.read()
            for ch in re.findall(r'MethodChannel\([\'"]([^\'"]+)[\'"]\)', c):
                dart_channels.add(ch)
            for inv in re.findall(r'invokeMethod(?:<[^>]+>)?\([\'"]([^\'"]+)[\'"](?:,\s*([^\)]+))?\)', c):
                mname, arg = inv
                dart_methods[mname] = arg

# Scan Kotlin files
kt_channels = set()
kt_methods = {}
kt_dir = os.path.join(repo_root, 'android', 'app', 'src', 'main', 'kotlin')
for root, _, files in os.walk(kt_dir):
    for f in files:
        if f.endswith('.kt'):
            with open(os.path.join(root, f), 'r', encoding='utf-8', errors='ignore') as kf:
                c = kf.read()
            for ch in re.findall(r'MethodChannel\(.+?,\s*[\'"]([^\'"]+)[\'"]\)', c):
                kt_channels.add(ch)
            # Find when (call.method) blocks
            for m in re.findall(r'[\'"]([a-zA-Z0-9_]+)[\'"]\s*->', c):
                kt_methods[m] = f

print('=== DART METHOD CHANNELS ===')
for ch in sorted(dart_channels):
    print(f'  {ch}')

print('\n=== KOTLIN METHOD CHANNELS ===')
for ch in sorted(kt_channels):
    print(f'  {ch}')

print('\n=== DART INVOKED METHODS ===')
for m, a in sorted(dart_methods.items()):
    print(f'  {m:<30} (arg: {a})')

print('\n=== KOTLIN HANDLED METHODS ===')
for m, f in sorted(kt_methods.items()):
    print(f'  {m:<30} (in {f})')
