# Requirements

- [ScanImage](http://scanimage.vidriotechnologies.com/)  by Vidrio Technologies.
  - Version 5.2.4 ([Requirements](http://scanimage.vidriotechnologies.com/display/SIH/ScanImage+Installation+Instructions))
  - Other versions, including the nonfree versions, may also work, but are untested.
  - PrintImage requires that these pieces of hardware be configured in ScanImage:
    - Resonant scanner
    - Fast Z piezo stage
    - Pockels cell controlled by a fast analogue output card
    - Pockels power calibration hardware (e.g. a photodiode)
    - For stitched printing: an XYZ stage with around 0.1% linear error
- Mesh Voxelisation by Adam H. Aitkenhead: [Matlab File Exchange 27390](https://www.mathworks.com/matlabcentral/fileexchange/27390-mesh-voxelisation)
- STL File Reader by Eric Johnson: [Matlab File Exchange 22409](https://www.mathworks.com/matlabcentral/fileexchange/22409-stl-file-reader)
- stlTools by Pau Micó: [Matlab File Exchange 51200](https://www.mathworks.com/matlabcentral/fileexchange/51200-stltools)
- Significant Figures by Teck Por Lim: [Matlab File Exchange 10669](https://www.mathworks.com/matlabcentral/fileexchange/10669-significant-figures)

# Installation

- Install ScanImage in the MATLAB path
- Run ScanImage and set up your hardware
- Calibrate hardware
  - Lens safe working depth
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
  - For a test substrate, we use a microscope slide cover slip suspended by its ends. This ensures that if the lens is lowered too far, the cover slip will break before anything expensive.


## Interacting with the substrate

The working distance of the lens is important, as you do not want the lens to touch anything solid! Our lens has a 380-um working distance, which has the following implications:
- If we are focused on the surface of the substrate we can move down another 380 microns before something breaks.
  - If we have just printed something 200 um high, we can scroll down 180 um before the lens hits the thing we just printed.
- If we are imaging at substrate+10 um and moving the XY stage, anything over 390 um (previously printed, or slide holders, etc) can potentially hit the lens.

### Finding 0 (where the substrate meets the IP-Dip)

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
- The "Print preview" button will paint the current preview slice (PrintImage's rightmost figure) where PrintImage will print it. You can then move the item under the image to align it.
  - But it's not quite accurate: it shows where PrintImage will turn up the power to the Pockels, but does not take into account any delays in the latter's response.

## Power calibration

PrintImage's "Power Test" button will print a bunch of rectangular prisms at various power settings, which can be seen in ScanImage's "Power Box Settings" window, available through the "POWER CONTROLS" window.
- Unfortunately there is a nonlinear relationship between zoom level, Z step size, and polymerisation power required. If those parameters change, you should re-run the power test at that level.
- Set the "Print Power" level to something that polymerises but doesn't bubble.

## Controlling print dimensions

- Your system probably has the worst resolution along the resonant scanner's axis, which we call X. If the object to be printed has finer features along one dimension than another, use PrintImage's dimension buttons to choose to place the coarser features along X
- Objects are printed in slices from Z=0 to higher Z. Slices that print later must attach to slices that print earlier. The Z axis should have no overhangs.
  - Because PrintImage is so fast, we have noticed that some overhangs are okay: the overhanging part may not have time to drift away. But this is untested: do not rely on it! Rather, choose Z so that there are no overhangs.

## Controlling print size

Because STL files are dimensionless, you have to choose the size of the object.

### Stitching

If the object to be printed exceeds any of the dimensions allowed by your hardware, PrintImage will break it into parts and print them in sequence using your XYZ stage.
- Z and safe-working-depth warning!

## After printing

### Inspecting the print

### Resetting the Z position

### Developing the print
