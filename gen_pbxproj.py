#!/usr/bin/env python3
"""Generates Keel.xcodeproj/project.pbxproj from the current file layout.
Re-run after adding/removing Swift files under Keel/ or KeelTests/.
Uses the classic PBXFileReference/PBXBuildFile format (no synchronized groups)
for maximum compatibility.
"""
import os
import hashlib
import itertools

ROOT = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(ROOT, "Keel")
TESTS_DIR = os.path.join(ROOT, "KeelTests")
PBXPROJ_PATH = os.path.join(ROOT, "Keel.xcodeproj", "project.pbxproj")

_counter = itertools.count(1)


def make_id(name):
    h = hashlib.sha1(name.encode()).hexdigest().upper()
    return h[:24]


def collect_swift_files(base_dir):
    files = []
    for dirpath, _dirnames, filenames in sorted(os.walk(base_dir)):
        for fn in sorted(filenames):
            if fn.endswith(".swift"):
                rel = os.path.relpath(os.path.join(dirpath, fn), base_dir)
                files.append(rel)
    return files


app_swift = collect_swift_files(APP_DIR)
test_swift = collect_swift_files(TESTS_DIR)

# ---- object id allocation ----
ids = {}


def oid(key):
    if key not in ids:
        ids[key] = make_id(key)
    return ids[key]


# fixed top-level ids
PROJECT_ID = oid("project")
MAIN_GROUP = oid("mainGroup")
PRODUCTS_GROUP = oid("productsGroup")
KEEL_GROUP = oid("keelGroup")
TESTS_GROUP = oid("testsGroup")

APP_TARGET = oid("appTarget")
TEST_TARGET = oid("testTarget")

APP_PRODUCT_REF = oid("appProductRef")
TEST_PRODUCT_REF = oid("testProductRef")

APP_CONFIG_LIST = oid("appConfigList")
TEST_CONFIG_LIST = oid("testConfigList")
PROJECT_CONFIG_LIST = oid("projectConfigList")

APP_DEBUG_CONFIG = oid("appDebugConfig")
APP_RELEASE_CONFIG = oid("appReleaseConfig")
TEST_DEBUG_CONFIG = oid("testDebugConfig")
TEST_RELEASE_CONFIG = oid("testReleaseConfig")
PROJECT_DEBUG_CONFIG = oid("projectDebugConfig")
PROJECT_RELEASE_CONFIG = oid("projectReleaseConfig")

APP_SOURCES_PHASE = oid("appSourcesPhase")
APP_RESOURCES_PHASE = oid("appResourcesPhase")
APP_FRAMEWORKS_PHASE = oid("appFrameworksPhase")
TEST_SOURCES_PHASE = oid("testSourcesPhase")
TEST_FRAMEWORKS_PHASE = oid("testFrameworksPhase")

TEST_DEPENDENCY = oid("testDependency")
TEST_CONTAINER_PROXY = oid("testContainerProxy")

ASSETS_FILE_REF = oid("assetsFileRef")

file_refs = {}
build_files = {}

for rel in app_swift:
    file_refs[("app", rel)] = oid(f"appFileRef::{rel}")
    build_files[("app", rel)] = oid(f"appBuildFile::{rel}")

for rel in test_swift:
    file_refs[("test", rel)] = oid(f"testFileRef::{rel}")
    build_files[("test", rel)] = oid(f"testBuildFile::{rel}")


def group_id_for(dirpath):
    return oid(f"group::{dirpath}")


# Build nested group structure for app files, mirroring folder layout
def build_group_tree(files, root_group_id, root_name):
    """Returns list of PBXGroup entries and a dict dirpath -> group id."""
    dirs = set()
    for rel in files:
        d = os.path.dirname(rel)
        parts = d.split(os.sep) if d else []
        for i in range(len(parts)):
            dirs.add(os.sep.join(parts[: i + 1]))
    groups = {}
    for d in sorted(dirs):
        groups[d] = group_id_for(f"{root_name}/{d}")
    return groups


