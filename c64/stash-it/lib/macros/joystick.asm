// C64 joystick helpers (active-low bits on CIA #1 ports).
.const JOY_PORT2_ADDR = $dc00 // Joystick port 2 register address (most common for 1-player games).
.const JOY_PORT1_ADDR = $dc01 // Joystick port 1 register address.
.const JOY_UP_MASK    = $01   // Up direction bit mask.
.const JOY_DOWN_MASK  = $02   // Down direction bit mask.
.const JOY_LEFT_MASK  = $04   // Left direction bit mask.
.const JOY_RIGHT_MASK = $08   // Right direction bit mask.
.const JOY_FIRE_MASK  = $10   // Fire button bit mask.

// Loads raw joystick bits from port 1 (active-low: 0 means pressed).
.macro joy_read_port1() {
    lda JOY_PORT1_ADDR
}

// Loads raw joystick bits from port 2 (active-low: 0 means pressed).
.macro joy_read_port2() {
    lda JOY_PORT2_ADDR
}

// Loads normalized pressed bits from port 1 (active-high in A).
.macro joy_read_pressed_port1() {
    lda JOY_PORT1_ADDR
    eor #$ff
    and #$1f
}

// Loads normalized pressed bits from port 2 (active-high in A).
.macro joy_read_pressed_port2() {
    lda JOY_PORT2_ADDR
    eor #$ff
    and #$1f
}

// Branches when any joystick direction/button is pressed on the selected port.
.macro joy_any_pressed(portAddr, branchLabel) {
    lda portAddr
    and #$1f
    cmp #$1f
    bne branchLabel
}

// Branches when no joystick direction/button is pressed on the selected port.
.macro joy_none_pressed(portAddr, branchLabel) {
    lda portAddr
    and #$1f
    cmp #$1f
    beq branchLabel
}

// Branches when all bits in mask are pressed on the selected port.
.macro joy_mask_pressed(portAddr, mask, branchLabel) {
    lda portAddr
    eor #$ff
    and #mask
    cmp #mask
    beq branchLabel
}

// Branches when UP is pressed on the selected port.
.macro joy_up_pressed(portAddr, branchLabel) {
    lda portAddr
    and #JOY_UP_MASK
    beq branchLabel
}

// Branches when DOWN is pressed on the selected port.
.macro joy_down_pressed(portAddr, branchLabel) {
    lda portAddr
    and #JOY_DOWN_MASK
    beq branchLabel
}

// Branches when LEFT is pressed on the selected port.
.macro joy_left_pressed(portAddr, branchLabel) {
    lda portAddr
    and #JOY_LEFT_MASK
    beq branchLabel
}

// Branches when RIGHT is pressed on the selected port.
.macro joy_right_pressed(portAddr, branchLabel) {
    lda portAddr
    and #JOY_RIGHT_MASK
    beq branchLabel
}

// Branches when FIRE is pressed on the selected port.
.macro joy_fire_pressed(portAddr, branchLabel) {
    lda portAddr
    and #JOY_FIRE_MASK
    beq branchLabel
}
