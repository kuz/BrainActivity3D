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
    glEnable(GL_DEPTH_TEST);

    # Enable basic lighting
    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);
    glEnable(GL_LIGHTING);
    
    # Set up projectino and viewport
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    #gluLookAt(0,0,3,0,0,0,0,0,1)
    glOrtho(-5.0, 5.0, -5.0, 5.0, -5.0, 5.0)

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

    # Draw brain
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

    brain = objloader.OBJ('al.obj', 'model', swapyz=False)

def main():
    """
    Build the main pipeline
    """
    init()


# Start the program
main()

