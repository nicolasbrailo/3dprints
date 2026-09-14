// Mini-PC mount for a monitor arm
//
// A 130 x 45 mm plate with a U-shaped "step" in the middle that wraps
// around the monitor arm. The computer screws onto the two flat wings
// through slotted M3 holes (95.5 mm nominal spacing); the arm ends up
// clamped between the U channel and the underside of the computer.
//
//        computer sits on top of this face (z = plate_t)
//   ______________________        ______________________
//  |__o_(slot)____________|      |____________(slot)_o__|
//                         |      |
//                         | arm  |   <- 22 x 32 channel
//                         |______|
//
// Axes: X = along the 130 mm length, Y = along the 45 mm width
// (also the direction the arm runs), Z = up (computer side).

/* [Plate] */
plate_len   = 130;   // overall length (X)
plate_wid   = 45;    // overall width (Y), also the arm contact length
plate_t     = 4;     // thickness of the flat wings and channel walls
corner_r    = 4;     // plan-view rounding of the plate's outer corners

/* [Arm channel (step)] */
arm_w       = 22;    // arm width  -> channel inner width
arm_h       = 32;    // arm height -> channel inner depth
fit_w       = 0.4;   // extra width so the arm slides in
fit_h       = 0;     // extra depth; make negative (e.g. -0.3) for a tighter clamp
arm_r       = 1.5;   // inner radius at the bottom of the channel
bend_r      = 3;     // fillet where the wings meet the channel walls

/* [Computer mounting holes] */
hole_spacing = 95.5; // nominal centre-to-centre distance (X)
hole_y       = 0;    // Y offset of the holes from the plate centre line
hole_d       = 4.5;  // M4 clearance
slot_travel  = 6;    // total slot length beyond the hole (+/- 3 mm)
washer_od    = 7;    // M3 washer (DIN 125), only used for the sanity checks

$fn = 64;

// ---- derived ----------------------------------------------------------
eps  = 0.01;
cw   = arm_w + fit_w;          // channel inner width
ch   = arm_h + fit_h;          // channel inner depth (from the top face)
cow  = cw + 2 * plate_t;       // channel outer width

// Keep the washer seated on flat material, clear of the plate end and
// of the bend fillet.
slot_min_x = hole_spacing / 2 - slot_travel / 2 - washer_od / 2;
slot_max_x = hole_spacing / 2 + slot_travel / 2 + washer_od / 2;
assert(slot_min_x > cow / 2 + bend_r,
       "Washer would overlap the channel fillet: reduce slot_travel or bend_r");
assert(slot_max_x < plate_len / 2 - corner_r / 2,
       "Washer would overhang the plate end: reduce slot_travel");
assert(abs(hole_y) + washer_od / 2 < plate_wid / 2,
       "Washer would overhang the plate side: reduce hole_y");

// ---- 2D helpers (profile lives in the XZ plane, drawn as XY) ----------

// Rectangle centred on x = 0, spanning y = [0, h], with only the two
// bottom corners rounded to radius r.
module u_rect(w, h, r) {
    r = max(r, eps);
    hull() {
        for (s = [-1, 1])
            translate([s * (w / 2 - r), r]) circle(r);
        translate([-w / 2, h - eps]) square([w, eps]);
    }
}

// Concave fillet filling the inside corner at the origin, extending
// into +x / -y.
module inside_fillet(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r);
    }
}

// Cross-section of the whole part.
module profile() {
    difference() {
        union() {
            // flat wings
            translate([-plate_len / 2, 0]) square([plate_len, plate_t]);
            // channel outer shell
            translate([0, -ch]) u_rect(cow, ch + plate_t, arm_r + plate_t);
            // fillets where the wings meet the channel
            for (m = [0, 1]) mirror([m, 0])
                translate([cow / 2, 0]) inside_fillet(bend_r);
        }
        // arm cavity, open towards the computer
        translate([0, plate_t - ch]) u_rect(cw, ch + 1, arm_r);
    }
}

// ---- 3D ---------------------------------------------------------------

module slot() {
    hull()
        for (s = [-1, 1])
            translate([s * slot_travel / 2, 0, 0])
                cylinder(d = hole_d, h = 3 * plate_t, center = true);
}

module plan_outline() {
    offset(r = corner_r) offset(delta = -corner_r)
        square([plate_len, plate_wid], center = true);
}

module mount() {
    difference() {
        intersection() {
            rotate([90, 0, 0])
                linear_extrude(plate_wid, center = true) profile();
            // round the plate's outer corners in plan view
            translate([0, 0, -ch - 1])
                linear_extrude(ch + plate_t + 2) plan_outline();
        }
        for (s = [-1, 1])
            translate([s * hole_spacing / 2, hole_y, plate_t / 2]) slot();
    }
}

mount();
