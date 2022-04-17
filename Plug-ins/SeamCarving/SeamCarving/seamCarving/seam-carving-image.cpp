#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include <iostream>
#include <fstream>
#include <cstring>


using namespace cv;
using namespace std;

static bool g_stopSeamCarving;

inline int get(Mat I, int x, int y)
{
    return (int)I.at<uchar>(y,x);
}

Mat calculate_energy(Mat I){
    int Y = I.rows,X = I.cols;
    Mat energy = Mat(Y, X, CV_32S);

    for(int x = 0;x < X;++x){
        for(int y = 0;y < Y;++y){
            int val = 0;

            if(x > 0 && x + 1 < X)
                val += abs((int)I.at<uchar>(y,x + 1) - (int)I.at<uchar>(y,x - 1));
            else if(x > 0)
                val += 2 * abs((int)I.at<uchar>(y,x) - (int)I.at<uchar>(y,x - 1));
            else if(x == 0)
                val += 2 * 0;
            else
                val += 2 * abs((int)I.at<uchar>(y,x + 1) - (int)I.at<uchar>(y,x));

            if(y > 0 && y + 1 < Y)
                val += abs((int)I.at<uchar>(y + 1,x) - (int)I.at<uchar>(y - 1,x));
            else if(y > 0)
                val += 2 * abs((int)I.at<uchar>(y,x) - (int)I.at<uchar>(y - 1,x));
            else if(y == 0)
                val += 2 * 0;
            else
                val += 2 * abs((int)I.at<uchar>(y + 1,x) - (int)I.at<uchar>(y,x));

            energy.at<int>(y,x) = val;
        }
    }

    return energy;
}

//#define MAXR 1000
//#define MAXC 1000
//
////Mat gray,energy;
//int dpH[MAXR][MAXC],dpV[MAXR][MAXC];
//int dirH[MAXR][MAXC],dirV[MAXR][MAXC];

