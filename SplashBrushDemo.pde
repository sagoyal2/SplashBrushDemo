/** 
 *  Based off of:
 * 	Particle-Based Fluid Simulation for Interactive Applications
 * 
 * 
 *  SplashBrushDemo
 *  @author Samaksh (Avi) Goyal, 6/27/2021
 */

import java.util.*;


// GLOBALS
float RADIUS = 6;
float BRUSH_RADIUS = 20.0;
float KERNAL_RADIUS = 50.0;
float MASS = 20000;

float GAS_CONSTANT = 80.314;
float REST_DENSITY = 800000;
float SURFACE_TENSION = 35;

int ROWS 		= 11; //(rows - 1)/2 above and below
int COLUMNS = 21; //same

SplashBrush brush;

ArrayList<SPHParticle> droplet  = new ArrayList<SPHParticle>();
LinkedList<ArrayList<SPHParticle>> undo_droplet = new LinkedList<ArrayList<SPHParticle>>();


// Drivers
/////////////////////////////////////////////////////////////////
void setup() {
  //fullScreen(); 
  size(1280, 1024);  
  smooth(8);
  reset();
}

void reset() { 

	droplet  = new ArrayList<SPHParticle>();
	// Populate the initial droplet with particles

	float origin_x = width/2.0;
	float origin_y = height/2.0;

	for(int i = 0; i < ROWS; i++){
		for(int j = 0; j < COLUMNS; j++){

			float px = origin_x + 20*(j*1.0 - (COLUMNS - 1)/2.0);
			float py = origin_y + 20*(i*1.0 - (ROWS - 1)/2.0);
			
			boolean on_surface = false;
			if((i == 0) || (i == ROWS-1) || (j == 0) || (j == COLUMNS-1)){
				on_surface = true;
			}

			SPHParticle sphparticle = new SPHParticle(px, py, RADIUS, MASS, on_surface);
			droplet.add(sphparticle);

		}
	}

  undo_droplet = new LinkedList<ArrayList<SPHParticle>>();
}

// use as indicator to keep looping
int INDICATOR = 0;

void draw() {
  background(255);

  fill(0);
  text("CONTROLS: Radius[w-s], undo[z],", 5, 10); 
  text("#UNDOS: " + undo_droplet.size(), 5, 25);


  // Visualize
  drawBrushes();
  viewDroplet();


  // Time Step with forces
  calculate_density();
  calculate_color_field(); //not actual color but rather 1/0

	set_force_pressure();
  set_force_surface_tension();
  // set_force_external();


	if(INDICATOR == 0){
		// Using forward Euler rn but can try other schemes and timesteps later
	  float dt = 0.000002;
	  for (SPHParticle p : droplet) { 
	  	p.position.add(PVector.mult(p.velocity, dt));

	  	//println("a.x: " + p.position.x + " a.y: " + p.position.y + " a.z: " + p.position.z);

	  	p.velocity.add(PVector.mult(p.force_total, dt));

	  	//println("a.x: " + p.velocity.x + " a.y: " + p.velocity.y + " a.z: " + p.velocity.z);
	  }
	}
	
	// UNCOMMENT below to only draw once which is useful to debug - also uncomment prints below
	// INDICATOR = 1;
	// noLoop();
}

void keyPressed() {
  if (key == 'r') { 
    reset();
  }
  if (key == 'w') {
    BRUSH_RADIUS *= 1.1;
    // brush.setRadius(eps);
  }
  if (key == 's') { 
    BRUSH_RADIUS *= 0.9; 
    // brush.setRadius(eps);
  }

  if (key == 'z') {//undo
    if (undo_droplet.size() > 0) {
      droplet = undo_droplet.pollFirst();
    }
  }
}
/////////////////////////////////////////////////////////////////


// Helper Functions
/////////////////////////////////////////////////////////////////

void drawBrushes() {
  drawBrush(mouseX, mouseY);
}

void drawBrush(float x, float y)
{
  noFill();
  circle(x, y, 2*BRUSH_RADIUS);
}

void viewDroplet() {
  // lets just draw the particles on the grid with the appropriate color
  for(int i = 0; i < droplet.size(); i++){
  	
  	SPHParticle curr_particle = droplet.get(i);
  	fill(curr_particle.c);
  	circle(curr_particle.position.x, curr_particle.position.y, curr_particle.radius);
  }
}

void mousePressed() {
  brush = new SplashBrush(mouseX, mouseY, BRUSH_RADIUS);
  saveDropletState();
}

void saveDropletState() {
  ArrayList<SPHParticle> Q = new ArrayList<SPHParticle>();
  for (SPHParticle p : droplet) { 
  	SPHParticle q = new SPHParticle(p);
  	Q.add(q);
  }

  undo_droplet.addFirst(Q);
}

void mouseDragged() {
  PVector new_position = new PVector(mouseX, mouseY, 0);
  brush.setForceBasedOnNewPosition(new_position);

  // solveAndDeform();
  // move points within brush somehow
  deform();

  // Slide brush to newP:
  brush.setPosition(new_position);
}


void deform(){
	//simply move all points within initial radius of circle over by force
	for (SPHParticle p : droplet){ 
		float sqr_dist = (p.position.x - brush.position.x)*(p.position.x - brush.position.x) + (p.position.y - brush.position.y)*(p.position.y - brush.position.y);
		if(sqr_dist < BRUSH_RADIUS*BRUSH_RADIUS){
			p.position.x += brush.force.x;
			p.position.y += brush.force.y;

			//p.force_total.add(PVector.mult(new PVector(0.0, 1.0, 0.0), -100.0));

		}
  }
}

