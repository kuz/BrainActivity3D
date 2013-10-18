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
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB)
    glutInitWindowSize(800, 600)
    glutInitWindowPosition(200,50);
    glutCreateWindow('Brain Activity 3D')

    # Enable Z-Buffer
    glEnable(GL_DEPTH_TEST)

    # Perpective
    glMatrixMode(GL_PROJECTION)
    gluPerspective(45, 1, 0.5, 100)
    glMatrixMode(GL_MODELVIEW)

    # Enable basic lighting
    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);
    glEnable(GL_LIGHTING);

    # Initialize model
    init_model()

    # Initialize functions
    glutReshapeFunc(reshape)
    glutDisplayFunc(display)
    glutIdleFunc(idle)
    glutMouseFunc(mouse)
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

    glLoadIdentity()
    #gluLookAt(0, 1, 1, 0, 0, 0, 0, 1, 0)
    gluLookAt(0, 1, 10, 0, 0, 0, 0, 1, 0)
    #glOrtho(-5.0, 5.0, -5.0, 5.0, -5.0, 5.0)

    glLightfv(GL_LIGHT0, GL_POSITION, [-5, 5, 0.5, 1])

    glScalef(0.01, 0.01, 0.01)

    glPushMatrix()
    glTranslatef(-5, 5, 0.5)
    glutSolidSphere(10, 10, 10)
    glPopMatrix()
    
    glRotatef(glutGet(GLUT_ELAPSED_TIME)*0.03, -1, 0, 0)
    
    #glPushMatrix()
    #glTranslatef(0, 0.5, 0)
    #glRotatef(90, 1, 0, 0)
    #glColor(1, 0, 0);
    #glutSolidCylinder(0.3, 1, 10, 10)
    #glPopMatrix()

    #glColor(0, 1, 0);
    #glRectf(-1, 1, 1, -1)

    # Draw brain
    #glTranslatef(0, 0.5, 0)
    glCallList(brain.gl_list)

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

    brain = objloader.OBJ('brain_10.obj', 'model', swapyz=False)
    #brain = objloader.OBJ('al.obj', 'model', swapyz=False)

def main():
    """
    Build the main pipeline
    """
    init()


# Start the program
main()

