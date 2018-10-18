# Requirements

- [ScanImage](http://scanimage.vidriotechnologies.com/)  by Vidrio Technologies.
  - Version ≥5.2.4 ([Requirements](http://scanimage.vidriotechnologies.com/display/SIH/ScanImage+Installation+Instructions))
  - Other versions, including the nonfree versions, may also work, but are untested.
  - PrintImage requires that these pieces of hardware be configured in ScanImage:
    - Resonant scanner
    - Fast Z piezo stage
    - Pockels cell controlled by a fast analogue output card
    - Pockels power calibration hardware (e.g. a photodiode)
    - For stitched printing: an XYZ stage with around 0.1% linear error
- Mesh Voxelisation by Adam H. Aitkenhead: [Matlab File Exchange 27390](https://www.mathworks.com/matlabcentral/fileexchange/27390-mesh-voxelisation)
- STL File Reader by Eric Johnson: [Matlab File Exchange 22409](https://www.mathworks.com/matlabcentral/fileexchange/22409-stl-file-reader)
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
- Patch the ScanImage code. In a shell, go to your ScanImage base directory, and run something like `git apply ../printimage/scanimage-integration/patches/scanimage-5.3.1.patch --whitespace=fix` (here I've assumed that scanimage and printimage are subdirectories of a common parent). If you don't see your favourite ScanImage version here, look at the patch: it's dead simple!
  - [For ScanImage 5.2.4](scanimage_integration/patches/scanimage-5.2.4.patch)
  - [For ScanImage 5.3](scanimage_integration/patches/scanimage-5.3.patch)
  - [For ScanImage 5.3.1](scanimage_integration/patches/scanimage-5.3.1.patch)
  - [For ScanImage 5.4](scanimage_integration/patches/scanimage-5.4.patch)
- Install PrintImage and the above packages in the MATLAB path
- Modify the appropriate PrintImage default parameters (this will be in a configuration file eventually)

# Calibration

Size Calibration is done through parameters in ScanImage's `Machine_Data_File.m`, not through PrintImage. This is because we figure you'll want your microscope calibrated properly whether or not you're printing anything today.

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

### Scan phase

If the size of objects appears different on the left vs. right sides of the display (e.g. if you print or image a grid, and scrolling left-right changes the apparent grid size), you may need to adjust the scan phase. It's `hSI.hScan2D.linePhase`, available in the "Scan Phase" box in ScanImage's CONFIGURATION window. I haven't had much luck with "Auto Adjust".

Note that since this is not available in `Machine_Data_File.m`, I set it by hand in `printimage.m`. This will be moved to a printimage config file soon... For now, change the value until it looks right, and then modify `hSI.hScan2D.linePhase` in `printimage.m`.

## Z scale (adjusting the FastZ actuator)

### Background

ScanImage allows you to specify certain known models of FastZ stage. From `Machine_Data_File.m`:

        actuators(1).controllerType = 'thorlabs.pfm450';           % If supplied, one of {'pi.e665', 'pi.e816', 'npoint.lc40x', 'analog'}.

We have a ThorLabs pfm450, which ScanImage <em>should</em> know how to talk to. However, ours was not moving quite as far as ScanImage expected. In order to correct that, I modified some variables.

Also, note that it is essential to run at least our FastZ controller in closed-loop mode!

### Measuring the error

The procedure is generally the same as for X and Y: either print something of ostensible size and measure it, or image something of known size. For this we provide a vertical pyramid ruler. <em>FIXME Link to it!</em>

### Setting the values

If you need to adjust the scaling, you must <em>not</em> tell ScanImage what kind of FastZ controller you have, so it will actually use your adjusted values rather than its own. Just tell it you're using an analog controller:

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

## Leveling (with a hexapod)

### Background:

Desiderata:
- We want the slide (or printable medium) to be parallel with the optical plane.
- We want moves to track the optical plane.

Now imagine that your printable medium is a piece of something (e.g. an electrode in need of a cuff) loosely taped onto a slide. It may not be parallel to, well, anything. First step is to tilt the medium into alignment with the optical plane. Second step is to align the movement coordinate system.

### Tilting

Start a "focus", and add a bullseye. Focus on the substrate, and then bring the lens up just far enough to see a hint of fluorescence beginning to show. Use the hexapod's angle controls to put that hint of fluorescence in the middle of the FOV (using the bullseye). It will probably be necessary to tilt the object and then re-focus on the hint-of-fluorescence, tilt some more, re-focus again, etc.

### Leveling

Again focus on the substrate and then bring the lens up just far enough to see a hint of fluorescence, as above. Run a "brightness test" and look at the results (FIXME `falloff_slide.m` right now, but that's not ready for primetime). The goal will be to set the leveling coordinate system so that the (possibly tilted, but optically aligned) substrate moves along the optical XY plane. This is controlled by 
  `STL.motors.hex.leveling = [ X Y Z U V W ];`
Set it in `printimage_config.m`, and adjust as needed. For example, on our printer:
- If brightness increases as X increases, increase V (pos 5)
- If brightness increases as Y increases, increase U (pos 4)
Your printer may differ.

My favourite workflow: edit the values in `printimage_config.m`, copy and paste the definition into the MATLAB commandline, and run `hexapod_set_leveling()`, which will store the values in the hexapod. Run another brightness test and repeat until the brightness traces don't change too much over XY movement (I can usually get them down to about 10% variation, depending on how close I am to the substrate).

The sixth value of `STL.motors.hex.leveling` controls the alignment of stitched parts. Print something stitched and adjust W in order to align the hexapod's XY motion with the resonant-galvo axis.

### Saving the tilt

One more parameter should be saved in `printimage_config.m`:
  `STL.motors.hex.slide_level = [ 0 0 0 0.255 -0.09 0 ];`
These numbers are the tilt offsets from the tilt calibration process, above, but they must be read _after_ the leveling coordinate system is correctly defined and tuned.

## Vignetting compensation

### Background

This began as an effort to model the falloff due to optical vignetting. The theoretical model of cos(theta)^4 seemed to fit pretty well, but couldn't be justified for a near-field laser (i.e. working less than a few kilometres from the laser source). And then I reasoned that since all models are wrong, it might be better to do something free-form. Hence the adaptive power compensation.

### THINGS I NEED TO FIX

- This requires a stitching stage with good precision, and currently actually requires the Physik-Instrumente hexapod controller! Sorry... I'll see about fixing that, or helping someone with other hardware to write a patch.
- I need to figure out at what size and zoom to print the test object!

### How?

Zero: Set your desired print zoom level...? Still working on this.

First, focus within the IP-Dip (yielding a fluorescent image that appears approximately Gaussian). Use `Calibrate / Save baseline image` to save the default brightness at the camera.

Second, find the substrate: follow the instructions regarding "Finding 0" in "Printing" (below in this document), and use the `Calibrate / Calibrate vignetting compensation` menu item to begin. This will:
- Load and print a "cube" (actually a rectangular prism) of the size defined at the top of `calibrate_vignetting_slide.m`.
- Servo the stitching stage over the printed cube near its surface (currently `height - 2` um) and measure the brightness at lots of points
- Fit a curve to the measured brightnesses
All future prints will use this curve to adjust the power in real time as objects print. If the curve isn't producing good results, you may do the same thing again (start with "Finding 0" again), which will print another cube using the curve you just generated, measure output, and create a new fit, _which will be stacked on top of the old one._ In this way, you may iterate until you get good results (I've only tried up to 5 iterations; there is no software limit but I have found that I get diminishing returns or even degradation of results after about 2. YMMV).

To start from scratch, use the `Calibrate / Clear vignetting compensation` menu item. You may then start again. Feel free to add your own calibration procedure! They're applied in `printimage_modify_beam.m`.

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

## Understage zeroing

### Aligning a rotation stage with the microscope stage

Print something (e.g. a power test pattern). Use the rotation slider to rotate the stage, and see if it rotates about the centre of the screen (the "bullseye" can be used to facilitate this). Move the microscope stage toward what looks like the centre of rotation. Repeat until the image rotates about the centre of the field. This is the alignment point. You may add "STL.motors.mom.understage_centre = [12655 10857 16890];" to  your printimage_config, reading those numbers off the microscope stage's location (microns).

### Leveling a hexapod

Find the substrate, and then pull the lens just a little bit away from it so you can just see some light in the image centre. Scroll up and down on Y while adjusting the hexapod's X rotation control such that scrolling on Y doesn't affect the spot's brightness (closeness to substrate). Vice versa for X-Y.

For Z, print something that involves stitching, such as a linearity test. Scrolling back and forth with the microscope's stage should produce motion parallel with the line of dots that the stitching procedure produced.

The final numbers can be added to printimage_config; e.g., "STL.motors.hex.leveling = [0 0 0 0.9 -0.1 -1.1];"

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

# After printing

## Inspecting the print

## Resetting the Z position

## Developing the print
