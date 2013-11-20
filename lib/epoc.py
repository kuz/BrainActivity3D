"""

Class to comunicate with Emotic EPOC device

"""

from lib.emokit import emotiv
import gevent
import numpy as np

class Epoc:

    def __init__(self):
        headset = emotiv.Emotiv()
        gevent.spawn(headset.setup)
        gevent.sleep(1)

    def get_packet(self):
        '''
        Get one packet from the device packet queue
        '''
        packet = headset.dequeue()
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

    def read_next_sample(self, size):
        '''
        Know that Emotiv Epoc sampling rate is 128 Hz
        For example to get 300ms of data take size = 0.3 * 128 = 38
        '''
        data = None
        while len(data) < size:
            data.append(self.get_packet())
        return data

    def read_next_sample_dummy(self):
        f = open('data/201305161823-KT-mental-3-240.csv').readlines()
        lines = [map(float, ln.split(',')) for ln in f]
        lines = np.asarray(lines)
        lines = np.delete(lines, [14,15,16], axis=1) # delete last 2 columns
        
        return lines