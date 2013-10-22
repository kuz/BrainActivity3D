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

brain = None

def init():
    """
    Initialize OpenGL and GLUT
    """
    # Initialize engine
    glutInit(sys.argv)
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_SRGB)
    glutInitWindowSize(800, 600)
    glutInitWindowPosition(200,50);
    glutCreateWindow('Brain Activity 3D')

    # Enable Z-Buffer
    glEnable(GL_DEPTH_TEST)
    #glEnable(36281)

    # Re-compute normals
    glEnable(GL_AUTO_NORMAL)

    # Perpective
    glMatrixMode(GL_PROJECTION)
    gluPerspective(45, 4/3, 0.5, 40)

    glMatrixMode(GL_MODELVIEW)

    # Enable basic lighting
    #glEnable(GL_COLOR_MATERIAL)
    glEnable(GL_LIGHTING)

    # Put all defaults to zero
    glEnable(GL_LIGHT0)
    #glLightfv(GL_LIGHT0, GL_AMBIENT, [0, 0, 0, 0])
    #glLightfv(GL_LIGHT0, GL_SPECULAR, [0, 0, 0, 0])
    #glLightfv(GL_LIGHT0, GL_DIFFUSE, [0, 0, 0, 0])
    #glLightModelfv(GL_LIGHT_MODEL_AMBIENT, [0, 0, 0, 0])

    # Backface culling
    glEnable(GL_CULL_FACE)
    
    # Initialize model
    init_model()

    # Initialize functions
    glutReshapeFunc(reshape)
    glutDisplayFunc(display)
    glutIdleFunc(idle)
    #glutMouseFunc(mouse)
    glutKeyboardFunc(keyboard)

    # Start main loop
    glutMainLoop()

def reshape(w, h):
    """
    Process reshaping of the window
    """
    pass

def display():
    """
    Main drawing function
    """
    global brain

    # Clear screen
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    #Light source 0
    glLightfv(GL_LIGHT0, GL_POSITION, [0, 1, 0, 0])
    glLightfv(GL_LIGHT0, GL_SPECULAR, [0, 0, 0, 1])
    
    # Material    
    glMaterialfv(GL_FRONT, GL_AMBIENT, [0.5, 0.5, 0.5, 1])
    glMaterialfv(GL_FRONT, GL_DIFFUSE, [0.5, 0.5, 0.5, 1])
    glMaterialfv(GL_FRONT, GL_SPECULAR, [0.8, 0.8, 0.8, 1])
    
    glLoadIdentity()
    gluLookAt(0, 20, 20, 0, 0, 0, 0, 0, 1)
    
    glScalef(0.1, 0.1, 0.1)

    glPushMatrix()
    glTranslatef(0, 0, 0)
    #glRotatef(90,1,0,0)
    #glutSolidTeapot(3)
    #glutSolidTorus(3, 5, 30, 30)
    glPopMatrix()
    
    # Draw brain
    glPushMatrix()
    glRotatef(glutGet(GLUT_ELAPSED_TIME)*0.03, -1, 0, 0)
    glCallList(brain.gl_list)
    glPopMatrix()

    # Switch buffers
    glutSwapBuffers()

def idle():
    """
    Computation to be performed during idle
    """
    display()

def mouse():
    """
    Process mouse events
    """
    pass

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
    brain = objloader.OBJ('brain_simplified.obj', 'model', swapyz=False)
    #brain = objloader.OBJ('brain.obj', 'model', swapyz=False)

def main():
    """
    Build the main pipeline
    """
    init()


# Start the program
main()

