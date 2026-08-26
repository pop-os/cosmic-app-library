name := 'cosmic-app-library'
appid := 'com.system76.CosmicAppLibrary'

export APP_ID := 'com.system76.CosmicAppLibrary'
export LOCKSTEP_XML_PATH := absolute_path('vendor/atspi-common/xml')

rootdir := ''
prefix := '/usr'

base-dir := absolute_path(clean(rootdir / prefix))
cargo-target-dir := env('CARGO_TARGET_DIR', 'target')

mod cargo 'cargo.just'

bin-src := cargo-target-dir / 'release' / name
bin-dst := base-dir / 'bin' / name

appdata := appid + '.metainfo.xml'
appdata-dst := base-dir / 'share' / 'appdata' / appdata

desktop := appid + '.desktop'
desktop-dst := base-dir / 'share' / 'applications' / desktop

icon := appid + '.svg'
icon-dst := base-dir / 'share' / 'icons' / 'hicolor' / 'scalable' / 'apps' / icon

# Default recipe which runs `just build-release`
default: build-release

# Runs `cargo clean`
clean: cargo::clean

# `cargo clean` and removes vendored dependencies
clean-dist: cargo::clean-dist

# Compiles with debug profile
build-debug *args: (cargo::build-debug args)

# Compiles with release profile
build-release *args: (cargo::build-release args)

# Compiles release profile with vendored dependencies
build-vendored *args: (cargo::build-vendored args)

# Compiles and runs a standalone instance
run *args: (cargo::run args)

# Runs a clippy check
check *args: (cargo::check args)

# Runs a clippy check with JSON message format
check-json: (check '--message-format=json')

# Installs files
install:
    install -Dm0755 {{bin-src}} {{bin-dst}}
    install -Dm0644 {{ 'target' / 'xdgen' / desktop }} {{desktop-dst}}
    install -Dm0644 {{ 'target' / 'xdgen' / appdata }} {{appdata-dst}}
    install -Dm0644 {{ 'data' / 'icons' / icon }} {{icon-dst}}

# Uninstalls installed files
uninstall:
    rm {{bin-dst}} {{desktop-dst}} {{appdata-dst}} {{icon-dst}}

# Vendor dependencies locally
vendor: cargo::vendor

# Extracts vendored dependencies
vendor-extract: cargo::vendor-extract

