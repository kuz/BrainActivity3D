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
from lib.epoc import Epoc
from lib.sourcelocalizer import SourceLocalizer
from OpenGL.GL.shaders import *
from threading import Thread
import traceback
import time

# Register global variables
brain = None
program = None
epoc = None
sample_sec = 0.5
localizer = None
source_locations = []

angle_x = 0
angle_y = 0

prev_x = 0
prev_y = 0

screen_w = 800
screen_h = 600

p_shader_xray = 0

def initgl():
    """
    Initialize OpenGL and GLUT
    """

    global screen_w
    global screen_h
    global program
    global p_shader_xray
    
    # Initialize engine
    glutInit(sys.argv)
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_SRGB)
    glutInitWindowSize(screen_w, screen_h)
    glutInitWindowPosition(200,50);
    glutCreateWindow('Brain Activity 3D')
   
    # Z-buffer
    glEnable(GL_DEPTH_TEST)

    # Enable basic lighting
    glEnable(GL_LIGHTING)

    # Add light sources
    glEnable(GL_LIGHT0)
    
    # Blending
    glClearColor(0.7, 0.7, 0.7, 1)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    
    # Initialize model
    init_model()

    # Initialize functions
    glutReshapeFunc(reshape)
    glutDisplayFunc(display)
    glutIdleFunc(idle)
    glutMouseFunc(mouse)
    glutMotionFunc(mouse_drag)
    glutKeyboardFunc(keyboard)
    
    # Set up shaders
    with open("brain_vertex_shader.glsl") as vertex_shader, open("brain_fragment_shader.glsl") as fragment_shader:    
        program = compileProgram(
            compileShader(vertex_shader.read(), GL_VERTEX_SHADER),
            compileShader(fragment_shader.read(), GL_FRAGMENT_SHADER),
        )
    
    # Use shaders
    glUseProgram(program)
    p_shader_xray = glGetUniformLocation(program, 'shader_xray')
    if p_shader_xray in (None,-1):
                print 'Warning, no uniform: %s'%( 'shader_xray' )
        
    # Start main loop
    glutMainLoop()

def initepoc():
    global epoc
    epoc = Epoc(sample_sec)
    epoc_reader_thread = Thread(target=epoc.read_dummy_samples)
    epoc_reader_thread.start()

def initsourceloc():
    global localizer
    localizer = SourceLocalizer()
    source_localizer_thread = Thread(target=localize_sources)
    source_localizer_thread.start()

def reshape(w, h):
    """
    Process reshaping of the window
    """
    screen_w = w
    screen_h = h
    glViewport(0, 0, w, h)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    gluPerspective(45, (3.0*w)/(4.0*h), 0.5, 500.0)
    print (3.0*w)/(4.0*h)
    glMatrixMode(GL_MODELVIEW)
    
 

def display():
    """
    Main drawing function
    """
    global brain
    global angle_x
    global angle_y
    global p_shader_xray
    
    # Clear screen
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    # Initialize view-transform matrix
    glLoadIdentity()

    # Light source 0
    glLightfv(GL_LIGHT0, GL_AMBIENT, [0, 0, 0, 1])
    glLightfv(GL_LIGHT0, GL_DIFFUSE, [1, 1, 1, 1])
    glLightfv(GL_LIGHT0, GL_SPECULAR, [1, 1, 1, 1])
    glLightfv(GL_LIGHT0, GL_POSITION, [0, 0, 1, 0])
    
    # Set up the camera    
    gluLookAt(0, 300, 0, 0, 0, 0, 0, 0, 1)
    glRotatef(90,0,0,1)
    
    # Draw things
    #draw_sources()
    draw_electrodes()
    draw_brain()
    
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
    # Once we pressed the left button this corresponds to the start of the rotation
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
    
    # Could be done more precisely
    angle_x += dx 
    angle_y += -dy
    
    prev_x = x
    prev_y = y

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
    initepoc()
    initsourceloc()
    initgl()

def draw_brain():

    global p_shader_xray
    glColor3f(0, 0, 0)
    
    # Material front   
    glMaterialfv(GL_FRONT, GL_AMBIENT, [0.2, 0.2, 0.2, 1])
    glMaterialfv(GL_FRONT, GL_DIFFUSE, [0.8, 0.8, 0.8, 1])
    glMaterialfv(GL_FRONT, GL_SPECULAR, [0, 0, 0, 1])
    glMaterialfv(GL_FRONT, GL_SHININESS, 0)
    glMaterialfv(GL_FRONT, GL_EMISSION, [0, 0, 0, 1])
    
    glPushMatrix()
    glUniform1i(p_shader_xray, True)
  

    try:
        glRotatef(angle_x, 0, 0, 1)
        glRotatef(angle_y, 1, 0, 0)
        glCallList(brain.gl_list)
    except:
        traceback.print_exc()
    finally:
        glPopMatrix()

