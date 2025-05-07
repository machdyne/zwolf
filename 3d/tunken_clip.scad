/*
 * Zwölf Tunken Adapter Clip
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 * This works best when printed with TPU filament.
 *
 */
 
 
tunken_clip();

//translate([0,0,8]) rotate([0,0,90]) zwolf();
//translate([0,0,5]) tunken();

module tunken_clip() {
 
    translate([0,0,0.5]) cube([20,4,3], center=true);
    translate([-16/2-3,0,5]) cube([4,4,12], center=true);
    translate([16/2+3,0,5]) cube([4,4,12], center=true);
     
    translate([16/2+1,0,11]) cube([10,4,4], center=true);
    translate([-16/2-1,0,11]) cube([10,4,4], center=true);
     
 }

module tunken() {
    color([1,0,0]) cube([16,16.5,5], center=true);
}
 
module zwolf(height = 1.6)
{
	 
	translate([0,-2.25,0])
		linear_extrude(1)
			text("zwölf", size=2, halign="center", font="Lato:style=Black");

	 difference() {
		 
		union () {
			color([0,1,0]) cube([16,13.5,height], center=true);
			translate([-6.35,4,0]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([-6.35,-4,-0.01]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([-3.81,4,0]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([-3.81,-4,-0.01]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([-1.27,4,0]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([-1.27,-4,-0.01]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([1.27,4,0]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([1.27,-4,-0.01]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([3.81,4,0]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([3.81,-4,-0.01]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([6.35,4,0]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
			translate([6.35,-4,-0.01]) color([1,1,0]) cube([1.7,5,height+0.01], center=true);
	   }
	 
		translate([-6.35,2.75,-1]) cylinder(d=1, h=10);		 
		translate([-6.35,2.75-7.62,-1]) cylinder(d=1, h=10);
		translate([-3.81,2.75,-1]) cylinder(d=1, h=10);
		translate([-3.81,2.75-7.62,-1]) cylinder(d=1, h=10);
		translate([-1.27,2.75,-1]) cylinder(d=1, h=10);
		translate([-1.27,2.75-7.62,-1]) cylinder(d=1, h=10);
		translate([1.27,2.75,-1]) cylinder(d=1, h=10);
		translate([1.27,2.75-7.62,-1]) cylinder(d=1, h=10);
		translate([3.81,2.75,-1]) cylinder(d=1, h=10);
		translate([3.81,2.75-7.62,-1]) cylinder(d=1, h=10);
		translate([6.35,2.75,-1]) cylinder(d=1, h=10);
		translate([6.35,2.75-7.62,-1]) cylinder(d=1, h=10);
		
	 }
 }
