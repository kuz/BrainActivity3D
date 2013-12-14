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
from multiprocessing import freeze_support
from cgkit.cgtypes import *
import traceback
import time
import math
from lib.emokit import emotiv
import gevent
import sys
import warnings
import copy

warnings.filterwarnings("ignore", category=DeprecationWarning) 

# Register global variables
brain = None
program = None
epoc = None
sample_sec = 2.0
localizer = None
source_locations = []
localizer_thread_alive = True
influential_per_source = 3
most_influential_electrodes = dict()
connecting_line_width = 2.0
# Rotation variables:
rotation_matrix = mat4(1.0)
prev_x = 0
prev_y = 0
curr_x = 0
curr_y = 0
arcball_on = False

screen_w = 800
screen_h = 600
zoom_factor = 1.0
# Drawing mode for fragment shader:
#   0 - simple color
#   1 - blinn model
#   2 - xray
#   3 - xray with half of the intensity
p_shader_mode = 0

# Drawing mode for the brain
#   0 - solid model
#   1 - xray
transparency_mode = False

# Menu
menu = None

# Scene Id
scene_id = 1

def initgl():
    '''
    Initialize OpenGL and GLUT
    '''

    global screen_w
    global screen_h
    global program
    global p_shader_mode

    
    # Initialize engine
    glutInit(sys.argv)
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_SRGB)
    glutInitWindowSize(screen_w, screen_h)
    glutInitWindowPosition(200,50);
    glutCreateWindow('Brain Activity 3D')
    
    # Create menu
    createMenu()
   
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
    glutSpecialFunc(keyboard)
    
    # Set up shaders
    with open("brain_vertex_shader.glsl") as vertex_shader, open("brain_fragment_shader.glsl") as fragment_shader:    
        program = compileProgram(
            compileShader(vertex_shader.read(), GL_VERTEX_SHADER),
            compileShader(fragment_shader.read(), GL_FRAGMENT_SHADER),
        )
    
    # Use shaders
    glUseProgram(program)
    p_shader_mode = glGetUniformLocation(program, 'shader_mode')
    if p_shader_mode in (None,-1):
        print 'Warning, no uniform: %s'%( 'shader_mode' )

    # Start main loop
    glutMainLoop()

def createMenu():
    global menu
    menu = glutCreateMenu(processMenuEvents)  
    glutAddMenuEntry("Help - H", 1)
    glutAddMenuEntry("Brain - B", 2)
    
    mainMenu = glutCreateMenu(processMainMenu);
    glutAddMenuEntry("Change transparency mode - T", 1)
    glutAddMenuEntry("Initial view - I", 2)
    glutAddSubMenu("Display:", menu)
    glutAddMenuEntry("Quit - ESC", 3)
    
    glutAttachMenu(GLUT_RIGHT_BUTTON)
    return 0

def processMenuEvents(option):    
    global arcball_on
    global scene_id
    
    arcball_on = False
    if option == 1:
        scene_id = 0
    elif option == 2:
        scene_id = 1

def processMainMenu(option):    
    global arcball_on
    global rotation_matrix
    global localizer_thread_alive
    global epoc
    
    arcball_on = False
    if option == 1:
        change_transparency_mode()
    elif option == 2:
        rotation_matrix = mat4(1.0)
        glLoadIdentity()
    elif option == 3:
        quit()

def initepoc():
    global epoc
    epoc = Epoc(sample_sec)

def initsourceloc():
    global localizer
    localizer = SourceLocalizer(epoc)
    source_localizer_thread = Thread(target=localize_sources)
    source_localizer_thread.start()

def reshape(w, h):
    '''
    Process reshaping of the window
    '''
    global screen_w
    global screen_h
    
    screen_w = w
    screen_h = h
    glViewport(0, 0, w, h)
    setProjectionMatrix(w,h)
    
def setProjectionMatrix(width, height):
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    if height == 0:
        gluPerspective (45.0, 3.0*width, 0.5, 1000.0)
    else:
        gluPerspective (45.0, (3.0*width)/(4.0*height), 0.5, 1000.0)
    glMatrixMode(GL_MODELVIEW)
    
def display():
    '''
    Main drawing function
    '''
    global screen_w
    global screen_h
    global brain
    global p_shader_mode
    global localizer
    global scene_id
    
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
    
    # Draw things
    draw_background()
    
    if scene_id == 1:
        brain_scene()
    else:
        help_scene()

    # Switch buffers
    glutSwapBuffers()

