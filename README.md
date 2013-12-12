BrainActivity3D
===============
![Screenshot](https://github.com/kuz/BrainActivity3D/raw/master/doc/Images/screenshot.png)

Intro
-----

In the [computational neuroscience lab](http://neuro.cs.ut.ee/) we have small EEG device: [Emotiv EPOC](http://www.emotiv.com). The device has 14 electrodes to measure electrical activity of a brain in 14 points on the surface of a head. The signal itself, as you can imagine, is not born on the surface of the head, but somewhere inside of it. The purpose of this project is to locate and visualize this "somewhere".

By analyzing data from 14 electrodes and using source localization techniques we pinpoint 3D coordinates of the presumable source of the EEG signal inside the brain.

How to run
----------
Install all the missing python modules and run main application file:
```
python brainactivity.py
```

How to use
----------
After some loading time you will be able to see
* model of a brain
* estimated locations of the Emotiv EPOC electrodes
* estimated sources
* list of sources, lobe they appeared in and the list of mental tasks for this lobe

You can
* use contextual menu [right mouse click] to see additional options
* change model transparancy mode [T]
* rotate the model [mouse click & drag]
* zoom [mouse scroll]

Dependecies
------------
* Python 2.7
* [emokit](https://github.com/openyou/emokit) to communicate with the device. It is bundled with the application.
* pywinusb
* gevent
* PyCrypto
* OpenGL
* cgkit
* sklearn
* scipy
* numpy

(this abomination will be over as soon as we create proper buildout script)


Miscellaneous
-------------

<b>Major things to do</b>:
* Create proper egg
* Use beamforming to assign activity value to each point inside the model
* Run experiments on proper EEG device

<b>References</b>:
* www.brainder.org - Reference model of a human brain
* Saeid, S. & Chambers, J. A. (2007). EEG Signal Processing.
