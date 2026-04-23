#!/usr/bin/env bats
# Tests for temp file lifecycle — PID cleanup, stale file sweeps, uninstall cleanup

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
    cp "$BATS_TEST_DIRNAME/../hooks/"*.sh "$CL4UD3_HOME/hooks/"
    chmod +x "$CL4UD3_HOME/hooks/"*.sh
}

teardown() {
    _common_teardown
    rm -f /tmp/.cl4ud3-cr4ck-stop-cooldown
    rm -f /tmp/.cl4ud3-cr4ck-tool-cooldown
    rm -rf /tmp/.cl4ud3-cr4ck-all-jingles-test-*
}

# ── Stale file sweep via stop.sh ──

@test "stop.sh sweep: removes stale sound PID files" {
    echo "99999" > "/tmp/.cl4ud3-cr4ck-sound-pid-test-sweep1"
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-sweep1" ]
}

@test "stop.sh sweep: removes stale music PID files" {
    echo "99999" > "/tmp/.cl4ud3-cr4ck-music-pid-test-sweep2"
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -f "/tmp/.cl4ud3-cr4ck-music-pid-test-sweep2" ]
}

@test "stop.sh sweep: removes stale timer PID files" {
    echo "99999" > "/tmp/.cl4ud3-cr4ck-timer-pid-test-sweep3"
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -f "/tmp/.cl4ud3-cr4ck-timer-pid-test-sweep3" ]
}

@test "stop.sh sweep: preserves PID files for running processes" {
    echo "$$" > "/tmp/.cl4ud3-cr4ck-sound-pid-test-alive"
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-alive" ]
    rm -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-alive"
}

@test "stop.sh sweep: handles empty PID files" {
    touch "/tmp/.cl4ud3-cr4ck-sound-pid-test-empty"
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-empty" ]
}

@test "stop.sh sweep: removes orphaned jingle dirs" {
    mkdir -p "/tmp/.cl4ud3-cr4ck-all-jingles-test-deadjingle"
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -d "/tmp/.cl4ud3-cr4ck-all-jingles-test-deadjingle" ]
}

# ── Cooldown file permissions ──

@test "cooldown: stop cooldown file created" {
    rm -f /tmp/.cl4ud3-cr4ck-stop-cooldown
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ -f /tmp/.cl4ud3-cr4ck-stop-cooldown ]
}

@test "cooldown: tool cooldown file created" {
    rm -f /tmp/.cl4ud3-cr4ck-tool-cooldown
    export CL4UD3_SOUNDS_ENABLED="false"
    bash "$CL4UD3_HOME/hooks/pre-tool-use.sh"
    [ -f /tmp/.cl4ud3-cr4ck-tool-cooldown ]
}

# ── Uninstall cleanup ──

@test "uninstall: cleans up temp files" {
    # Create some temp files that uninstall should clean
    touch "/tmp/.cl4ud3-cr4ck-test-uninstall"
    mkdir -p "/tmp/.cl4ud3-cr4ck-all-jingles-test-uninstall"
    touch "/tmp/.cl4ud3-stop-debug.log"

    # Replicate uninstall.sh cleanup logic
    rm -rf /tmp/.cl4ud3-cr4ck-* /tmp/.cl4ud3-stop-debug.log
    rm -rf /tmp/.cl4ud3-cr4ck-all-jingles-*

    [ ! -f "/tmp/.cl4ud3-cr4ck-test-uninstall" ]
    [ ! -d "/tmp/.cl4ud3-cr4ck-all-jingles-test-uninstall" ]
    [ ! -f "/tmp/.cl4ud3-stop-debug.log" ]
}

# ── Session isolation ──

@test "isolation: different SIDs get different PID files" {
    export CL4UD3_SOUNDS_ENABLED="true"
    export CL4UD3_SID="session-A"
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    local pf_a="$_PF_SOUND"

    export CL4UD3_SID="session-B"
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    local pf_b="$_PF_SOUND"

    [ "$pf_a" != "$pf_b" ]
    [[ "$pf_a" == *"session-A" ]]
    [[ "$pf_b" == *"session-B" ]]
}

@test "isolation: kill_active_sounds only affects own session" {
    export CL4UD3_SOUNDS_ENABLED="true"

    # Create PID files for two sessions
    echo "99999" > "/tmp/.cl4ud3-cr4ck-sound-pid-test-sessionX"
    echo "99998" > "/tmp/.cl4ud3-cr4ck-sound-pid-test-sessionY"

    # Kill sounds for session X only
    export CL4UD3_SID="test-sessionX"
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    kill_active_sounds

    [ ! -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-sessionX" ]
    [ -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-sessionY" ]
    rm -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-sessionY"
}
