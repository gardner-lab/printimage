# Requirements:

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

# Installation:

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

# Use:

## Preparing the sample

- Place a drop of IP-Dip on the substrate
  - We use a microscope slide cover slip suspended by its ends. This ensures that if the lens is lowered too far, the cover slip will break.

## Finding the substrate

- Lower the lens until it touches the IP-Dip.
- Set ScanImage's zoom level to 1.
- Set ScanImage's power level somewhere too low to cause polymerisation. This will take experience, but start at 5%. On our equipment, at zoom level 1, polymerisation does not happen below around 40%, so we image at 10% or so.
- Press the ScanImage "FOCUS" button to begin obtaining images.
  - ScanImage's view window should glow, and you will probably see some vignetting at zoom=1.
- IP-Dip fluoresces at the print wavelength (780 nm), and glass does not. As long as the lens is focusing in the IP-Dip, the microscope will show an image. Lower the lens until the whole FOV turns dark, indicating that the lens is now focused on the substrate. Lowering another micron or 3 ensures good bonding.

## Power calibration

## Controlling print dimensions

## Controlling print size

## After printing

### Inspecting the print

### Resetting the Z position

### Developing the print
