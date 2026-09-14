// Parametric IKEA SKÅDIS corner holder for a box- or panel-shaped object
// (network switch, router, sign, flat panel, ...)
//
// Two corner cups (left + right) hang on the pegboard and carry the object by its bottom
// corners. Each cup has a floor, a front lip and a side wall. Two things can keep the
// object from being knocked forward, pick one with the switches below:
//   strap = true   the side walls stick out past the front face and have a slot, so an
//                  elastic band / velcro strap / shock cord runs across the front
//   clips = true   two more pieces grab the top corners with a lip that hangs down over
//                  the front face (better for a sign - nothing crosses the face)
//
// A cup hangs from one hook, plus an optional anti-rotation stub in the hole 40 mm below.
// With cup_stub = false a cup uses a single hole, which frees its height on the board: the
// model then raises the cups so the top clips sit right above the object and stay tiny.
// A single cup could swivel on its one peg, but once the object spans both of them neither
// can turn. A top clip is a small tab on one hole: it carries no weight, it only stops the
// object tipping forward. Install a piece by tilting it, hooking the peg in, then swinging
// the bottom towards the board.
// With clips: hang the cups and clips, drop the object into the cups, lift it by a few mm
// and tilt its top in under the clips' lips, then let it back down.
//
// Every piece prints lying on the outer face of its side wall, so the hook profiles are in
// the XY plane (layer lines don't cross the hooks). No supports needed.
//
// Coordinates while modelling (use orientation): x = along the board, y = away from the
// board, z = up. y = 0 is the front face of the board, z = 0 is the bottom of the hook hole.
//
// Presets:
//   Netgear GS108PEv3 switch: dev_w=158,   dev_h=101, dev_d=29,  strap=true,  clips=false
//   Sign, portrait:           dev_w=139.5, dev_h=215, dev_d=8.5, strap=false, clips=true,
//                             cup_stub=false, wall_h=60, lip_h=10, corner_w=25

/* [What to render] */
part = "assembly"; // [assembly, print_all, cups, clips, left, right, clip_left, clip_right, test]

/* [Object] */
dev_w = 215.5;   // width, horizontal along the board
dev_h = 139.8;   // height
dev_d = 9;    // depth, how far it sticks out from the board
clr   = 1;     // clearance added to width, height and depth

/* [How it is held] */
strap = false;    // slot in the side walls for a band across the front
clips = true;     // small tabs that grab the top edge
cup_stub = false; // second peg 40 mm below a cup's hook; false = one peg, freely placed

/* [Top clips] */
clip_w   = 14;   // width of a clip
clip_lip = 6;    // how far a clip's lip reaches down the front face
gap_top  = 8;    // clearance left above the object, so it can be lifted in under the lips
hook_up_target = 40; // preferred height of a cup's hook above its floor (free placement only)
hook_up_min    = 15; // lowest allowed value of the same

/* [Holder] */
corner_w = 25;  // how far the floor + lip reach under the object, measured from the side wall
wall_h   = 50;  // side wall height of a cup, measured from the floor
lip_h    = 12;  // front lip height
t        = 3;   // back plate / floor / ceiling thickness
min_wall = 2.4; // thinnest allowed side wall (the real one is sized to hit the hole grid)
ch       = 2.5; // chamfer that guides the object past a lip

/* [Strap slot] */
strap_w = 20;         // strap / band width (slot length)
strap_t = 3.5;        // slot width (strap thickness + play; ~4-5 for shock cord)
strap_from_top = 5;   // distance from wall top to the slot

/* [SKÅDIS] */
pitch     = 40;   // hole spacing in a column (columns are 20 mm apart, every other one offset by 20 mm)
slot_h    = 15;   // hole height
board_t   = 5;    // board thickness
board_clr = 0.4;  // extra gap behind the board for the hook
peg_w     = 4.4;  // peg thickness, must be < 5 mm hole width
neck_h    = 8;    // height of the part of the hook that goes through the hole
tongue_t  = 3.5;  // thickness of the hook part behind the board
hook_over = 3.5;  // how far the hook reaches above the top of the hole
stub_depth = 4;   // anti-rotation stub, how deep it goes into the lower hole
stub_h    = 10;

