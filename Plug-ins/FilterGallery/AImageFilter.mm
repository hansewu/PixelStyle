//
//  AImageFilter.cpp
//  MyBrushesPlugin_mac
//
//  Created by wu zhiqiang on 2/5/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//

#include "AImageFilter.h"
#include <math.h>
#include <assert.h>
#include <map>
#include <vector>
#include <string>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

using namespace std;

typedef struct _AstructAlgorithmItem
{
    string strAlgorithmName;
    string strInAlgorithmName;
    string stringNameOfCategory;
    int nFilterType;
    vector<AUNI_VARIABLE>  vectorParam;
    
    _AstructAlgorithmItem()
    {
        strAlgorithmName = "";  strInAlgorithmName=""; nFilterType = -1; vectorParam.clear();
    }
    
    void Init(string name, string inName,string sNameOfCategory)
    {
        nFilterType = 0;
        strAlgorithmName = name;
        strInAlgorithmName = inName;
        stringNameOfCategory = sNameOfCategory;
        vectorParam.clear();
    }
}AALGORITHM_ITEM;

class CAImageFilterInfo
{
public:
    CAImageFilterInfo(){
        Init();
    }
    static CAImageFilterInfo* GetImageFilterInfoInstance();
    
    int GetSupportedCount() {return (int)m_Algorithms.size(); };
    
    string GetAlgorithmInName(int nIndex) {return m_Algorithms[nIndex].strInAlgorithmName; };
    string GetAlgorithmName(int nIndex) {return m_Algorithms[nIndex].strAlgorithmName; };
    int GetParamCount(int nIndex) { return (int)m_Algorithms[nIndex].vectorParam.size(); };
    
    AUNI_VARIABLE GetParamInfo(int nFuncIndex, int nParmIndex)
    { return m_Algorithms[nFuncIndex].vectorParam[nParmIndex]; };
    
    
//    struct CmpName{
//        bool operator() (const string& s1, const string& s2){
//            return s1.length() < s2.length();
//        }
//    };

public:
    vector<AALGORITHM_ITEM> m_Algorithms;
    map<string, vector<AALGORITHM_ITEM> > m_mapStringAndVector;
    
protected:
    void Init();
    void initCategoryBlur();
    void initCategoryColorAdjustment();
    void initCategoryColorEffect();
    void initCategoryDistortionEffect();
//    void initCategoryGeometryAdjustment();
    void initCategoryGradient();
    void initCategoryHalftoneEffect();
    void initCategoryStylize();
    void initCategoryTileEffect();
    
    void MakeDistinguishOfCategory();
};

static CAImageFilterInfo s_ImageFilterInfo;

CAImageFilterInfo * CAImageFilterInfo::GetImageFilterInfoInstance()
{
    return &s_ImageFilterInfo;
}

bool IsUnivariableEqual(AUNI_VARIABLE &Var1, AUNI_VARIABLE &Var2)
{
    if(Var1.nType != Var2.nType)
        return false;
    
    if(string(Var1.cName) != string(Var2.cName))
        return false;
    
    switch(Var1.nType)
    {
        case AV_INT:
        case AV_DWORDCOLOR:
        case AV_DWORDCOLORRGB:
            if(Var1.Value.nIntValue != Var2.Value.nIntValue)
                return false;
            break;
        case AV_FLOAT:
            if(fabs(Var1.Value.fFloatValue - Var2.Value.fFloatValue) > 0.0000001)
                return false;
        default:
            assert(false);
    }
    return true;
}


bool IsAlgorithmEqual(AALGORITHM_ITEM &Alg1, AALGORITHM_ITEM &Alg2)
{
    // if(Alg1.nAlgorithm != Alg2.nAlgorithm)
    //     return false;
    
    assert(Alg1.vectorParam.size() == Alg2.vectorParam.size());
    
    for(int i=0; i< Alg1.vectorParam.size(); i++)
    {
        if(IsUnivariableEqual(Alg1.vectorParam[i], Alg2.vectorParam[i]) == false)
            return false;
    }
    
    return true;
}

static AUNI_VARIABLE UniVariableMakeColor(string Name,string inName, unsigned int nValueDefault)
{
    AUNI_VARIABLE Variable;
    
    strcpy(Variable.cName, Name.c_str());
    strcpy(Variable.cInterName, inName.c_str());
    
    Variable.nType = AV_DWORDCOLOR;
    Variable.Value.nUnsignedValue = nValueDefault;
    Variable.nValueEnable = 0x01;
    
    Variable.DefaultValue.nUnsignedValue = nValueDefault;
    
    return  Variable;
}

static AUNI_VARIABLE UniVariableMakeRGB(string Name,string inName, unsigned int nValueDefault)
{
    AUNI_VARIABLE Variable;
    
    strcpy(Variable.cName, Name.c_str());
    strcpy(Variable.cInterName, inName.c_str());
    
    Variable.nType = AV_DWORDCOLORRGB;
    Variable.Value.nUnsignedValue = nValueDefault;
    Variable.nValueEnable = 0x01;
    
    Variable.DefaultValue.nUnsignedValue = nValueDefault;
    
    return  Variable;
}

static AUNI_VARIABLE UniVariableMake(string Name, string inName, float fDeault, float fMin, float fMax, int mod = 0)
{
    AUNI_VARIABLE Variable;
    
    strcpy(Variable.cName, Name.c_str());
    strcpy(Variable.cInterName, inName.c_str());
    
    Variable.nType = AV_FLOAT;
    Variable.Value.fFloatValue = fDeault;
    Variable.nValueEnable = 0x07;
    Variable.mod = mod;
    
    Variable.DefaultValue.fFloatValue = fDeault;
    Variable.MaxValue.fFloatValue = fMax;
    Variable.MinValue.fFloatValue = fMin;
    
    return  Variable;
}

static AUNI_VARIABLE UniVariableMakePOS(string Name, string inName, float fDeault[2], float fMin[2], float fMax[2],int mod = 1,int nValueNormalizationEnable = 0)
{
    AUNI_VARIABLE Variable;
    
    strcpy(Variable.cName, Name.c_str());
    strcpy(Variable.cInterName, inName.c_str());
    
    Variable.mod = mod;
    Variable.nValueNormalizationEnable = nValueNormalizationEnable;
    Variable.nType = AV_CENTEROFFSET;
    Variable.Value.fOffsetXY[0] = fDeault[0];
    Variable.Value.fOffsetXY[1] = fDeault[1];
    Variable.nValueEnable = 0x07;
    Variable.DefaultValue.fOffsetXY[0] = fDeault[0];
    Variable.DefaultValue.fOffsetXY[1] = fDeault[1];
    
    Variable.MaxValue.fOffsetXY[0] = fMax[0];
    Variable.MaxValue.fOffsetXY[1] = fMax[1];
    
    Variable.MinValue.fOffsetXY[0] = fMin[0];
    Variable.MinValue.fOffsetXY[1] = fMin[1];
    
    return  Variable;
}

void CAImageFilterInfo::MakeDistinguishOfCategory()
{
    for(vector<AALGORITHM_ITEM>::iterator it = m_Algorithms.begin();it != m_Algorithms.end();it++)
    {
        string sFilterCategoryName = (*it).stringNameOfCategory;
        map<string,vector<AALGORITHM_ITEM>  >::iterator mapIt = m_mapStringAndVector.find(sFilterCategoryName);
        if(mapIt != m_mapStringAndVector.end())
        {
            (mapIt -> second).push_back(*it);
        }else{
            vector<AALGORITHM_ITEM> newVector;
            newVector.push_back(*it);
            m_mapStringAndVector.insert(map<string,vector<AALGORITHM_ITEM>  >::value_type(sFilterCategoryName, newVector));
        }
    }
}

