#!/usr/bin/env bats
# Tests for hook scripts — session-start, stop, pre-tool-use, user-prompt-submit

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
    # Copy all hook scripts
    cp "$BATS_TEST_DIRNAME/../hooks/"*.sh "$CL4UD3_HOME/hooks/"
    cp "$BATS_TEST_DIRNAME/../art/screens.sh" "$CL4UD3_HOME/art/"
    chmod +x "$CL4UD3_HOME/hooks/"*.sh "$CL4UD3_HOME/art/screens.sh"
    export CL4UD3_SOUNDS_ENABLED="false"
    export CL4UD3_STARTUP_ART="false"
    export CL4UD3_STARTUP_JINGLE="false"
    export CL4UD3_SID="test-$$-$BATS_TEST_NUMBER"
}

teardown() {
    _common_teardown
    rm -f /tmp/.cl4ud3-cr4ck-stop-cooldown
    rm -f /tmp/.cl4ud3-cr4ck-tool-cooldown
    rm -rf /tmp/.cl4ud3-cr4ck-all-jingles-test-*
}

# ── stop.sh ──

@test "stop.sh: exits 0 with sounds disabled" {
    run bash "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: exits 0 with config missing" {
    rm -f "$CL4UD3_HOME/config.sh"
    run bash "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: cooldown prevents rapid re-trigger" {
    LOCKFILE="/tmp/.cl4ud3-cr4ck-stop-cooldown"
    touch "$LOCKFILE"
    run bash "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: creates cooldown file" {
    rm -f /tmp/.cl4ud3-cr4ck-stop-cooldown
    export CL4UD3_GLITCH_SOUNDS="false"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ -f /tmp/.cl4ud3-cr4ck-stop-cooldown ]
}

@test "stop.sh: cleans up stale PID files" {
    echo "99999" > "/tmp/.cl4ud3-cr4ck-sound-pid-test-stale"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -f "/tmp/.cl4ud3-cr4ck-sound-pid-test-stale" ]
}

@test "stop.sh: cleans up orphaned jingle dirs" {
    mkdir -p "/tmp/.cl4ud3-cr4ck-all-jingles-test-orphan"
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -d "/tmp/.cl4ud3-cr4ck-all-jingles-test-orphan" ]
}

@test "stop.sh: no debug log created" {
    rm -f /tmp/.cl4ud3-stop-debug.log
    bash "$CL4UD3_HOME/hooks/stop.sh"
    [ ! -f /tmp/.cl4ud3-stop-debug.log ]
}

# ── pre-tool-use.sh ──

@test "pre-tool-use.sh: exits 0 with sounds disabled" {
    run bash "$CL4UD3_HOME/hooks/pre-tool-use.sh"
    assert_success
}

@test "pre-tool-use.sh: exits 0 with config missing" {
    rm -f "$CL4UD3_HOME/config.sh"
    run bash "$CL4UD3_HOME/hooks/pre-tool-use.sh"
    assert_success
}

@test "pre-tool-use.sh: cooldown prevents rapid re-trigger" {
    LOCKFILE="/tmp/.cl4ud3-cr4ck-tool-cooldown"
    touch "$LOCKFILE"
    run bash "$CL4UD3_HOME/hooks/pre-tool-use.sh"
    assert_success
}

@test "pre-tool-use.sh: creates cooldown file" {
    rm -f /tmp/.cl4ud3-cr4ck-tool-cooldown
    bash "$CL4UD3_HOME/hooks/pre-tool-use.sh"
    [ -f /tmp/.cl4ud3-cr4ck-tool-cooldown ]
}

# ── user-prompt-submit.sh ──

@test "user-prompt-submit.sh: exits 0" {
    run bash "$CL4UD3_HOME/hooks/user-prompt-submit.sh"
    assert_success
}

@test "user-prompt-submit.sh: exits 0 with config missing" {
    rm -f "$CL4UD3_HOME/config.sh"
    run bash "$CL4UD3_HOME/hooks/user-prompt-submit.sh"
    assert_success
}