/*
void reduce(Mat &I, int YF, int XF, bool forward=false){
    cout << "REDUCE" << endl;
    int Y0 = I.rows,X0 = I.cols;
    int Y = Y0,X = X0;
    
    pair<int, int> **pos = NULL;
    *pos = (pair<int, int> *)malloc(sizeof(int)*2*X);
    for (int i = 0; i < X; ++i)
    {
        pos[i] = (pair<int, int> *)malloc(sizeof(int)*2*Y);
    }
    
//    pair<int, int> pos[X][Y];
    for(int i = 0;i < X;++i)
        for(int j = 0;j < Y;++j)
            pos[i][j] = make_pair(i,j);

    Mat seams = I.clone();

    // Horizontal seams

    for(int it = 0;it < Y0 - YF;++it){
        cvtColor(I,gray,CV_BGRA2GRAY);
        energy = calculate_energy(gray);

        for(int y = 0;y < Y;++y)
            dpH[0][y] = energy.at<int>(y,0);

        for(int x = 1;x < X;++x){
            for(int y = 0;y < Y;++y){
                unsigned int val = energy.at<int>(y,x);
                dpH[x][y] = -1;

                int cost1 = 0,cost2 = 0,cost3 = 0;

                if(!forward){
                    cost1 = val;
                    cost2 = val;
                    cost3 = val;
                }else{
                    if(y > 0 && y + 1 < Y){
                        cost1 = abs(get(gray,x,y - 1) - get(gray,x,y + 1));
                    }else if(y == 0){
                        cost1 = abs(get(gray,x,y) - get(gray,x,y + 1));
                    }else{
                        cost1 = abs(get(gray,x,y - 1) - get(gray,x,y));
                    }
                    
                    cost1 = cost1 + val;
                    cost2 = cost1;
                    cost3 = cost1;

                    if(y > 0)
                        cost1 += abs(get(gray,x,y - 1) - get(gray,x - 1,y));

                    if(y + 1 < Y)
                        cost3 += abs(get(gray,x,y + 1) - get(gray,x - 1,y + 1));
                }

                if(y > 0 && (dpH[x][y] == -1 || cost1 + dpH[x - 1][y - 1] < dpH[x][y])){
                    dpH[x][y] = cost1 + dpH[x - 1][y - 1];
                    dirH[x][y] = -1;
                }

                if(dpH[x][y] == -1 || cost2 + dpH[x - 1][y] < dpH[x][y]){
                    dpH[x][y] = cost2 + dpH[x - 1][y];
                    dirH[x][y] = 0;
                }

                if(y + 1 < Y && (dpH[x][y] == -1 || cost3 + dpH[x - 1][y + 1] < dpH[x][y])){
                    dpH[x][y] = cost3 + dpH[x - 1][y + 1];
                    dirH[x][y] = 1;
                }
            }
        }

        int bestH = dpH[X - 1][0];
        int cury = 0;

        for(int y = 0;y < Y;++y){
            if(dpH[X - 1][y] < bestH){
                bestH = dpH[X - 1][y];
                cury = y;
            }
        }

        Mat_<Vec4b> tmp(Y - 1,X);

        for(int x = X - 1,cont = 0;x >= 0;--x,++cont){
            for(int i = 0;i < Y;++i){
                if(i < cury){
                    tmp.at<Vec4b>(i,x) = I.at<Vec4b>(i,x);
                }else if(i > cury){
                    tmp.at<Vec4b>(i - 1,x) = I.at<Vec4b>(i,x);
                    pos[x][i - 1] = pos[x][i];
                }else{
                    seams.at<Vec4b>(pos[x][i].second, pos[x][i].first) = Vec4b(0,0,255);
                }
            }

            if(x > 0)
                cury = cury + dirH[x][cury];
        }

        I = tmp;
        --Y;
    }

    // Vertical seams

    for(int it = 0;it < X0 - XF;++it){
        cvtColor(I,gray,CV_BGRA2GRAY);
        energy = calculate_energy(gray);

        for(int x = 0;x < X;++x)
            dpV[x][0] = energy.at<int>(0,x); 

        for(int y = 1;y < Y;++y){
            for(int x = 0;x < X;++x){
                int val = energy.at<int>(y,x);
                dpV[x][y] = -1;

                int cost1 = 0,cost2 = 0,cost3 = 0;

                if(!forward){
                    cost1 = val;
                    cost2 = val;
                    cost3 = val;
                }else{
                    if(x > 0 && x + 1 < X){
                        cost1 = abs(get(gray,x - 1,y) - get(gray,x + 1,y));
                    }else if(x == 0){
                        cost1 = abs(get(gray,x,y) - get(gray,x + 1,y));
                    }else{
                        cost1 = abs(get(gray,x - 1,y) - get(gray,x,y));
                    }

                    cost2 = cost1;
                    cost3 = cost1;

                    if(x > 0)
                        cost1 += abs(get(gray,x - 1,y) - get(gray,x,y - 1));

                    if(x + 1 < X)
                        cost3 += abs(get(gray,x + 1,y) - get(gray,x,y - 1));
                }

                if(x > 0 && (dpV[x][y] == -1 || cost1 + dpV[x - 1][y - 1] < dpV[x][y])){
                    dpV[x][y] = cost1 + dpV[x - 1][y - 1];
                    dirV[x][y] = -1;
                }

                if(dpV[x][y] == -1 || cost2 + dpV[x][y - 1] < dpV[x][y]){
                    dpV[x][y] = cost2 + dpV[x][y - 1];
                    dirV[x][y] = 0;
                }

                if(x + 1 < X && (dpV[x][y] == -1 || cost3 + dpV[x + 1][y - 1] < dpV[x][y])){
                    dpV[x][y] = cost3 + dpV[x + 1][y - 1];
                    dirV[x][y] = 1;
                }
            }
        }

        int bestV = dpV[0][Y - 1];
        int curx = 0;

        for(int x = 0;x < X;++x){
            if(dpV[x][Y - 1] < bestV){
                bestV = dpV[x][Y - 1];
                curx = x;
            }
        }

        Mat_<Vec4b> tmp(Y,X - 1);

        for(int y = Y - 1;y >= 0;--y){
            for(int i = 0;i < X;++i){
                if(i < curx){
                    tmp.at<Vec4b>(y,i) = I.at<Vec4b>(y,i);
                }else if(i > curx){
                    tmp.at<Vec4b>(y,i - 1) = I.at<Vec4b>(y,i);
                    pos[i - 1][y] = pos[i][y];
                }else{
                    seams.at<Vec4b>(pos[i][y].second, pos[i][y].first) = Vec4b(0,0,255);
                }
            }

            if(y > 0)
                curx = curx + dirV[curx][y];
        }

        I = tmp;
        --X;
    }

    string w1 = "seams",w2 = "seam-carving-out";

    if(forward){
        w1 += "-forward";
        w2 += "-forward";
    }

    imshow(w1,seams);

    if(forward)
        imwrite("seams-forward.jpg", seams);
    else
        imwrite("seams.jpg", seams);

    imshow(w2,I);

    if(forward)
        imwrite("result-forward.jpg",I);
    else
        imwrite("result.jpg",I);

    waitKey(0);
}
*/

