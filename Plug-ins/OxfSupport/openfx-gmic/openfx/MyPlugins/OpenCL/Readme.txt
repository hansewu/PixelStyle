This example is derived from the OpenGL example. The main changes are in the
render() and describe() functions.

In the describe() function, kOfxImageEffectPropOpenCLRenderSupported is added
to indicate if the plugin and host supports the OpenCL render feature. In this
case, this plugin sets this property to be true. This plugin also queries
the host to determine if the host supports the OpenCL render feature.

The plugin needs to query the host to determine if the OpenCL render feature is
enabled by querying this property kOfxImageEffectPropOpenCLEnabled.

If the OpenCL render is enabled, the OpenCL command queue could be obtained 
by querying this property kOfxImageEffectPropOpenCLCommandQueue. The OpenCL
context and device ID can then be obtained from the command queue. In this
example, it is using the same device as the host. Therefore, the plugin can
continue to process the data using the pointers that it is given.

In the situation that OpenCL render is not enabled, the data are routed
through the CPU using the clEnqueueReadBuffer() and clEnqueueWriteBuffer()
functions.

