#!/usr/bin/env python3
"""Generate GroceryList.xcodeproj from GroceryListiOS sources."""
import hashlib
from pathlib import Path

IOS_ROOT = Path(__file__).resolve().parent.parent / "GroceryListiOS"
SRC = IOS_ROOT / "GroceryList"
TESTS = IOS_ROOT / "GroceryListTests"
PROJECT = "GroceryList"
TEST_PROJECT = "GroceryListTests"

SCHEME_TEMPLATE = """<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1500" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="APP_TARGET_ID" BuildableName="GroceryList.app" BlueprintName="GroceryList" ReferencedContainer="container:GroceryList.xcodeproj"/>
         </BuildActionEntry>
         <BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="TEST_TARGET_ID" BuildableName="GroceryListTests.xctest" BlueprintName="GroceryListTests" ReferencedContainer="container:GroceryList.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="TEST_TARGET_ID" BuildableName="GroceryListTests.xctest" BlueprintName="GroceryListTests" ReferencedContainer="container:GroceryList.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="APP_TARGET_ID" BuildableName="GroceryList.app" BlueprintName="GroceryList" ReferencedContainer="container:GroceryList.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
"""


def uid(text: str) -> str:
    return hashlib.sha1(text.encode()).hexdigest()[:24].upper()


def discover() -> tuple[list[Path], list[Path], list[Path]]:
    swift = sorted(p.relative_to(SRC) for p in SRC.rglob("*.swift"))
    resources = sorted(
        p.relative_to(SRC)
        for p in SRC.rglob("*")
        if p.is_file() and p.suffix == ".json" and "Resources" in p.parts
    )
    tests = sorted(p.relative_to(TESTS) for p in TESTS.rglob("*.swift")) if TESTS.exists() else []
    return swift, resources, tests