void remove_horizontal(Mat &Image, int nOutPutHeight, Mat &horizontalSeam)
{
    int nRows = Image.rows;
    int nOutRows = nRows,nCols = Image.cols;
    
    vector<vector<int>> dpH(nCols, vector<int>(nOutRows));
    vector<vector<int>> dirH(nCols, vector<int>(nOutRows));
    //bool mark[nOutRows][nCols];
    vector<vector<bool>> mark(nOutRows, vector<bool>(nCols, false));
    //memset(mark,false,sizeof mark);
    
    //int pos[nCols][nOutRows];
    vector<vector<int>> pos(nCols, vector<int>(nOutRows));
        
    for(int i = 0;i < nCols;++i)
        for(int j = 0;j < nOutRows;++j)
            pos[i][j] = j;

    
    for(int it = 0;it < nRows - nOutPutHeight && (!g_stopSeamCarving);++it)
    {
        Mat gray = Mat(Image.rows, Image.cols, CV_8UC1);
        cvtColor(Image,gray,cv::COLOR_BGRA2GRAY);
        Mat energy = calculate_energy(gray);

        for(int y = 0;y < nOutRows;++y)
            dpH[0][y] = energy.at<int>(y,0);

        for(int x = 1;x < nCols;++x)
        {
            for(int y = 0;y < nOutRows;++y)
            {
                unsigned int val = energy.at<int>(y,x);
                dpH[x][y] = -1;

                if(y > 0 && (dpH[x][y] == -1 || val + dpH[x - 1][y - 1] < dpH[x][y]))
                {
                    dpH[x][y] = val + dpH[x - 1][y - 1];
                    dirH[x][y] = -1;
                }

                if(dpH[x][y] == -1 || val + dpH[x - 1][y] < dpH[x][y])
                {
                    dpH[x][y] = val + dpH[x - 1][y];
                    dirH[x][y] = 0;
                }

                if(y + 1 < nOutRows && (dpH[x][y] == -1 || val + dpH[x - 1][y + 1] < dpH[x][y]))
                {
                    dpH[x][y] = val + dpH[x - 1][y + 1];
                    dirH[x][y] = 1;
                }
            }
        }

        int bestH = dpH[nCols - 1][0];
        int cury = 0;

        for(int y = 0;y < nOutRows;++y)  //最后一列的最小值
        {
            if(dpH[nCols - 1][y] < bestH)
            {
                bestH = dpH[nCols - 1][y];
                cury = y;
            }
        }

        Mat_<Vec4b> tmp(nOutRows - 1,nCols);

        for(int x = nCols - 1,cont = 0;x >= 0;--x,++cont)
        {
//            horizontalSeam.at<uchar>(cury,x) = 255;
            for(int i = 0;i < nOutRows;++i)
            {
                if(i < cury)
                {
                    tmp.at<Vec4b>(i,x) = Image.at<Vec4b>(i,x);
                }
                else if(i > cury)
                {
                    tmp.at<Vec4b>(i - 1,x) = Image.at<Vec4b>(i,x);
                    pos[x][i - 1] = pos[x][i];
                }
                else
                {
                    mark[ pos[x][i] ][x] = true;
                }
            }

            if(x > 0)
                cury = cury + dirH[x][cury];
        }

        Image = tmp;
        --nOutRows;
    }
    
    for(int j = 0;j < nCols;++j)
    {
        for(int i = 0;i < nRows;++i)
        {
            if(mark[i][j])
            {
                horizontalSeam.at<uchar>(i,j) = 255;
            }
        }
    }

}

void remove_vertical(Mat &Image, int nOutputWidth, Mat &verticalSeam){
    int nCols = Image.cols;
    int nOutCols = nCols,nRows = Image.rows;

    vector<vector<int>> dpV(nCols, vector<int>(nRows));
    vector<vector<int>> dirV(nCols, vector<int>(nRows));
    
//    bool mark[nRows][nOutCols];
//    int pos[nOutCols][nRows];
//
//    memset(mark,false,sizeof mark);
    vector<vector<bool>> mark(nRows, vector<bool>(nOutCols, false));
    vector<vector<int>> pos(nOutCols, vector<int>(nRows));
    
    for(int i = 0;i < nOutCols;++i)
        for(int j = 0;j < nRows;++j)
            pos[i][j] = i;
    
    for(int it = 0;it < nCols - nOutputWidth && (!g_stopSeamCarving);++it){
         Mat gray = Mat(Image.rows, Image.cols, CV_8UC1);
        cvtColor(Image,gray,COLOR_BGRA2GRAY);
        Mat energy = calculate_energy(gray);

        for(int x = 0;x < nOutCols;++x)
            dpV[x][0] = energy.at<int>(0,x);

        for(int y = 1;y < nRows;++y){
            for(int x = 0;x < nOutCols;++x){
                int val = energy.at<int>(y,x);
                dpV[x][y] = -1;

                if(x > 0 && (dpV[x][y] == -1 || val + dpV[x - 1][y - 1] < dpV[x][y])){
                    dpV[x][y] = val + dpV[x - 1][y - 1];
                    dirV[x][y] = -1;
                }

                if(dpV[x][y] == -1 || val + dpV[x][y - 1] < dpV[x][y]){
                    dpV[x][y] = val + dpV[x][y - 1];
                    dirV[x][y] = 0;
                }

                if(x + 1 < nOutCols && (dpV[x][y] == -1 || val + dpV[x + 1][y - 1] < dpV[x][y])){
                    dpV[x][y] = val + dpV[x + 1][y - 1];
                    dirV[x][y] = 1;
                }
            }
        }

        int bestV = dpV[0][nRows - 1];
        int curx = 0;

        for(int x = 0;x < nOutCols;++x){
            if(dpV[x][nRows - 1] < bestV){
                bestV = dpV[x][nRows - 1];
                curx = x;
            }
        }

        Mat_<Vec4b> tmp(nRows,nOutCols - 1);

        for(int y = nRows - 1;y >= 0;--y)
        {
//            verticalSeam.at<uchar>(y,curx) = 255;
            for(int i = 0;i < nOutCols;++i)
            {
                if(i < curx){
                    tmp.at<Vec4b>(y,i) = Image.at<Vec4b>(y,i);
                }else if(i > curx){
                    tmp.at<Vec4b>(y,i - 1) = Image.at<Vec4b>(y,i);
                    pos[i - 1][y] = pos[i][y];
                }else{
                    mark[y][ pos[i][y]] = true;
                }
            }

            if(y > 0)
                curx = curx + dirV[curx][y];
        }

        Image = tmp;
        --nOutCols;
    }
    
    
    for(int i = 0;i < nRows;++i)
    {
        for(int j = 0;j < nCols;++j)
        {
            if(mark[i][j])
                verticalSeam.at<uchar>(i,j) = 255;
        }
    }
}

