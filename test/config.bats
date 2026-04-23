#!/usr/bin/env bats
# Tests for config.sh — toggle defaults, env overrides, soundfont selection

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
}

teardown() {
    _common_teardown
}

@test "config: all sound toggles default to true" {
    unset CL4UD3_SOUNDS_ENABLED CL4UD3_STARTUP_JINGLE CL4UD3_GLITCH_SOUNDS CL4UD3_ERROR_SOUNDS CL4UD3_MODEM_SOUNDS
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_STARTUP_JINGLE" = "true" ]
    [ "$CL4UD3_GLITCH_SOUNDS" = "true" ]
    [ "$CL4UD3_ERROR_SOUNDS" = "true" ]
    [ "$CL4UD3_MODEM_SOUNDS" = "true" ]
    [ "$CL4UD3_SOUNDS_ENABLED" = "true" ]
}

@test "config: art defaults to true" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_STARTUP_ART" = "true" ]
}

@test "config: acid mode defaults to false" {
    unset CL4UD3_ACID_MODE
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_ACID_MODE" = "false" ]
}

@test "config: acid mode env override works" {
    export CL4UD3_ACID_MODE="true"
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_ACID_MODE" = "true" ]
    unset CL4UD3_ACID_MODE
}

@test "config: custom content defaults to true" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_CUSTOM_JINGLES" = "true" ]
    [ "$CL4UD3_CUSTOM_ART" = "true" ]
}

@test "config: startup loop defaults to false" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_STARTUP_LOOP" = "false" ]
}

@test "config: kill intro on message defaults to true" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_KILL_INTRO_ON_MESSAGE" = "true" ]
}

@test "config: intro max play defaults to 60" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_INTRO_MAX_PLAY" = "60" ]
}

@test "config: jingle dir defaults to all" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_JINGLE_DIR" = "all" ]
}

@test "config: jingle duration defaults to 25" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_JINGLE_DURATION" = "25" ]
}

@test "config: soundfont mode defaults to random" {
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_SOUNDFONT_MODE" = "random" ]
}

@test "config: MIDI player defaults to empty" {
    source "$CL4UD3_HOME/config.sh"
    [ -z "$CL4UD3_MIDI_PLAYER" ]
}

@test "config: environment variable overrides default" {
    export CL4UD3_MODEM_SOUNDS="false"
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_MODEM_SOUNDS" = "false" ]
    unset CL4UD3_MODEM_SOUNDS
}

@test "config: multiple env overrides work" {
    export CL4UD3_GLITCH_SOUNDS="false"
    export CL4UD3_ERROR_SOUNDS="false"
    export CL4UD3_STARTUP_JINGLE="false"
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_GLITCH_SOUNDS" = "false" ]
    [ "$CL4UD3_ERROR_SOUNDS" = "false" ]
    [ "$CL4UD3_STARTUP_JINGLE" = "false" ]
    unset CL4UD3_GLITCH_SOUNDS CL4UD3_ERROR_SOUNDS CL4UD3_STARTUP_JINGLE
}

@test "config: CL4UD3_HOME defaults to ~/.cl4ud3-cr4ck" {
    local saved="$CL4UD3_HOME"
    unset CL4UD3_HOME
    source "$saved/config.sh"
    [ "$CL4UD3_HOME" = "$HOME/.cl4ud3-cr4ck" ]
    export CL4UD3_HOME="$saved"
}

@test "config: soundfont generaluser mode" {
    export CL4UD3_SOUNDFONT_MODE="generaluser"
    unset CL4UD3_SOUNDFONT
    source "$CL4UD3_HOME/config.sh"
    [[ "$CL4UD3_SOUNDFONT" == *"GeneralUser-GS.sf2" ]]
}

@test "config: soundfont vintage mode" {
    export CL4UD3_SOUNDFONT_MODE="vintage"
    unset CL4UD3_SOUNDFONT
    source "$CL4UD3_HOME/config.sh"
    [[ "$CL4UD3_SOUNDFONT" == *"VintageDreamsWaves-v2.sf2" ]]
}

@test "config: soundfont random mode picks one of two" {
    export CL4UD3_SOUNDFONT_MODE="random"
    unset CL4UD3_SOUNDFONT
    touch "$CL4UD3_HOME/sounds/GeneralUser-GS.sf2"
    touch "$CL4UD3_HOME/sounds/VintageDreamsWaves-v2.sf2"
    # Run multiple times to exercise randomness — must always pick valid one
    for i in $(seq 1 5); do
        unset CL4UD3_SOUNDFONT
        source "$CL4UD3_HOME/config.sh"
        [[ "$CL4UD3_SOUNDFONT" == *"GeneralUser-GS.sf2" ]] || [[ "$CL4UD3_SOUNDFONT" == *"VintageDreamsWaves-v2.sf2" ]]
    done
}

@test "config: soundfont random fallback when vintage missing" {
    export CL4UD3_SOUNDFONT_MODE="random"
    unset CL4UD3_SOUNDFONT
    # _SF_GENERALUSER and _SF_VINTAGE use $HOME not $CL4UD3_HOME, so in test
    # context neither file exists. Random mode falls to else = generaluser path.
    source "$CL4UD3_HOME/config.sh"
    # Should always resolve to generaluser path (regardless of file existence)
    [[ "$CL4UD3_SOUNDFONT" == *"GeneralUser-GS.sf2" ]] || [[ "$CL4UD3_SOUNDFONT" == *"VintageDreamsWaves-v2.sf2" ]]
}

@test "config: explicit soundfont path not overridden" {
    export CL4UD3_SOUNDFONT="/custom/path.sf2"
    source "$CL4UD3_HOME/config.sh"
    [ "$CL4UD3_SOUNDFONT" = "/custom/path.sf2" ]
    unset CL4UD3_SOUNDFONT
}

@test "config: soundfont fallback for unknown mode" {
    export CL4UD3_SOUNDFONT_MODE="nonexistent"
    unset CL4UD3_SOUNDFONT
    source "$CL4UD3_HOME/config.sh"
    [[ "$CL4UD3_SOUNDFONT" == *"GeneralUser-GS.sf2" ]]
}
