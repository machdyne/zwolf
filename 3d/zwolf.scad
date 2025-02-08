/*
 * Zwölf Module
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 * 
 * See PCB footprints for precise dimensions.
 *
 */
 
 $fn = 36;
 
 zwolf();
 
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