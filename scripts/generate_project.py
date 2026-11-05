#!/usr/bin/env python3
"""Regenerate a deterministic Xcode project without dependencies. Python 3.9+."""
import hashlib
import json
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
objects = {}

def uid(label):
    return hashlib.sha1(label.encode()).hexdigest()[:24].upper()

def add(label, isa, **fields):
    key = uid(label)
    objects[key] = dict(isa=isa, **fields)
    return key

sources = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 'PinHaven').rglob('*.swift'))
shared = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 'Shared').rglob('*.swift'))
extension_sources = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 'PinHavenShare').rglob('*.swift'))
tests = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 'PinHavenTests').rglob('*.swift'))
refs = {}
for path in sources + shared + extension_sources + tests + ['PinHaven/Resources/PinHaven.entitlements', 'PinHavenShare/PinHavenShare.entitlements', 'PinHavenShare/Info.plist', 'PinHaven/Resources/Info.plist', 'PinHaven/Resources/PrivacyInfo.xcprivacy', 'PinHaven/Resources/Assets.xcassets']:
    kind = 'folder.assetcatalog' if path.endswith('.xcassets') else ('sourcecode.swift' if path.endswith('.swift') else 'text.plist.xml')
    refs[path] = add(path, 'PBXFileReference', lastKnownFileType=kind, path=path, sourceTree='<group>')
app_product = add('app-product', 'PBXFileReference', explicitFileType='wrapper.application',
                  includeInIndex=0, path='PinHaven.app', sourceTree='BUILT_PRODUCTS_DIR')
test_product = add('test-product', 'PBXFileReference', explicitFileType='wrapper.cfbundle',
                   includeInIndex=0, path='PinHavenTests.xctest', sourceTree='BUILT_PRODUCTS_DIR')
share_product = add('share-product', 'PBXFileReference', explicitFileType='wrapper.app-extension',
    includeInIndex=0, path='PinHavenShare.appex', sourceTree='BUILT_PRODUCTS_DIR')
products = add('products', 'PBXGroup', children=[app_product, test_product, share_product], name='Products', sourceTree='<group>')
main = add('main-group', 'PBXGroup', children=list(refs.values())+[products], sourceTree='<group>')

def phase(label, paths, isa):
    builds = [add(label+path, 'PBXBuildFile', fileRef=refs[path]) for path in paths]
    return add(label, isa, buildActionMask=2147483647, files=builds, runOnlyForDeploymentPostprocessing=0)

app_src = phase('app-sources', sources + shared, 'PBXSourcesBuildPhase')
test_src = phase('test-sources', tests, 'PBXSourcesBuildPhase')
app_res = phase('app-resources', ['PinHaven/Resources/PrivacyInfo.xcprivacy', 'PinHaven/Resources/Assets.xcassets'], 'PBXResourcesBuildPhase')
app_fw = phase('app-frameworks', [], 'PBXFrameworksBuildPhase')
test_fw = phase('test-frameworks', [], 'PBXFrameworksBuildPhase')
share_members = extension_sources + shared + ['PinHaven/Models/PlaceRecord.swift',
    'PinHaven/Services/MapLinks.swift', 'PinHaven/Services/AddressSearch.swift', 'PinHaven/Views/MapPicker.swift']
share_src = phase('share-sources', share_members, 'PBXSourcesBuildPhase')
share_fw = phase('share-frameworks', [], 'PBXFrameworksBuildPhase')
share_res = phase('share-resources', ['PinHaven/Resources/PrivacyInfo.xcprivacy'], 'PBXResourcesBuildPhase')
embed_file = add('embed-share-file', 'PBXBuildFile', fileRef=share_product,
    settings={'ATTRIBUTES': ['RemoveHeadersOnCopy']})
embed_share = add('embed-share', 'PBXCopyFilesBuildPhase', buildActionMask=2147483647,
    dstPath='', dstSubfolderSpec=13, files=[embed_file], name='Embed App Extensions', runOnlyForDeploymentPostprocessing=0)

common = dict(SWIFT_VERSION='5.0', IPHONEOS_DEPLOYMENT_TARGET='17.0', SDKROOT='iphoneos',
              CLANG_ENABLE_MODULES='YES', CLANG_ENABLE_OBJC_ARC='YES',
              TARGETED_DEVICE_FAMILY='1', SUPPORTED_PLATFORMS='iphoneos iphonesimulator',
              CODE_SIGN_STYLE='Automatic', DEVELOPMENT_TEAM='7799N4RYUG',
              ENABLE_USER_SCRIPT_SANDBOXING='YES')

def configs(label, extra):
    keys = []
    for config in ['Debug', 'Release']:
        settings = dict(common)
        settings.update(extra)
        settings.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if config == 'Debug' else '-O',
                        DEBUG_INFORMATION_FORMAT='dwarf' if config == 'Debug' else 'dwarf-with-dsym',
                        ENABLE_TESTABILITY='YES' if config == 'Debug' else 'NO')
        if config == 'Debug': settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG $(inherited)'
        keys.append(add(label+config, 'XCBuildConfiguration', buildSettings=settings, name=config))
    return add(label+'config-list', 'XCConfigurationList', buildConfigurations=keys,
               defaultConfigurationIsVisible=0, defaultConfigurationName='Release')