def main() -> None:
    swift_files, resource_files, test_files = discover()
    ids = {name: uid(name) for name in [
        "project", "target", "product", "main_group", "products_group",
        "sources", "resources", "frameworks", "assets", "assets_build",
        "cfg_proj", "cfg_tgt", "dbg_proj", "rel_proj", "dbg_tgt", "rel_tgt",
        "test_target", "test_product", "test_sources", "test_frameworks",
        "test_cfg_tgt", "test_dbg_tgt", "test_rel_tgt", "test_group",
        "container_proxy", "target_dependency", "xctest_framework", "xctest_build",
    ]}

    for rel in swift_files + test_files:
        key = str(rel)
        ids[f"file:{key}"] = uid(f"file:{key}")
        ids[f"build:{key}"] = uid(f"build:{key}")
    for rel in resource_files:
        key = str(rel)
        ids[f"file:{key}"] = uid(f"file:{key}")
        ids[f"build:{key}"] = uid(f"build:{key}")

    folders: set[tuple[str, ...]] = {()}
    for rel in swift_files + resource_files:
        folders.add(tuple(rel.parts[:-1]))
    for parts in sorted(folders):
        ids[f"group:{'/'.join(parts)}"] = uid(f"group:{'/'.join(parts)}")

    def g(parts: tuple[str, ...]) -> str:
        return ids[f"group:{'/'.join(parts)}"]

    lines: list[str] = []
    a = lines.append

    a("// !$*UTF8*$!")
    a("{")
    a("\tarchiveVersion = 1;")
    a("\tclasses = {};")
    a("\tobjectVersion = 56;")
    a("\tobjects = {")

    a("\n/* Begin PBXBuildFile section */")
    for rel in swift_files:
        a(f"\t\t{ids[f'build:{rel}']} /* {rel.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ids[f'file:{rel}']}; }};")
    for rel in resource_files:
        a(f"\t\t{ids[f'build:{rel}']} /* {rel.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ids[f'file:{rel}']}; }};")
    a(f"\t\t{ids['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['assets']}; }};")
    for rel in test_files:
        a(f"\t\t{ids[f'build:{rel}']} /* {rel.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ids[f'file:{rel}']}; }};")
    a(f"\t\t{ids['xctest_build']} /* XCTest.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {ids['xctest_framework']}; }};")
    a("/* End PBXBuildFile section */")

    a("\n/* Begin PBXContainerItemProxy section */")
    a(f"\t\t{ids['container_proxy']} = {{isa = PBXContainerItemProxy; containerPortal = {ids['project']}; proxyType = 1; remoteGlobalIDString = {ids['target']}; remoteInfo = GroceryList; }};")
    a("/* End PBXContainerItemProxy section */")

    a("\n/* Begin PBXFileReference section */")
    a(f"\t\t{ids['product']} /* {PROJECT}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PROJECT}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    a(f"\t\t{ids['test_product']} /* {TEST_PROJECT}.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {TEST_PROJECT}.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for rel in swift_files:
        a(f"\t\t{ids[f'file:{rel}']} /* {rel.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {rel.name}; sourceTree = \"<group>\"; }};")
    for rel in resource_files:
        a(f"\t\t{ids[f'file:{rel}']} /* {rel.name} */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = {rel.name}; sourceTree = \"<group>\"; }};")
    for rel in test_files:
        a(f"\t\t{ids[f'file:{rel}']} /* {rel.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {rel.name}; sourceTree = \"<group>\"; }};")
    a(f"\t\t{ids['assets']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
    a(f"\t\t{ids['xctest_framework']} /* XCTest.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = XCTest.framework; path = Platform/Developer/Library/Frameworks/XCTest.framework; sourceTree = DEVELOPER_DIR; }};")
    a("/* End PBXFileReference section */")

    a("\n/* Begin PBXFrameworksBuildPhase section */")
    a(f"\t\t{ids['frameworks']} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
    a(f"\t\t{ids['test_frameworks']} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({ids['xctest_build']}); runOnlyForDeploymentPostprocessing = 0; }};")
    a("/* End PBXFrameworksBuildPhase section */")

    root_group = g(())

    a("\n/* Begin PBXGroup section */")
    test_children = ", ".join(ids[f"file:{rel}"] for rel in test_files)
    a(f"\t\t{ids['main_group']} = {{isa = PBXGroup; children = ({root_group}, {ids['test_group']}, {ids['products_group']}); sourceTree = \"<group>\"; }};")
    a(f"\t\t{ids['products_group']} = {{isa = PBXGroup; children = ({ids['product']}, {ids['test_product']}); name = Products; sourceTree = \"<group>\"; }};")
    a(f"\t\t{ids['test_group']} = {{isa = PBXGroup; children = ({test_children}); path = {TEST_PROJECT}; sourceTree = \"<group>\"; }};")

    def group_lines(parts: tuple[str, ...]) -> None:
        gid = g(parts)
        children: list[str] = []
        subfolders = sorted({p for p in folders if len(p) == len(parts) + 1 and p[: len(parts)] == parts})
        for sub in subfolders:
            group_lines(sub)
            children.append(g(sub))
        for rel in swift_files + resource_files:
            if tuple(rel.parts[:-1]) == parts:
                children.append(ids[f"file:{rel}"])
        if parts == ():
            children.append(ids["assets"])
        path = "GroceryList" if parts == () else parts[-1]
        child_csv = ", ".join(children) if children else ""
        a(f"\t\t{gid} = {{isa = PBXGroup; children = ({child_csv}); path = {path}; sourceTree = \"<group>\"; }};")

    group_lines(())
    a("/* End PBXGroup section */")

    a("\n/* Begin PBXNativeTarget section */")
    a(f"\t\t{ids['target']} = {{")
    a(f"\t\t\tisa = PBXNativeTarget; buildConfigurationList = {ids['cfg_tgt']};")
    a(f"\t\t\tbuildPhases = ({ids['sources']}, {ids['frameworks']}, {ids['resources']});")
    a(f"\t\t\tbuildRules = (); dependencies = (); name = {PROJECT}; productName = {PROJECT};")
    a(f"\t\t\tproductReference = {ids['product']}; productType = \"com.apple.product-type.application\";")
    a("\t\t};")
    if test_files:
        a(f"\t\t{ids['test_target']} = {{")
        a(f"\t\t\tisa = PBXNativeTarget; buildConfigurationList = {ids['test_cfg_tgt']};")
        a(f"\t\t\tbuildPhases = ({ids['test_sources']}, {ids['test_frameworks']});")
        a(f"\t\t\tbuildRules = (); dependencies = ({ids['target_dependency']}); name = {TEST_PROJECT}; productName = {TEST_PROJECT};")
        a(f"\t\t\tproductReference = {ids['test_product']}; productType = \"com.apple.product-type.bundle.unit-test\";")
        a("\t\t};")
    a("/* End PBXNativeTarget section */")

    a("\n/* Begin PBXProject section */")
    targets = ids['target']
    if test_files:
        targets += f", {ids['test_target']}"
    a(f"\t\t{ids['project']} = {{")
    a("\t\t\tisa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1500; LastUpgradeCheck = 1500; };")
    a(f"\t\t\tbuildConfigurationList = {ids['cfg_proj']}; compatibilityVersion = \"Xcode 14.0\";")
    a("\t\t\tdevelopmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base);")
    a(f"\t\t\tmainGroup = {ids['main_group']}; productRefGroup = {ids['products_group']};")
    a("\t\t\tprojectDirPath = \"\"; projectRoot = \"\";")
    a(f"\t\t\ttargets = ({targets});")
    a("\t\t};")
    a("/* End PBXProject section */")

    a("\n/* Begin PBXResourcesBuildPhase section */")
    res = [ids[f"build:{rel}"] for rel in resource_files] + [ids["assets_build"]]
    a(f"\t\t{ids['resources']} = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({', '.join(res)}); runOnlyForDeploymentPostprocessing = 0; }};")
    a("/* End PBXResourcesBuildPhase section */")

    a("\n/* Begin PBXSourcesBuildPhase section */")
    src = [ids[f"build:{rel}"] for rel in swift_files]
    a(f"\t\t{ids['sources']} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({', '.join(src)}); runOnlyForDeploymentPostprocessing = 0; }};")
    if test_files:
        test_src = [ids[f"build:{rel}"] for rel in test_files]
        a(f"\t\t{ids['test_sources']} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({', '.join(test_src)}); runOnlyForDeploymentPostprocessing = 0; }};")
    a("/* End PBXSourcesBuildPhase section */")

    a("\n/* Begin PBXTargetDependency section */")
    a(f"\t\t{ids['target_dependency']} = {{isa = PBXTargetDependency; target = {ids['target']}; targetProxy = {ids['container_proxy']}; }};")
    a("/* End PBXTargetDependency section */")

    test_host = f"$(BUILT_PRODUCTS_DIR)/{PROJECT}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{PROJECT}"
    a("\n/* Begin XCBuildConfiguration section */")
    a(f"\t\t{ids['dbg_proj']} = {{isa = XCBuildConfiguration; name = Debug; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_TESTABILITY = YES; GCC_OPTIMIZATION_LEVEL = 0; IPHONEOS_DEPLOYMENT_TARGET = 17.0; MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE; ONLY_ACTIVE_ARCH = YES; SDKROOT = iphoneos; SWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\"; }}; }};")
    a(f"\t\t{ids['rel_proj']} = {{isa = XCBuildConfiguration; name = Release; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\"; ENABLE_NS_ASSERTIONS = NO; IPHONEOS_DEPLOYMENT_TARGET = 17.0; MTL_ENABLE_DEBUG_INFO = NO; SDKROOT = iphoneos; SWIFT_COMPILATION_MODE = wholemodule; SWIFT_OPTIMIZATION_LEVEL = \"-O\"; VALIDATE_PRODUCT = YES; }}; }};")
    a(f"\t\t{ids['dbg_tgt']} = {{isa = XCBuildConfiguration; name = Debug; buildSettings = {{ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = \"Grocery List\"; INFOPLIST_KEY_NSCameraUsageDescription = \"Scan QR codes to import shared grocery lists.\"; INFOPLIST_KEY_UILaunchScreen_Generation = YES; IPHONEOS_DEPLOYMENT_TARGET = 17.0; PRODUCT_BUNDLE_IDENTIFIER = com.grocerylist.app; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; }}; }};")
    a(f"\t\t{ids['rel_tgt']} = {{isa = XCBuildConfiguration; name = Release; buildSettings = {{ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = \"Grocery List\"; INFOPLIST_KEY_NSCameraUsageDescription = \"Scan QR codes to import shared grocery lists.\"; INFOPLIST_KEY_UILaunchScreen_Generation = YES; IPHONEOS_DEPLOYMENT_TARGET = 17.0; PRODUCT_BUNDLE_IDENTIFIER = com.grocerylist.app; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; }}; }};")
    if test_files:
        a(f"\t\t{ids['test_dbg_tgt']} = {{isa = XCBuildConfiguration; name = Debug; buildSettings = {{BUNDLE_LOADER = \"{test_host}\"; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 17.0; LD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/Frameworks @loader_path/Frameworks\"; PRODUCT_BUNDLE_IDENTIFIER = com.grocerylist.app.tests; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; TEST_HOST = \"{test_host}\"; }}; }};")
        a(f"\t\t{ids['test_rel_tgt']} = {{isa = XCBuildConfiguration; name = Release; buildSettings = {{BUNDLE_LOADER = \"{test_host}\"; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 17.0; LD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/Frameworks @loader_path/Frameworks\"; PRODUCT_BUNDLE_IDENTIFIER = com.grocerylist.app.tests; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; TEST_HOST = \"{test_host}\"; }}; }};")
    a("/* End XCBuildConfiguration section */")

    a("\n/* Begin XCConfigurationList section */")
    a(f"\t\t{ids['cfg_proj']} = {{isa = XCConfigurationList; buildConfigurations = ({ids['dbg_proj']}, {ids['rel_proj']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    a(f"\t\t{ids['cfg_tgt']} = {{isa = XCConfigurationList; buildConfigurations = ({ids['dbg_tgt']}, {ids['rel_tgt']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    if test_files:
        a(f"\t\t{ids['test_cfg_tgt']} = {{isa = XCConfigurationList; buildConfigurations = ({ids['test_dbg_tgt']}, {ids['test_rel_tgt']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    a("/* End XCConfigurationList section */")

    a("\t};")
    a(f"\trootObject = {ids['project']};")
    a("}")

    out_dir = IOS_ROOT / f"{PROJECT}.xcodeproj"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "project.pbxproj"
    out_file.write_text("\n".join(lines) + "\n")
    print(f"Wrote {out_file} ({len(swift_files)} app Swift, {len(test_files)} test Swift, {len(resource_files)} JSON)")

    scheme_dir = out_dir / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    scheme_path = scheme_dir / f"{PROJECT}.xcscheme"
    scheme = SCHEME_TEMPLATE.replace("APP_TARGET_ID", ids["target"])
    if test_files:
        scheme = scheme.replace("TEST_TARGET_ID", ids["test_target"])
    else:
        scheme = scheme.replace('<BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">\n            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="TEST_TARGET_ID" BuildableName="GroceryListTests.xctest" BlueprintName="GroceryListTests" ReferencedContainer="container:GroceryList.xcodeproj"/>\n         </BuildActionEntry>\n', "")
        scheme = scheme.replace("""   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="TEST_TARGET_ID" BuildableName="GroceryListTests.xctest" BlueprintName="GroceryListTests" ReferencedContainer="container:GroceryList.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
""", "")
    scheme_path.write_text(scheme)
    print(f"Wrote {scheme_path}")


if __name__ == "__main__":
    main()
