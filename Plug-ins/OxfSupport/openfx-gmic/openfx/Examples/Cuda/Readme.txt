This example is derived from the OpenGL example. The main changes are in the
render() and describe() functions.

In the describe() function, kOfxImageEffectPropCudaRenderSupported is added
to indicate if the plugin and host supports the Cuda render feature. In this
case, this plugin sets this property to be true. This plugin also queries
the host to determine if the host supports the Cuda render feature.

This plugin is processing the data using Cuda. Before this plugin set the
Cuda device to be used, it will get the current Cuda device that is used by
the host, if any. Then, the plugin will set the device to be used for
processing the data. In this case, the first device is used.

The plugin needs to query the host to determine if the Cuda render feature is
enabled by querying this property kOfxImageEffectPropCudaEnabled.

If the Cuda render is enabled, there are two possible situations. The first
situation is that the plugin and host are running on the same Cuda device. 
The other situation is that the plugin and host are running on two different
Cuda devices. In the first case, the plugin can continue to process the data
using the pointers that it is given. In the case of running on two different
Cuda devices, there is a need to copy the data from the host device to the
plugin device. This can be done using cudaMemcpyPeer() function. After the
data is being processed, the result is copied from the plugin device back to
the host device using cudaMemcpyPeer() function.

In the situation that Cuda render is not enabled, the data flow is similar
to the case of running on two different Cuda devices. However, the data are
routed through the CPU using the cudaMemcpy() function instead.

