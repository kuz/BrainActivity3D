"""

Main file of the application

  * Read data from Emotiv
  * Compute 3D positions of activity sources
  * Plot them inside 3D model of the brain

"""

from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *
from lib import objloader

# Register global variables
brain = None

angle_x = 0
angle_y = 0

prev_x = 0
prev_y = 0

screen_w = 800
screen_h = 600

def init():
    """
    Initialize OpenGL and GLUT
    """

    global screen_w
    global screen_h

    # Initialize engine
    glutInit(sys.argv)
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_SRGB)
    glutInitWindowSize(screen_w, screen_h)
    glutInitWindowPosition(200,50);
    glutCreateWindow('Brain Activity 3D')

    # Enable Z-Buffer
    glEnable(GL_DEPTH_TEST)
    #glEnable(36281)

    # Re-compute normals
    glEnable(GL_AUTO_NORMAL)

    # Perpective
    glMatrixMode(GL_PROJECTION)
    gluPerspective(45, 4/3, 0.5, 400)

    glMatrixMode(GL_MODELVIEW)

    # Enable basic lighting
    glEnable(GL_LIGHTING)

    # Add light sources
    glEnable(GL_LIGHT0)

    # Backface culling
    glEnable(GL_CULL_FACE)
    
    # Initialize model
    init_model()

    # Initialize functions
    glutReshapeFunc(reshape)
    glutDisplayFunc(display)
    glutIdleFunc(idle)
    glutMouseFunc(mouse)
    glutMotionFunc(mouse_drag)
    glutKeyboardFunc(keyboard)

    # Start main loop
    glutMainLoop()

def reshape(w, h):
    """
    Process reshaping of the window
    """
    screen_w = w
    screen_h = h

def display():
    """
    Main drawing function
    """
    global brain
    global angle_x
    global angle_y

    # Clear screen
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    # Ambient light
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, [0.4, 0.4, 0.4, 1.0]);

    #Light source 0
    glLightfv(GL_LIGHT0, GL_DIFFUSE, [0.4, 0.4, 0.4, 1])
    glLightfv(GL_LIGHT0, GL_SPECULAR, [0, 0, 0, 1])
    glLightfv(GL_LIGHT0, GL_POSITION, [0, 0, 1, 0])
    
    # Material    
    glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, [0.4, 0.4, 0.4, 1])
    glMaterialfv(GL_FRONT, GL_SPECULAR, [0, 0, 0, 1])
    glMaterialfv(GL_FRONT, GL_SHININESS, 100)
    glMaterialfv(GL_FRONT, GL_EMISSION, [0.3, 0.3, 0.3, 1])
    
    # Set up the camera
    glLoadIdentity()
    gluLookAt(200, 200, 0, 0, 0, 0, 0, 0, 1)

    # Draw brain
    glPushMatrix()
    glRotatef(angle_x, 0, 0, 1)
    glRotatef(angle_y, 1, 0, 0)
    glCallList(brain.gl_list)
    glPopMatrix()

    # Switch buffers
    glutSwapBuffers()

def idle():
    """
    Computation to be performed during idle
    """
    display()

def mouse(button, state, x, y):
    """
    Process mouse events
    """
    # once we pressed the left button this corresponds to the start of the rotation
    global prev_x
    global prev_y
    if state == GLUT_DOWN and button == GLUT_LEFT_BUTTON:
        prev_x = x
        prev_y = y
    pass

def mouse_drag(x, y):
    """
    Process mouse events
    """
    global screen_w
    global screen_h
    global angle_x
    global angle_y
    global prev_x
    global prev_y
    
    dx = x - prev_x
    dy = y - prev_y
    
    # could be done more precisely
    angle_x += dx 
    angle_y += -dy
    
    prev_x = x
    prev_y = y
    
    #angle_x = (360 / float(screen_w)) * x;
    #angle_y = (-1)*(360 / float(screen_h)) * y ;

def keyboard():
    """
    Process keyboard events
    """
    pass

def init_model():
    """
    Load model from Wavefront .obj file
    """
    global brain
    brain = objloader.OBJ('brain_20k.obj', 'model', swapyz=False)

def main():
    """
    Build the main pipeline
    """
    init()


# Start the program
main()

