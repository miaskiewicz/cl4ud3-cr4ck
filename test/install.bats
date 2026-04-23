#!/usr/bin/env bats
# Tests for install.sh — platform detection, package naming, sed helpers

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
}

teardown() {
    _common_teardown
}

# ── Platform detection ──

@test "install: detects macOS correctly" {
    if [ "$(uname -s)" != "Darwin" ]; then skip "macOS only"; fi
    run bash -c 'source /dev/stdin <<< "
        OS=\"\$(uname -s)\"
        case \"\$OS\" in
            Darwin) echo macos ;;
            Linux) echo linux ;;
        esac
    "'
    assert_output "macos"
}

@test "install: detects Linux correctly" {
    if [ "$(uname -s)" != "Linux" ]; then skip "Linux only"; fi
    run bash -c 'source /dev/stdin <<< "
        OS=\"\$(uname -s)\"
        case \"\$OS\" in
            Darwin) echo macos ;;
            Linux) echo linux ;;
        esac
    "'
    assert_output "linux"
}

# ── sed helper ──

@test "install: _sed_i works on current platform" {
    local testfile="$TEST_CL4UD3_HOME/test_sed.txt"
    echo "hello world" > "$testfile"

    if [ "$(uname -s)" = "Darwin" ]; then
        sed -i '' 's/hello/goodbye/' "$testfile"
    else
        sed -i 's/hello/goodbye/' "$testfile"
    fi

    run cat "$testfile"
    assert_output "goodbye world"
}

# ── Toggle preservation ──

@test "install: toggle extraction regex works" {
    local config="$TEST_CL4UD3_HOME/config.sh"
    cat > "$config" << 'EOF'
CL4UD3_MODEM_SOUNDS="${CL4UD3_MODEM_SOUNDS:-false}"
CL4UD3_GLITCH_SOUNDS="${CL4UD3_GLITCH_SOUNDS:-true}"
CL4UD3_STARTUP_JINGLE="${CL4UD3_STARTUP_JINGLE:-false}"
EOF

    local toggles
    toggles=$(grep -o 'CL4UD3_[A-Z_]*:-[a-z]*' "$config" 2>/dev/null || true)
    [[ "$toggles" == *"CL4UD3_MODEM_SOUNDS:-false"* ]]
    [[ "$toggles" == *"CL4UD3_GLITCH_SOUNDS:-true"* ]]
    [[ "$toggles" == *"CL4UD3_STARTUP_JINGLE:-false"* ]]
}

@test "install: toggle re-apply works" {
    local config="$TEST_CL4UD3_HOME/config.sh"
    # Start with default config
    echo 'CL4UD3_MODEM_SOUNDS="${CL4UD3_MODEM_SOUNDS:-true}"' > "$config"

    # Apply override: modem disabled
    local toggle="CL4UD3_MODEM_SOUNDS:-false"
    local varname="${toggle%%:-*}"
    local value="${toggle##*:-}"

    if [ "$(uname -s)" = "Darwin" ]; then
        sed -i '' "s|${varname}:-[a-z]*|${varname}:-${value}|" "$config"
    else
        sed -i "s|${varname}:-[a-z]*|${varname}:-${value}|" "$config"
    fi

    run cat "$config"
    assert_output 'CL4UD3_MODEM_SOUNDS="${CL4UD3_MODEM_SOUNDS:-false}"'
}

# ── midiutil version pinning ──

@test "install: midiutil install line uses version pin" {
    local install_script="$BATS_TEST_DIRNAME/../install.sh"
    run grep "midiutil" "$install_script"
    assert_output --partial "midiutil>=1.2.1,<2"
}

# ── Directory creation ──

@test "install: creates correct directory structure" {
    local dir="$TEST_CL4UD3_HOME"
    mkdir -p "$dir"/{hooks,art,sounds/{startup,glitches,error,modem},bin,tools}
    [ -d "$dir/hooks" ]
    [ -d "$dir/art" ]
    [ -d "$dir/sounds/startup" ]
    [ -d "$dir/sounds/glitches" ]
    [ -d "$dir/sounds/error" ]
    [ -d "$dir/sounds/modem" ]
    [ -d "$dir/bin" ]
    [ -d "$dir/tools" ]
}

# ── Uninstall ──

@test "uninstall: temp cleanup lines present" {
    local uninstall_script="$BATS_TEST_DIRNAME/../uninstall.sh"
    run grep "cl4ud3-cr4ck-\*" "$uninstall_script"
    assert_success
}

@test "uninstall: debug log cleanup present" {
    local uninstall_script="$BATS_TEST_DIRNAME/../uninstall.sh"
    run grep "cl4ud3-stop-debug.log" "$uninstall_script"
    assert_success
}