/* [Hidden] */
eps = 0.01;
gap = board_t + board_clr;
W = dev_w + clr;

// The side wall's outer face is flush with the peg's outer face (so both sit on the print
// bed), which means the distance between the two pegs sets the wall thickness. Pick the
// nearest peg spacing on the 20 mm column grid that leaves at least min_wall.
peg_dist = 20 * ceil((W - peg_w + 2*min_wall) / 20);
t_w = (peg_dist + peg_w - W) / 2;
odd_col = (peg_dist / 20) % 2 == 1;  // right peg lands in a column offset 20 mm vertically

// Where the cup's hook sits above its floor. With a stub the cup needs the hole 40 mm
// below as well, which pins it; without one the cup can hang from any hole, so the height
// is chosen to put a clip's hole exactly gap_top above the object.
H = dev_h + clr + gap_top;   // floor top -> the hole a clip should hang from
free = clips && !cup_stub;
k = min(floor((H - hook_up_min)/20), round((H - hook_up_target)/20));
hook_up  = free ? H - 20*k : pitch + 2 - t;
top_rise = free ? 20*k : 20*ceil((dev_h + clr + gap_top - hook_up)/20);
top_drop = top_rise + hook_up - (dev_h + clr);  // clip hole bottom -> top of the object

drop_l = hook_up + t;                 // cup hook hole bottom -> floor bottom
drop_r = drop_l + (odd_col ? 20 : 0); // right hook hangs 20 mm higher in an offset column

lip_t   = strap ? strap_t + min_wall : t;  // lip / front-of-wall thickness
y_dev   = t + dev_d + clr;                 // front face of the object
y_front = y_dev + lip_t;                   // front of floor / lip / wall

cup_len  = t_w + corner_w;

assert(peg_w < 5, "peg_w must be smaller than the 5 mm SKÅDIS hole");
assert(neck_h < slot_h, "neck_h must be smaller than the hole height");
assert(!free || hook_up >= hook_up_min, "no hole works out - raise gap_top or lower hook_up_min");

echo(str("Peg spacing: ", peg_dist, " mm = ", peg_dist/20, " columns of holes (count every column, including the offset ones)"));
echo(str(odd_col ? "Right hook goes in the offset column, 20 mm higher than the left one"
                 : "Both hooks go in the same row"));
echo(str("Side wall thickness: ", t_w, " mm"));
echo(str("Cup hook sits ", hook_up, " mm above the floor of the cup"));
if (clips) echo(str("Clips hang ", top_rise, " mm above a cup's hook, in ",
                    (top_rise/20) % 2 == 1 ? "a column one step (20 mm) to the side" : "the same column",
                    "; gap above the object: ", top_drop, " mm"));

module hook() {
    top = slot_h + hook_over;
    back = -(gap + tongue_t);
    rotate([90, 0, 90]) linear_extrude(peg_w) polygon([
        [0.5, 0],
        [back + 1, 0],
        [back, 1],
        [back, top - 1.5],
        [back + 1.5, top],
        [-gap - 0.8, top],
        [-gap, top - 0.8],
        [-gap, neck_h],
        [0.5, neck_h],
    ]);
}

module stub() {
    translate([0, 0, -pitch + 0.5]) rotate([90, 0, 90]) linear_extrude(peg_w) polygon([
        [0.5, 0],
        [-stub_depth + 1, 0],
        [-stub_depth, 1],
        [-stub_depth, stub_h - 1],
        [-stub_depth + 1, stub_h],
        [0.5, stub_h],
    ]);
}

// Lip with a chamfered inner edge, extruded along x. dir = +1 sticks up (cup), -1 down (clip).
module lip(len, z_base, dir, h = lip_h, y_end = y_front) {
    translate([0, 0, z_base]) rotate([90, 0, 90]) linear_extrude(len) polygon([
        [y_dev, 0],
        [y_end, 0],
        [y_end, dir * h],
        [y_dev + ch, dir * h],
        [y_dev, dir * (h - ch)],
    ]);
}

