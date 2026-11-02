import os, re

repo_root = r'C:\_STAGING_VEROAPP_SMSGUARD'
engines_dir = os.path.join(repo_root, 'lib', 'engines')
engines = sorted([f for f in os.listdir(engines_dir) if f.endswith('.dart')])

lib_files = []
for root, _, files in os.walk(os.path.join(repo_root, 'lib')):
    for f in files:
        if f.endswith('.dart'):
            lib_files.append(os.path.join(root, f))

test_files = []
for root, _, files in os.walk(os.path.join(repo_root, 'test')):
    for f in files:
        if f.endswith('.dart'):
            test_files.append(os.path.join(root, f))

results = []

for eng in engines:
    eng_path = os.path.join(engines_dir, eng)
    with open(eng_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    code_lines = [l for l in lines if l.strip() and not l.strip().startswith('//') and not l.strip().startswith('/*') and not l.strip().startswith('*')]
    real_logic_lines = len(code_lines)
    
    content = ''.join(lines)
    todos = len(re.findall(r'//\s*TODO', content, re.I))
    unimpl = len(re.findall(r'UnimplementedError', content))
    
    class_names = re.findall(r'class\s+([A-Za-z0-9_]+)', content)
    
    callers = set()
    for lf in lib_files:
        if os.path.abspath(lf) == os.path.abspath(eng_path):
            continue
        with open(lf, 'r', encoding='utf-8', errors='ignore') as f:
            lc = f.read()
        for cn in class_names:
            if cn in lc:
                callers.add(os.path.basename(lf))
        if eng in lc:
            callers.add(os.path.basename(lf))
            
    tests = set()
    for tf in test_files:
        with open(tf, 'r', encoding='utf-8', errors='ignore') as f:
            tc = f.read()
        for cn in class_names:
            if cn in tc:
                tests.add(os.path.basename(tf))
        if eng in tc:
            tests.add(os.path.basename(tf))
            
    results.append({
        'engine': eng,
        'classes': class_names,
        'lines': total_lines,
        'logic_lines': real_logic_lines,
        'todos': todos,
        'unimplemented': unimpl,
        'callers': sorted(list(callers)),
        'tests': sorted(list(tests))
    })

print(f'Total engines: {len(results)}')
for r in results:
    caller_str = ', '.join(r['callers']) if r['callers'] else 'NONE'
    test_str = ', '.join(r['tests']) if r['tests'] else 'NONE'
    print(f"{r['engine']:<30} | Logic: {r['logic_lines']:<4} | Classes: {len(r['classes']):<2} | TODOs: {r['todos']} | Unimpl: {r['unimplemented']} | Callers: {caller_str} | Tests: {test_str}")