def brain_scene():
    global transparency_mode
    global source_locations
    
    glPushMatrix()
    glScale(zoom_factor, zoom_factor, zoom_factor)
    glRotatef(-90,0,0,1)
    draw_sources()
    #draw_lobes()
    
    if transparency_mode == True:
        glDepthMask(False)
        draw_brain()
        glDepthMask(True)
    else:
        glColorMask(False, False, False, False)
        draw_brain()
        glDepthFunc(GL_LEQUAL)
        glColorMask(True, True, True, True)
        draw_brain()
    draw_electrodes()
    glPopMatrix()
    
    # Display info
    for i, sn in enumerate(source_locations):
       lobe = identify_lobe(sn)
       display_info(10, screen_h-10 - 20 * len(source_locations) + (i + 1) * 20, 'Source %d: %s (%s)' % (i + 1, lobe[0], lobe[1]))
    
def help_scene():
    global screen_w
    global screen_h

    # Draw text
    display_info(screen_w/18, screen_h/3, 'BrainActivity3D')
    display_info(screen_w/18, screen_h/3 + 20, 'In the computational neuroscience lab we have small EEG device (http://www.emotiv.com). ') 
    display_info(screen_w/18, screen_h/3 + 40, 'The device has 14 electrodes to measure electrical activity of a brain in 14 points ') 
    display_info(screen_w/18, screen_h/3 + 60, 'on the surface of a head. The signal itself, as you can imagine, is not born on the surface of ') 
    display_info(screen_w/18, screen_h/3 + 80, 'the head, but somewhere inside of it. The purpose of this project is to locate ')
    display_info(screen_w/18, screen_h/3 + 100, 'and visualize this "somewhere"')

def idle():
    '''
    Computation to be performed during idle
    '''
    display()

def mouse(button, state, x, y):
    '''
    Process mouse events
    '''
    global zoom_factor
    global screen_w
    global screen_h
    
    # Once we pressed the left button this corresponds to the start of the rotation
    global prev_x
    global prev_y
    global arcball_on
    
    if state == GLUT_DOWN and button == GLUT_LEFT_BUTTON:
        prev_x = x
        prev_y = y
        curr_x = x
        curr_y = y
        arcball_on = True
    
    if state == GLUT_UP and button == GLUT_LEFT_BUTTON:
        acrball_on = False

    # MouseWheel
    if button == 3:
        if zoom_factor <= 10.0:
            zoom_factor += 0.05
    if button == 4 :
        if zoom_factor >= 0.1:
            zoom_factor -= 0.05
    
def get_arcball_vector(x, y):
    '''
    Get a normalized vector from the center of the virtual ball O to a
    point P on the virtual ball surface, such that P is aligned on
    screen's (X,Y) coordinates.  If (X,Y) is too far away from the
    sphere, return the nearest point on the virtual ball surface.
    '''
    global screen_w
    global screen_h
    P = vec3(1.0*x/screen_w*2 - 1.0, 1.0*y/screen_h*2 - 1.0, 0)
    P.y = P.y
    OP_squared = P.x * P.x + P.y * P.y
    if OP_squared <= 1*1:
        P.z = math.sqrt(1*1 - OP_squared)
    else:
        P = P.normalize()
    return P 

def mouse_drag(x, y):
    '''
    Process mouse events
    '''
    global prev_x   # Location where mouse was pressed
    global prev_y
    global curr_x   
    global curr_y
    global rotation_matrix # Current rotation matrix
    
    if arcball_on == True:
        curr_x = x
        curr_y = y
    
    # Arcball implementation:
    if (curr_x != prev_x or curr_y != prev_y) and arcball_on == True:

        # Calculating two vectors to both mouse positions on the screen
        vec_to_first_click = get_arcball_vector(prev_x, prev_y)
        vec_to_second_click = get_arcball_vector(curr_x, curr_y)
        
        # Angle of the turn is calculated by taking a dot product between those two vectors
        angle = math.acos(min(1.0, vec_to_first_click*vec_to_second_click))
        
        # Axis of a turn is calculated by taking a cross product
        axis_in_camera_coord = vec_to_first_click.cross(vec_to_second_click)
        
        # Magic happens here, to be able to make a turn very intuitive shift y with z axis
        x = axis_in_camera_coord.y
        axis_in_camera_coord.y = axis_in_camera_coord.x
        axis_in_camera_coord.x = x       
        
        z = axis_in_camera_coord.x
        axis_in_camera_coord.x = axis_in_camera_coord.z
        axis_in_camera_coord.z = z
        # Multiply current rotation with a new angle from the left
        rotation_matrix = mat4(1.0).rotate(math.degrees(angle)/30.0, axis_in_camera_coord)*rotation_matrix
        
        # Save new coordinates as old
        prev_x = curr_x
        prev_y = curr_y
    
