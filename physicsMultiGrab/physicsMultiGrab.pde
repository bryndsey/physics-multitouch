/*
 mutltiTouchCoreImproved.pde
 Bryan Lindsey - 1/15/2013

 Adapted from:
 multiTouchCore.pde
 Eric Pavey - 2011-01-02
 as well as work by
 Mauricio Jabur - 2012/jul/10
*/

import java.util.*;
import fisica.*;
import ketai.sensors.*;
import android.view.MotionEvent;

//------------------------------
// Setup globals:
Map <Integer, MultiTouch> touchList = Collections.synchronizedMap(new HashMap() );
Map <Integer, FMouseJoint> jointList = Collections.synchronizedMap(new HashMap() );
int[] jointsToRemove = new int[5];
//HashMap jointList = new HashMap(5);
FWorld world;

KetaiSensor sensor;
float accelerometerX, accelerometerY, accelerometerZ;
boolean isGrabbed = false;

// Constants:
int maxGrav = 500;
int gravScale = 200;

//------------------------------
void setup() 
{
  sensor = new KetaiSensor(this);
  sensor.start();
  
  Fisica.init(this);
  
  orientation(LANDSCAPE);
  world = new FWorld();
  world.setEdges();
  
  float cx, cy, cSize;
  FCircle circle;
  for (int i = 0; i < 5; i++)
  {
    cSize = random(50, 150);
    circle = new FCircle(cSize);
    circle.setDensity(4*cSize);
    circle.setName("circle" + i);
    circle.setAllowSleeping(false);
    cx = random(circle.getSize(), width-circle.getSize());
    cy = random(circle.getSize(), height-circle.getSize());
    circle.setPosition(cx, cy);
    world.add(circle);
  }
  
}

//------------------------------
void draw() {
  background(255);

  int id;
  Iterator it;
  MultiTouch currTouch;
  Map.Entry entry;
  float thisX, thisY, gx, gy;
  FMouseJoint newJoint;
  FBody touchedBody;
  
  synchronized(jointList)
  {
    synchronized(touchList)
    {
      // ...for each possible touch event...
      
      it = touchList.entrySet().iterator();
      while (it.hasNext())
      {
        entry = (Map.Entry)it.next();
        
        currTouch = (MultiTouch)entry.getValue();
        //Integer id = (Integer)entry.getKey();
        id = int((Integer)entry.getKey());
        
        thisX = currTouch.motionX;
        thisY = currTouch.motionY;
        if (!currTouch.hasJoint)
        {
          touchedBody = world.getBody(thisX, thisY);
          if (touchedBody != null)
          {
            println(touchedBody.getName());
            newJoint = new FMouseJoint(touchedBody, thisX, thisY);
            newJoint.setAnchor(thisX, thisY);
            world.add(newJoint);
            jointList.put(id, newJoint);
            currTouch.hasJoint = true;
          }
        }
        else
        {
          jointList.get(id).setTarget(thisX, thisY);
        }         
      }
    }
    
    gy = constrain(accelerometerY*200, -500, 500);
    gx = constrain(accelerometerX*200, -500, 500);
    //println("gx: " + gx + " gy: " + gy);
    world.setGravity(gy, gx);
    
    world.step();
    world.drawDebug();
  }
}  

//------------------------------
// Override parent class's surfaceTouchEvent() method to enable multi-touch.
// This is what grabs the Android multitouch data, and feeds our MultiTouch
// classes.  Only executes on touch change (movement across screen, or initial
// touch).

public boolean surfaceTouchEvent(MotionEvent me) {
  int actionIndex = me.getActionIndex();
  int actionId = me.getPointerId(actionIndex);
  int actionMasked = me.getActionMasked();

  switch(actionMasked)
  {
  case MotionEvent.ACTION_DOWN:
  case MotionEvent.ACTION_POINTER_DOWN:
    if (!touchList.containsKey(actionId))
    {
      touchList.put(actionId, new MultiTouch() );
    }
    println("Down ID: "+ actionId+" Index: "+ actionIndex +" Total: "+ me.getPointerCount() );
    break;

  case MotionEvent.ACTION_UP:
  case MotionEvent.ACTION_POINTER_UP:
  case MotionEvent.ACTION_CANCEL:
    touchList.remove(actionId);
    synchronized(jointList)
    {
      FMouseJoint currJoint = jointList.get(actionId);
      //currJoint.releaseGrabbedBody();
      jointList.remove(actionId);
      world.remove(currJoint);
      //append(jointsToRemove, actionId);
      
    }
    println("-Up- ID: "+ actionId+" Index: "+actionIndex +" Total: "+ (me.getPointerCount()-1) );
    break;

  case 2://ACTION_MOVE:
    break;

  default:
    println("action: "+actionMasked);
  }

  for (int i = 0; i<me.getPointerCount(); i++)
  {
    MultiTouch touch = touchList.get(me.getPointerId(i));
    if (touch != null) // it could have been removed above
    {
      touch.update(me, i);
    }
  }
  return super.surfaceTouchEvent(me);
}

//------------------------------
// Class to store our multitouch data per touch event.

class MultiTouch {
  // Public attrs that can be queried for each touch point:
  float motionX, motionY;
  float pmotionX, pmotionY;
  float size, psize;
  float pressure, ppressure;
  int id;
  boolean touched = false;
  boolean hasJoint = false;
  
  void update(MotionEvent me, int index) {

    pmotionX = motionX;
    pmotionY = motionY;
    psize = size;
    ppressure = pressure; 

    motionX = me.getX(index);
    motionY = me.getY(index);
    size = me.getSize(index);
    pressure = me.getPressure(index);

    id = me.getPointerId(index);
    touched = true;
  }

  void update() {
    pmotionX = motionX;
    pmotionY = motionY;
    psize = size;
    touched = false;
  }
}

void onAccelerometerEvent(float x, float y, float z)
{
  accelerometerX = x;
  accelerometerY = y;
  accelerometerZ = z;
}
