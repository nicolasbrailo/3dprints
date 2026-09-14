// Adjustable-height stand — THREE printed pieces in one file:
//   1. the box assembly (base + hollow compartment + 2 threaded posts)
//   2. & 3. two height-adjustment screws that thread into the posts
// NOTE: pieces are modeled upside-down / print-ready. Dimensions in millimeters.

use <threads.scad>

// --- Box parameters ---
width  = 125;  // X dimension (wide axis)
depth  = 55;   // Y dimension (depth axis)
height = 3;    // base Z thickness

wall      = 0;   // border/rim thickness around the outside of the bump
bump_span = 60;  // bump reach along X, measured from the far (+X) end
bump_rise = 15;  // how much the bump rises above the base top

comp_wall = 2;  // compartment wall thickness
comp_cap  = 2;  // closed (top) cap thickness
corner_r  = 3;  // vertical-corner rounding radius of the base & bump (0 = sharp)

// Single window through the inner (-X) wall of the compartment
hole_w = 13;  // hole size across the depth (Y)
hole_h = 9;   // hole size vertically (Z)
hole_r = 1;   // hole corner radius

// --- Thread / post parameters (shared by posts and screws) ---
thread_d      = 6;  // nominal thread diameter
thread_pitch  = 2;   // thread pitch
post_wall     = 1.5;   // solid wall around the threaded hole
post_protrude = 15;  // how far the posts rise above the assembly top
post_inset    = 5;  // post-center distance in from each X end
thread_len    = 7;  // depth of the tapped hole, measured from the post top. Rest of post unthreaded
screw_thread_len = 18;  // shaft length, not necessarily the same as thread of post len
fit_clearance = 0.6; // PRINT-FIT KNOB: extra diameter added to the tapped hole.
                     // 0 = nominal threads.scad fit; raise (e.g. 0.4–0.8) if the
                     // screw is too tight, lower toward 0 if it's loose/sloppy.
                     // Only the post (female thread) changes; the screw stays nominal.

// --- Screw parameters ---
screw_foot_h = 5;  // foot/grip height -> sets the minimum total height

// --- Derived ---
// Bump outer footprint: last `bump_span` mm in X, full depth in Y,
// inset by `wall` on all four sides. The compartment is hollowed out
// of that block, leaving `comp_wall` walls and a `comp_cap` closed top,
// open on the bottom (cavity cuts through the base).
ox = width - bump_span + wall;  // bump origin X
oy = wall;                      // bump origin Y
bx = bump_span - 2 * wall;      // bump outer size X
by = depth - 2 * wall;          // bump outer size Y

top_z   = height + bump_rise;       // highest point of the assembly
post_d  = thread_d + 2 * post_wall; // post outer diameter
post_h  = top_z + post_protrude;    // post total height (from z=0) == assembly height

// Screw geometry derives from the post so the two always match:
screw_foot_d     = 1.5*post_d;      // foot diameter == post OD

// Side-hole centering: middle of the cavity in X, middle of the cavity
// interior height in Z.
hole_cx = ox + bx / 2;
hole_cz = (height + bump_rise - comp_cap) / 2;

// Total (assembly + screw) height range, for reference:
//   max engagement (screw fully in) -> post_h + screw_foot_h          = 35 mm
//   min engagement (~5 mm)          -> post_h + screw_foot_h + 10     = 45 mm

// ============================================================
// Piece 1: box assembly
// ============================================================

// A box occupying [0,sx] x [0,sy] x [0,sz] with rounded vertical corners
// (flat top and bottom). r = 0 falls back to a plain cube.
module rounded_box(sx, sy, sz, r) {
    if (r <= 0) {
        cube([sx, sy, sz]);
    } else {
        hull()
            for (x = [r, sx - r], y = [r, sy - r])
                translate([x, y, 0])
                    cylinder(r = r, h = sz, $fn = 48);
    }
}

