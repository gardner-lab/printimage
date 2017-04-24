# Requirements

- [ScanImage](http://scanimage.vidriotechnologies.com/)  by Vidrio Technologies.
    - Version 5.2 from 2016-11-08.
    - Other versions, including the nonfree versions, may also work, but are untested.
    - All its hardware requirements (It works with a wide variety of software; specifics forthcoming)
      - Resonant scanner
      - Fast Z piezo stage
      - Pockels cell controlled by a fast analogue output card
      - Post-Pockels power measurement
- Mesh Voxelisation by Adam A: [Matlab File Exchange 27390](https://www.mathworks.com/matlabcentral/fileexchange/27390-mesh-voxelisation)
- STL File Reader by Eric Johnson: [Matlab File Exchange 22409](https://www.mathworks.com/matlabcentral/fileexchange/22409-stl-file-reader)
- stlTools by Pau Micó: [Matlab File Exchange 51200](https://www.mathworks.com/matlabcentral/fileexchange/51200-stltools)
- Significant Figures by Teck Por Lim: [Matlab File Exchange 10669](https://www.mathworks.com/matlabcentral/fileexchange/10669-significant-figures)

# Installation

- Install ScanImage in the MATLAB path
- Run ScanImage and set up your hardware
- Calibrate hardware
  - Lens FOV
  - Resonant scanner degrees per volt
  - Galvo degrees per volt
  - Slow XY or XYZ stage accuracy
  - Fast Z stage accuracy
- Patch the ScanImage code
  - Patch files coming presently, or email me
- Install PrintImage and the above packages in the MATLAB path
- Modify the appropriate PrintImage default parameters (this will be in a configuration file eventually)

# Use

## Preparing the sample

- Undeveloped IP-Dip is _extremely_ toxic. Use gloves, and treat all spills, wipes, etc., as biohazard waste.
- Place a drop of IP-Dip on the substrate.
  - We use a syringe or a stirring rod to place the IP-Dip.
  - For a test substrate, we use a microscope slide cover slip suspended by its ends. This ensures that if the lens is lowered too far, the cover slip will break.


## Finding the substrate

The working distance of the lens is important, as you do not want the lens to touch anything solid! Our lens has a 380-um working distance, which has the following implications:
- If we are focused on the surface of the substrate we can move down another 380 microns before something breaks.
  - If we have just printed something 200 um high, we can scroll down 180 um before the lens hits the thing we just printed.
- If we are imaging at substrate+10 um and moving the XY stage, anything over 390 um (previously printed, or slide holders, etc) can potentially hit the lens.

### Finding 0

- Lower the lens until it touches the IP-Dip.
- Set ScanImage's zoom level to 1.
- Set ScanImage's power level somewhere too low to cause polymerisation. This will take experience, but start at 5%. On our equipment, at zoom level 1, polymerisation does not happen below around 40%, so we image at 10% or so.
- Press the ScanImage "FOCUS" button to begin obtaining images.
  - ScanImage's view window should glow, and you will probably see some vignetting at zoom=1.
- IP-Dip fluoresces at the print wavelength (780 nm), and glass does not. As long as the lens is focusing in the IP-Dip, the microscope will show an image. Lower the lens until the whole FOV turns dark, indicating that the lens is now focused on the substrate. Lowering another micron or 3 ensures good bonding.

### Printing in a specific location (e.g. on a nonuniform object attached to the substrate)
- Align according to your best guess.
- Find an appropriate lens depth (Z).
- Search outward from there using the "Search" button until the object you want to print on appears in the image.
- If you must manually rotate the sample, it is helpful to tell PrintImage about the axis of rotation:
  - Find the centre of your rotation stage by imaging something (possibly something you just printed) and rotating the stage, servoing until the centre of rotation is in the centre of the ScanImage imaging window.
  - Press the PrintImage "Set rotation centre" button.
    - You may also want to change the PrintImage parameter STL.logistics.rotation_centre to match this.
  - From now on, if you manually rotate the stage, you can have PrintImage track the location of the object by entering the angle of rotation in the "Track rotation" box.

## Power calibration

## Controlling print dimensions

## Controlling print size

## After printing

### Inspecting the print

### Resetting the Z position

### Developing the print
