#include "MultiplyGPU.h"

#include <cstdio>

#ifdef __APPLE__
#include <OpenCL/cl.h>
#else
#include <CL/cl.h>
#endif

namespace OFX {
namespace Plugin {
namespace MultiplyGPU {

const char *KernelSource = "\n" \
"__kernel void MultiplyKernel(                                        \n" \
"   int p_Width,                                                        \n" \
"   int p_Height,                                                       \n" \
"   float p_ValueR,                                                      \n" \
"   float p_ValueG,                                                      \n" \
"   float p_ValueB,                                                      \n" \
"   float p_ValueA,                                                      \n" \
"   __global const float* p_Input,                                      \n" \
"   __global float* p_Output)                                           \n" \
"{                                                                      \n" \
"   const int x = get_global_id(0);                                     \n" \
"   const int y = get_global_id(1);                                     \n" \
"                                                                       \n" \
"   if ((x < p_Width) && (y < p_Height))                                \n" \
"   {                                                                   \n" \
"       const int index = ((y * p_Width) + x) * 4;                      \n" \
"                                                                       \n" \
"       p_Output[index + 0] = p_Input[index + 0] * p_ValueR;             \n" \
"       p_Output[index + 1] = p_Input[index + 1] * p_ValueG;             \n" \
"       p_Output[index + 2] = p_Input[index + 2] * p_ValueB;             \n" \
"       p_Output[index + 3] = p_Input[index + 3] * p_ValueA;             \n" \
"   }                                                                   \n" \
"}                                                                      \n" \
"\n";

static
void CheckError(cl_int p_Error, const char* p_Msg)
{
    if (p_Error != CL_SUCCESS) {
      std::fprintf(stderr, "%s [%d]\n", p_Msg, p_Error);
    }
}

void RunOpenCLKernel(void* p_CmdQ, int p_Width, int p_Height, const float* p_Value, const float* p_Input, float* p_Output)
{
    cl_int error;

    cl_command_queue cmdQ = static_cast<cl_command_queue>(p_CmdQ);

    static cl_context clContext = NULL;
    if (clContext == NULL) {
        error = clGetCommandQueueInfo(cmdQ, CL_QUEUE_CONTEXT, sizeof(cl_context), &clContext, NULL);
        CheckError(error, "Unable to get the context");
    }

    static cl_device_id deviceId = NULL;
    if (deviceId == NULL) {
        error = clGetCommandQueueInfo(cmdQ, CL_QUEUE_DEVICE, sizeof(cl_device_id), &deviceId, NULL);
        CheckError(error, "Unable to get the device");
    }

    static cl_kernel kernel = NULL;
    if (kernel == NULL) {
        cl_program program = clCreateProgramWithSource(clContext, 1, (const char **)&KernelSource, NULL, &error);
        CheckError(error, "Unable to create program");

        error = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
        CheckError(error, "Unable to build program");

        kernel = clCreateKernel(program, "MultiplyKernel", &error);
        CheckError(error, "Unable to create kernel");
    }

    int count = 0;
    error  = clSetKernelArg(kernel, count++, sizeof(int), &p_Width);
    error |= clSetKernelArg(kernel, count++, sizeof(int), &p_Height);
    error |= clSetKernelArg(kernel, count++, sizeof(float), &p_Value[0]);
    error |= clSetKernelArg(kernel, count++, sizeof(float), &p_Value[1]);
    error |= clSetKernelArg(kernel, count++, sizeof(float), &p_Value[2]);
    error |= clSetKernelArg(kernel, count++, sizeof(float), &p_Value[3]);
    error |= clSetKernelArg(kernel, count++, sizeof(cl_mem), &p_Input);
    error |= clSetKernelArg(kernel, count++, sizeof(cl_mem), &p_Output);
    CheckError(error, "Unable to set kernel arguments");

    size_t localWorkSize[2], globalWorkSize[2];
    clGetKernelWorkGroupInfo(kernel, deviceId, CL_KERNEL_WORK_GROUP_SIZE, sizeof(size_t), localWorkSize, NULL);
    localWorkSize[1] = 1;
    globalWorkSize[0] = ((p_Width + localWorkSize[0] - 1) / localWorkSize[0]) * localWorkSize[0];
    globalWorkSize[1] = p_Height;

    clEnqueueNDRangeKernel(cmdQ, kernel, 2, NULL, globalWorkSize, localWorkSize, 0, NULL, NULL);
}

} // namespace MultiplyGPU {
} // namespace Plugin {
} // namespace OFX {

