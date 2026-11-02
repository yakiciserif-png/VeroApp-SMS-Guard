import os, re

repo_root = r'C:\_STAGING_VEROAPP_SMSGUARD'
core_dir = os.path.join(repo_root, 'lib', 'core')

core_files = []
for root, _, files in os.walk(core_dir):
    for f in files:
        if f.endswith('.dart'):
            core_files.append(os.path.join(root, f))

print(f'Total core files: {len(core_files)}')

for cf in sorted(core_files):
    rel = os.path.relpath(cf, core_dir).replace('\\', '/')
    with open(cf, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    code_lines = [l for l in lines if l.strip() and not l.strip().startswith('//') and not l.strip().startswith('/*') and not l.strip().startswith('*')]
    content = ''.join(lines)
    todos = len(re.findall(r'//\s*TODO', content, re.I))
    unimpl = len(re.findall(r'UnimplementedError', content))
    classes = re.findall(r'class\s+([A-Za-z0-9_]+)', content)
    print(f'{rel:<35} | Lines: {len(lines):<4} | Code: {len(code_lines):<4} | TODOs: {todos} | Unimpl: {unimpl} | Classes: {classes}')