project_configs = configs('project', {})
app_configs = configs('app', dict(PRODUCT_BUNDLE_IDENTIFIER='com.innovalogic.pinhaven', PRODUCT_NAME='$(TARGET_NAME)',
    INFOPLIST_FILE='PinHaven/Resources/Info.plist', GENERATE_INFOPLIST_FILE='NO',
    ASSETCATALOG_COMPILER_APPICON_NAME='AppIcon', CODE_SIGN_ENTITLEMENTS='PinHaven/Resources/PinHaven.entitlements',
    CURRENT_PROJECT_VERSION='1', MARKETING_VERSION='0.1.0',
    LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/Frameworks'))
test_configs = configs('tests', dict(PRODUCT_BUNDLE_IDENTIFIER='com.innovalogic.pinhaven.tests',
    PRODUCT_NAME='$(TARGET_NAME)', GENERATE_INFOPLIST_FILE='YES',
    TEST_HOST='$(BUILT_PRODUCTS_DIR)/PinHaven.app/PinHaven',
    BUNDLE_LOADER='$(TEST_HOST)', LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/Frameworks @loader_path/Frameworks'))
share_configs = configs('share', dict(PRODUCT_BUNDLE_IDENTIFIER='com.innovalogic.pinhaven.share',
    PRODUCT_NAME='$(TARGET_NAME)', INFOPLIST_FILE='PinHavenShare/Info.plist', GENERATE_INFOPLIST_FILE='NO',
    CODE_SIGN_ENTITLEMENTS='PinHavenShare/PinHavenShare.entitlements', APPLICATION_EXTENSION_API_ONLY='YES',
    SKIP_INSTALL='YES', CURRENT_PROJECT_VERSION='1', MARKETING_VERSION='0.1.0',
    LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'))
share = add('share-target', 'PBXNativeTarget', buildConfigurationList=share_configs,
    buildPhases=[share_src, share_fw, share_res], buildRules=[], dependencies=[], name='PinHavenShare',
    productName='PinHavenShare', productReference=share_product, productType='com.apple.product-type.app-extension')
share_proxy = add('share-proxy', 'PBXContainerItemProxy', containerPortal=uid('project'), proxyType=1,
    remoteGlobalIDString=share, remoteInfo='PinHavenShare')
share_dep = add('share-dependency', 'PBXTargetDependency', target=share, targetProxy=share_proxy)
app = add('app-target', 'PBXNativeTarget', buildConfigurationList=app_configs,
    buildPhases=[app_src, app_fw, app_res, embed_share], buildRules=[], dependencies=[share_dep], name='PinHaven',
    productName='PinHaven', productReference=app_product, productType='com.apple.product-type.application')
proxy = add('proxy', 'PBXContainerItemProxy', containerPortal=uid('project'), proxyType=1,
            remoteGlobalIDString=app, remoteInfo='PinHaven')
dep = add('dependency', 'PBXTargetDependency', target=app, targetProxy=proxy)
test = add('test-target', 'PBXNativeTarget', buildConfigurationList=test_configs,
    buildPhases=[test_src, test_fw], buildRules=[], dependencies=[dep], name='PinHavenTests',
    productName='PinHavenTests', productReference=test_product, productType='com.apple.product-type.bundle.unit-test')
project = add('project', 'PBXProject', attributes={'BuildIndependentTargetsInParallel':'YES',
    'LastUpgradeCheck':'1600', 'TargetAttributes':{share:{'CreatedOnToolsVersion':'16.0'}, app:{'CreatedOnToolsVersion':'16.0'},
    test:{'CreatedOnToolsVersion':'16.0','TestTargetID':app}}}, buildConfigurationList=project_configs,
    compatibilityVersion='Xcode 14.0', developmentRegion='en', hasScannedForEncodings=0,
    knownRegions=['en','es','Base'], mainGroup=main, productRefGroup=products,
    projectDirPath='', projectRoot='', targets=[app,test,share])

def serialize(value, indent=0):
    pad='\t'*indent
    if isinstance(value, dict):
        return '{\n' + ''.join('\t'*(indent+1)+json.dumps(k)+' = '+serialize(v,indent+1)+';\n' for k,v in value.items())+pad+'}'
    if isinstance(value, list):
        return '(\n'+''.join('\t'*(indent+1)+serialize(v,indent+1)+',\n' for v in value)+pad+')'
    if isinstance(value, int): return str(value)
    return json.dumps(value, ensure_ascii=False)

folder=ROOT/'PinHaven.xcodeproj'
folder.mkdir(exist_ok=True)
(folder/'project.pbxproj').write_text('// !$*UTF8*$!\n'+serialize(dict(archiveVersion=1, classes={}, objectVersion=56, objects=objects, rootObject=project))+'\n', encoding='utf-8', newline='\n')
scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
   <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="PinHaven.app" BlueprintName="PinHaven" ReferencedContainer="container:PinHaven.xcodeproj"/>
  </BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
  <Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{test}" BuildableName="PinHavenTests.xctest" BlueprintName="PinHavenTests" ReferencedContainer="container:PinHaven.xcodeproj"/></TestableReference></Testables>
 </TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
  <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="PinHaven.app" BlueprintName="PinHaven" ReferencedContainer="container:PinHaven.xcodeproj"/></BuildableProductRunnable>
 </LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
  <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="PinHaven.app" BlueprintName="PinHaven" ReferencedContainer="container:PinHaven.xcodeproj"/></BuildableProductRunnable>
 </ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>"""
ET.fromstring(scheme)
path=folder/'xcshareddata/xcschemes/PinHaven.xcscheme'
path.parent.mkdir(parents=True,exist_ok=True); path.write_text(scheme+'\n', encoding='utf-8', newline='\n')
# Structural data used only by the validator; not a second app configuration.
assert len(objects)==len(set(objects))
for path in refs: assert (ROOT/path).exists(), path
print(f'Generated {folder.name}: {len(sources)} app sources, {len(tests)} test sources, {len(objects)} objects')
