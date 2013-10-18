BrainActivity3D
===============

In the computational neuroscience lab we have small EEG device (http://www.emotiv.com). The device has 14 electrodes to measure electrical activity of a brain in 14 points on the surface of a head. The signal itself, as you can imagine, is not born on the surface of the head, but somewhere inside of it. The purpose of this project is to locate and visualize this "somewhere".

By analyzing data from 14 electrodes and using source localization (beamforming) techniques we will pinpoint the location of the EEG signal inside the brain. Program should be fast enough to work in real time.

We will use a 3D model of a human brain. Then we will interlace data about brain activity location and magnitude with the model. The resulting software should be able to display brain activity of a test subject in a 3D space in real time.

<b>References</b>:
* www.brainder.org - Reference model of a human brain
* Saeid, S. & Chambers, J. A. (2007). EEG Signal Processing.
