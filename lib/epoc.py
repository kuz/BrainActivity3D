"""

Class to comunicate with Emotic EPOC device

"""

from lib.emokit import emotiv
import gevent
import numpy as np
import time

class Epoc:

    sample = None
    sample_sec = 0
    sample_size = 0

    def __init__(self, sample_sec):
        self.headset = emotiv.Emotiv()
        gevent.spawn(self.headset.setup)
        gevent.sleep(1)
        self.sample_sec = sample_sec
        self.sample_size = int(128 * float(sample_sec))

        # Load dummy data
        f = open('data/201305161823-KT-mental-3-240.csv').readlines()
        self.lines = [map(float, ln.split(',')) for ln in f]
        self.lines = np.asarray(self.lines)
        self.lines = np.delete(self.lines, [14,15,16], axis=1) # delete last 2 columns
        self.lastline = 0


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

    def read_next_sample(self):
        data = None
        while len(data) < self.sample_size:
            data.append(self.get_packet())
        return data

    def read_samples(self):
        '''
        This function is run via thread
        '''
        while True:
            self.sample = self.read_next_sample()
            print time.strftime('%d %b %Y %H:%M:%S') + ' EPOC   ' + 'Sample readed'
            time.sleep(self.sample_sec)

    def read_next_sample_dummy(self):
        if self.lastline + self.sample_size >= self.lines.shape[0]:
            self.lastline = 0 
        self.lastline += self.sample_size
        return self.lines[self.lastline:self.lastline + self.sample_size]

    def read_dummy_samples(self):
        '''
        This function is run via thread
        '''
        while True:
            self.sample = self.read_next_sample_dummy()
            print time.strftime('%d %b %Y %H:%M:%S') + ' EPOC   ' + 'Sample readed'
            time.sleep(self.sample_sec)