Vec4b average(Vec4b x, Vec4b y){
    Vec4b ret;

    for(int i = 0;i < 4;++i)
        ret.val[i] = (x.val[i] + y.val[i]) / 2;
    
    return ret;
}

void add_horizontal(Mat &Image, int nOutputHeight, Mat &horizontalSeam){
    Mat I0 = Image;
    int Y0 = Image.rows;
    int Y = Y0,X = Image.cols;
    
    vector<vector<int>> dpH(Image.cols, vector<int>(nOutputHeight));
    vector<vector<int>> dirH(Image.cols, vector<int>(nOutputHeight));

    vector<vector<bool>> mark(nOutputHeight, vector<bool>(Image.cols, false));
    vector<vector<int>> pos(Image.cols, vector<int>(nOutputHeight));
 
//    bool mark[Y][X];
//    int pos[X][Y];
//
//    memset(mark,false,sizeof mark);

    for(int i = 0;i < X;++i)
        for(int j = 0;j < Y;++j)
            pos[i][j] = j;
    
    for(int it = 0;it < nOutputHeight - Y0 && (!g_stopSeamCarving);++it){
        
        if(Image.rows <= 0) break;
        Mat gray = Mat(Image.rows, Image.cols, CV_8UC1);
        cvtColor(Image,gray, COLOR_BGRA2GRAY);
        Mat energy = calculate_energy(gray);

        for(int y = 0;y < Y;++y)
            dpH[0][y] = energy.at<int>(y,0);

        for(int x = 1;x < X;++x){
            for(int y = 0;y < Y;++y){
                unsigned int val = energy.at<int>(y,x);
                dpH[x][y] = -1;

                if(y > 0 && (dpH[x][y] == -1 || val + dpH[x - 1][y - 1] < dpH[x][y])){
                    dpH[x][y] = val + dpH[x - 1][y - 1];
                    dirH[x][y] = -1;
                }

                if(dpH[x][y] == -1 || val + dpH[x - 1][y] < dpH[x][y]){
                    dpH[x][y] = val + dpH[x - 1][y];
                    dirH[x][y] = 0;
                }

                if(y + 1 < Y && (dpH[x][y] == -1 || val + dpH[x - 1][y + 1] < dpH[x][y])){
                    dpH[x][y] = val + dpH[x - 1][y + 1];
                    dirH[x][y] = 1;
                }
            }
        }

        int bestH = dpH[X - 1][0];
        int cury = 0;

        for(int y = 0;y < Y;++y){
            if(dpH[X - 1][y] < bestH){
                bestH = dpH[X - 1][y];
                cury = y;
            }
        }

        Mat_<Vec4b> tmp(Y - 1,X);

        for(int x = X - 1,cont = 0;x >= 0;--x,++cont)
        {
//            horizontalSeam.at<uchar>(cury,x) = 255;
            for(int i = 0;i < Y;++i)
            {
                if(i < cury){
                    tmp.at<Vec4b>(i,x) = Image.at<Vec4b>(i,x);
                }else if(i > cury){
                    tmp.at<Vec4b>(i - 1,x) = Image.at<Vec4b>(i,x);
                    pos[x][i - 1] = pos[x][i];
                }else{
                    mark[ pos[x][i] ][x] = true;
                }
            }

            if(x > 0)
                cury = cury + dirH[x][cury];
        }

        Image = tmp;
        --Y;
    }

    Mat_<Vec4b> tmp(nOutputHeight,X);

    for(int j = 0;j < X;++j){
        int cont = 0;

        for(int i = 0;i < Y0;++i){
            if(mark[i][j]){
                horizontalSeam.at<uchar>(i,j) = 255;
                
                Vec4b aux;

                if(i == 0) aux = average(I0.at<Vec4b>(i,j),I0.at<Vec4b>(i + 1,j));
                else if(i == Y0 - 1) aux = average(I0.at<Vec4b>(i,j),I0.at<Vec4b>(i - 1,j));
                else aux = average(I0.at<Vec4b>(i - 1,j),I0.at<Vec4b>(i + 1,j));

                tmp.at<Vec4b>(cont,j) = aux; cont++;
                tmp.at<Vec4b>(cont,j) = aux; cont++;
            }else{
                tmp.at<Vec4b>(cont,j) = I0.at<Vec4b>(i,j);
                cont++;
            }
        }
    }

    Image = tmp;
}

