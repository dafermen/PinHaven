#!/usr/bin/env python3
"""Structural checks only. Does NOT compile or type-check Swift."""
import ast
import csv
import hashlib
import json
import plistlib
import re
import subprocess
import sys
import shutil
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
checks = 0

def check(condition, message):
    global checks
    if not condition:
        raise AssertionError(message)
    checks += 1
    print('PASS:', message)

# Parse the OpenStep subset emitted by generate_project.py, independently of it.
class OpenStep:
    def __init__(self, text):
        text = re.sub(r'//[^\n]*', '', text)
        self.tokens = re.findall(r'"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,]+', text)
        self.index = 0

    def take(self):
        value = self.tokens[self.index]; self.index += 1
        return value

    def expect(self, token):
        value = self.take()
        if value != token: raise ValueError(f'Expected {token}, found {value}')

    def parse(self):
        token = self.take()
        if token == '{':
            result = {}
            while self.tokens[self.index] != '}':
                key = self.parse(); self.expect('='); value = self.parse(); self.expect(';')
                if key in result: raise ValueError(f'Duplicate key: {key}')
                result[key] = value
            self.expect('}'); return result
        if token == '(':
            result = []
            while self.tokens[self.index] != ')':
                result.append(self.parse()); self.expect(',')
            self.expect(')'); return result
        return json.loads(token) if token.startswith('"') else int(token) if token.isdigit() else token

for path in sorted((ROOT/'scripts').glob('*.py')):
    ast.parse(path.read_text(encoding='utf-8')); check(True, f'Python syntax: {path.name}')
for path in [ROOT/'PinHaven/Resources/Info.plist', ROOT/'PinHaven/Resources/PrivacyInfo.xcprivacy']:
    plistlib.loads(path.read_bytes()); check(True, f'Valid plist: {path.name}')
info=plistlib.loads((ROOT/'PinHaven/Resources/Info.plist').read_bytes())
check(bool(info.get('NSLocationWhenInUseUsageDescription')), 'Foreground location permission description present')
check(not any('Always' in key for key in info), 'No background-location permission in Info.plist')

project_path=ROOT/'PinHaven.xcodeproj/project.pbxproj'
parser=OpenStep(project_path.read_text(encoding='utf-8')); project=parser.parse()
check(parser.index==len(parser.tokens), 'Xcode project OpenStep syntax consumed completely')
objects=project['objects']; root=objects[project['rootObject']]
check(root['isa']=='PBXProject' and len(root['targets'])==2, 'App and test targets present')
reference_keys={'fileRef','buildConfigurationList','mainGroup','productRefGroup','productReference',
                'containerPortal','remoteGlobalIDString','target','targetProxy'}
list_keys={'children','files','buildConfigurations','buildPhases','dependencies','targets'}
for oid,obj in objects.items():
    for key,value in obj.items():
        if key in reference_keys: check(value in objects, f'Reference {key} in {oid} resolves')
        if key in list_keys:
            check(all(v in objects for v in value), f'References {key} in {oid} resolve')
    if obj['isa']=='PBXFileReference' and obj.get('sourceTree')=='<group>':
        check((ROOT/obj['path']).is_dir() if obj.get('lastKnownFileType')=='folder.assetcatalog' else (ROOT/obj['path']).is_file(), f'File reference exists: {obj["path"]}')
# App icon must be included in app resources and selected in both configurations.
icon_root=ROOT/'PinHaven/Resources/Assets.xcassets'
icon_set=icon_root/'AppIcon.appiconset'
icon_manifest=json.loads((icon_set/'Contents.json').read_text(encoding='utf-8'))
icon=icon_set/icon_manifest['images'][0]['filename']
import struct
header=icon.read_bytes()[:33]
check(header[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', header[16:24])==(1024,1024)
      and header[25]==2, 'App icon is opaque RGB PNG at 1024x1024')
app_target=next(objects[t] for t in root['targets'] if objects[t]['name']=='PinHaven')
for config_id in objects[app_target['buildConfigurationList']]['buildConfigurations']:
    check(objects[config_id]['buildSettings'].get('ASSETCATALOG_COMPILER_APPICON_NAME')=='AppIcon',
          'AppIcon selected: '+objects[config_id]['name'])
resource_paths={objects[objects[f]['fileRef']]['path']
    for phase_id in app_target['buildPhases'] if objects[phase_id]['isa']=='PBXResourcesBuildPhase'
    for f in objects[phase_id]['files']}
check('PinHaven/Resources/Assets.xcassets' in resource_paths, 'App asset catalog included in resources')

expected={p.relative_to(ROOT).as_posix() for p in (ROOT/'PinHaven').rglob('*.swift')}
actual={obj['path'] for obj in objects.values() if obj['isa']=='PBXFileReference' and obj.get('path') in expected}
check(actual==expected, 'Every Swift app file included in project')
for target in root['targets']:
    obj=objects[target]
    phases=[objects[p] for p in obj['buildPhases'] if objects[p]['isa']=='PBXSourcesBuildPhase']
    built={objects[objects[f]['fileRef']]['path'] for phase in phases for f in phase['files']}
    expected_target=expected if obj['name']=='PinHaven' else {p.relative_to(ROOT).as_posix() for p in (ROOT/'PinHavenTests').rglob('*.swift')}
    check(built==expected_target, f'Exact source build membership: {obj["name"]}')

scheme=ET.parse(ROOT/'PinHaven.xcodeproj/xcshareddata/xcschemes/PinHaven.xcscheme')
for element in scheme.findall('.//BuildableReference'):
    check(element.attrib['BlueprintIdentifier'] in root['targets'], 'Scheme target resolves')
check(len(scheme.findall('.//TestableReference'))==1,'Shared scheme contains test target')

for path in sorted(ROOT.rglob('*.md')):
    for label,target in re.findall(r'\[([^\]]+)\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
        if '://' in target or target.startswith('#'): continue
        check((path.parent/target.split('#')[0]).exists(), f'Document link: {path.name} -> {target}')
rows=list(csv.DictReader((ROOT/'docs/BACKLOG.csv').open(encoding='utf-8', newline='')))
check(len(rows)==36 and len({r['id'] for r in rows})==len(rows), '36 uniquely identified backlog tasks')
roadmap=(ROOT/'docs/04_FASES_Y_TAREAS.md').read_text(encoding='utf-8')
check(all(r['id'] in roadmap for r in rows),'Backlog tasks correspond to roadmap')
bash = shutil.which('bash')
if sys.platform == 'win32':
    git = shutil.which('git')
    git_bash = Path(git).parent.parent / 'bin/bash.exe' if git else None
    bash = str(git_bash) if git_bash and git_bash.is_file() else None
if bash:
    subprocess.run([bash, '-n', 'scripts/test_ios.sh'], cwd=ROOT, check=True)
    check(True, 'iOS test shell script syntax')
else:
    print('SKIP: Bash unavailable; shell syntax not checked')
try:
    import yaml
    flow=yaml.safe_load((ROOT/'.github/workflows/ios.yml').read_text(encoding='utf-8'))
    check('test' in flow['jobs'], 'Workflow YAML syntax and test job')
except ImportError:
    print('SKIP: YAML parser unavailable; workflow requires GitHub validation')

before=hashlib.sha256(project_path.read_bytes()).hexdigest()
subprocess.run([sys.executable,str(ROOT/'scripts/generate_project.py')],check=True,capture_output=True)
after=hashlib.sha256(project_path.read_bytes()).hexdigest()
check(before==after,'Project generator reproducible')
print(f'\n{checks} structural checks passed. Swift compilation and XCTest NOT executed.')