// Bottom corner cup. The side wall's outer face (and the pegs) are at x = 0.
module cup(drop) {
    fz0 = -drop;          // floor bottom
    fz1 = fz0 + t;        // floor top, the object sits here
    wall_top = fz1 + wall_h;
    plate_top = max(neck_h + 3, wall_top);

    difference() {
        union() {
            translate([0, 0, fz0]) cube([cup_len, t, plate_top - fz0]);  // back plate
            translate([0, 0, fz0]) cube([cup_len, y_front, t]);          // floor
            lip(cup_len, fz1, 1);                                        // front lip
            translate([0, 0, fz0]) cube([t_w, y_front, wall_top - fz0]); // side wall
        }
        // strap slot through the side wall, just in front of the object
        if (strap)
            translate([-eps, y_dev, wall_top - strap_from_top - strap_w])
                cube([t_w + 2*eps, strap_t, strap_w]);
    }
    hook();
    stub();
}

// Top clip: a small tab on a single hole. Sits on the top edge of the object and hangs a
// lip over its front face, so the object cannot tip forward. Carries no weight.
module clip() {
    cz1 = -top_drop;        // underside, the top of the object
    y_c = y_dev + t;        // this piece stays as shallow as the object
    plate_top = neck_h + 3;

    translate([0, 0, cz1]) cube([clip_w, t, plate_top - cz1]);  // back plate
    translate([0, 0, cz1]) cube([clip_w, y_c, t]);              // tab over the top edge
    lip(clip_w, cz1, -1, clip_lip, y_c);                        // lip, hanging down
    hook();
}

module left()       { cup(drop_l); }
module right()      { mirror([1, 0, 0]) cup(drop_r); }
module clip_left()  { clip(); }
module clip_right() { mirror([1, 0, 0]) clip(); }

module test_piece() {
    translate([0, 0, -pitch - 2]) cube([peg_w + 4, t, pitch + neck_h + 5]);
    hook();
    stub();
}

module board_preview(cols = 14, rows = 8) {
    color("tan", 0.35) difference() {
        translate([-60, -board_t, -100]) cube([cols*20 + 20, board_t, rows*pitch + 100]);
        for (i = [-2 : cols], j = [-2 : rows])
            translate([i*20 - 2.5, -board_t - 1, j*pitch + (i % 2 ? 20 : 0)])
                cube([5, board_t + 2, slot_h]);
    }
}

// print orientation: lay a piece on the outer face of its side wall
module lay_left()  { rotate([0, -90, 0]) children(); }
module lay_right() { rotate([0,  90, 0]) children(); }
row = y_front + gap + tongue_t + 10;  // spacing between pieces on the bed

if (part == "assembly") {
    board_preview(cols = ceil((peg_dist + 80)/20), rows = ceil((top_rise + 120)/pitch));
    translate([-peg_w/2, 0, 0]) color("steelblue") left();
    translate([peg_dist + peg_w/2, 0, odd_col ? 20 : 0]) color("steelblue") right();
    if (clips) {
        // a clip's column may be one 20 mm step to the side of the cup's, so show it there
        dx = (top_rise/20) % 2 == 1 ? 20 : 0;
        translate([-peg_w/2 + dx, 0, top_rise]) color("seagreen") clip_left();
        translate([peg_dist + peg_w/2 - dx, 0, top_rise + (odd_col ? 20 : 0)]) color("seagreen") clip_right();
    }
    %translate([-peg_w/2 + t_w, t, -drop_l + t]) cube([W - clr, dev_d, dev_h]);
} else if (part == "cups" || part == "print_all") {
    lay_left() left();
    translate([0, row, 0]) lay_right() right();
    if (clips && part == "print_all") {
        translate([0, 2*row, 0]) lay_left() clip_left();
        translate([0, 3*row, 0]) lay_right() clip_right();
    }
} else if (part == "clips") {
    lay_left() clip_left();
    translate([0, row, 0]) lay_right() clip_right();
} else if (part == "left")       { lay_left()  left();
} else if (part == "right")      { lay_right() right();
} else if (part == "clip_left")  { lay_left()  clip_left();
} else if (part == "clip_right") { lay_right() clip_right();
} else if (part == "test")       { lay_left()  test_piece(); }