void add_vertical(Mat &inputImage, int nOutputWidth, Mat &verticalSeam){
    Mat inputImageCopy = inputImage;
    int nInputImageCols = inputImage.cols;
    int nCols = nInputImageCols,nRows = inputImage.rows;
    
    vector<vector<int>> dpV(nOutputWidth, vector<int>(inputImage.rows));
    vector<vector<int>> dirV(nOutputWidth, vector<int>(inputImage.rows));

    vector<vector<bool>> mark(inputImage.rows, vector<bool>(nOutputWidth, false));
    vector<vector<int>> pos(nOutputWidth, vector<int>(inputImage.rows));
    
//    bool mark[nRows][nCols];
//    int pos[nCols][nRows];
//
//    memset(mark,false,sizeof mark);

    for(int i = 0;i < nCols;++i)
        for(int j = 0;j < nRows;++j)
            pos[i][j] = i;

    for(int it = 0;it < nOutputWidth - nInputImageCols && (!g_stopSeamCarving);++it){
        
        if(inputImage.cols <= 0) break;
        
//        printf("it = %d\n", it);
        Mat gray = Mat(inputImage.rows, inputImage.cols, CV_8UC1);
        cvtColor(inputImage,gray,COLOR_BGRA2GRAY);
        Mat energy = calculate_energy(gray);

        for(int x = 0;x < nCols;++x)
            dpV[x][0] = energy.at<int>(0,x);

        for(int y = 1;y < nRows;++y){
            for(int x = 0;x < nCols;++x){
                int val = energy.at<int>(y,x);
                dpV[x][y] = -1;

                if(x > 0 && (dpV[x][y] == -1 || val + dpV[x - 1][y - 1] < dpV[x][y])){
                    dpV[x][y] = val + dpV[x - 1][y - 1];
                    dirV[x][y] = -1;
                }

                if(dpV[x][y] == -1 || val + dpV[x][y - 1] < dpV[x][y]){
                    dpV[x][y] = val + dpV[x][y - 1];
                    dirV[x][y] = 0;
                }

                if(x + 1 < nCols && (dpV[x][y] == -1 || val + dpV[x + 1][y - 1] < dpV[x][y])){
                    dpV[x][y] = val + dpV[x + 1][y - 1];
                    dirV[x][y] = 1;
                }
            }
        }

        int bestV = dpV[0][nRows - 1];
        int curx = 0;

        for(int x = 0;x < nCols;++x){
            if(dpV[x][nRows - 1] < bestV){
                bestV = dpV[x][nRows - 1];
                curx = x;
            }
        }

        Mat_<Vec4b> tmp(nRows,nCols - 1);

        for(int y = nRows - 1;y >= 0;--y)
        {
            for(int i = 0;i < nCols;++i)
            {
                if(i < curx){
                    tmp.at<Vec4b>(y,i) = inputImage.at<Vec4b>(y,i);
                }else if(i > curx){
                    tmp.at<Vec4b>(y,i - 1) = inputImage.at<Vec4b>(y,i);
                    pos[i - 1][y] = pos[i][y];
                }else{
                    mark[y][ pos[i][y]] = true;
                }
                
            }
            
            if(y > 0)
                curx = curx + dirV[curx][y];
        }
        inputImage = tmp;
        --nCols;
    }

    Mat_<Vec4b> tmp(nRows,nOutputWidth);

    for(int i = 0;i < nRows;++i){
        int cont = 0;

        for(int j = 0;j < nInputImageCols;++j){
            if(mark[i][j]){
                verticalSeam.at<uchar>(i,j) = 255;
                
                Vec4b aux;
                
                if(j == 0) aux = average(inputImageCopy.at<Vec4b>(i,j),inputImageCopy.at<Vec4b>(i,j + 1));
                else if(j == nInputImageCols - 1) aux = average(inputImageCopy.at<Vec4b>(i,j),inputImageCopy.at<Vec4b>(i,j - 1));
                else aux = average(inputImageCopy.at<Vec4b>(i,j - 1),inputImageCopy.at<Vec4b>(i,j + 1));

                tmp.at<Vec4b>(i,cont) = aux; cont++;
                tmp.at<Vec4b>(i,cont) = aux; cont++;
            }else{
                tmp.at<Vec4b>(i,cont) = inputImageCopy.at<Vec4b>(i,j);
                cont++;
            }
        }
    }

    inputImage = tmp;
}

void process(Mat &I, int nOutputImageHeight, int nOutputImageWidth, Mat &horizontalSeam, Mat &verticalSeam){
    cout << "Process (" << I.rows << ", " << I.cols << ") -> (" << nOutputImageHeight << ", " << nOutputImageWidth << ")" << endl;
    
    if(nOutputImageHeight < I.rows)
        remove_horizontal(I,nOutputImageHeight,horizontalSeam);
    else if(nOutputImageHeight > I.rows)
        add_horizontal(I,nOutputImageHeight,horizontalSeam);
    
    if(nOutputImageWidth < I.cols)
        remove_vertical(I,nOutputImageWidth,verticalSeam);
    else if(nOutputImageWidth > I.cols)
        add_vertical(I,nOutputImageWidth,verticalSeam);
}