def keyboard(key, x, y):
    '''
    Process keyboard events
    '''
    global rotation_matrix
    global localizer_thread_alive
    global epoc
    global scene_id
    
    if key == GLUT_KEY_LEFT:
        # Compute an 'object vector' which is a corresponding axis in object's coordinates  
        object_axis_vector = rotation_matrix.inverse()*vec3([0, 0, 1])
        rotation_matrix = rotation_matrix.rotate(-3.14/90, object_axis_vector)
    if key == GLUT_KEY_RIGHT:
        object_axis_vector = rotation_matrix.inverse()*vec3([0, 0, 1])
        rotation_matrix = rotation_matrix.rotate(3.14/90, object_axis_vector)
    if key == GLUT_KEY_UP:
        object_axis_vector = rotation_matrix.inverse()*vec3([0, 1, 0])
        rotation_matrix = rotation_matrix.rotate(3.14/90, object_axis_vector)
    if key == GLUT_KEY_DOWN:
        object_axis_vector = rotation_matrix.inverse()*vec3([0, 1, 0])
        rotation_matrix = rotation_matrix.rotate(-3.14/90, object_axis_vector)
    elif key == chr(27):
        quit()
    elif key == 't' or key == 'T':
        change_transparency_mode()
    elif key == 'i' or key == 'I':
        rotation_matrix = mat4(1.0)
        glLoadIdentity()
    elif key == 'h' or key == 'H':
        scene_id = 0
    elif key == 'b' or key == 'B':
        scene_id = 1
            
def change_transparency_mode():
    global transparency_mode
    if transparency_mode == False:
        transparency_mode = True
    else:
        transparency_mode = False

def init_model():
    '''
    Load model from Wavefront .obj file
    '''
    global brain
    brain = objloader.OBJ('brain_20k_colored_properly.obj', 'model', swapyz=False)

def main():
    '''
    Build the main pipeline
    '''
    initepoc()
    initsourceloc()
    initgl()
        
def draw_brain():
    global p_shader_mode
    
    glPushMatrix()
    if(transparency_mode == False):
        glUniform1i(p_shader_mode, 2) # xray
    else: glUniform1i(p_shader_mode, 3) # xray with half of the intensity

    try:
        glMultMatrixf(rotation_matrix.toList())
        glCallList(brain.gl_list)
    except:
        traceback.print_exc()
    finally:
        glPopMatrix()

def draw_electrodes():
    global p_shader_mode
    global electrodes_activity
    global source_locations
    global most_influential_electrodes
    global transparency_mode
    
    # Material front   
    glMaterialfv(GL_FRONT, GL_AMBIENT, [0.2, 0.2, 0.2, 1])
    #glMaterialfv(GL_FRONT, GL_DIFFUSE, [0.4, 0.4, 0.9, 1])
    glMaterialfv(GL_FRONT, GL_SPECULAR, [0, 0, 0, 1])
    glMaterialfv(GL_FRONT, GL_SHININESS, 0)
    glMaterialfv(GL_FRONT, GL_EMISSION, [0, 0, 0, 1])

    glUniform1i(p_shader_mode, 1) # blinn
    glPushMatrix()
    glMultMatrixf(rotation_matrix.toList())
    
    # Protecting variables from overwriting by other threads
    mie = copy.deepcopy(most_influential_electrodes)
    sl = copy.deepcopy(source_locations)
    
    for electrode,coordinate in enumerate(epoc.coordinates):     
        if mie.has_key(electrode):           
            for contributed_source in mie[electrode]:
                line_color = get_color(contributed_source)
                draw_electrode(coordinate[0], coordinate[1], line_color)
                if transparency_mode:
                    draw_connecting_line(coordinate[0],sl[contributed_source], line_color)
        else:
            draw_electrode(coordinate[0], coordinate[1], [0.9, 0.9, 0.9, 1])
    glPopMatrix()