@test "user-prompt-submit.sh: kills music loop PID file" {
    echo "99999" > "/tmp/.cl4ud3-cr4ck-music-pid-$CL4UD3_SID"
    bash "$CL4UD3_HOME/hooks/user-prompt-submit.sh"
    [ ! -f "/tmp/.cl4ud3-cr4ck-music-pid-$CL4UD3_SID" ]
}

@test "user-prompt-submit.sh: respects kill intro toggle" {
    export CL4UD3_KILL_INTRO_ON_MESSAGE="false"
    echo "99999" > "/tmp/.cl4ud3-cr4ck-music-pid-$CL4UD3_SID"
    bash "$CL4UD3_HOME/hooks/user-prompt-submit.sh"
    # Music PID file should still exist (not killed)
    [ -f "/tmp/.cl4ud3-cr4ck-music-pid-$CL4UD3_SID" ]
    rm -f "/tmp/.cl4ud3-cr4ck-music-pid-$CL4UD3_SID"
}

# ── session-start.sh ──

@test "session-start.sh: exits 0 with everything disabled" {
    run bash "$CL4UD3_HOME/hooks/session-start.sh"
    assert_success
}

@test "session-start.sh: exits 0 with config missing" {
    rm -f "$CL4UD3_HOME/config.sh"
    run bash "$CL4UD3_HOME/hooks/session-start.sh"
    assert_success
}

@test "session-start.sh: creates session-scoped jingle dir" {
    export CL4UD3_STARTUP_JINGLE="true"
    export CL4UD3_SOUNDS_ENABLED="true"
    export CL4UD3_JINGLE_DIR="all"
    export CL4UD3_STARTUP_LOOP="false"
    # Create dummy MIDI file so it has something to find
    touch "$CL4UD3_HOME/sounds/startup/test.mid"
    bash "$CL4UD3_HOME/hooks/session-start.sh" 2>/dev/null || true
    # Jingle dir should be session-scoped
    [ -d "/tmp/.cl4ud3-cr4ck-all-jingles-$CL4UD3_SID" ]
    rm -rf "/tmp/.cl4ud3-cr4ck-all-jingles-$CL4UD3_SID"
}

@test "session-start.sh: skips art when disabled" {
    export CL4UD3_STARTUP_ART="false"
    run bash "$CL4UD3_HOME/hooks/session-start.sh"
    assert_success
    # No TTY output expected (can't easily test /dev/tty writes)
}

@test "session-start.sh: handles specific jingle dir" {
    export CL4UD3_STARTUP_JINGLE="true"
    export CL4UD3_SOUNDS_ENABLED="true"
    export CL4UD3_JINGLE_DIR="startup-warez"
    export CL4UD3_STARTUP_LOOP="false"
    touch "$CL4UD3_HOME/sounds/startup-warez/test.mid"
    run bash "$CL4UD3_HOME/hooks/session-start.sh"
    # Should not create all-jingles dir
    [ ! -d "/tmp/.cl4ud3-cr4ck-all-jingles-$CL4UD3_SID" ]
}

# ── post-tool-use.sh ──

@test "post-tool-use.sh: exits 0 with sounds disabled" {
    run bash "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: exits 0 with config missing" {
    rm -f "$CL4UD3_HOME/config.sh"
    run bash "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: cooldown prevents rapid re-trigger" {
    LOCKFILE="/tmp/.cl4ud3-cr4ck-tool-cooldown"
    touch "$LOCKFILE"
    run bash "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: creates cooldown file" {
    rm -f /tmp/.cl4ud3-cr4ck-tool-cooldown
    bash "$CL4UD3_HOME/hooks/post-tool-use.sh"
    [ -f /tmp/.cl4ud3-cr4ck-tool-cooldown ]
}

@test "post-tool-use.sh: skips play when modem disabled" {
    rm -f /tmp/.cl4ud3-cr4ck-tool-cooldown
    export CL4UD3_SOUNDS_ENABLED="true"
    export CL4UD3_MODEM_SOUNDS="false"
    run bash "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}
