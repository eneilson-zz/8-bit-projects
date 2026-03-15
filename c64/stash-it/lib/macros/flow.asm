// Control flow helpers.
// Branches to the given label when the zero flag is set.
.macro flow_if_zero(branchLabel) {
    beq branchLabel
}

// Decrements X and loops to the label until X reaches zero.
.macro flow_loop_x(loopLabel) {
    dex
    bne loopLabel
}

// Branches to the given label when the zero flag is clear.
.macro flow_if_not_zero(branchLabel) {
    bne branchLabel
}

// Decrements Y and loops to the label until Y reaches zero.
.macro flow_loop_y(loopLabel) {
    dey
    bne loopLabel
}
