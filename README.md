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

# Use

## Find substrate

## Power calibration

## Controlling print dimensions

## Controlling print size

