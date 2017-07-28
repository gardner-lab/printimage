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

# Calibration: getting the size right

Calibration is done through parameters in ScanImage's `Machine_Data_File.m`, not through PrintImage. This is because we figure you'll want your microscope calibrated properly whether or not you're printing anything today.

I will refer to the axis over which the resonant scanner scans as X. The galvo scans over Y. The "fast Z" stage, perpendicular to the focal plane, is (surprise!) Z.

Unsurprisingly, you will want to set zoom to 1, using either ScanImage's interface or `hSI.hRoiManager.scanZoomFactor = 1`

For X and Y, three parameters affect two degrees of freedom. I think there's a correct way to do this, but I'll describe the kludge.

## X and Y (field of view)

### Background

ScanImage mainains its idea of the lens's field of view in a variable called `hSI.hRoiManager.imagingFovUm`. This is a matrix giving the corner positions of the FOV. I've assumed that this is square and centered around 0, so if it's not, my code will be buggy! But here's one way to read ScanImage's idea of the FOV in X and Y:

        fov = hSI.hRoiManager.imagingFovUm
        [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)]

### Parameters in `Machine_Data_File.m`

- `objectiveResolution` controls X and Y FOV together
- `rScanVoltsPerOpticalDegree` controls the magnitude of the voltage signal to the resonant scanner (X)
- `galvoVoltsPerOpticalDegreeY` controls the magnitude of the voltage signal to the galvo (Y)

### Setting the values

You'll need a way to measure the actual FOV. This can be done by imaging something of known size, or by printing something and then measuring it on a calibrated device. For this purpose we have calibration rulers. <em>FIXME Add links to our calibration rulers and the paper's instructions.</em>

This accomplished, compute your error in X and Y, and just multiply some combination of those numbers to scale the image. It is likely that the numbers have nominal values (e.g. for our hardware, in theory `galvoVoltsPerOpticalDegreeY = 1`), so maybe try not to stray too far from those values, or keep one of them at the nominal value or something. We've found that one iteration of this procedure can get us to within 1% or so.

## Z scale (FastZ scale adjustment)

### Background

ScanImage allows you to specify certain known models of FastZ stage. From `Machine_Data_File.m`:

        actuators(1).controllerType = 'thorlabs.pfm450';           % If supplied, one of {'pi.e665', 'pi.e816', 'npoint.lc40x', 'analog'}.

We have a ThorLabs pfm450, which ScanImage <em>should</em> know how to talk to. However, ours was not moving quite as far as ScanImage expected. In order to correct that, I modified some variables.

Also, note that it is essential to run at least our FastZ controller in closed-loop mode!

### Measuring the error

The procedure is generally the same as for X and Y: either print something of ostensible size and measure it, or image something of known size. For this we provide a vertical pyramid ruler. <em>FIXME Link to it!</em>

### Setting the values

First, convince ScanImage that you don't know what kind of FastZ controller you're using, so it will actually use your adjusted values and not its own. Just tell it you're using an analog controller:

        actuators(1).controllerType = 'analog';          % If supplied, one of {'thorlabs.pfm450', 'pi.e665', 'pi.e816', 'npoint.lc40x', 'analog'}.

Now, adjust the VoltsPerMicron values according to your measurements:

        actuators(1).commandVoltsPerMicron = (10/450)/1.1;    % Conversion factor for desired command position in um to output voltage

The maximum voltage is 10 (specified in the manual, transcribed to `actuators(1).maxCommandVolts`; likewise the 450 and other constants (see below).

<em>The "/1.1" is the important part--it compensates for the 10% error that we measured.</em>

        actuators(1).commandVoltsOffset = [];        % Offset in volts for desired command position in um to output voltage
        actuators(1).sensorVoltsPerMicron = (10/450)/1.1;     % Conversion factor from sensor signal voltage to actuator position in um. Leave empty for automatic calibration

Same thing here--the sensor was off by the same amount. That led us to double-check our measurements (looks like two independent (?) systems were in agreement), but the printed parts really were the wrong size, measured on an SEM and via our slow Z stage (Sutter MOM, which is notoriously inaccurate but which in this case agreed with the SEM, as well as with itself at different locations in its range). So that can happen, I guess. Photoresist shrinkage? Anyway, our parts are the right size now.

        actuators(1).sensorVoltsOffset = -0.12;        % Sensor signal voltage offset. Leave empty for automatic calibration
        actuators(1).maxCommandVolts = 10;          % Maximum allowable voltage command
        actuators(1).maxCommandPosn = 450;           % Maximum allowable position command in microns
        actuators(1).minCommandVolts = 0;          % Minimum allowable voltage command
        actuators(1).minCommandPosn = 0;           % Minimum allowable position command in microns

# Printing

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

## Controlling print resolution

X and Y resolutions are functions of various things (position on the X axis, zoom level, hardware...), and you have limited control over them. Z is easiest.

- X "resolution" is always determined by the speed of the analogue output card controlling your Pockels cell. It will always be as high as it can be. There's no single number for this--voxels are smaller near the edges of the FOV than in the middle where the resonant scanner moves the beam faster. Sorry.
- Y resolution is controlled by the number of Y scan lines: ScanImage's `Lines / Frame` parameter in the CONFIGURATION window, also available at the command line through `hSI.hRoiManager.linesPerFrame`. It is always a power of two, so the choice of actual resolutions is somewhat limited. Resolution is the FOV / number of scan lines. Useful resolutions are determined by your photoresist, optics, etc.
- Z resolution is agnostic to zoom level, and it's measured in real units. Woot! Please control this through PrintImage's variable `STL.print.zstep`, which is in microns, and it will instruct ScanImage correctly <em>assuming ScanImage moves your FastZ stage in the same direction as mine with the same voltage change. You may need to change the sign and do a little minor debugging.</em> (Internally, PrintImage controls ScanImage's internal variable `Steps/Slice` in the FAST Z CONTROLS window (`hSI.hStackManager.stackZStepSize`).) One version of the PrintImage interface gives you direct control over that, but if you don't see it, then you have to modify the variable in `printimage.m`.

## Controlling print size

Because STL files are dimensionless, you have to choose the size of the object.

### Stitching

If the object to be printed exceeds any of the dimensions allowed by your hardware, PrintImage will break it into parts and print them in sequence using your XYZ stage.
- Z and safe-working-depth warning!

## After printing

### Inspecting the print

### Resetting the Z position

### Developing the print
