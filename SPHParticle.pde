



public class SPHParticle{

	PVector position;
	PVector velocity;
	PVector force_total;
	PVector normal;
	color	c;
	float radius;
	float mass;
	float density;
	float color_value;
	float laplacian;
	boolean on_surface;


  public SPHParticle(float px, float py, float radius, float mass, boolean on_surface) 
  {
  	this.position 		= new PVector(px, py, 0.0);
  	this.velocity 		= new PVector(0.0, 0.0, 0.0);
  	this.force_total 	= new PVector(0.0, 0.0, 0.0);
  	this.normal 			= new PVector(0.0, 0.0, 0.0);
    this.radius 			= radius;
    this.mass  				= mass;
    this.density			= 0.0;
    this.color_value	= 0.0;
    this.laplacian		= 0.0;
    this.on_surface 	= on_surface;

    if(on_surface){
    	this.c					=	color(52, 125, 235);
    }else{
    	this.c					=	color(255, 255, 255);
    }
  }

  // Copy Constructor
  public SPHParticle(SPHParticle new_sph_particle){
  	this.position 		= new_sph_particle.position.copy();
  	this.velocity 		= new_sph_particle.velocity.copy();
  	this.force_total	= new_sph_particle.force_total.copy();
  	this.normal				= new_sph_particle.normal.copy();
  	this.c 						= new_sph_particle.c;
  	this.radius 			= new_sph_particle.radius;
  	this.mass 				= new_sph_particle.mass;
  	this.density			= new_sph_particle.density;
  	this.color_value	= new_sph_particle.color_value;
  	this.laplacian		= new_sph_particle.laplacian;
  	this.on_surface 	= new_sph_particle.on_surface;
  }



}