#pragma mark - resizeWithSeams
#import "SeamCarveApi.h"

void removeHorizontalSeams(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData,IMAGE_DATA *pHorizontalSeamsData)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth         = pInputData->nWidth;
    int nInputHeight        = pInputData->nHeight;
    int nOutputWidth        = pOutputData->nWidth;
    int nOutputHeight       = pOutputData->nHeight;
    int nInputChannels      = pInputData->nChannels;
    int nOutputChannels     = pOutputData->nChannels;
    
    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    assert(nOutputHeight <= nInputHeight);
    assert(nInputChannels == nOutputChannels);
    
    int nSeamsWidth         = pHorizontalSeamsData->nWidth;
    int nSeamsHeight        = pHorizontalSeamsData->nHeight;
    assert(nSeamsWidth && nSeamsHeight);
    
    assert(pHorizontalSeamsData->nChannels == 1);
    
    //Horizontal seams
    for (int x = 0; x < nOutputWidth; x++)
    {
        for (int y = 0, nInputY = 0; y < nOutputHeight && nInputY < nInputHeight; y++, nInputY ++)
        {
            do
            {
                if(nInputY >= pHorizontalSeamsData->nHeight)
                {
                    nInputY = pHorizontalSeamsData->nHeight -1;
                    break;
                }
                else if(pHorizontalSeamsData->pData[nInputY*1 * nOutputWidth + x * 1] > 0)
                    nInputY ++;
                else
                    break;
            }while (1);
            
            for (int n = 0; n < nInputChannels; n++)
            {
                pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = pInputData->pData[nInputY*nInputChannels * nInputWidth + x * nInputChannels + n];
            }
        }
    }
}

void removeVerticalSeams(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData,IMAGE_DATA *pVerticalSeamsData)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth         = pInputData->nWidth;
    int nInputHeight        = pInputData->nHeight;
    int nOutputWidth        = pOutputData->nWidth;
    int nOutputHeight       = pOutputData->nHeight;
    int nInputChannels      = pInputData->nChannels;
    int nOutputChannels     = pOutputData->nChannels;
    
    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    assert(nOutputWidth <= nInputWidth);
    assert(nInputChannels == nOutputChannels);
    
    int nSeamsWidth = pVerticalSeamsData->nWidth;
    int nSeamsHeight = pVerticalSeamsData->nHeight;
    assert(nSeamsWidth && nSeamsHeight);
    
    assert(pVerticalSeamsData->nChannels == 1);
    
    
    
    //Vertical seams
    for (int y = 0; y < nOutputHeight; y++)
    {
        for (int x = 0, nInputX = 0; x < nOutputWidth && nInputX < nInputWidth; x++, nInputX++)
        {
            do
            {
                if(nInputX >= pVerticalSeamsData->nWidth)
                {
                    nInputX = pVerticalSeamsData->nWidth -1;
                    break;
                }
                else if(pVerticalSeamsData->pData[y*1 * nSeamsWidth + nInputX * 1] > 0)
                {
                    nInputX ++;
                }
                else
                    break;
            }while (1);
            
            for (int n = 0; n < nInputChannels; n++)
            {
                pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = pInputData->pData[y*nInputChannels * nInputWidth + nInputX * nInputChannels + n];
            }
        }
    }
}