def get_color(index):
    if index == 0:
        line_color = list([0.9, 0.4, 0.4,1])
    elif index == 1:
        line_color = list([0.96, 0.64, 0.38,1])
    elif index == 2:
        line_color = list([0.0, 0.5, 0.0,1])
    elif index == 3:
        line_color = list([0.94, 0.5, 0.5,1])
    elif index == 4:
        line_color = list([0.29, 0, 0.5,1])
    return line_color
    
def draw_connecting_line(electrod_coordinates, source_coordinates, color):
    global connecting_line_width
    
    glUniform1i(p_shader_mode, 0)
    
    glColor3f(color[0], color[1], color[2])
    glPushMatrix()
    glLineWidth(connecting_line_width)
    glLineStipple(6, 0xAAAA)
    glEnable(GL_LINE_STIPPLE)
    glBegin(GL_LINES)
    glVertex3f(electrod_coordinates[0], electrod_coordinates[1], electrod_coordinates[2])
    glVertex3f(source_coordinates[0], source_coordinates[1], source_coordinates[2])
    glEnd()
    glPopMatrix()
    
    glUniform1i(p_shader_mode, 1)
    
def draw_electrode(position, label, material):
    glColor3f(0.18, 0.31, 0.31)
    glPushMatrix()
    glTranslate(position[0],  position[1],  position[2])
    draw_label(label)
    glMaterialfv(GL_FRONT, GL_DIFFUSE, material)
    glutSolidSphere(5, 20, 20)
    glPopMatrix()

    
def draw_label(text):
    global program 
    glUseProgram(0)
    glDisable(GL_LIGHTING)
    glRasterPos2f(0+2*zoom_factor, 3+2*zoom_factor)
    glutBitmapString(GLUT_BITMAP_HELVETICA_18, text)
    glEnable(GL_LIGHTING)
    glUseProgram(program)

def draw_source(position):    
    glMaterialfv(GL_FRONT, GL_AMBIENT, [0.2, 0.2, 0.2, 1])
    glMaterialfv(GL_FRONT, GL_DIFFUSE, [0.9, 0.3, 0.3, 1])
    glMaterialfv(GL_FRONT, GL_SPECULAR, [0, 0, 0, 1])
    glMaterialfv(GL_FRONT, GL_SHININESS, 0)
    glMaterialfv(GL_FRONT, GL_EMISSION, [0, 0, 0, 1])

    glUniform1i(p_shader_mode, 1) # blinn

    glBlendColor(0, 0, 0, 0.2)
    glBlendFunc(GL_CONSTANT_ALPHA, GL_ONE)

    glPushMatrix()
    glTranslate(position[0],  position[1],  position[2])
    for i in range(10):
        glScale(1.05, 1.05, 1.05)
        glutSolidSphere(5, 20, 20)
    glPopMatrix()
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

def localize_sources():
    '''
    This function is run via thread
    '''
    global localizer
    global source_locations
    global sample_sec
    global localizer_thread_alive
    global influential_per_source
    global most_influential_electrodes
    
    while localizer_thread_alive:
        localizer.set_data(epoc.read_next_sample())
        localizer.ica()  
        locations = []
        influential_electrodes = {}
        
        for sn in range(localizer.number_of_sources):           
            locations.append(localizer.localize(sn))
            
            contributions = []
            for j in range(len(localizer.mixing_matrix)):
                contributions.append(localizer.mixing_matrix[j][sn]**2)
                
            # Finding most influential contributions:
            contributing_electrodes = sorted(range(len(contributions)), key=lambda x: contributions[x])[-influential_per_source:]
            for electrode in contributing_electrodes:
                if not influential_electrodes.has_key(electrode):
                    influential_electrodes[electrode] = []
                influential_electrodes[electrode].append(sn)
                
        most_influential_electrodes = influential_electrodes
        source_locations = locations
        # Hand-picked 1-second delay for larger windows
        # TODO: estimate it in runtime
        time.sleep(2.0)

def draw_sources():
    global source_locations

    glPushMatrix()
    glMultMatrixf(rotation_matrix.toList())
    for source in source_locations:
        draw_source(source)
    glPopMatrix()

