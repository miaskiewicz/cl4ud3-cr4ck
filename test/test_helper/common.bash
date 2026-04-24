#!/bin/bash
# Common test setup/teardown for cl4ud3-cr4ck bats tests

_common_setup() {
    # Create isolated temp install dir for each test
    TEST_CL4UD3_HOME="$(mktemp -d)"
    export CL4UD3_HOME="$TEST_CL4UD3_HOME"
    export CL4UD3_SOUNDS_ENABLED="false"  # Never play real sounds in tests

    # Create minimal directory structure
    mkdir -p "$TEST_CL4UD3_HOME"/{hooks,art,sounds/{startup,startup-warez,glitches,error,modem,custom},bin,tools}

    # Copy config and play-midi from repo
    cp "$BATS_TEST_DIRNAME/../config.sh" "$TEST_CL4UD3_HOME/"
    cp "$BATS_TEST_DIRNAME/../hooks/play-midi.sh" "$TEST_CL4UD3_HOME/hooks/"

    # Override SID to avoid collisions with real sessions
    export CL4UD3_SID="test-$$-$BATS_TEST_NUMBER"
}

_common_teardown() {
    # Clean test temp files
    rm -rf "$TEST_CL4UD3_HOME"
    rm -f /tmp/.cl4ud3-cr4ck-*-"test-$$-$BATS_TEST_NUMBER"
    rm -f /tmp/.cl4ud3-cr4ck-sound-pid-test-* /tmp/.cl4ud3-cr4ck-music-pid-test-* /tmp/.cl4ud3-cr4ck-timer-pid-test-* /tmp/.cl4ud3-cr4ck-loading-pid-test-*
    rm -f /tmp/.cl4ud3-cr4ck-sound-pid-fake* /tmp/.cl4ud3-cr4ck-music-pid-fake* /tmp/.cl4ud3-cr4ck-timer-pid-fake* /tmp/.cl4ud3-cr4ck-loading-pid-fake*
}