// Equation 3
void calculate_density(){
	for (SPHParticle p : droplet){ 
		float curr_density = 0.0;

		for(SPHParticle q : droplet){
			curr_density += q.mass*W_poly6(PVector.sub(p.position, q.position), KERNAL_RADIUS);
		}

		p.density = curr_density;
		// println("density: " + p.density);
	}
}

// Equation 15
void calculate_color_field(){

	for (SPHParticle p : droplet){ 
		float curr_color_value = 0.0;
		for(SPHParticle q : droplet){
			curr_color_value += (q.mass/ q.density)*W_poly6(PVector.sub(p.position, q.position), KERNAL_RADIUS);
		}

		p.color_value = curr_color_value;
		//println("color_value: " + p.color_value);
	}
}

// Equation 10 + 12
void set_force_pressure(){
	for (SPHParticle p : droplet){ 
		PVector curr_force_pressure = new PVector(0.0, 0.0, 0.0);
		float p_pressure = GAS_CONSTANT*(p.density - REST_DENSITY);

		for(SPHParticle q : droplet){
			float q_pressure = GAS_CONSTANT*(q.density - REST_DENSITY);
			float constants = q.mass*((p_pressure + q_pressure)/(2*q.density));

			//println("constants: " + constants);

			curr_force_pressure.add(PVector.mult(grad_W_spiky(PVector.sub(p.position, q.position), KERNAL_RADIUS),constants));
			// println("inner curr_force_pressure a.x: " + p.force_total.x + " a.y: " + p.force_total.y + " a.z: " + p.force_total.z);
		}

		p.force_total.add(PVector.mult(curr_force_pressure, -1.0));
		println("a.x: " + p.force_total.x + " a.y: " + p.force_total.y + " a.z: " + p.force_total.z);
	}
}

// Equation 19
void set_force_surface_tension(){

	calculate_normals();
	calculate_laplacian();

	for (SPHParticle p : droplet){ 

		//ONLY add surface tension on particles on surface
		if(p.on_surface){
			p.force_total.add(PVector.mult(p.normal, -1.0*(SURFACE_TENSION*p.laplacian/p.normal.mag())));
		}
	}
}

// Equation 16 + 4
void calculate_normals(){
	for (SPHParticle p : droplet){ 

		PVector curr_normal = new PVector(0.0, 0.0, 0.0);

		for(SPHParticle q : droplet){
			curr_normal.add(PVector.mult(grad_W_poly6(PVector.sub(p.position, q.position), KERNAL_RADIUS), (q.mass*q.color_value/q.density)));
		}

		p.normal = curr_normal;
	}	
}

// Equation 17 + 5
void calculate_laplacian(){
	for (SPHParticle p : droplet){ 

		float curr_laplacian = 0.0;

		for(SPHParticle q : droplet){
			curr_laplacian += (q.mass*q.color_value/q.density) * laplacian_W_poly6(PVector.sub(p.position, q.position), KERNAL_RADIUS);
		}

		p.laplacian = curr_laplacian;
	}	
}

// We will add stuff here later
void set_force_external(){
	// DO nothing right now
	//PVector p = new PVector(0.0, 0.0, 0.0);
}
/////////////////////////////////////////////////////////////////

// Kernal
/////////////////////////////////////////////////////////////////

float W_poly6(PVector r, float h){
	float h2 = pow(h,2);
	float r2 = r.magSq();

	if(r2 < h2){
		return (315.0/(64.0*PI*pow(h, 9)))*pow(h2 - r2,3);
	}
	return 0.0;
}

PVector grad_W_poly6(PVector r, float h){
	PVector p = new PVector(0.0, 0.0, 0.0);

	float h2 = pow(h,2);
	float r2 = r.magSq();

	if(r2 < h2){
		p.add(PVector.mult(r, -6.0*(315.0/(64.0*PI*pow(h, 9)))*pow(h2 - r2,3)));
	}
	return p;
}

float laplacian_W_poly6(PVector r, float h){
	float h2 = pow(h,2);
	float r2 = r.magSq();

	if(r2 < h2){

		float constant = -6.0*(315.0/(64.0*PI*pow(h, 9)))*pow(h2 - r2,3);

		float a = (5*r.x*r.x + r.y*r.y + r.z*r.z + h*h);
		float b = (5*r.y*r.y + r.x*r.x + r.z*r.z + h*h);
		float c = (5*r.z*r.z + r.y*r.y + r.x*r.x + h*h);

		return constant*(a + b + c);
	}	

	return 0.0;
}


PVector grad_W_spiky(PVector r, float h){
	PVector p = new PVector(0.0, 0.0, 0.0);

	float diff = h - r.mag();

	if((diff > 0.0) && (r.mag() > 0.0)){

		// println("in here");
		p.set(PVector.mult(r, (45.0/(PI*pow(h,6)))*(pow(diff, 2)/ r.mag())));
	}

	// println("inside grad_W_spiky a.x: " + p.x + " a.y: " + p.y + " a.z: " + p.z);

	return p;
}
/////////////////////////////////////////////////////////////////



































