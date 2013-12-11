"""

Comunication with Emotic EPOC device

"""

from lib.emokit import emotiv
import gevent
import numpy as np
import time

class Epoc:

    sample = None
    sample_sec = 0
    sample_size = 0
    dummy = False
    
    coordinates = [([-38.4,  68.6,   1.0], 'AF3'), # AF3  (1)
                   ([-69.6,  36.2,   2.6], 'F7'),  # F7   (2)
                   ([ -11.1, 52.4,  39.6], 'F3'),  # F3   (3)
                   ([-45.2,  20.1,  45.7], 'FC5'), # FC5  (4)
                   ([-79.8,  -7.9, -26.5], 'T7'),  # T7   (5)
                   ([-57.1, -44.7,  52.4], 'P7'),  # P7   (6)
                   ([-27.1, -97.2,  26.4], 'O1'),  # O1   (7)
                   ([ 27.1, -97.2,  26.4], 'O2'),  # O2   (8)
                   ([ 57.1, -44.7,  52.4], 'P8'),  # P8   (9)
                   ([ 79.8,  -7.9, -26.5], 'T8'),  # T8  (10)
                   ([ 45.2,  20.1,  45.7], 'FC6'), # FC6 (11)
                   ([ 11.1,  52.4,  39.6], 'F4'),  # F4  (12)
                   ([ 69.6,  36.2,   2.6], 'F8'),  # F8  (13)
                   ([ 38.4,  68.6,   1.0], 'AF4')] # AF4 (14)
    
    def __init__(self, sample_sec):
        self.headset = emotiv.Emotiv()
        g = gevent.spawn(self.headset.setup)
        gevent.sleep(1)
        
        if not g.successful():
            print 'Could not connect to the Emotiv EPOC device. Please check that it is enabled and dongle is connected.'
            print 'Running with dummy data for now...'
            self.dummy = True
        
        self.sample_sec = sample_sec
        self.sample_size = int(128 * float(sample_sec))

        # Load dummy data
        f = open('data/201305182224-DF-facial-3-420.csv').readlines()
        self.lines = [map(float, ln.split(',')) for ln in f]
        self.lines = np.asarray(self.lines)
        self.lines = np.delete(self.lines, [14,15,16], axis=1) # delete last 2 columns
        self.lastline = 0
    
    def read_samples(self, epoc_packet_queue, epoc_process_alive):
        '''
        This function is run via thread
        '''
        while epoc_process_alive.value == True:

            if self.dummy:
                epoc_packet_queue.put(self.read_next_sample_dummy())
            else:
                epoc_packet_queue.put(self.read_next_sample())

            time.sleep(0.05)

    def read_next_sample(self):
        data = []
        while len(data) < self.sample_size:
            data.append(self.get_packet())
        return data

    def read_next_sample_dummy(self):
        if self.lastline + self.sample_size >= self.lines.shape[0]:
            self.lastline = 0 
        self.lastline += self.sample_size
        return self.lines[self.lastline:self.lastline + self.sample_size]

    def get_packet(self):
        '''
        Get one packet from the device packet queue
        '''
        packet = self.headset.dequeue()
        return [packet.AF3[0],
                packet.F7[0],
                packet.F3[0],
                packet.FC5[0],
                packet.T7[0],
                packet.P7[0],
                packet.O1[0],
                packet.O2[0],
                packet.P8[0],
                packet.T8[0],
                packet.FC6[0],
                packet.F4[0],
                packet.F8[0],
                packet.AF4[0]]
            