void CAImageFilterInfo::initCategoryColorAdjustment()
{
    AALGORITHM_ITEM AlgothimItem;
    AUNI_VARIABLE UniVariable;

    AlgothimItem.Init("Hue", "CIHueAdjust","Adjustment");
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Controls", "CIColorControls","Adjustment");
    UniVariable = UniVariableMake("Saturation", "inputSaturation", 1.0, 0.0, 2.0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Brightness", "inputBrightness", 0.0, -1.0, 1.0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Contrast", "inputContrast", 1.0, 0.25, 4.0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Vibrance", "CIVibrance","Adjustment");
    UniVariable = UniVariableMake("Amount", "inputAmount", 0.0, -1.0, 1.0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Temperature and Tint", "CITemperatureAndTint","Adjustment");
    float fOffset[2] = {6500, 0};
    float fOffsetMax[2] = {50000, 1500};
    float fOffsetMin[2] = {0.0, 0.0};
    UniVariable = UniVariableMakePOS("Neutral", "inputNeutral", fOffset, fOffsetMin, fOffsetMax,0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    fOffset[0] = 6500; fOffset[1] =  0;
    fOffsetMax[0] = 50000; fOffsetMax[1] =  1500;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("TargetNeutral", "inputTargetNeutral", fOffset, fOffsetMin, fOffsetMax,0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Exposure", "CIExposureAdjust","Adjustment");
    UniVariable = UniVariableMake("EV", "inputEV", 0.0, -10.0, 10.0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Gamma", "CIGammaAdjust","Adjustment");
    UniVariable = UniVariableMake("Power", "inputPower", 1.0, 0.25, 4.00);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("WhiteAdjust", "CIWhitePointAdjust","Adjustment");
    UniVariable = UniVariableMakeColor("Color", "inputColor", (255<<24) + (255<<16) + (255<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Invert", "CIColorInvert", "Adjustment");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("False", "CIFalseColor", "Adjustment");
    UniVariable = UniVariableMakeColor("Color 1", "inputColor0", (76<<24)+255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeColor("Color 2", "inputColor1", (255<<24) + (230<<16) + (204<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("NoiseRedu", "CINoiseReduction", "Adjustment");
    UniVariable = UniVariableMake("Noise Level", "inputNoiseLevel", 0.02, 0.0, 0.1, 3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Sharpness", "inputSharpness", 0.4, 0.0, 2, 3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Luminance", "CISharpenLuminance", "Adjustment");
    UniVariable = UniVariableMake("Sharpness", "inputSharpness", 0.4, 0.0, 2.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Unsharp Mask", "CIUnsharpMask", "Adjustment");
    UniVariable = UniVariableMake("Radius", "inputRadius", 2.5, 0.0, 100.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Intensity", "inputIntensity", 0.5, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Lanczos", "CILanczosScaleTransform", "Adjustment");
    UniVariable = UniVariableMake("Scale", "inputScale", 1.00, 0.05, 1.5,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Aspect Ratio", "inputAspectRatio", 1.00, 0.5, 2.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
/************layer上显示与模板图像输出后不一致**************
    AlgothimItem.Init("Straighten", "CIStraightenFilter", "Adjustment");
    UniVariable = UniVariableMake("Angel", "inputAngle", 0.00, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
 */
    
//    AlgothimItem.Init("Tone Curve", "CIToneCurve","Adjustment");
//    float fOffset[2] = {0.5, 0.5};
//    float fOffsetMax[2] = {1.0, 1.0};
//    float fOffsetMin[2] = {0.0, 0.0};
//    UniVariable = UniVariableMakePOS("Point 0", "inputPoint0", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Point 1", "inputPoint1", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Point 2", "inputPoint2", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Point 3", "inputPoint3", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Point 4", "inputPoint4", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
    
    //    AlgothimItem.Init("Matrix", "CIColorMatrix","Adjustment");
    //    UniVariable = UniVariableMakeRGB("Red Vector", "inputRVector", 255 << 24);
    //    AlgothimItem.vectorParam.push_back(UniVariable);
    //    UniVariable = UniVariableMakeRGB("Green Vector", "inputGVector", 255 << 16);
    //    AlgothimItem.vectorParam.push_back(UniVariable);
    //    UniVariable = UniVariableMakeRGB("Blue Vector", "inputBVector", 255 << 8);
    //    AlgothimItem.vectorParam.push_back(UniVariable);
    //    UniVariable = UniVariableMakeRGB("Alpha Vector", "inputAVector", 255);
    //    AlgothimItem.vectorParam.push_back(UniVariable);
    //    UniVariable = UniVariableMakeRGB("Bias Vector", "inputBiasVector", 0);
    //    AlgothimItem.vectorParam.push_back(UniVariable);
    //    m_Algorithms.push_back(AlgothimItem);
}

void CAImageFilterInfo::initCategoryColorEffect()
{
    AALGORITHM_ITEM AlgothimItem;
    AUNI_VARIABLE UniVariable;
    
//    AlgothimItem.Init("Color Cross Polynomial", "CIColorCrossPolynomial", "Color");
//    m_Algorithms.push_back(AlgothimItem);
    
//    AlgothimItem.Init("Color Cube", "CIColorCube", "Color");
//    UniVariable = UniVariableMake("Cube Dimension", "inputCubeDimension", 2.00, 0.0, 10.0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
    
//    AlgothimItem.Init("Color Cube with ColorSpace", "CIColorCubeWithColorSpace", "Color");
//    UniVariable = UniVariableMake("Cube Dimension","inputCubeDimension", 2.00,2.00,128.00);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Monochrome", "CIColorMonochrome", "Color");
    UniVariable = UniVariableMakeColor("Color", "inputColor", (153<<24) + (115<<16) + (76<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Intensity","inputIntensity", 1.00,0.00,1.00,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    

    
    AlgothimItem.Init("VignetteEffect", "CIVignetteEffect", "Color");
    float fOffset[2] = {0.5, 0.5};
    float fOffsetMax[2] = {1.0, 1.0};
    float fOffsetMin[2] = {0.0, 0.0};
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Falloff","inputFalloff", 1.00,0.0,1.00,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Intensity","inputIntensity", 0.50, -1.0,1.00,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius","inputRadius", 150,0.00,2000.00,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
//    AlgothimItem.Init("Color Map", "CIColorMap","Color");
//    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Posterize", "CIColorPosterize", "Color");
    UniVariable = UniVariableMake("Levels", "inputLevels", 6.0, 2.0, 30.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("MaskAlpha", "CIMaskToAlpha", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("MaxComponent", "CIMaximumComponent", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("MinComponent", "CIMinimumComponent", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Chrome", "CIPhotoEffectChrome", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Fade", "CIPhotoEffectFade", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Instant", "CIPhotoEffectInstant", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Mono", "CIPhotoEffectMono", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Noir", "CIPhotoEffectNoir", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Process", "CIPhotoEffectProcess", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Tonal", "CIPhotoEffectTonal", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Transfer", "CIPhotoEffectTransfer", "Color");
    m_Algorithms.push_back(AlgothimItem);
    
    
    AlgothimItem.Init("Sepia", "CISepiaTone", "Color");
    UniVariable = UniVariableMake("Intensity", "inputIntensity", 1.0, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Vignette", "CIVignette", "Color");
    UniVariable = UniVariableMake("Intensity", "inputIntensity", 0.0, -1.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 1.0, 0.0, 2.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("LinearToCurve", "CILinearToSRGBToneCurve","Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("CurveToLinear", "CISRGBToneCurveToLinear","Color");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Clamp", "CIColorClamp","Color");
    UniVariable = UniVariableMakeRGB("MinComp", "inputMinComponents", 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("MaxComp", "inputMaxComponents", (255 << 24) + (255 << 16) + (255 << 8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Polynomial", "CIColorPolynomial","Color");
    UniVariable = UniVariableMakeRGB("RedCoeff", "inputRedCoefficients", 255 << 16);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("GreenCoeff", "inputGreenCoefficients", 255 << 16);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("BlueCoefficients", "inputBlueCoefficients", 255 << 16);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("AlphaCoeff", "inputAlphaCoefficients", 255 << 16);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);

}

void CAImageFilterInfo::initCategoryBlur(void)
{
    AALGORITHM_ITEM AlgothimItem;
    AUNI_VARIABLE UniVariable;
    
    AlgothimItem.Init("Median", "CIMedianFilter", "Blur");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Disc", "CIDiscBlur", "Blur");
    UniVariable = UniVariableMake("Radius", "inputRadius", 8.0, 0.0, 100, 3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Gaussian", "CIGaussianBlur","Blur");
    UniVariable = UniVariableMake("Radius", "inputRadius", 10.0, 0.0, 100.0, 3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Box", "CIBoxBlur","Blur");
    UniVariable = UniVariableMake("Radius", "inputRadius", 10.0, 1.0, 100.0, 3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Motion", "CIMotionBlur","Blur");
    UniVariable = UniVariableMake("Radius", "inputRadius", 20.0, 0.0, 100.0, 3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Zoom", "CIZoomBlur", "Blur");
    UniVariable = UniVariableMake("Amout", "inputAmount", 20.0, 0.0, 200.0, 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    float fOffset[2] = {0.5, 0.5};
    float fOffsetMax[2] = {1.0, 1.0};
    float fOffsetMin[2] = {0.0, 0.0};
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
}

void CAImageFilterInfo::initCategoryDistortionEffect()
{
    AALGORITHM_ITEM AlgothimItem;
    AUNI_VARIABLE UniVariable;
    
    AlgothimItem.Init("Bump", "CIBumpDistortion","Distortion");
    UniVariable = UniVariableMake("Radius", "inputRadius", 300.0, 0.0, 600.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Scale", "inputScale", 0.50, -1.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    float fOffset[2] = {0.5, 0.5};
    float fOffsetMax[2] = {1.0, 1.0};
    float fOffsetMin[2] = {0.0, 0.0};
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("BumpLinear", "CIBumpDistortionLinear","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 300.0, 0.0, 600.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, 0.0, 6.28,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Scale", "inputScale", 0.5, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Circle Splash", "CICircleSplashDistortion","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 350, 0.0, 1000.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    SInt32 versMaj, versMin, versBugFix;
    Gestalt(gestaltSystemVersionMajor, &versMaj);
    Gestalt(gestaltSystemVersionMinor, &versMin);
    Gestalt(gestaltSystemVersionBugFix, &versBugFix);
    if (versMaj>=10&&versMin>=12)
//    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_12)
    {
        AlgothimItem.Init("Circle Wrap", "CICircularWrap","Distortion");
        fOffset[0] = 0.5; fOffset[1] =  0.5;
        fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
        fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
        UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        UniVariable = UniVariableMake("Angle", "inputAngle", 0, -3.14, 3.14,0);
        AlgothimItem.vectorParam.push_back(UniVariable);
        UniVariable = UniVariableMake("Radius", "inputRadius", 150.0, 0.0, 1000,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        m_Algorithms.push_back(AlgothimItem);
    }
    

/************layer上显示与模板图像输出后不一致**************
    AlgothimItem.Init("Droste", "CIDroste","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Point 1", "inputInsetPoint0", fOffset, fOffsetMin, fOffsetMax, 1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Point 2", "inputInsetPoint1", fOffset, fOffsetMin, fOffsetMax, 1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputStrands", 1.0, -2.0, 2.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Periodicity", "inputPeriodicity", 1.0, 1.0, 5.0, 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Rotation", "inputRotation", 0.0, 0.0, 6.28,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Zoom", "inputZoom", 1.0, 0.01, 5.0, 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
*/
    
    
    AlgothimItem.Init("Glass", "CIGlassLozenge","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Point 1", "inputPoint0", fOffset, fOffsetMin, fOffsetMax);
    AlgothimItem.vectorParam.push_back(UniVariable);
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Point 2", "inputPoint1", fOffset, fOffsetMin, fOffsetMax);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 100.0, 0.0, 1000.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Refraction", "inputRefraction", 1.7, 0.0, 5.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Hole", "CIHoleDistortion","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 150.0, 0, 2000,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    
    if (versMaj>=10&&versMin>=11)
//    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_11)
    {
        AlgothimItem.Init("Light Tunnel", "CILightTunnel","Distortion");
        fOffset[0] = 0.5; fOffset[1] =  0.5;
        fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
        fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
        UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        UniVariable = UniVariableMake("Rotation","inputRotation", 0.00, -20, 20,0);
        AlgothimItem.vectorParam.push_back(UniVariable);
        UniVariable = UniVariableMake("Radius", "inputRadius", 100.0, 0.0, 500.0,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        m_Algorithms.push_back(AlgothimItem);
    }
    
    
    AlgothimItem.Init("Pinch", "CIPinchDistortion","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 300.0, 0.0, 1000.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Scale", "inputScale", 0.5, 0.0, 2.00,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("StretchCrop", "CIStretchCrop","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0; fOffsetMin[1] =  0;
    UniVariable = UniVariableMakePOS("Size", "inputSize", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("CropAmount", "inputCropAmount", 0.25, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("StretchAmount", "inputCenterStretchAmount", 0.25, 0.0, 1.00,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Torus Lens", "CITorusLensDistortion","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 160.0, 0.0, 500.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 80.0, 0.0, 200.0, 1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Refraction", "inputRefraction", 1.70, 0.0, 5,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Twirl", "CITwirlDistortion","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 300.0, 0.0, 500.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 3.14, -12.57, 12.57,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Vortex", "CIVortexDistortion","Distortion");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 300.0, 0.0, 800.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 56.55, -94.25, 94.25,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
}

//void CAImageFilterInfo::initCategoryGeometryAdjustment()
//{
//    AALGORITHM_ITEM AlgothimItem;
//    AUNI_VARIABLE UniVariable;
//    AlgothimItem.Init("Perspective Correction", "CIPerspectiveCorrection","Geometry");
//    float fOffset[2] = {0, 0};
//    float fOffsetMin[2] = {0.0, 0.0};
//    float fOffsetMax[2] = {1.0, 1.0};
//    UniVariable = UniVariableMakePOS("Top Left", "inputTopLeft", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 1; fOffset[1] =  0;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Top Right", "inputTopRight", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 1; fOffset[1] =  1;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] = 0.0;
//    UniVariable = UniVariableMakePOS("Bottom Right", "inputBottomRight", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 0; fOffset[1] =  1;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] = 0.01;
//    UniVariable = UniVariableMakePOS("Bottom Left", "inputBottomLeft", fOffset, fOffsetMin, fOffsetMax);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//}

void CAImageFilterInfo::initCategoryGradient()
{
    AALGORITHM_ITEM AlgothimItem;
    AUNI_VARIABLE UniVariable;
    
    AlgothimItem.Init("Gaussian", "CIGaussianGradient", "Gradient");
    float fOffset[2] = {0.5, 0.5};
    float fOffsetMax[2] = {1.0, 1.0};
    float fOffsetMin[2] = {0.0, 0.0};
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 300.0, 0.0, 800.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("Color 1", "inputColor0", 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("Color 2", "inputColor1", 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Linear", "CILinearGradient", "Gradient");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Point 1", "inputPoint0", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Point 2", "inputPoint1", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("Color 1", "inputColor0", 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeRGB("Color 2", "inputColor1", 0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
}

void CAImageFilterInfo::initCategoryHalftoneEffect()
{
    AALGORITHM_ITEM AlgothimItem;
    AUNI_VARIABLE UniVariable;
    
    AlgothimItem.Init("Circular", "CICircularScreen", "Pixelate");
    float fOffset[2] = {0.5, 0.5};
    float fOffsetMax[2] = {1.0, 1.0};
    float fOffsetMin[2] = {0.0, 0.0};
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 6.00, 2.0, 50.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Sharpness", "inputSharpness", 0.70, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("CMYK", "CICMYKHalftone", "Pixelate");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 6.00, 2.0, 100.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", -3.14, 0.0, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Sharpness", "inputSharpness", 0.70, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Gray Component", "inputGCR", 1.00, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Color Removal", "inputUCR", 0.50, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Dot", "CIDotScreen", "Pixelate");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 6.00, 2.0, 50.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.00, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Sharpness", "inputSharpness", 0.70, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Hatched", "CIHatchedScreen", "Pixelate");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 6.00, 2.0, 50.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.00, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Sharpness", "inputSharpness", 0.70, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Line", "CILineScreen", "Pixelate");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 6.00, 2.0, 50.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.00,- 3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Sharpness", "inputSharpness", 0.70, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
}

void CAImageFilterInfo::initCategoryStylize()
{
    AALGORITHM_ITEM AlgothimItem;
    AUNI_VARIABLE UniVariable;
    
    AlgothimItem.Init("Bloom", "CIBloom", "Stylize");
    UniVariable = UniVariableMake("Radius", "inputRadius", 10.0, 0.0, 100.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Intensity", "inputIntensity", 1.0, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Crystallize", "CICrystallize", "Stylize");
    UniVariable = UniVariableMake("Radius", "inputRadius", 20.0, 1.0, 100.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    float fOffset[2] = {0.5, 0.5};
    float fOffsetMax[2] = {1.0, 1.0};
    float fOffsetMin[2] = {0.0, 0.0};
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("DepthOfField", "CIDepthOfField", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("inputPoint0", "inputPoint0", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("inputPoint1", "inputPoint1", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Saturation", "inputSaturation", 1.5, 0.0, 10.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("MaskRadius", "inputUnsharpMaskRadius", 2.5, 0.0, 10.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Intensity", "inputUnsharpMaskIntensity", 0.5, 0.0, 10.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 6.0, 0.0, 30.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    
    AlgothimItem.Init("Comic", "CIComicEffect", "Stylize");
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Edges", "CIEdges", "Stylize");
    UniVariable = UniVariableMake("Intensity", "inputIntensity", 1.0, 0, 10.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("EdgeWork", "CIEdgeWork", "Stylize");
    UniVariable = UniVariableMake("Radius", "inputRadius", 3.0, 0.0, 20.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Gloom", "CIGloom", "Stylize");
    UniVariable = UniVariableMake("Radius", "inputRadius", 10.0, 0.0, 100.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Intensity", "inputIntensity", 1.0, 0.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Height Field From Mask", "CIHeightFieldFromMask", "Stylize");
    UniVariable = UniVariableMake("Radius", "inputRadius", 10.0, 0.00, 30.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("HexagonalPixellate", "CIHexagonalPixellate", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Scale", "inputScale", 8.0, 0.01, 100.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Highlight and Shadows", "CIHighlightShadowAdjust", "Stylize");
    UniVariable = UniVariableMake("HighlightAmount", "inputHighlightAmount", 1.00, 0.3, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("ShadowAmount", "inputShadowAmount", 0.00, -1.0, 1.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 0.00, 0.0, 10.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("LineOverlay", "CILineOverlay", "Stylize");
    UniVariable = UniVariableMake("NRNoiseLevel", "inputNRNoiseLevel", 0.07, 0.00, 0.1,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("NRSharpness", "inputNRSharpness", 0.71, 0.00, 2.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("EdgeIntensity", "inputEdgeIntensity", 1.00, 0.00, 200.0,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Threshold", "inputThreshold", 0.10, 0.00, 1.00,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Contrast", "inputContrast", 50.00, 0.25, 200.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Pixellate", "CIPixellate", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Scale", "inputScale", 8.0, 1.0, 100.0, 3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Pointllize", "CIPointillize", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Radius", "inputRadius", 20.0, 1.0, 100.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);

    AlgothimItem.Init("Spot", "CISpotColor","Stylize");
    UniVariable = UniVariableMakeColor("Center Color 1", "inputCenterColor1", (20<<24) + (15<<16) + (18<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeColor("Replacement Color 1", "inputReplacementColor1", (112<<24) + (49<<16) + (51<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Closeness 1", "inputCloseness1", 0.22, 0.00, 0.5,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Contrast 1", "inputContrast1", 0.98, 0.00, 1,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeColor("Center Color 2", "inputCenterColor2", (135<<24) + (79<<16) + (89<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeColor("Replacement Color 2", "inputReplacementColor2", (232<<24) + (143<<16) + (130<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Closeness 2", "inputCloseness2", 0.15, 0.00, 0.5,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Contrast 2", "inputContrast2", 0.98, 0.00, 1,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeColor("Center Color 3", "inputCenterColor3", (235<<24) + (115<<16) + (84<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMakeColor("Replacement Color 3", "inputReplacementColor3", (232<<24) + (191<<16) + (156<<8) + 255);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Closeness 3", "inputCloseness3", 0.50, 0.00, 0.5,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Contrast 3", "inputContrast3", 0.99, 0.00, 1,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("EightfoldReflected", "CIEightfoldReflectedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("FourfoldReflected", "CIFourfoldReflectedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, 0.0, 10,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Acute Angle", "inputAcuteAngle", 1.57, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("FourfoldRotated", "CIFourfoldRotatedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("FourfoldTranslated", "CIFourfoldTranslatedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Acute Angle", "inputAcuteAngle", 1.57, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("GlideReflected", "CIGlideReflectedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    
    AlgothimItem.Init("Kaleidoscope", "CIKaleidoscope", "Stylize");
    UniVariable = UniVariableMake("Count", "inputCount", 6.0, 1.0, 64.0,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Op", "CIOpTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Scale", "inputScale", 2.80, 0.1, 10,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 65, 1.0, 1000.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Parallelogram", "CIParallelogramTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Acute Angle", "inputAcuteAngle", 1.57, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    SInt32 versMaj, versMin, versBugFix;
    Gestalt(gestaltSystemVersionMajor, &versMaj);
    Gestalt(gestaltSystemVersionMinor, &versMin);
    Gestalt(gestaltSystemVersionBugFix, &versBugFix);
    if (versMaj>=10&&versMin>=12)
//    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_12)
    {
        AlgothimItem.Init("Perspective", "CIPerspectiveTile","Stylize");
        fOffset[0] = 0; fOffset[1] =  0;
        fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
        fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
        UniVariable = UniVariableMakePOS("Top Left", "inputTopLeft", fOffset, fOffsetMin, fOffsetMax,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        fOffset[0] = 1; fOffset[1] =  0;
        fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
        fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
        UniVariable = UniVariableMakePOS("Top Right", "inputTopRight", fOffset, fOffsetMin, fOffsetMax,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        fOffset[0] = 1; fOffset[1] =  1;
        fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
        fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
        UniVariable = UniVariableMakePOS("Bottom Right", "inputBottomRight", fOffset, fOffsetMin, fOffsetMax,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        fOffset[0] = 0; fOffset[1] =  1.0;
        fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
        fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
        UniVariable = UniVariableMakePOS("Bottom Left", "inputBottomLeft", fOffset, fOffsetMin, fOffsetMax, 1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        m_Algorithms.push_back(AlgothimItem);
    }
    
    AlgothimItem.Init("SixfoldReflected", "CISixfoldReflectedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.8; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("SixfoldRotated", "CISixfoldRotatedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    if (versMaj>=10&&versMin>=11)
//    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_11)
    {
        AlgothimItem.Init("TKaleidoscope", "CITriangleKaleidoscope", "Stylize");
        fOffset[0] = 0.5; fOffset[1] =  0.5;
        fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
        fOffsetMin[0] = 0.00; fOffsetMin[1] =  0.00;
        UniVariable = UniVariableMakePOS("Point", "inputPoint", fOffset, fOffsetMin, fOffsetMax,1);
        AlgothimItem.vectorParam.push_back(UniVariable);
        UniVariable = UniVariableMake("Size", "inputSize", 1.00, 0.0, 1000,3);
        AlgothimItem.vectorParam.push_back(UniVariable);
        UniVariable = UniVariableMake("Rotation", "inputRotation", 5.92, 0, 6.28,0);
        AlgothimItem.vectorParam.push_back(UniVariable);
        UniVariable = UniVariableMake("Decay", "inputDecay", 0.85, 0.0, 1,0);
        AlgothimItem.vectorParam.push_back(UniVariable);
        m_Algorithms.push_back(AlgothimItem);
    }
    
    AlgothimItem.Init("Triangle", "CITriangleTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.8; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
    
    AlgothimItem.Init("Twelvefold", "CITwelvefoldReflectedTile", "Stylize");
    fOffset[0] = 0.5; fOffset[1] =  0.5;
    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
    AlgothimItem.vectorParam.push_back(UniVariable);
    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
    AlgothimItem.vectorParam.push_back(UniVariable);
    m_Algorithms.push_back(AlgothimItem);
}

//void CAImageFilterInfo::initCategoryTileEffect()
//{
//    AALGORITHM_ITEM AlgothimItem;
//    AUNI_VARIABLE UniVariable;
//    
//    AlgothimItem.Init("EightfoldReflected", "CIEightfoldReflectedTile", "Tile",1);
//    float fOffset[2] = {0.5, 0.5};
//    float fOffsetMax[2] = {0.99, 0.99};
//    float fOffsetMin[2] = {0.01, 0.01};
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("FourfoldReflected", "CIFourfoldReflectedTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, 0.0, 10,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Acute Angle", "inputAcuteAngle", 1.57, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("FourfoldRotated", "CIFourfoldRotatedTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("FourfoldTranslated", "CIFourfoldTranslatedTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Acute Angle", "inputAcuteAngle", 1.57, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("GlideReflected", "CIGlideReflectedTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("Kaleidoscope", "CIKaleidoscope", "Tile",1);
//    UniVariable = UniVariableMake("Count", "inputCount", 6.0, 1.0, 64.0,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("Op", "CIOpTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Scale", "inputScale", 2.80, 0.1, 10,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 65, 1.0, 1000.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("Parallelogram", "CIParallelogramTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Acute Angle", "inputAcuteAngle", 1.57, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("Perspective", "CIPerspectiveTile","Tile",1);
//    fOffset[0] = 0; fOffset[1] =  0;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Top Left", "inputTopLeft", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 1; fOffset[1] =  0;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Top Right", "inputTopRight", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 1; fOffset[1] =  1;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Bottom Right", "inputBottomRight", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    fOffset[0] = 0; fOffset[1] =  1.0;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.0; fOffsetMin[1] =  0.0;
//    UniVariable = UniVariableMakePOS("Bottom Left", "inputBottomLeft", fOffset, fOffsetMin, fOffsetMax, 1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("SixfoldReflected", "CISixfoldReflectedTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.8; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("SixfoldRotated", "CISixfoldRotatedTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("TKaleidoscope", "CITriangleKaleidoscope", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 1.0; fOffsetMax[1] =  1.0;
//    fOffsetMin[0] = 0.00; fOffsetMin[1] =  0.00;
//    UniVariable = UniVariableMakePOS("Point", "inputPoint", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Size", "inputSize", 1.00, 0.0, 1000,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Rotation", "inputRotation", 5.92, 0, 6.28,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Decay", "inputDecay", 0.85, 0.0, 1,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("Triangle", "CITriangleTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.8; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//    
//    AlgothimItem.Init("Twelvefold", "CITwelvefoldReflectedTile", "Tile",1);
//    fOffset[0] = 0.5; fOffset[1] =  0.5;
//    fOffsetMax[0] = 0.99; fOffsetMax[1] =  0.99;
//    fOffsetMin[0] = 0.01; fOffsetMin[1] =  0.01;
//    UniVariable = UniVariableMakePOS("Center", "inputCenter", fOffset, fOffsetMin, fOffsetMax,1);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Angle", "inputAngle", 0.0, -3.14, 3.14,0);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    UniVariable = UniVariableMake("Width", "inputWidth", 100.0, 1.0, 200.0,3);
//    AlgothimItem.vectorParam.push_back(UniVariable);
//    m_Algorithms.push_back(AlgothimItem);
//}

void CAImageFilterInfo::Init()
{
    initCategoryColorAdjustment();
    initCategoryBlur();
    initCategoryColorEffect();
    initCategoryDistortionEffect();
//    initCategoryGeometryAdjustment();
//    initCategoryGradient();
    initCategoryHalftoneEffect();
    initCategoryStylize();
//    initCategoryTileEffect();
    
    MakeDistinguishOfCategory();
}

int GetFiltersCount()
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
    return info->GetSupportedCount();
}

NSString *GetFilterName(int nFilterIndex)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    string name = info->GetAlgorithmName(nFilterIndex);
    
    NSString *strName = [NSString stringWithUTF8String:name.c_str()];
    
    return strName;
}

int	 GetFilterParaCount(int nFilterIndex)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
    return info -> GetParamCount(nFilterIndex);
}

NSString *GetFilterParamName(int nFilterIndex, int nItem)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
    if(nItem >= info->GetParamCount(nFilterIndex))
       return nil;
    
    AUNI_VARIABLE para = info -> GetParamInfo(nFilterIndex, nItem);
    
    NSString *strName = [NSString stringWithUTF8String:para.cName];
    
    return strName;
}

AVARIABLE_VALUE GetFilterParamMax(int nFilterIndex, int nItem)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    AUNI_VARIABLE para = info->GetParamInfo(nFilterIndex, nItem);
    
//    if((para.nValueEnable &2)  && para.nType == AV_FLOAT)
        return para.MaxValue;
}

AVARIABLE_VALUE GetFilterParamMin(int nFilterIndex, int nItem)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
//    if(nItem >= info->GetParamCount(nFilterIndex))
//        return nil;
    
    AUNI_VARIABLE para = info->GetParamInfo(nFilterIndex, nItem);
    
//    if((para.nValueEnable &4)  && para.nType == AV_FLOAT)
        return para.MinValue;
}

AVARIABLE_VALUE GetFilterParamDefault(int nFilterIndex, int nItem)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
//    if(nItem >= info->GetParamCount(nFilterIndex))
//        return nil;
    
    AUNI_VARIABLE para = info->GetParamInfo(nFilterIndex, nItem);
    
//    if((para.nValueEnable &1)  && para.nType == AV_FLOAT)
        return para.DefaultValue;
}

AENUM_VARIABLE_TYPE GetFilterParamType(int nFilterIndex, int nItem)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
    //    if(nItem >= info->GetParamCount(nFilterIndex))
    //        return nil;
    
    AUNI_VARIABLE para = info->GetParamInfo(nFilterIndex, nItem);
    
    //    if((para.nValueEnable &1)  && para.nType == AV_FLOAT)
    return para.nType;
}

void GetImageSize(IMAGE_FILTER_HANDLE hImageFilter,float* fWidth, float* fHeight)
{
    IMAGE_FILTER* pImageFilter = (IMAGE_FILTER *)hImageFilter;
    CIImage* inputImage = [(pImageFilter -> filter) valueForKey:@"inputImage"];
    CGRect rect = inputImage.extent;
    *fWidth = rect.size.width;
    *fHeight = rect.size.height;
}

IMAGE_FILTER_HANDLE CreateFilterForImage(CIImage *image, int nFilterIndex)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    string name = info->GetAlgorithmInName(nFilterIndex);
    
    NSString *strName = [NSString stringWithUTF8String:name.c_str()];
    
    CIFilter *filter = [CIFilter filterWithName:strName];
    
    if(!filter)  NULL;
    
    [filter setValue:image forKey:@"inputImage"];
    
    [filter setDefaults];
    filter.name = strName;
    
    CIImage *ciimage = [filter valueForKey:@"outputImage"];
    
    [ciimage retain];
    [filter retain];
    
    IMAGE_FILTER *pImageFilter = new IMAGE_FILTER;
    pImageFilter-> image = ciimage;
    pImageFilter-> filter = filter;
    pImageFilter-> nFilterIndex = nFilterIndex;
    
    return pImageFilter;
}

//IMAGE_FILTER_HANDLE CreateFilterForLayer(CALayer *layer, int nCategoryIndex,int nFilterIndex)
//{
//    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
//    
//    map<string,vector<AALGORITHM_ITEM>>::iterator it = (info -> m_mapStringAndVector).begin();
//    for(int i = 0; i < nCategoryIndex; i++)
//    {
//        ++it;
//    }
//    
//    string sInName = (it -> second)[nFilterIndex].strInAlgorithmName;
//    NSString* sName = [NSString stringWithUTF8String:sInName.c_str()];
//    CIFilter* filter = [CIFilter filterWithName:sName];
//    filter.name = sName;
//    [filter setDefaults];
//
//    
//    [filter retain];
//    
//    int index = 0;
//    for(int i = 0; i < nCategoryIndex; i++)
//    {
//        index += GetFiltersCountInCategory(i);
//    }
//    index += nFilterIndex;
//    IMAGE_FILTER *pImageFilter = new IMAGE_FILTER;
//    pImageFilter-> image = nil;
//    pImageFilter-> filter = filter;
//    pImageFilter-> nFilterIndex = index;
//    
//    [layer setfilters:]
//    
//    return ;
//}

IMAGE_FILTER_HANDLE CreateFilterForCALayerInCategory(int nCategoryIndex,int nFilterIndex)
{
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info -> m_mapStringAndVector).begin();
    for(int i = 0; i < nCategoryIndex; i++)
    {
        ++it;
    }
    
    string sInName = (it -> second)[nFilterIndex].strInAlgorithmName;
    NSString* sName = [NSString stringWithUTF8String:sInName.c_str()];
    CIFilter* filter = [CIFilter filterWithName:sName];
    
    [filter setDefaults];
    filter.name = sName;

    [filter retain];
    
    int index = 0;
    for(int i = 0; i < nCategoryIndex; i++)
    {
        index += GetFiltersCountInCategory(i);
    }
    index += nFilterIndex;
    IMAGE_FILTER *pImageFilter = new IMAGE_FILTER;
    pImageFilter-> image = nil;
    pImageFilter-> filter = filter;
    pImageFilter-> nFilterIndex = index;
    
    return pImageFilter;
}

IMAGE_FILTER_HANDLE CreateFilterForImageInCategory(CIImage *image, int nCategoryIndex,int nFilterIndex){
   float fWidth = image.extent.size.width;
   float fHeight = image.extent.size.height;
    
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();

   map<string,vector<AALGORITHM_ITEM>  >::iterator it = (info -> m_mapStringAndVector).begin();
    for(int i = 0; i < nCategoryIndex; i++)
    {
        ++it;
    }

    string sInName = (it -> second)[nFilterIndex].strInAlgorithmName;
    NSString* sName = [NSString stringWithUTF8String:sInName.c_str()];
    CIFilter* filter = [CIFilter filterWithName:sName];
    
    [filter setValue:image forKey:kCIInputImageKey];
    [filter setDefaults];
    filter.name = sName;
    if([filter.inputKeys containsObject:@"inputCenter"])
    {
        [filter setValue:[CIVector vectorWithX:fWidth/2 Y:fHeight/2] forKey:@"inputCenter"];
    }
    CIImage* imageOutput = [filter valueForKey:kCIOutputImageKey];
    
    [filter retain];
    [imageOutput retain];
    
    int index = 0;
    for(int i = 0; i < nCategoryIndex; i++)
    {
        index += GetFiltersCountInCategory(i);
    }
    index += nFilterIndex;
    IMAGE_FILTER *pImageFilter = new IMAGE_FILTER;
    pImageFilter -> image = imageOutput;
    pImageFilter -> filter = filter;
    pImageFilter -> nFilterIndex = index;
    
    return pImageFilter;
}

void DestroyImageFilter(IMAGE_FILTER_HANDLE hImageFilter)
{
    IMAGE_FILTER *pImageFilter = (IMAGE_FILTER *)hImageFilter;
    if(pImageFilter->image)
    {
        [pImageFilter->image release];
        pImageFilter->image = nil;
    }
    
    if(pImageFilter->filter)
    {
        [pImageFilter->filter release];
        pImageFilter->filter = nil;
    }
    
    delete pImageFilter;
}

void ModifyFilterParamInLayer(CALayer* layer, IMAGE_FILTER_HANDLE hImageFilter, int nItem, AVARIABLE_VALUE aValue)
{
    NSLog(@"FilterName:%@",((CIFilter*)(layer.filters)[0]).name);
    IMAGE_FILTER *pImageFilter = (IMAGE_FILTER *)hImageFilter;
    
    if(!pImageFilter)  return;
    if(!pImageFilter->filter) return;
    
    int nIndexOfFilter = pImageFilter -> nFilterIndex;
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    string sFilterInName = info->GetAlgorithmInName(nIndexOfFilter);
    NSString* sFilterName = [NSString stringWithUTF8String:sFilterInName.c_str()];
    NSLog(@"%@",(pImageFilter->filter).name);
    AUNI_VARIABLE paramInfo = info->GetParamInfo(nIndexOfFilter, nItem);
    NSString* paramName = [NSString stringWithUTF8String:paramInfo.cInterName];
    NSString* stringPath = [NSString stringWithFormat:@"%@.%@.%@", @"filters",sFilterName, paramName];
    
    if(nItem >=0 && nItem < info->GetParamCount(nIndexOfFilter))
    {
        AUNI_VARIABLE para = info->GetParamInfo(pImageFilter -> nFilterIndex, nItem);
        float a,b,c,d;
        float fWidth,fHeight;
        fWidth = layer.frame.size.width;
        fHeight = layer.frame.size.height;
        NSLog(@"进入Modify函数");
        switch (para.nType) {
            case AV_FLOAT:
                if(para.mod == 1)
                {
                    NSLog(@"%@",stringPath);
                    NSLog(@"%@", layer);
                    [layer setValue:[NSNumber numberWithFloat:aValue.fFloatValue * fWidth] forKeyPath:stringPath];
                    NSLog(@"-------------");
                    [pImageFilter->filter setValue:[NSNumber numberWithFloat:aValue.fFloatValue * fWidth] forKey:paramName];
                    NSLog(@"执行modify完成");
                }else{
                    NSLog(@"%@",stringPath);
                    NSLog(@"%@", layer);
                    [layer setValue:[NSNumber numberWithFloat:aValue.fFloatValue * (para.MaxValue.fFloatValue - para.MinValue.fFloatValue) + para.MinValue.fFloatValue] forKeyPath:stringPath];
                    NSLog(@"-------------");
                    [pImageFilter->filter setValue:[NSNumber numberWithFloat:aValue.fFloatValue * (para.MaxValue.fFloatValue - para.MinValue.fFloatValue) + para.MinValue.fFloatValue] forKey:paramName];
                    NSLog(@"执行modify完成");
                }
                break;
                
            case AV_DWORDCOLORRGB:
                a = (aValue.nUnsignedValue >> 24 & 255) / 255.0;
                b = (aValue.nUnsignedValue >> 16 & 255) / 255.0;
                c = (aValue.nUnsignedValue >> 8 & 255) / 255.0;
                d = (aValue.nUnsignedValue & 255) / 255.0;
                [layer setValue:[CIVector vectorWithX:a Y:b Z:c W:d] forKeyPath:stringPath];
                [pImageFilter->filter setValue:[CIVector vectorWithX:a Y:b Z:c W:d] forKey:paramName];
                break;
                
            case AV_DWORDCOLOR:
                a = (aValue.nUnsignedValue >> 24 & 255) / 255.0 ;
                b = (aValue.nUnsignedValue >> 16 & 255) / 255.0;
                c = (aValue.nUnsignedValue >> 8 & 255) / 255.0;
                d = (aValue.nUnsignedValue & 255) / 255.0;
                [layer setValue:[CIColor colorWithRed:a green:b blue:c alpha:d] forKeyPath:stringPath];
                [pImageFilter->filter setValue:[CIColor colorWithRed:a green:b blue:c alpha:d] forKey:paramName];
                break;
                
            case AV_CENTEROFFSET:
            {
                if(para.nValueNormalizationEnable == 1)
                {
                    fWidth = aValue.fOffsetXY[0] * para.MaxValue.fOffsetXY[0];
                    fHeight = aValue.fOffsetXY[1] * para.MinValue.fOffsetXY[1];
                    [layer setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKeyPath:stringPath];
                    [pImageFilter->filter setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKey:paramName];
                }else{
                    fWidth = 2 * (fWidth) * aValue.fOffsetXY[0] - 0.5 * fWidth;
                    fHeight = 2 * (fHeight) * (1 - aValue.fOffsetXY[1]) - 0.5 * fHeight;
                    [layer setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKeyPath:stringPath];
                    [pImageFilter->filter setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKey:paramName];
                }
                break;
            }
            default:
                break;
        }
    }

}

void ModifyImageFilterParm(IMAGE_FILTER_HANDLE hImageFilter, int nItem, AVARIABLE_VALUE aValue)
{
    IMAGE_FILTER *pImageFilter = (IMAGE_FILTER *)hImageFilter;
    
    if(!pImageFilter)  return;
    if(!pImageFilter->image) return;
    if(!pImageFilter->filter) return;
    
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
    if(nItem >=0 && nItem < info->GetParamCount(pImageFilter->nFilterIndex))
    {
        AUNI_VARIABLE para = info->GetParamInfo(pImageFilter->nFilterIndex, nItem);
        float a,b,c,d;
        float fWidth,fHeight;
        GetImageSize(hImageFilter, &fWidth, &fHeight);
        switch (para.nType) {
            case AV_FLOAT:
                if(para.mod == 1)
                {
                    [pImageFilter -> filter setValue:[NSNumber numberWithFloat:aValue.fFloatValue * fWidth] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }else{
                    [pImageFilter -> filter setValue:[NSNumber numberWithFloat:aValue.fFloatValue * (para.MaxValue.fFloatValue - para.MinValue.fFloatValue) + para.MinValue.fFloatValue] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }
                break;
                
            case AV_DWORDCOLORRGB:
                a = (aValue.nUnsignedValue >> 24 & 255) / 255.0 ;
                b = (aValue.nUnsignedValue >> 16 & 255) / 255.0;
                c = (aValue.nUnsignedValue >> 8 & 255) / 255.0;
                d = (aValue.nUnsignedValue & 255) / 255.0;
                [pImageFilter -> filter setValue:[CIVector vectorWithX:a Y:b Z:c W:d] forKey:[NSString stringWithUTF8String:para.cInterName]];
                break;
                    
            case AV_DWORDCOLOR:
                 a = (aValue.nUnsignedValue >> 24 & 255) / 255.0 ;
                 b = (aValue.nUnsignedValue >> 16 & 255) / 255.0;
                 c = (aValue.nUnsignedValue >> 8 & 255) / 255.0;
                 d = (aValue.nUnsignedValue & 255) / 255.0;
                [pImageFilter -> filter setValue:[CIColor colorWithRed:a green:b blue:c alpha:d] forKey:[NSString stringWithUTF8String:para.cInterName]];
                break;
                
            case AV_CENTEROFFSET:
            {
                if(para.nValueNormalizationEnable == 1)
                {
                    fWidth = aValue.fOffsetXY[0] * para.MaxValue.fOffsetXY[0];
                    fHeight = aValue.fOffsetXY[1] * para.MinValue.fOffsetXY[1];
                    [pImageFilter -> filter setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }else{
                    fWidth = 2 * (fWidth) * aValue.fOffsetXY[0] - 0.5*fWidth;
                    fHeight = 2 * (fHeight) * (1 - aValue.fOffsetXY[1]) - 0.5 * fHeight;
                    [pImageFilter -> filter setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }
                break;
            }
            default:
                break;
        }
    }
}

AUNI_VARIABLE GetImageFilterParm(IMAGE_FILTER_HANDLE hImageFilter, int nItem)
{
     IMAGE_FILTER *pImageFilter = (IMAGE_FILTER *)hImageFilter;
//    if(!pImageFilter)  return 0.0;
//    if(!pImageFilter->image) return 0.0;
//    if(!pImageFilter->filter) return 0.0;
    
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
//    if(nItem >=0 && nItem < info->GetParamCount(pImageFilter -> nFilterIndex))
//    {
        AUNI_VARIABLE para = info -> GetParamInfo(pImageFilter->nFilterIndex, nItem);
//        if(para.nType == AV_FLOAT)
//        {
//            NSNumber *nsValue = [pImageFilter -> filter valueForKey:[NSString stringWithUTF8String:para.cInterName]];
//            return [nsValue floatValue];
//        }
//    }
    return para;
}
void ModifyImageFilterParmWithWidthAndHeight(IMAGE_FILTER_HANDLE hImageFilter, int nItem, AVARIABLE_VALUE aValue,float fWidth, float fHeight)
{
    IMAGE_FILTER *pImageFilter = (IMAGE_FILTER *)hImageFilter;
    
    if(!pImageFilter)  return;
    if(!pImageFilter->filter) return;
    
    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
    
    if(nItem >=0 && nItem < info->GetParamCount(pImageFilter->nFilterIndex))
    {
        AUNI_VARIABLE para = info->GetParamInfo(pImageFilter->nFilterIndex, nItem);
        float a,b,c,d;
        switch (para.nType) {
            case AV_FLOAT:
                if(para.mod == 1)
                {
                    [pImageFilter -> filter setValue:[NSNumber numberWithFloat:aValue.fFloatValue * fWidth] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }else{
                    [pImageFilter -> filter setValue:[NSNumber numberWithFloat:aValue.fFloatValue * (para.MaxValue.fFloatValue - para.MinValue.fFloatValue) + para.MinValue.fFloatValue] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }
                break;
                
            case AV_DWORDCOLORRGB:
                a = (aValue.nUnsignedValue >> 24 & 255) / 255.0 ;
                b = (aValue.nUnsignedValue >> 16 & 255) / 255.0;
                c = (aValue.nUnsignedValue >> 8 & 255) / 255.0;
                d = (aValue.nUnsignedValue & 255) / 255.0;
                [pImageFilter -> filter setValue:[CIVector vectorWithX:a Y:b Z:c W:d] forKey:[NSString stringWithUTF8String:para.cInterName]];
                break;
                
            case AV_DWORDCOLOR:
                a = (aValue.nUnsignedValue >> 24 & 255) / 255.0 ;
                b = (aValue.nUnsignedValue >> 16 & 255) / 255.0;
                c = (aValue.nUnsignedValue >> 8 & 255) / 255.0;
                d = (aValue.nUnsignedValue & 255) / 255.0;
                [pImageFilter -> filter setValue:[CIColor colorWithRed:a green:b blue:c alpha:d] forKey:[NSString stringWithUTF8String:para.cInterName]];
                break;
                
            case AV_CENTEROFFSET:
            {
                if(para.nValueNormalizationEnable == 1)
                {
                    fWidth = aValue.fOffsetXY[0] * para.MaxValue.fOffsetXY[0];
                    fHeight = aValue.fOffsetXY[1] * para.MinValue.fOffsetXY[1];
                    [pImageFilter -> filter setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }else{
                    fWidth = 2 * (fWidth) * aValue.fOffsetXY[0] - 0.5*fWidth;
                    fHeight = 2 * (fHeight) * (1 - aValue.fOffsetXY[1]) - 0.5 * fHeight;
                    [pImageFilter -> filter setValue:[CIVector vectorWithX:fWidth Y:fHeight] forKey:[NSString stringWithUTF8String:para.cInterName]];
                }
                break;
            }
            default:
                break;
        }
    }
}

CIImage *GetOutImage(IMAGE_FILTER_HANDLE   hImageFilter)
{
    IMAGE_FILTER *pImageFilter = (IMAGE_FILTER *)hImageFilter;
    
    if(!pImageFilter)  return NULL;
    if(!pImageFilter->image) return  NULL;
    
    [pImageFilter->image release];
    pImageFilter->image = [pImageFilter->filter valueForKey:@"outputImage"];
    [pImageFilter->image retain];

   return pImageFilter->image;
}


void RenderCIImage(CGContextRef contextCG, CIImage *pCIImage, CGRect rectTo, CGRect rectFrom )
{
    //  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CIImage *image = (CIImage *)pCIImage;
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kCIContextUseSoftwareRenderer];
    CIContext *iContext = [CIContext contextWithCGContext:contextCG options:options];
    // [iContext retain];
    
    [iContext drawImage:image inRect:rectTo fromRect:rectFrom];
    //    [iContext retain];
}

int GetCategoriesCount()
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    return (int)(info->m_mapStringAndVector).size();
}

NSString* GetCategoryNameInCategory(int nCategoryIndex)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).begin();
    for(int i = 0 ; i < nCategoryIndex; i++)
        ++it;
    string sCategoryName = it -> first;
    
    NSString* nameString = [NSString stringWithUTF8String:sCategoryName.c_str()];
    return nameString;
}

int GetFiltersCountInCategory(int nCategoryIndex)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    return (int)(it -> second).size();
}

//NSString* GetFilterInNameInCategory(int nCategoryIndex, int nFilterCategoryIndex)
//{
//    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
//    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
//    const char* cName = [sNameOfCategory UTF8String];
//    string stringName = string(cName);
//    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
//    string sShowFilterInName = (it->second)[nFilterCategoryIndex].strInAlgorithmName;
//    return [NSString stringWithUTF8String:sShowFilterInName.c_str()];
//}

NSString* GetFilterNameInCategory(int nCategoryIndex,int nFilterInCatetoryIndex)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    string sShowFilterName = (it->second)[nFilterInCatetoryIndex].strAlgorithmName;
    return [NSString stringWithUTF8String:sShowFilterName.c_str()];
}

int GetFilterParaCountInCategory(int nCategoryIndex, int nFilterInCatetoryIndex)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    return (int)(it->second)[nFilterInCatetoryIndex].vectorParam.size();
}

NSString *GetFilterParamInNameInCategory(int nCategoryIndex,int nFilterInCatetoryIndex, int nItem)
{
    if(nCategoryIndex>(GetCategoriesCount() - 1) || nFilterInCatetoryIndex > (GetFiltersCountInCategory(nCategoryIndex) - 1) || nItem >(GetFilterParaCountInCategory(nCategoryIndex,nFilterInCatetoryIndex) - 1))
        return nil;
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    char* cParamInName = (it->second)[nFilterInCatetoryIndex].vectorParam[nItem].cInterName;
    return [NSString stringWithUTF8String:cParamInName];
}

NSString *GetFilterParamNameInCategory(int nCategoryIndex,int nFilterInCatetoryIndex, int nItem)
{
    if(nCategoryIndex>(GetCategoriesCount() - 1) || nFilterInCatetoryIndex > (GetFiltersCountInCategory(nCategoryIndex) - 1) || nItem >(GetFilterParaCountInCategory(nCategoryIndex,nFilterInCatetoryIndex) - 1))
        return nil;
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    char* cShowParamName = (it->second)[nFilterInCatetoryIndex].vectorParam[nItem].cName;
    return [NSString stringWithUTF8String:cShowParamName];
}

AVARIABLE_VALUE GetFilterParamMaxInCategory(int nCategoryIndex,int nFilterInCatetoryIndex,int nItem)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    return (it->second)[nFilterInCatetoryIndex].vectorParam[nItem].MaxValue;
}

AVARIABLE_VALUE GetFilterParamMinInCategory(int nCategoryIndex,int nFilterInCatetoryIndex,int nItem)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
     return (it->second)[nFilterInCatetoryIndex].vectorParam[nItem].MinValue;
}

AVARIABLE_VALUE GetFilterParamDefaultInCategory(int nCategoryIndex,int nFilterInCatetoryIndex,int nItem)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    return (it->second)[nFilterInCatetoryIndex].vectorParam[nItem].DefaultValue;
}

AENUM_VARIABLE_TYPE GetFilterParamTypeInCategory(int nCategoryIndex,  int nFilterInCategoryIndex, int nItem)
{
    CAImageFilterInfo* info = CAImageFilterInfo::GetImageFilterInfoInstance();
    NSString* sNameOfCategory = GetCategoryNameInCategory(nCategoryIndex);
    const char* cName = [sNameOfCategory UTF8String];
    string stringName = string(cName);
    map<string,vector<AALGORITHM_ITEM> >::iterator it = (info->m_mapStringAndVector).find(stringName);
    return (it->second)[nFilterInCategoryIndex].vectorParam[nItem].nType;
}

//CIFilter* CreateFilterInCategory(CIImage* inputImage,int nCategoryIndex, int nFilterIndex)
//{
//    float fWidth = inputImage.extent.size.width;
//    float fHeight = inputImage.extent.size.height;
//    
//    CAImageFilterInfo *info =  CAImageFilterInfo::GetImageFilterInfoInstance();
//    
//    map<string,vector<AALGORITHM_ITEM>>::iterator it = (info -> m_mapStringAndVector).begin();
//    for(int i = 0; i < nCategoryIndex; i++)
//    {
//        ++it;
//    }
//    string sInName = (it -> second)[nFilterIndex].strInAlgorithmName;
//    NSString* sName = [NSString stringWithUTF8String:sInName.c_str()];
//    CIFilter* filter = [CIFilter filterWithName:sName];
//    [filter retain];
//    [filter setDefaults];
//    if([filter.inputKeys containsObject:@"inputCenter"])
//    {
//        [filter setValue:[CIVector vectorWithX:fWidth/2 Y:fHeight/2] forKey:@"inputCenter"];
//    }
//    return filter;
//}