def draw_background(): 
    glUniform1i(p_shader_mode, 0)
    glBegin(GL_QUADS)
    glColor3f(0.53, 0.81, 0.98)
    glVertex3f(-1000.0, -500.0, -340.0)
    glVertex3f(1000.0, -500.0, -340.0)
    glColor3f(0.93, 0.91, 0.67)
    glVertex3f(1000.0, -500.0, 340.0)
    glVertex3f(-1000.0, -500.0, 340.0)
    glEnd()   

def draw_lobes(): 
    glUniform1i(p_shader_mode, 0)
    glPushMatrix()
    glMultMatrixf(rotation_matrix.toList())
    draw_plane(-80,80,80,-80,75,75,75,75,-45,-45,60,60)         # frontal lobe
    draw_plane(-80,80,80,-80,25,25,25,25,-10,-10,60,60)         # motor cortex
    draw_plane(-80,80,80,-80,0,0,0,0,-10,-10,60,60)             # motor cortex
    draw_plane(-80,80,80,-80,-20,-20,-20,-20,-10,-10,60,60)     # sensory cortex
    draw_plane(-80,-80,80,80,25,-60,-60,25,-10,-10,-10,-10)     # temporal lobe
    draw_plane(-80,-80,80,80,25,-60,-60,25,-60,-60,-60,-60)     # temporal lobe
    draw_plane(-80,80,80,-80,-60,-60,-60,-60,-30,-30,60,60)     # parietal lobe
    draw_plane(-80,80,80,-80,-105,-105,-105,-105,-30,-30,60,60) # occipital lobe
    glPopMatrix()
    
def draw_plane(x1,x2,x3,x4,y1,y2,y3,y4,z1,z2,z3,z4):
    glBegin(GL_POLYGON)
    glColor3f(  0.5,  0.5, 0.5 )
    glVertex3f( x1, y1,  z1 )
    glVertex3f( x2,  y2,  z2 )
    glVertex3f( x3,  y3,  z3)
    glVertex3f( x4, y4, z4 )
    glEnd()
    
def draw_text(x, y, text):
    glRasterPos2f(x,y)
    glutBitmapString(GLUT_BITMAP_HELVETICA_18, text)

def display_info(x, y, text):
    global screen_w
    global screen_h

    glUseProgram(0)
    glMatrixMode(GL_PROJECTION)
    glPushMatrix()
    glLoadIdentity()
    if screen_h == 0:
        glOrtho(0.0, screen_w, 1.0, 0.0, -1.0, 10.0)
    else:
        glOrtho(0.0, screen_w, screen_h, 0.0, -1.0, 10.0)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    glClear(GL_DEPTH_BUFFER_BIT)
        
    draw_text(x, y, text)

    glMatrixMode(GL_PROJECTION)
    glPopMatrix()
    glMatrixMode(GL_MODELVIEW)
    glUseProgram(program)
    
def identify_lobe(pos):
    if -80 <= pos[0] and pos[0] < 80 and 25 <= pos[1] and pos[1] < 75 and -45 <= pos[2] and pos[2] < 60:
        return ("Frontal lobe", "planning, emotions, problem solving")
    if -80 <= pos[0] and pos[0] < 80 and 0 <= pos[1] and pos[1] < 25 and -10 <= pos[2] and pos[2] < 60:
        return ("Motor cortex", "movement")
    if -80 <= pos[0] and pos[0] < 80 and -20 <= pos[1] and pos[1] < 0 and -10 <= pos[2] and pos[2] < 60:
        return ("Sensory cortex", "sensations")
    if -80 <= pos[0] and pos[0] < 80 and -60 <= pos[1] and pos[1] < 25 and -60 <= pos[2] and pos[2] < -10:
        return ("Temporal lobe", "memory, understanding, language")
    if -80 <= pos[0] and pos[0] < 80 and -60 <= pos[1] and pos[1] < -20 and -10 <= pos[2] and pos[2] < 60:
        return ("Parietal lobe", "perception, arithmetic, spelling")
    if -80 <= pos[0] and pos[0] < 80 and -105 <= pos[1] and pos[1] < -60 and -30 <= pos[2] and pos[2] < 60:
        return ("Occipital lobe", "vision")
 
    return ("Unknown", "noisy signal")   
       
def quit():
    global localizer_thread_alive
    
    print "Shutting down threads..."
    epoc.stop_reader()
    localizer_thread_alive = False
    sys.exit()
    
# Start the program
if __name__ == '__main__':
    freeze_support()
    main()
    