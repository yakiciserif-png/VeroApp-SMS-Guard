import os, re

repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
lib_dir = os.path.join(repo_root, 'lib')

prints = []
empty_catches = []
broad_catches = []

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
                if re.search(r'\bprint\(', line):
                    prints.append((rel, idx + 1, s))
                if re.search(r'catch\s*\([^)]*\)\s*\{\s*\}', line) or re.search(r'catch\s*\{\s*\}', line):
                    empty_catches.append((rel, idx + 1, s))

print(f'=== PRINT STATEMENTS IN LIB ({len(prints)}) ===')
for rel, line_no, s in prints:
    print(f'  {rel}:{line_no}: {s}')

print(f'\n=== EMPTY CATCH BLOCKS ({len(empty_catches)}) ===')
for rel, line_no, s in empty_catches:
    print(f'  {rel}:{line_no}: {s}')
