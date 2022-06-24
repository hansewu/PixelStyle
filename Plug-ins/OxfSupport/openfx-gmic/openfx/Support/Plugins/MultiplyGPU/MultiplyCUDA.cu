#include "MultiplyGPU.h"

namespace OFX {
namespace Plugin {
namespace MultiplyGPU {

__global__ void CUDAKernel(int p_Width, int p_Height, float p_ValueR, float p_ValueG, float p_ValueB, float p_ValueA, const float* p_Input, float* p_Output)
{
   const int x = blockIdx.x * blockDim.x + threadIdx.x;
   const int y = blockIdx.y * blockDim.y + threadIdx.y;

   if ((x < p_Width) && (y < p_Height))
   {
       const int index = ((y * p_Width) + x) * 4;

       p_Output[index + 0] = p_Input[index + 0] * p_ValueR;
       p_Output[index + 1] = p_Input[index + 1] * p_ValueG;
       p_Output[index + 2] = p_Input[index + 2] * p_ValueB;
       p_Output[index + 3] = p_Input[index + 3] * p_ValueA;
   }
}

void RunCUDAKernel(int p_Width, int p_Height, const float* p_Value, const float* p_Input, float* p_Output)
{
    dim3 threads(128, 1, 1);
    dim3 blocks(((p_Width + threads.x - 1) / threads.x), p_Height, 1);

    CUDAKernel<<<blocks, threads>>>(p_Width, p_Height, p_Value[0], p_Value[1], p_Value[2], p_Value[3], p_Input, p_Output);
}

} // namespace MultiplyGPU {
} // namespace Plugin {
} // namespace OFX {
