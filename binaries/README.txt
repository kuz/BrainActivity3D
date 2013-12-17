Pre-compiled binary files
-------------------------
You can find pre-built binaries for your system in
    Windows\brainactivity.zip
    (MacOSX\brainactivity.app)
    (Linux\brainactivity)

Building the bundle on your own system
--------------------------------------
We use PyInstaller 2.1

If you want to rebuild the distribution run 
    pyinstaller onefile.spec
    
Or you can build a bundle not as one file, but as folder with all necessary resources within
    pyinstaller onefolder.spec