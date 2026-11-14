import os, re

repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
lib_dir = os.path.join(repo_root, 'lib')

stateful_files = []
for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            stateful_files.append(os.path.join(root, f))

leak_issues = []

for sf in sorted(stateful_files):
    with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Check for controllers or timers created as fields
    text_controllers = re.findall(r'(\b[a-zA-Z0-9_]+\s*=\s*TextEditingController\([^\)]*\))', content)
    anim_controllers = re.findall(r'(\b[a-zA-Z0-9_]+\s*=\s*AnimationController\([^\)]*\))', content)
    late_anim = re.findall(r'late\s+(?:final\s+)?AnimationController\s+([a-zA-Z0-9_]+)', content)
    late_text = re.findall(r'late\s+(?:final\s+)?TextEditingController\s+([a-zA-Z0-9_]+)', content)
    late_timers = re.findall(r'Timer\??\s+([a-zA-Z0-9_]+)', content)
    stream_subs = re.findall(r'StreamSubscription\??\s+([a-zA-Z0-9_]+)', content)
    
    has_dispose = 'void dispose()' in content
    
    # Check if controllers are disposed
    disposed_vars = re.findall(r'([a-zA-Z0-9_]+)\.dispose\(\)', content)
    cancelled_vars = re.findall(r'([a-zA-Z0-9_]+)\.cancel\(\)', content)
    
    all_controllers = []
    for tc in text_controllers:
        var_name = tc.split('=')[0].replace('final', '').replace('late', '').strip()
        all_controllers.append((var_name, 'TextEditingController'))
    for lt in late_text:
        all_controllers.append((lt, 'TextEditingController'))
    for ac in anim_controllers:
        var_name = ac.split('=')[0].replace('final', '').replace('late', '').strip()
        all_controllers.append((var_name, 'AnimationController'))
    for la in late_anim:
        all_controllers.append((la, 'AnimationController'))
        
    for var_name, ctype in all_controllers:
        if var_name not in disposed_vars:
            leak_issues.append((os.path.basename(sf), f'{ctype} "{var_name}" not disposed in dispose()'))
            
    for sub in stream_subs:
        if sub not in cancelled_vars:
            leak_issues.append((os.path.basename(sf), f'StreamSubscription "{sub}" not cancelled in dispose()'))

print(f'Total leak checks performed on {len(stateful_files)} files.')
print(f'Issues found: {len(leak_issues)}')
for issue in leak_issues:
    print(issue)
