#include "defineall.h"
#define LIB_INTERFACE 1
// Disable to measure the PSNR or the SSIM measure

#ifdef VERBOSE
#define DISPLAY 1
#else
#define DISPLAY 0
#endif

#define MESURES 1

//double* G_globalSimilarity = NULL;
//int G_initSim = 0;

int PatchMatch(cv::Mat &matImage, cv::Mat &matMask, cv::Mat &matOutImage)
{
    clock_t tic, toc;
    float cpu_time;     /* Total CPU time in minutes */
    
    
    cv::Mat ori_image = matImage;
    //cv::cvtColor(matImage, ori_image, cv::COLOR_RGBA2RGB);
    
    cv::Mat mask_image = matMask;
    if ((ori_image.empty()) || (mask_image.empty())) return 1;
    
    IplImage ori_ipl_img_data = cvIplImage(ori_image); //IplImage(ori_image);
    IplImage *ori_ipl_img = &ori_ipl_img_data;
    
    assert(ori_image.rows == mask_image.rows && ori_image.cols == mask_image.cols);
    int height = ori_image.rows, width = ori_image.cols;
    
    // generate mask array from mask image
    int channels = mask_image.channels();
    int step = mask_image.cols / sizeof(uchar);
    int ** mask = (int **)calloc(int(height), sizeof(int*));
    for (int i = 0; i < height; i++)
        mask[i] = (int *)calloc(int(width), sizeof(int));

    printf("----------------------------------------------------------------------\n");
    printf("\n");
    printf("Computing, please wait, this operation may take several minutes...\n");

    uchar* data = (uchar *)mask_image.data;
    //Timer: tic, toc
    tic = clock();
    for (int i = 0; i < height; ++i)
        for (int j = 0; j < width; ++j)
            if (data[i*step + j*channels] == 255)
                mask[i][j] = 1;

    Inpaint_P inp = initInpaint();
    IplImage * output_ipl_img = inpaint(inp, ori_ipl_img, (int**)mask, 2);
    if (output_ipl_img == NULL) return 1;
    cv::Mat output_image = cv::cvarrToMat(output_ipl_img);
    
    output_image.copyTo(matOutImage);
    freeInpaintingPyramid(inp);
    
    toc = clock();
    cpu_time = float((toc - tic) / CLOCKS_PER_SEC);

    //*time_total += cpu_time;

    int seconds;
    int time = (int)(cpu_time / 60);
    seconds = int(cpu_time - time * 60);

    printf("The CPU time is %i minutes and %i seconds ", time, seconds);
    
    //free memory
    cvReleaseImage(& output_ipl_img);
    for (int i = 0; i < height; ++i)
        free(mask[i]);
    free(mask);
    
    return 0;
}
#ifndef LIB_INTERFACE
int process(const char *image_path, const char *mask_path, const char *output_path, double *psnr_total, double *ssim_total, double *time_total)
{
    clock_t tic, toc;
    float cpu_time;     /* Total CPU time in minutes */

    // set random seed
    srand((unsigned)time(0));

    //Put your file name here
    std::string input_image_path = image_path;
    std::string input_mask_path = mask_path;
    std::string output_image_path = output_path;

    cv::Mat ori_image = cv::imread(input_image_path, cv::IMREAD_COLOR);
    cv::Mat mask_image = cv::imread(input_mask_path, cv::IMREAD_GRAYSCALE);
    
    cv::Mat output_image;
    PatchMatch(ori_image, mask_image, output_image);
    /*
    if ((ori_image.empty()) || (mask_image.empty())) return 1;
    IplImage ori_ipl_img_data = cvIplImage(ori_image); //IplImage(ori_image);
    IplImage *ori_ipl_img = &ori_ipl_img_data;

    assert(ori_image.rows == mask_image.rows && ori_image.cols == mask_image.cols);

    int height = ori_image.rows, width = ori_image.cols;

    //display images
    if (DISPLAY)
    {
        cv::namedWindow("Original image", cv::WINDOW_AUTOSIZE);
        cv::imshow("Original image", ori_image);

        cv::namedWindow("MASK", cv::WINDOW_AUTOSIZE);
        cv::imshow("MASK", mask_image);
    }

    // generate mask array from mask image
    int channels = mask_image.channels();
    int step = mask_image.cols / sizeof(uchar);
    int ** mask = (int **)calloc(int(height), sizeof(int*));
    for (int i = 0; i < height; i++)
        mask[i] = (int *)calloc(int(width), sizeof(int));

    printf("----------------------------------------------------------------------\n");
    printf("\n");
    printf("Computing, please wait, this operation may take several minutes...\n");

    uchar* data = (uchar *)mask_image.data;
    //Timer: tic, toc
    tic = clock();
    for (int i = 0; i < height; ++i)
        for (int j = 0; j < width; ++j)
            if (data[i*step + j*channels] == 255)
                mask[i][j] = 1;

    Inpaint_P inp = initInpaint();
    IplImage * output_ipl_img = inpaint(inp, ori_ipl_img, (int**)mask, 2);
    if (output_ipl_img == NULL) return 1;
    cv::Mat output_image = cv::cvarrToMat(output_ipl_img);
     */
    if (!cv::imwrite(output_image_path, output_image))
        printf("/!\\/!\\/!\\/!\\/!\\/!\\Could not save the resultant image. Check the path of saving.../!\\/!\\/!\\/!\\/!\\/!\\\n");

    /*---------------------------------------------- Quality Mesure ----------------------------------------------*/
    // It will be useful so far to measure the quality of the recontructed areas against the original ones
/*
#if MESURES
    double ssim;
    double psnr;

    psnr = PSNR(ori_ipl_img, output_ipl_img);
    ssim = SSIM(ori_ipl_img, output_ipl_img);

    *psnr_total += psnr;
    *ssim_total += ssim;

    printf("Quality mesures: \n");

    printf("--> PSNR=%f dB\n", psnr);
    printf("--> SSIM= %f \n", ssim);
#endif
 */
    /*------------------------------------------------------------------------------------------------------------*/
    printf("DONE\n");
    printf("\n");
    printf("The result is saved in: %s\n", output_image_path.c_str());
 /*   toc = clock();
    cpu_time = float((toc - tic) / CLOCKS_PER_SEC);

    *time_total += cpu_time;

    int seconds;
    int time = (int)(cpu_time / 60);
    seconds = int(cpu_time - time * 60);

    printf("The CPU time is %i minutes and %i seconds ", time, seconds);

    if (DISPLAY)
    {
        cv::waitKey(0);
        cv::destroyAllWindows();
    }

    //free memory
    cvReleaseImage(& output_ipl_img);
    for (int i = 0; i < height; ++i)
        free(mask[i]);
    free(mask);
  */

    return 0;
}


int main(int argc, char** argv)
{

    if ((argc != 4) && (argc != 6))
    {
        printf("Usage:\n");
        printf("log mode: %s [image_path] [mask_path] [output_path] [log_path] [misc]\n", argv[0]);
        printf("simple  : %s [image] [mask] [output]\n", argv[0]);
        exit(1);
    }

    double psnr_total = 0.0;
    double ssim_total = 0.0;
    double time_total = 0.0;

    process(argv[1], argv[2], argv[3], &psnr_total, &ssim_total, &time_total);

    if (argc == 4)
    {
        printf("average psnr: %lf\taverage ssim: %lf\taverage time: %lf\n", psnr_total, ssim_total, time_total);
    }
    else
    {
        FILE * fp = fopen(argv[4], "a");
        fprintf(fp, "%s\t%lf\t%lf\t%lf\n", argv[5], psnr_total, ssim_total, time_total);
        fclose(fp);
    }

    return 0;
}

#endif //LIB_INTERFACE