void addHorizontalSeams(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData,IMAGE_DATA *pHorizontalSeamsData)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth         = pInputData->nWidth;
    int nInputHeight        = pInputData->nHeight;
    int nOutputWidth        = pOutputData->nWidth;
    int nOutputHeight       = pOutputData->nHeight;
    int nInputChannels      = pInputData->nChannels;
    int nOutputChannels     = pOutputData->nChannels;

    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    assert(nOutputHeight >= nInputHeight);
    assert(nInputChannels == nOutputChannels);
    
    int nSeamsWidth         = pHorizontalSeamsData->nWidth;
    int nSeamsHeight        = pHorizontalSeamsData->nHeight;
    assert(nSeamsWidth && nSeamsHeight);
    
    assert(pHorizontalSeamsData->nChannels == 1);
    
    //Horizontal seams
    for (int x = 0; x < nOutputWidth; x++)
    {
        for (int y = 0,nInputY = 0; y < nOutputHeight && nInputY < nInputHeight; y++,nInputY++)
        {
            int nPoint1Y        = 0;
            int nPoint2Y        = 0;
            if(nInputY == 0)
            {
                nPoint1Y        = nInputY;
                nPoint2Y        = nInputY + 1;
            }
            else if(nInputY == nInputHeight - 1)
            {
                nPoint1Y        = nInputY;
                nPoint2Y        = nInputY - 1;
            }
            else
            {
                nPoint1Y        = nInputY - 1;
                nPoint2Y        = nInputY + 1;
            }
            
            int nValue[4]       = {0};
            nValue[0]           = (pInputData->pData[nPoint1Y*nInputChannels * nInputWidth + x * nInputChannels] + pInputData->pData[nPoint2Y*nInputChannels * nInputWidth + x * nInputChannels])/2.0;
            nValue[1]           = (pInputData->pData[nPoint1Y*nInputChannels * nInputWidth + x * nInputChannels + 1] + pInputData->pData[nPoint2Y*nInputChannels * nInputWidth + x * nInputChannels + 1])/2.0;
            nValue[2]           = (pInputData->pData[nPoint1Y*nInputChannels * nInputWidth + x * nInputChannels + 2] + pInputData->pData[nPoint2Y*nInputChannels * nInputWidth + x * nInputChannels + 2])/2.0;
            nValue[3]           = (pInputData->pData[nPoint1Y*nInputChannels * nInputWidth + x * nInputChannels + 3] + pInputData->pData[nPoint2Y*nInputChannels * nInputWidth + x * nInputChannels + 3])/2.0;
            
            
            if(pHorizontalSeamsData->pData[nInputY*1 * nInputWidth + x * 1] > 0)
            {
                for (int n = 0; n < nInputChannels; n++)
                    pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = nValue[n];
                
                y++;
                if(y < nOutputHeight)
                {
                    for (int n = 0; n < nInputChannels; n++)
                        pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = nValue[n];
                }
            }
            else
            {
                for (int n = 0; n < nInputChannels; n++)
                    pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = pInputData->pData[nInputY*nInputChannels * nInputWidth + x * nInputChannels + n];
            }
        }
        
    }
}

void addVerticalSeams(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData,IMAGE_DATA *pVerticalSeamsData)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth         = pInputData->nWidth;
    int nInputHeight        = pInputData->nHeight;
    int nOutputWidth        = pOutputData->nWidth;
    int nOutputHeight       = pOutputData->nHeight;
    int nInputChannels      = pInputData->nChannels;
    int nOutputChannels     = pOutputData->nChannels;
    
    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    assert(nOutputWidth >= nInputWidth);
    assert(nInputChannels == nOutputChannels);
    
    int nSeamsWidth         = pVerticalSeamsData->nWidth;
    int nSeamsHeight        = pVerticalSeamsData->nHeight;
    assert(nSeamsWidth && nSeamsHeight);
    
    assert(pVerticalSeamsData->nChannels == 1);
    
    //Vertical seams
    
    for (int y = 0; y < nOutputHeight; y++)
    {
        for (int x = 0, nInputX = 0; x < nOutputWidth && nInputX < nInputWidth; x++, nInputX++)
        {
            int nPoint1X        = 0;
            int nPoint2X        = 0;
            if(nInputX == 0)
            {
                nPoint1X        = nInputX;
                nPoint2X        = nInputX + 1;
            }
            else if(nInputX == nInputWidth - 1)
            {
                nPoint1X        = nInputX;
                nPoint2X        = nInputX - 1;
            }
            else
            {
                nPoint1X        = nInputX + 1;
                nPoint2X        = nInputX - 1;
            }
            
            int nValue[4]       = {0};
            nValue[0]           = (pInputData->pData[y*nInputChannels * nInputWidth + nPoint1X * nInputChannels] + pInputData->pData[y*nInputChannels * nInputWidth + nPoint2X * nInputChannels])/2.0;
            nValue[1]           = (pInputData->pData[y*nInputChannels * nInputWidth + nPoint1X * nInputChannels + 1] + pInputData->pData[y*nInputChannels * nInputWidth + nPoint2X * nInputChannels + 1])/2.0;
            nValue[2]           = (pInputData->pData[y*nInputChannels * nInputWidth + nPoint1X * nInputChannels + 2] + pInputData->pData[y*nInputChannels * nInputWidth + nPoint2X * nInputChannels + 2])/2.0;
            nValue[3]           = (pInputData->pData[y*nInputChannels * nInputWidth + nPoint1X * nInputChannels + 3] + pInputData->pData[y*nInputChannels * nInputWidth + nPoint2X * nInputChannels + 3])/2.0;
            
            
            if(pVerticalSeamsData->pData[y*1 * nInputWidth + nInputX * 1] > 0)
            {
                for (int n = 0; n < nInputChannels; n++)
                    pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = nValue[n];
                
                x++;
                if(x < nOutputWidth)
                {
                    for (int n = 0; n < nInputChannels; n++)
                        pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = nValue[n];
                }
            }
            else
            {
                for (int n = 0; n < nInputChannels; n++)
                    pOutputData->pData[y*nOutputChannels * nOutputWidth + x * nOutputChannels + n] = pInputData->pData[y*nInputChannels * nInputWidth + nInputX * nInputChannels + n];
            }
        }
    }
}

