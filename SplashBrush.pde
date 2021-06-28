



public class SplashBrush{

	PVector position;
	float radius;
	PVector force = new PVector();


  public SplashBrush(float px, float py, float radius) 
  {
  	this.position	= new PVector(px, py, 0.0);
    this.radius 	= radius;
  }

  void setForceBasedOnNewPosition(PVector new_position){
  	this.force.set(new_position);
    this.force.sub(this.position);
  }

  void setPosition(PVector new_position){
  	this.position.set(new_position);
  }


}