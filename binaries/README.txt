Pre-compiled binary files
-------------------------
You can find pre-built binaries for your system here
    Windows: www.ikuz.eu/download/brainactivity3d/brainactivity3d_win.zip
    MacOSX: www.ikuz.eu/download/brainactivity3d/brainactivity3d_mac.zip
    (Linux: ...)

Building the bundle on your own system
--------------------------------------
We use PyInstaller 2.1

If you want to rebuild the distribution run 
    pyinstaller onefile.spec
    
Or you can build a bundle not as one file, but as folder with all necessary resources within
    pyinstaller onefolder.spec