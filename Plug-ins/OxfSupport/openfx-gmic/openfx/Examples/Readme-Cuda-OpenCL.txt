Update as of 21 April 2015
--------------------------

In this package, you can find the following subdirectories.

1. CudaPlugin   - Sample OpenFX plugin using the Cuda render support
2. OpenCLPlugin - Sample OpenFX plugin using the OpenCL render support
3. OpenFX-1.3   - Contains the header files from the OpenFX package

In OpenFX-1.3/include/ofxImageEffect.h, the following definitions are added for the Cuda and OpenCL render support.

1. kOfxImageEffectPropCudaRenderSupported   - Indicates whether a host or plugin can support Cuda render
2. kOfxImageEffectPropCudaEnabled           - Indicates that an image effect SHOULD use Cuda render in the current action
3. kOfxImageEffectPropOpenCLRenderSupported - Indicates whether a host or plugin can support OpenCL render
4. kOfxImageEffectPropOpenCLEnabled         - Indicates that an image effect SHOULD use OpenCL render in the current action
5. kOfxImageEffectPropOpenCLCommandQueue    - The command queue of OpenCL render

In order to keep it simple, two individual sample plugins are provided (CUDA and OpenCL). However, it is possible for an OFX plugin
to support both CUDA and OpenCL by setting both render supports to be true. Depending on whether Resolve is running on CUDA or 
OpenCL platform, either CUDA or OpenCL render would be enabled accordingly. Therefore, the plugin could decide which mode to run
to obtain the best performance. 

More information about the necessary changes is provided in the respective Readme.txt found in the plugin directories.