app_dirs = build_group_tree(app_swift, KEEL_GROUP, "Keel")

lines = []


def emit(s=""):
    lines.append(s)


emit("// !$*UTF8*$!")
emit("{")
emit("\tarchiveVersion = 1;")
emit("\tclasses = {")
emit("\t};")
emit("\tobjectVersion = 56;")
emit("\tobjects = {")

# ---------------- PBXBuildFile ----------------
emit()
emit("/* Begin PBXBuildFile section */")
for rel in app_swift:
    emit(f"\t\t{build_files[('app', rel)]} /* {os.path.basename(rel)} in Sources */ = "
         f"{{isa = PBXBuildFile; fileRef = {file_refs[('app', rel)]} /* {os.path.basename(rel)} */; }};")
for rel in test_swift:
    emit(f"\t\t{build_files[('test', rel)]} /* {os.path.basename(rel)} in Sources */ = "
         f"{{isa = PBXBuildFile; fileRef = {file_refs[('test', rel)]} /* {os.path.basename(rel)} */; }};")
ASSETS_BUILD_FILE = oid("assetsBuildFile")
emit(f"\t\t{ASSETS_BUILD_FILE} /* Assets.xcassets in Resources */ = "
     f"{{isa = PBXBuildFile; fileRef = {ASSETS_FILE_REF} /* Assets.xcassets */; }};")
emit("/* End PBXBuildFile section */")

# ---------------- PBXContainerItemProxy ----------------
emit()
emit("/* Begin PBXContainerItemProxy section */")
emit(f"\t\t{TEST_CONTAINER_PROXY} /* PBXContainerItemProxy */ = {{")
emit("\t\t\tisa = PBXContainerItemProxy;")
emit(f"\t\t\tcontainerPortal = {PROJECT_ID} /* Project object */;")
emit("\t\t\tproxyType = 1;")
emit(f"\t\t\tremoteGlobalIDString = {APP_TARGET};")
emit("\t\t\tremoteInfo = Keel;")
emit("\t\t};")
emit("/* End PBXContainerItemProxy section */")