def draw_electrodes():
    global p_shader_xray

    # Material front   
    glMaterialfv(GL_FRONT, GL_AMBIENT, [0.2, 0.2, 0.2, 1])
    glMaterialfv(GL_FRONT, GL_DIFFUSE, [0.4, 0.4, 0.9, 1])
    glMaterialfv(GL_FRONT, GL_SPECULAR, [0, 0, 0, 1])
    glMaterialfv(GL_FRONT, GL_SHININESS, 0)
    glMaterialfv(GL_FRONT, GL_EMISSION, [0, 0, 0, 1])

    glUniform1i(p_shader_xray, False)
    
    glPushMatrix()
    glRotatef(angle_x, 0, 0, 1)
    glRotatef(angle_y, 1, 0, 0)
    
    draw_electrode([-31.1,  55.5, 0.8], 'AF3') # AF3  (1)
    draw_electrode([-56.3,  29.3,  2.1], 'F7') # F7   (2)
    draw_electrode([ -8.6,  40.6, 30.7], 'F3') # F3   (3)
    draw_electrode([-35.1,  15.6, 35.5], 'FC5') # FC5  (4)
    draw_electrode([-65.6,  -6.5, -21.8], 'T7') # T7   (5)
    draw_electrode([-47.5, -37.2, 43.6], 'P7') # P7   (6)
    draw_electrode([-23.2, -83.2, 22.6], 'O1') # O1   (7)
    draw_electrode([ 23.2, -83.2, 22.6], 'O2') # O2   (8)
    draw_electrode([ 47.5, -37.2, 43.6], 'P8') # P8   (9)
    draw_electrode([ 65.6,  -6.5,  -21.8], 'T8') # T8  (10)
    draw_electrode([ 35.1,  15.6, 35.5], 'FC6') # FC6 (11)
    draw_electrode([  8.6,  40.6, 30.7], 'F4') # F4  (12)
    draw_electrode([ 56.3,  29.3,  2.1], 'F8') # F8  (13)
    draw_electrode([ 31.1,  55.5, 0.8], 'AF4') # AF4 (14)
    
    glPopMatrix()

def draw_electrode(position, label):
    glColor3f(0, 0, 1)
    glPushMatrix()
    glTranslate(position[0],  position[1],  position[2])
    draw_label(label)
    glutSolidSphere(5, 20, 20)
    glPopMatrix()

def draw_label(text):
    global program 
    glUseProgram(0)
    glDisable(GL_LIGHTING)
    glRasterPos2f(0, 6)
    glutBitmapString(GLUT_BITMAP_HELVETICA_18, text)
    glEnable(GL_LIGHTING)
    glUseProgram(program)

def draw_source(position):    
    glMaterialfv(GL_FRONT, GL_AMBIENT, [0.2, 0.2, 0.2, 1])
    glMaterialfv(GL_FRONT, GL_DIFFUSE, [0.9, 0.3, 0.3, 1])
    glMaterialfv(GL_FRONT, GL_SPECULAR, [0, 0, 0, 1])
    glMaterialfv(GL_FRONT, GL_SHININESS, 0)
    glMaterialfv(GL_FRONT, GL_EMISSION, [0, 0, 0, 1])

    glUniform1i(p_shader_xray, False)

    glPushMatrix()
    glTranslate(position[0],  position[1],  position[2])
    glutSolidSphere(5, 20, 20)
    glPopMatrix()

def localize_sources():
    '''
    This function is run via thread
    '''
    global localizer
    global source_locations
    global sample_sec

    while True:
        localizer.set_data(epoc.sample)
        locations = []
        for sn in range(localizer.number_of_sources):
            locations.append(localizer.localize(sn))

        source_locations = locations
        print time.strftime('%d %b %Y %H:%M:%S') + ' SLOC   ' + 'New source location are calculated'

        time.sleep(sample_sec)

def draw_sources():
    global source_locations

    glPushMatrix()
    glRotatef(angle_x, 0, 0, 1)
    glRotatef(angle_y, 1, 0, 0)
    for source in source_locations:
        draw_source(source)
    glPopMatrix()

# Start the program
main()