// A rounded-rectangle tunnel: cross-section hole_w (X) x hole_h (Z) with
// hole_r corners, axis along +Y, running from y=0 to y=len. Used to punch
// a window through a compartment wall.
module rrect_tunnel(len) {
    hull()
        for (dx = [-(hole_w / 2 - hole_r), hole_w / 2 - hole_r],
             dz = [-(hole_h / 2 - hole_r), hole_h / 2 - hole_r])
            translate([dx, 0, dz])
                rotate([-90, 0, 0])
                    cylinder(r = hole_r, h = len, $fn = 32);
}

// A single window through the inner (-X) wall of the compartment — the wall
// at x~ox that faces the rest of the base (the +X wall is the outer end of
// the box). Centered in depth and on the cavity interior height. The tunnel
// is rotated so its axis runs along +X, with hole_w measured along depth (Y).
module cavity_inner_hole() {
    translate([ox - 1, depth / 2, hole_cz])
        rotate([0, 0, -90])
            rrect_tunnel(comp_wall + 2);
}

// A solid post rising from the base, with an internally-threaded hole
// tapped down from the top (open at the top). The hole passes all the way
// through: the top `thread_len` mm is tapped, the rest is a plain clearance
// bore so the screw shaft can pass freely even when the thread is short.
module height_post(x, y) {
    translate([x, y, 0])
    difference() {
        cylinder(d = post_d, h = post_h, $fn = 64);

        // tapped hole, open at the top (+1 over-cut breaks the top face).
        // `fit_clearance` enlarges the female thread for a looser print fit.
        translate([0, 0, post_h - thread_len])
            metric_thread(diameter = thread_d + fit_clearance, pitch = thread_pitch,
                          length = thread_len + 1, internal = true);

        // plain clearance bore through the unthreaded remainder, from the base
        // up to where the thread begins (overlapping it by 1 so they merge).
        // Keeps the post pass-through regardless of thread_len.
        translate([0, 0, -1])
            cylinder(d = thread_d + fit_clearance, h = post_h - thread_len + 1,
                     $fn = 64);
    }
}

module box_assembly() {
    // The compartment cavity is subtracted from everything (base, bump AND
    // posts), so where a post overlaps the bump the cavity stays free.
    difference() {
        union() {
            // base
            rounded_box(width, depth, height, corner_r);

            // raised bump (outer shell)
            translate([ox, oy, height])
                rounded_box(bx, by, bump_rise, corner_r);

            // posts at the far ends of the wide axis, centered in depth
            height_post(post_inset, depth / 2);
            height_post(width - post_inset, depth / 2);
        }

        // hollow out the compartment (open bottom: cuts through the base).
        // Inner corner radius = corner_r - comp_wall keeps the wall a uniform
        // comp_wall around the rounded corners (falls back to square if <= 0).
        translate([ox + comp_wall, oy + comp_wall, -1])
            rounded_box(bx - 2 * comp_wall, by - 2 * comp_wall,
                        height + bump_rise - comp_cap + 1, corner_r - comp_wall);

        // single window through the inner (-X) wall of the compartment
        cavity_inner_hole();
    }
}

// ============================================================
// Pieces 2 & 3: height-adjustment screw (print two)
// ============================================================
// Printed foot-down, thread up. External thread => internal=false.
module screw() {
    union() {
        // hexagonal foot / grip knob (sits on the print bed).
        // $fn = 6 turns the cylinder into a hex prism; screw_foot_d is the
        // across-corners (vertex-to-vertex) size.
        cylinder(d = screw_foot_d, h = screw_foot_h, $fn = 6);

        // threaded shaft, chamfered tip (leadin) for easy starting
        translate([0, 0, screw_foot_h])
            metric_thread(diameter = thread_d, pitch = thread_pitch,
                          length = screw_thread_len, internal = false, leadin = 1);
    }
}

// ============================================================
// Layout — set `part` to export pieces individually
// ============================================================
part = "all";  // "all" (whole plate), "box", or "screw"

if (part == "all") {
    box_assembly();
    // two screws laid out in front of the box, clear of it
    translate([20,        -(screw_foot_d / 2 + 12), 0]) screw();
    translate([20 + screw_foot_d + 10, -(screw_foot_d / 2 + 12), 0]) screw();
} else if (part == "box") {
    box_assembly();
} else if (part == "screw") {
    screw();
}