# ---------------- PBXFileReference ----------------
emit()
emit("/* Begin PBXFileReference section */")
emit(f"\t\t{APP_PRODUCT_REF} /* Keel.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; "
     f"includeInIndex = 0; path = Keel.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
emit(f"\t\t{TEST_PRODUCT_REF} /* KeelTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; "
     f"includeInIndex = 0; path = KeelTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
for rel in app_swift:
    fname = os.path.basename(rel)
    emit(f"\t\t{file_refs[('app', rel)]} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
         f"path = {fname}; sourceTree = \"<group>\"; }};")
for rel in test_swift:
    fname = os.path.basename(rel)
    emit(f"\t\t{file_refs[('test', rel)]} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
         f"path = {fname}; sourceTree = \"<group>\"; }};")
emit(f"\t\t{ASSETS_FILE_REF} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; "
     f"path = Assets.xcassets; sourceTree = \"<group>\"; }};")
emit("/* End PBXFileReference section */")

# ---------------- PBXFrameworksBuildPhase ----------------
emit()
emit("/* Begin PBXFrameworksBuildPhase section */")
emit(f"\t\t{APP_FRAMEWORKS_PHASE} /* Frameworks */ = {{")
emit("\t\t\tisa = PBXFrameworksBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit(f"\t\t{TEST_FRAMEWORKS_PHASE} /* Frameworks */ = {{")
emit("\t\t\tisa = PBXFrameworksBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit("/* End PBXFrameworksBuildPhase section */")

# ---------------- PBXGroup ----------------
emit()
emit("/* Begin PBXGroup section */")

# leaf/subdirectory groups for app files
# map dirpath -> list of (kind, rel) direct children + subdir names
children_map = {}
for rel in app_swift:
    d = os.path.dirname(rel)
    children_map.setdefault(d, []).append(("file", rel))
for d in app_dirs:
    parent = os.sep.join(d.split(os.sep)[:-1])
    children_map.setdefault(parent, []).append(("dir", d))

def emit_group(dirpath, group_id, display_name):
    emit(f"\t\t{group_id} /* {display_name} */ = {{")
    emit("\t\t\tisa = PBXGroup;")
    emit("\t\t\tchildren = (")
    for kind, val in sorted(children_map.get(dirpath, [])):
        if kind == "file":
            emit(f"\t\t\t\t{file_refs[('app', val)]} /* {os.path.basename(val)} */,")
        else:
            emit(f"\t\t\t\t{app_dirs[val]} /* {os.path.basename(val)} */,")
    emit("\t\t\t);")
    emit(f"\t\t\tpath = {display_name};")
    emit("\t\t\tsourceTree = \"<group>\";")
    emit("\t\t};")

for d, gid in sorted(app_dirs.items()):
    emit_group(d, gid, os.path.basename(d))

# top level Keel group (root, no path attr needed beyond name)
emit(f"\t\t{KEEL_GROUP} /* Keel */ = {{")
emit("\t\t\tisa = PBXGroup;")
emit("\t\t\tchildren = (")
for kind, val in sorted(children_map.get("", [])):
    if kind == "file":
        emit(f"\t\t\t\t{file_refs[('app', val)]} /* {os.path.basename(val)} */,")
    else:
        emit(f"\t\t\t\t{app_dirs[val]} /* {os.path.basename(val)} */,")
emit(f"\t\t\t\t{ASSETS_FILE_REF} /* Assets.xcassets */,")
emit("\t\t\t);")
emit("\t\t\tpath = Keel;")
emit("\t\t\tsourceTree = \"<group>\";")
emit("\t\t};")

# tests group (flat)
emit(f"\t\t{TESTS_GROUP} /* KeelTests */ = {{")
emit("\t\t\tisa = PBXGroup;")
emit("\t\t\tchildren = (")
for rel in sorted(test_swift):
    emit(f"\t\t\t\t{file_refs[('test', rel)]} /* {os.path.basename(rel)} */,")
emit("\t\t\t);")
emit("\t\t\tpath = KeelTests;")
emit("\t\t\tsourceTree = \"<group>\";")
emit("\t\t};")

# products group
emit(f"\t\t{PRODUCTS_GROUP} /* Products */ = {{")
emit("\t\t\tisa = PBXGroup;")
emit("\t\t\tchildren = (")
emit(f"\t\t\t\t{APP_PRODUCT_REF} /* Keel.app */,")
emit(f"\t\t\t\t{TEST_PRODUCT_REF} /* KeelTests.xctest */,")
emit("\t\t\t);")
emit("\t\t\tname = Products;")
emit("\t\t\tsourceTree = \"<group>\";")
emit("\t\t};")

# main group
emit(f"\t\t{MAIN_GROUP} = {{")
emit("\t\t\tisa = PBXGroup;")
emit("\t\t\tchildren = (")
emit(f"\t\t\t\t{KEEL_GROUP} /* Keel */,")
emit(f"\t\t\t\t{TESTS_GROUP} /* KeelTests */,")
emit(f"\t\t\t\t{PRODUCTS_GROUP} /* Products */,")
emit("\t\t\t);")
emit("\t\t\tsourceTree = \"<group>\";")
emit("\t\t};")
emit("/* End PBXGroup section */")

# ---------------- PBXNativeTarget ----------------
emit()
emit("/* Begin PBXNativeTarget section */")
emit(f"\t\t{APP_TARGET} /* Keel */ = {{")
emit("\t\t\tisa = PBXNativeTarget;")
emit(f"\t\t\tbuildConfigurationList = {APP_CONFIG_LIST} /* Build configuration list for PBXNativeTarget \"Keel\" */;")
emit("\t\t\tbuildPhases = (")
emit(f"\t\t\t\t{APP_SOURCES_PHASE} /* Sources */,")
emit(f"\t\t\t\t{APP_FRAMEWORKS_PHASE} /* Frameworks */,")
emit(f"\t\t\t\t{APP_RESOURCES_PHASE} /* Resources */,")
emit("\t\t\t);")
emit("\t\t\tbuildRules = (")
emit("\t\t\t);")
emit("\t\t\tdependencies = (")
emit("\t\t\t);")
emit("\t\t\tname = Keel;")
emit("\t\t\tproductName = Keel;")
emit(f"\t\t\tproductReference = {APP_PRODUCT_REF} /* Keel.app */;")
emit("\t\t\tproductType = \"com.apple.product-type.application\";")
emit("\t\t};")
emit(f"\t\t{TEST_TARGET} /* KeelTests */ = {{")
emit("\t\t\tisa = PBXNativeTarget;")
emit(f"\t\t\tbuildConfigurationList = {TEST_CONFIG_LIST} /* Build configuration list for PBXNativeTarget \"KeelTests\" */;")
emit("\t\t\tbuildPhases = (")
emit(f"\t\t\t\t{TEST_SOURCES_PHASE} /* Sources */,")
emit(f"\t\t\t\t{TEST_FRAMEWORKS_PHASE} /* Frameworks */,")
emit("\t\t\t);")
emit("\t\t\tbuildRules = (")
emit("\t\t\t);")
emit("\t\t\tdependencies = (")
emit(f"\t\t\t\t{TEST_DEPENDENCY} /* PBXTargetDependency */,")
emit("\t\t\t);")
emit("\t\t\tname = KeelTests;")
emit("\t\t\tproductName = KeelTests;")
emit(f"\t\t\tproductReference = {TEST_PRODUCT_REF} /* KeelTests.xctest */;")
emit("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
emit("\t\t};")
emit("/* End PBXNativeTarget section */")

# ---------------- PBXProject ----------------
emit()
emit("/* Begin PBXProject section */")
emit(f"\t\t{PROJECT_ID} /* Project object */ = {{")
emit("\t\t\tisa = PBXProject;")
emit("\t\t\tattributes = {")
emit("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
emit("\t\t\t\tLastSwiftUpdateCheck = 1620;")
emit("\t\t\t\tLastUpgradeCheck = 1620;")
emit("\t\t\t\tTargetAttributes = {")
emit(f"\t\t\t\t\t{APP_TARGET} = {{")
emit("\t\t\t\t\t\tCreatedOnToolsVersion = 16.2;")
emit("\t\t\t\t\t};")
emit(f"\t\t\t\t\t{TEST_TARGET} = {{")
emit("\t\t\t\t\t\tCreatedOnToolsVersion = 16.2;")
emit(f"\t\t\t\t\t\tTestTargetID = {APP_TARGET};")
emit("\t\t\t\t\t};")
emit("\t\t\t\t};")
emit("\t\t\t};")
emit(f"\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST} /* Build configuration list for PBXProject \"Keel\" */;")
emit("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
emit("\t\t\tdevelopmentRegion = en;")
emit("\t\t\thasScannedForEncodings = 0;")
emit("\t\t\tknownRegions = (")
emit("\t\t\t\ten,")
emit("\t\t\t\tBase,")
emit("\t\t\t);")
emit(f"\t\t\tmainGroup = {MAIN_GROUP};")
emit(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP} /* Products */;")
emit("\t\t\tprojectDirPath = \"\";")
emit("\t\t\tprojectRoot = \"\";")
emit("\t\t\ttargets = (")
emit(f"\t\t\t\t{APP_TARGET} /* Keel */,")
emit(f"\t\t\t\t{TEST_TARGET} /* KeelTests */,")
emit("\t\t\t);")
emit("\t\t};")
emit("/* End PBXProject section */")

# ---------------- PBXResourcesBuildPhase ----------------
emit()
emit("/* Begin PBXResourcesBuildPhase section */")
emit(f"\t\t{APP_RESOURCES_PHASE} /* Resources */ = {{")
emit("\t\t\tisa = PBXResourcesBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
emit(f"\t\t\t\t{ASSETS_BUILD_FILE} /* Assets.xcassets in Resources */,")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit("/* End PBXResourcesBuildPhase section */")

# ---------------- PBXSourcesBuildPhase ----------------
emit()
emit("/* Begin PBXSourcesBuildPhase section */")
emit(f"\t\t{APP_SOURCES_PHASE} /* Sources */ = {{")
emit("\t\t\tisa = PBXSourcesBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
for rel in app_swift:
    emit(f"\t\t\t\t{build_files[('app', rel)]} /* {os.path.basename(rel)} in Sources */,")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit(f"\t\t{TEST_SOURCES_PHASE} /* Sources */ = {{")
emit("\t\t\tisa = PBXSourcesBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
for rel in test_swift:
    emit(f"\t\t\t\t{build_files[('test', rel)]} /* {os.path.basename(rel)} in Sources */,")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit("/* End PBXSourcesBuildPhase section */")

# ---------------- PBXTargetDependency ----------------
emit()
emit("/* Begin PBXTargetDependency section */")
emit(f"\t\t{TEST_DEPENDENCY} /* PBXTargetDependency */ = {{")
emit("\t\t\tisa = PBXTargetDependency;")
emit(f"\t\t\ttarget = {APP_TARGET} /* Keel */;")
emit(f"\t\t\ttargetProxy = {TEST_CONTAINER_PROXY} /* PBXContainerItemProxy */;")
emit("\t\t};")
emit("/* End PBXTargetDependency section */")

# ---------------- XCBuildConfiguration ----------------
emit()
emit("/* Begin XCBuildConfiguration section */")

common_debug = """\
\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\tCLANG_WARN_COMMA = YES;
\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\tENABLE_TESTABILITY = YES;
\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t"DEBUG=1",
\t\t\t\t"$(inherited)",
\t\t\t);
\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\tMTL_FAST_MATH = YES;
\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\tSDKROOT = iphoneos;
\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\tSWIFT_VERSION = 5.0;
"""

common_release = common_debug.replace(
    'GCC_PREPROCESSOR_DEFINITIONS = (\n\t\t\t\t"DEBUG=1",\n\t\t\t\t"$(inherited)",\n\t\t\t);\n', ""
).replace("ENABLE_TESTABILITY = YES;\n", "").replace(
    "GCC_OPTIMIZATION_LEVEL = 0;\n", ""
).replace(
    "ONLY_ACTIVE_ARCH = YES;\n", "VALIDATE_PRODUCT = YES;\n"
).replace(
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;\n\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";\n',
    'SWIFT_COMPILATION_MODE = wholemodule;\n'
).replace("DEBUG_INFORMATION_FORMAT = dwarf;\n", 'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";\n')

emit(f"\t\t{PROJECT_DEBUG_CONFIG} /* Debug */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(common_debug.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Debug;")
emit("\t\t};")
emit(f"\t\t{PROJECT_RELEASE_CONFIG} /* Release */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(common_release.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Release;")
emit("\t\t};")

app_target_settings = """\
\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t"$(inherited)",
\t\t\t\t"@executable_path/Frameworks",
\t\t\t);
\t\t\tMARKETING_VERSION = 1.0;
\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.andrewkolpack.Keel;
\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
"""

emit(f"\t\t{APP_DEBUG_CONFIG} /* Debug */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(app_target_settings.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Debug;")
emit("\t\t};")
emit(f"\t\t{APP_RELEASE_CONFIG} /* Release */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(app_target_settings.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Release;")
emit("\t\t};")

test_target_settings = """\
\t\t\tALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;
\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.andrewkolpack.KeelTests;
\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Keel.app/Keel";
"""

emit(f"\t\t{TEST_DEBUG_CONFIG} /* Debug */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(test_target_settings.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Debug;")
emit("\t\t};")
emit(f"\t\t{TEST_RELEASE_CONFIG} /* Release */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(test_target_settings.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Release;")
emit("\t\t};")
emit("/* End XCBuildConfiguration section */")

# ---------------- XCConfigurationList ----------------
emit()
emit("/* Begin XCConfigurationList section */")
emit(f"\t\t{PROJECT_CONFIG_LIST} /* Build configuration list for PBXProject \"Keel\" */ = {{")
emit("\t\t\tisa = XCConfigurationList;")
emit("\t\t\tbuildConfigurations = (")
emit(f"\t\t\t\t{PROJECT_DEBUG_CONFIG} /* Debug */,")
emit(f"\t\t\t\t{PROJECT_RELEASE_CONFIG} /* Release */,")
emit("\t\t\t);")
emit("\t\t\tdefaultConfigurationIsVisible = 0;")
emit("\t\t\tdefaultConfigurationName = Release;")
emit("\t\t};")
emit(f"\t\t{APP_CONFIG_LIST} /* Build configuration list for PBXNativeTarget \"Keel\" */ = {{")
emit("\t\t\tisa = XCConfigurationList;")
emit("\t\t\tbuildConfigurations = (")
emit(f"\t\t\t\t{APP_DEBUG_CONFIG} /* Debug */,")
emit(f"\t\t\t\t{APP_RELEASE_CONFIG} /* Release */,")
emit("\t\t\t);")
emit("\t\t\tdefaultConfigurationIsVisible = 0;")
emit("\t\t\tdefaultConfigurationName = Release;")
emit("\t\t};")
emit(f"\t\t{TEST_CONFIG_LIST} /* Build configuration list for PBXNativeTarget \"KeelTests\" */ = {{")
emit("\t\t\tisa = XCConfigurationList;")
emit("\t\t\tbuildConfigurations = (")
emit(f"\t\t\t\t{TEST_DEBUG_CONFIG} /* Debug */,")
emit(f"\t\t\t\t{TEST_RELEASE_CONFIG} /* Release */,")
emit("\t\t\t);")
emit("\t\t\tdefaultConfigurationIsVisible = 0;")
emit("\t\t\tdefaultConfigurationName = Release;")
emit("\t\t};")
emit("/* End XCConfigurationList section */")

emit("\t};")
emit(f"\trootObject = {PROJECT_ID} /* Project object */;")
emit("}")
emit("")

with open(PBXPROJ_PATH, "w") as f:
    f.write("\n".join(lines))

SCHEME_DIR = os.path.join(ROOT, "Keel.xcodeproj", "xcshareddata", "xcschemes")
os.makedirs(SCHEME_DIR, exist_ok=True)
SCHEME_PATH = os.path.join(SCHEME_DIR, "Keel.xcscheme")

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1620"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{APP_TARGET}"
               BuildableName = "Keel.app"
               BlueprintName = "Keel"
               ReferencedContainer = "container:Keel.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{TEST_TARGET}"
               BuildableName = "KeelTests.xctest"
               BlueprintName = "KeelTests"
               ReferencedContainer = "container:Keel.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{TEST_TARGET}"
               BuildableName = "KeelTests.xctest"
               BlueprintName = "KeelTests"
               ReferencedContainer = "container:Keel.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{APP_TARGET}"
            BuildableName = "Keel.app"
            BlueprintName = "Keel"
            ReferencedContainer = "container:Keel.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{APP_TARGET}"
            BuildableName = "Keel.app"
            BlueprintName = "Keel"
            ReferencedContainer = "container:Keel.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

with open(SCHEME_PATH, "w") as f:
    f.write(scheme)

print(f"Wrote {PBXPROJ_PATH}")
print(f"Wrote {SCHEME_PATH}")
print(f"App files: {app_swift}")
print(f"Test files: {test_swift}")
