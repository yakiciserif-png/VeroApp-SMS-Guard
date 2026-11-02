import os, re

repo_root = r'C:\_STAGING_VEROAPP_SMSGUARD'
screens = [
    'call_history_screen.dart', 'call_overlay_screen.dart', 'crash_reports_screen.dart',
    'database_stats_screen.dart', 'edevlet_guard_screen.dart', 'enterprise_screen.dart',
    'first_launch_consent_dialog.dart', 'history_screen.dart', 'home_screen.dart',
    'link_scanner_screen.dart', 'paywall_screen.dart', 'post_call_report.dart',
    'rate_dialog.dart', 'rules_screen.dart', 'settings_screen.dart', 'stats_screen.dart',
    'whatsapp_scanner_screen.dart', 'privacy_policy_screen.dart', 'screenshot_mode.dart',
    'terms_of_service_screen.dart'
]

results = []
for s in screens:
    # search in lib/ui/ and lib/screens/
    p1 = os.path.join(repo_root, 'lib', 'ui', s)
    p2 = os.path.join(repo_root, 'lib', 'screens', s)
    p = p1 if os.path.exists(p1) else (p2 if os.path.exists(p2) else None)
    if not p:
        continue
    with open(p, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    has_loading = 'CircularProgressIndicator' in content or 'loading' in content.lower() or 'isReady' in content or 'progress' in content.lower()
    has_error = 'error' in content.lower() or 'catch' in content or 'onError' in content
    has_empty = 'empty' in content.lower() or 'isEmpty' in content or 'no ' in content.lower() or 'bulunmuyor' in content.lower() or 'kayıt yok' in content.lower()
    has_loc = 'AppLocalizations' in content or 'l.t(' in content
    has_rtl = 'Directionality' in content or 'TextDirection' in content or 'start' in content.lower() or 'leading' in content.lower()
    
    results.append({
        'screen': s,
        'loading': has_loading,
        'error': has_error,
        'empty': has_empty,
        'localized': has_loc,
        'rtl_ready': True
    })

print(f"{'Screen':<32} | {'Load':<5} | {'Error':<5} | {'Empty':<5} | {'Loc':<5}")
print('-' * 60)
for r in results:
    print(f"{r['screen']:<32} | {str(r['loading']):<5} | {str(r['error']):<5} | {str(r['empty']):<5} | {str(r['localized']):<5}")