#pragma mark - api
int seamcarveImage(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData, IMAGE_DATA *pHorizontalSeamsData, IMAGE_DATA *pVerticalSeamsData)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth     = pInputData->nWidth;
    int nInputHeight    = pInputData->nHeight;
    int nOutputWidth    = pOutputData->nWidth;
    int nOutputHeight   = pOutputData->nHeight;
    int nChannels       = pInputData->nChannels;
    
    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    assert(pHorizontalSeamsData->nChannels == 1);
    assert(pVerticalSeamsData->nChannels == 1);
    
    
    
    Mat_<Vec4b> image;
    if(nChannels == 4)
    {
        image = Mat(nInputHeight, nInputWidth, CV_8UC4, pInputData->pData);
    }
    else
    {
        cout << "Invalid input, seamcarveImage only support 4 channels";
        return -1;
    }
    
    if (!image.data)
    {
        cout << "Invalid input";
        image.release();
        return -1;
    }
    
    
    Mat imageCopy = image;
    Mat horizontalseams = Mat(nInputHeight, nInputWidth, CV_8UC1, pHorizontalSeamsData->pData);
    Mat verticalseams = Mat(nOutputHeight, nInputWidth, CV_8UC1, pVerticalSeamsData->pData);
    process(imageCopy, nOutputHeight, nOutputWidth, horizontalseams, verticalseams);
    
    
    //处理输出
    if(nChannels == 4)
    {
        memcpy(pOutputData->pData, imageCopy.data, nOutputWidth * nOutputHeight*4);
    }
    
    memcpy(pHorizontalSeamsData->pData, horizontalseams.data, nInputWidth * nInputHeight * 1);
    memcpy(pVerticalSeamsData->pData, verticalseams.data, nInputWidth * nOutputHeight * 1);
    
    return 0;
}

int resizeImageWithSeams(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData, IMAGE_DATA *pHorizontalSeamsData, IMAGE_DATA *pVerticalSeamsData)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth         = pInputData->nWidth;
    int nInputHeight        = pInputData->nHeight;
    int nOutputWidth        = pOutputData->nWidth;
    int nOutputHeight       = pOutputData->nHeight;
    int nInputChannels      = pInputData->nChannels;
    int nOutputChannels     = pOutputData->nChannels;
    
    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    assert(nInputChannels == nOutputChannels);
    
    int nSeamsWidth         = pHorizontalSeamsData->nWidth;
    int nSeamsHeight        = pHorizontalSeamsData->nHeight;
    assert(nSeamsWidth && nSeamsHeight);
    
    assert(pHorizontalSeamsData->nChannels == 1);
    assert(pVerticalSeamsData->nChannels == 1);
    
    IMAGE_DATA pTempData;
    pTempData.nWidth        = nInputWidth;
    pTempData.nHeight       = nOutputHeight;
    pTempData.nChannels     = nOutputChannels;
    unsigned char *pData    = (unsigned char *)malloc(pTempData.nWidth * pTempData.nHeight *pTempData.nChannels);
    pTempData.pData         = pData;
    
    //HorizontalSeams
    if(nOutputHeight < nInputHeight)
        removeHorizontalSeams(pInputData, &pTempData, pHorizontalSeamsData);
    else if(nOutputHeight > nInputHeight)
        addHorizontalSeams(pInputData, &pTempData, pHorizontalSeamsData);
    else
        memcpy(pTempData.pData, pInputData->pData, pTempData.nWidth * pTempData.nHeight * pTempData.nChannels);
    
    //VerticalSeams
    if(nOutputWidth < nInputWidth)
        removeVerticalSeams(&pTempData, pOutputData, pVerticalSeamsData);
    else if(nOutputWidth > nInputWidth)
        addVerticalSeams(&pTempData, pOutputData, pVerticalSeamsData);
    else
        memcpy(pOutputData->pData, pTempData.pData, pOutputData->nWidth * pOutputData->nHeight *pOutputData->nChannels);
    
    free(pData);
    
    return 0;
}


void stopSeamcarveImage(bool bStop)
{
    g_stopSeamCarving = bStop;
}

int resizeImage(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData, int nInterpolation)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth = pInputData->nWidth;
    int nInputHeight = pInputData->nHeight;
    int nOutputWidth = pOutputData->nWidth;
    int nOutputHeight = pOutputData->nHeight;
    
    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    
    int nChannels = pInputData->nChannels;
    
    Mat image;
    if(nChannels == 3)
    {
        image = Mat(nInputHeight, nInputWidth, CV_8UC3, pInputData->pData);
    }
    else if(nChannels == 4)
    {
        image = Mat(nInputHeight, nInputWidth, CV_8UC4, pInputData->pData);
    }
    else if(nChannels == 1)
    {
        image = Mat(nInputHeight, nInputWidth, CV_8UC1, pInputData->pData);
    }
    else
    {
        cout << "Invalid input,only support 4 /3 /1 channels";
        return -1;
    }
    
    if (!image.data)
    {
        cout << "Invalid input";
        image.release();
        return -1;
    }
    
    Mat imageOut;
    resize(image, imageOut, Size(nOutputWidth, nOutputHeight), 0, 0,nInterpolation);
    
    memcpy(pOutputData->pData, imageOut.data, nOutputWidth * nOutputHeight*nChannels);
    
    
    return 0;
}
