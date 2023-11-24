__global__ void gain(int width, int height, float rGain, float gGain, float bGain, float* input, float* output)
{
   int x = blockIdx.x * blockDim.x + threadIdx.x;
   int y = blockIdx.y * blockDim.y + threadIdx.y;

   if ((x < width) && (y < height))
   {
       int index = (y * width + x) * 4;
       output[index + 0] = input[index + 0] * rGain;
       output[index + 1] = input[index + 1] * gGain;
       output[index + 2] = input[index + 2] * bGain;
       output[index + 3] = input[index + 3];
   }
}

void RunKernel(int p_Width, int p_Height, float p_RGain, float p_GGain, float p_BGain, float* p_Input, float* p_Output)
{
    dim3 threads(128, 1, 1);
    dim3 blocks((((p_Width + threads.x - 1) / threads.x) * threads.x), p_Height, 1);

    gain<<<blocks, threads>>>(p_Width, p_Height, p_RGain, p_GGain, p_BGain, p_Input, p_Output);
}
