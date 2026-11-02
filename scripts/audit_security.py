import os, re

repo_root = r'C:\_STAGING_VEROAPP_SMSGUARD'
lib_dir = os.path.join(repo_root, 'lib')

insecure_http = []
raw_sql = []

for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            p = os.path.join(root, f)
            rel = os.path.relpath(p, repo_root).replace('\\', '/')
            with open(p, 'r', encoding='utf-8', errors='ignore') as df:
                lines = df.readlines()
            for idx, line in enumerate(lines):
                s = line.strip()
                if s.startswith('//') or s.startswith('*'):
                    continue
                # Insecure HTTP
                if 'http://' in line and not 'http://schemas.android' in line and not 'localhost' in line:
                    insecure_http.append((rel, idx + 1, s))
                # Raw SQL interpolation
                if re.search(r'rawQuery\(.*\$', line) or re.search(r'execute\(.*\$', line):
                    raw_sql.append((rel, idx + 1, s))

print(f'=== INSECURE HTTP ENDPOINTS ({len(insecure_http)}) ===')
for r, i, s in insecure_http:
    print(f'  {r}:{i}: {s}')

print(f'\n=== RAW SQL INTERPOLATION ({len(raw_sql)}) ===')
for r, i, s in raw_sql:
    print(f'  {r}:{i}: {s}')
