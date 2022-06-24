

#include <iostream>
#include <fstream>
#include <cassert>
#include <stdexcept>
#include <sstream> // stringstream

// ofx
#include "ofxCore.h"
#include "ofxImageEffect.h"
#include "ofxPixels.h"

// ofx host
#include "ofxhBinary.h"
#include "ofxhPropertySuite.h"
#include "ofxhClip.h"
#include "ofxhParam.h"
#include "ofxhMemory.h"
#include "ofxhImageEffect.h"
#include "ofxhPluginAPICache.h"
#include "ofxhPluginCache.h"
#include "ofxhHost.h"
#include "ofxhImageEffectAPI.h"

// my host
#include "hostDemoHostDescriptor.h"
#include "hostDemoEffectInstance.h"
#include "hostDemoClipInstance.h"
#include "hostDemoParamInstance.h"

typedef void * OFX_HOST_HANDLE;
//OFX::Host::ImageEffect::Instance *
OFX_HOST_HANDLE oxfHostLoad(const std::string &pluginPath, const std::string &plugid);
int oxfHostGetParamsCount(OFX_HOST_HANDLE ofxHandle);
int oxfHostGetParamInfo(OFX_HOST_HANDLE ofxHandle,
                        int index, std::string &outParaName, std::string &outParaType);
int oxfHostGetParamDefaultInfo(OFX_HOST_HANDLE ofxHandle,
                               int index, int nValueIndex, std::string &outParaDefault, std::string &outParaMax, std::string &outParaMin, std::vector<std::string> *pvecChoice);
int oxfHostSetParamValue(OFX_HOST_HANDLE ofxHandle,
                         int index, int nValueIndex, const std::string &paraValue);
int oxfHostSetImageFrame(OFX_HOST_HANDLE ofxHandle,
                         unsigned char *pRGBABuf, int nWidth, int nHeight);
int oxfHostProcess(OFX_HOST_HANDLE ofxHandle, unsigned char *pRGBABufOut, int nBufWidth, int nBufHeight);

struct TypeMap {
  const char *paramType;
    OFX::Host::Property::TypeEnum propType;
  int propDimension;
};

static const TypeMap typeMap[] = {
  { kOfxParamTypeInteger,   OFX::Host::Property::eInt,    1 },
  { kOfxParamTypeDouble,    OFX::Host::Property::eDouble, 1 },
  { kOfxParamTypeBoolean,   OFX::Host::Property::eInt,    1 },
  { kOfxParamTypeChoice,    OFX::Host::Property::eInt,    1 },
#ifdef OFX_EXTENSIONS_RESOLVE
  { kOfxParamTypeStrChoice, OFX::Host::Property::eString, 1 },
#endif
  { kOfxParamTypeRGBA,      OFX::Host::Property::eDouble, 4 },
  { kOfxParamTypeRGB,       OFX::Host::Property::eDouble, 3 },
  { kOfxParamTypeDouble2D,  OFX::Host::Property::eDouble, 2 },
  { kOfxParamTypeInteger2D, OFX::Host::Property::eInt,    2 },
  { kOfxParamTypeDouble3D,  OFX::Host::Property::eDouble, 3 },
  { kOfxParamTypeInteger3D, OFX::Host::Property::eInt,    3 },
  { kOfxParamTypeString,    OFX::Host::Property::eString, 1 },
  { kOfxParamTypeCustom,    OFX::Host::Property::eString, 1 },
  { kOfxParamTypeGroup,     OFX::Host::Property::eNone,   0 },
  { kOfxParamTypePage,      OFX::Host::Property::eNone,   0 },
  { kOfxParamTypePushButton,OFX::Host::Property::eNone,   0 },
#ifdef OFX_SUPPORTS_PARAMETRIC
  { kOfxParamTypeParametric,OFX::Host::Property::eDouble, 0 },
#endif
  { 0,                      OFX::Host::Property::eNone,   0  }
};

static bool findType(const std::string paramType, OFX::Host::Property::TypeEnum &propType, int &propDim)
{
  const TypeMap *tm = typeMap;
  while (tm->paramType) {
    if (tm->paramType == paramType) {
      propType = tm->propType;
      propDim = tm->propDimension;
      return true;
    }
    tm++;
  }
  return false;
}

//OFX::Host::ImageEffect::Instance *
OFX_HOST_HANDLE oxfHostLoad(const std::string &pluginPath, const std::string &plugid)
{
    // set the version label in the global cache
    OFX::Host::PluginCache::getPluginCache()->setCacheVersion("hostDemoV1");

    // create our derived image effect host which provides
    // a factory to make plugin instances and acts
    // as a description of the host application
    MyHost::Host myHost;

    // make an image effect plugin cache. This is what knows about
    // all the plugins.
    OFX::Host::ImageEffect::PluginCache imageEffectPluginCache(&myHost);

    // register the image effect cache with the global plugin cache
    imageEffectPluginCache.registerInCache(*OFX::Host::PluginCache::getPluginCache());

    // try to read an old cache
   /* std::ifstream ifs("hostDemoPluginCache.xml");
    try {
      OFX::Host::PluginCache::getPluginCache()->readCache(ifs);
    } catch (const std::exception &e) {
      std::cerr << "Error while reading XML cache: " << e.what() << std::endl;
    }
    ifs.close();
    */
    OFX::Host::PluginCache::getPluginCache()->addFileToPath(pluginPath, false);
    OFX::Host::PluginCache::getPluginCache()->scanPluginFiles();
    

    /// flush out the current cache
    //std::ofstream of("hostDemoPluginCache.xml");
    //OFX::Host::PluginCache::getPluginCache()->writePluginCache(of);
    //of.close();

    // get the invert example plugin which uses the OFX C++ support code
    OFX::Host::ImageEffect::ImageEffectPlugin* plugin = imageEffectPluginCache.getPluginById(plugid);//eu.gmic
    
    if(!plugin) return NULL;
    
    OFX::Host::ImageEffect::Instance* instance = plugin->createInstance(kOfxImageEffectContextFilter, NULL);
    if(!instance) return NULL;
    
    OfxStatus stat;

  // now we need to call the create instance action. Only call this once you have initialised all the params
  // and clips to their correct values. So if you are loading a saved plugin state, set up your params from
  // that state, _then_ call create instance.
    stat = instance->createInstanceAction();
    assert(stat == kOfxStatOK || stat == kOfxStatReplyDefault);

  // now we need to to call getClipPreferences on the instance so that it does the clip component/depth
  // logic and caches away the components and depth on each clip.
    bool ok = instance->getClipPreferences();
    assert(ok);
    
    return instance;
}

int oxfHostGetParamsCount(OFX_HOST_HANDLE ofxHandle)
{
    OFX::Host::ImageEffect::Instance *instance = (OFX::Host::ImageEffect::Instance *)ofxHandle;
    const std::list<OFX::Host::Param::Instance*> &Prams =  instance->getParamList();
    return (int)Prams.size();
}

static OFX::Host::Param::Instance*getParamFrom(OFX::Host::ImageEffect::Instance *instance, int index)
{
    const std::list<OFX::Host::Param::Instance*> &Prams =  instance->getParamList();
    if(index < 0 || index > Prams.size())
        return NULL;
    
    int count = 0;
    OFX::Host::Param::Instance* param = NULL;
    for(std::list<OFX::Host::Param::Instance*>::const_iterator it=Prams.begin(); it!=Prams.end(); ++it)
    {
        param = (*it);
        if(count == index) break;
        count++;
    }
    
    return param;
}


int oxfHostGetParamInfo(OFX_HOST_HANDLE ofxHandle,
                          int index, std::string &outParaName, std::string &outParaType)

{
    OFX::Host::ImageEffect::Instance *instance = (OFX::Host::ImageEffect::Instance *)ofxHandle;
    OFX::Host::Param::Instance* param = NULL;
    param = getParamFrom(instance, index);
    
    if(!param) return -1;
    if(param->getEnabled() == false)  return -2;
    if(param->getSecret()) return -3;
    
    outParaType = param->getType();
    outParaName = param->getName();
    
    OFX::Host::Property::TypeEnum propType;
    int propDim;
    if(findType(outParaType, propType, propDim))
        return propDim;
    
    return -2;
}

static std::string getParmStringProperty(const OFX::Host::Property::Set &properties, OFX::Host::Property::TypeEnum propType, std::string name, int nValueIndex)
{
    OFX::Host::Property::Property *prop = properties.fetchProperty(name);
    if(!prop) return "";
    
    switch (propType)
    {
        case OFX::Host::Property::eInt:
        {
            int nValue = properties.getIntProperty(name, nValueIndex);
            return std::to_string(nValue);
            break;
        }
        case OFX::Host::Property::eDouble:
        {
            double fValue = properties.getDoubleProperty(name, nValueIndex);
            return std::to_string(fValue);
            break;
        }
        case OFX::Host::Property::eString:
            return properties.getStringProperty(name, nValueIndex);
        default:
            return "";
            break;
    }

}

/*
static int setParmStringProperty(OFX::Host::Property::Set &properties, OFX::Host::Property::TypeEnum propType, const std::string &name, int nValueIndex, const std::string &strValue)
{
    OFX::Host::Property::Property *prop = properties.fetchProperty(name);
    if(!prop) return -1;
    
    switch (propType)
    {
        case OFX::Host::Property::eInt:
        {
            int nValue = atoi(strValue.c_str());
            properties.setIntProperty(name, nValue, nValueIndex);
            return 0;
            break;
        }
        case OFX::Host::Property::eDouble:
        {
            double fValue = atof(strValue.c_str());
            properties.setDoubleProperty(name, fValue, nValueIndex);
            return 0;
            break;
        }
        case OFX::Host::Property::eString:
             properties.setStringProperty(name, strValue, nValueIndex);
            return 0;
        default:
            return -2;
            break;
    }

}*/

int oxfHostGetParamDefaultInfo(OFX_HOST_HANDLE ofxHandle,
                          int index, int nValueIndex, std::string &outParaDefault, std::string &outParaMax, std::string &outParaMin, std::vector<std::string> *pvecChoice)
{
    OFX::Host::ImageEffect::Instance *instance = (OFX::Host::ImageEffect::Instance *)ofxHandle;
    OFX::Host::Param::Instance* param = NULL;
    param = getParamFrom(instance, index);
    
    if(!param) return -1;
    
    std::string outParaType = param->getType();
    std::string outParaName = param->getName();
    
    OFX::Host::Property::TypeEnum propType;
    int propDim;
    if(findType(outParaType, propType, propDim))
    {
        if(nValueIndex < 0 || nValueIndex >= propDim)
            return -3;
        const OFX::Host::Property::Set &properties = param->getProperties();
        
        outParaDefault = getParmStringProperty(properties, propType, std::string(kOfxParamPropDefault), nValueIndex);
        outParaMax = getParmStringProperty(properties, propType, kOfxParamPropMax, nValueIndex);
        outParaMin = getParmStringProperty(properties, propType, kOfxParamPropMin, nValueIndex);
        
        OFX::Host::Property::Property *currentProp= properties.fetchStringProperty(kOfxParamPropChoiceOption);
        if(pvecChoice && currentProp)
        {
            for(int i=0; i< currentProp->getDimension(); i++)
                pvecChoice->push_back(currentProp->getStringValue(i));
        }
        
        return 0;
    }
    
    return -4;
}

static int setParamValue(OFX::Host::Param::Instance* param, std::string paraType, int nValueIndex, const std::string &paraValue)
{
     if(paraType==kOfxParamTypeInteger)
     {
         int nValue = atoi(paraValue.c_str());
         ((MyHost::MyIntegerInstance *)param)->set(nValue);
     }
     else if(paraType==kOfxParamTypeDouble)
     {
         double fValue = atof(paraValue.c_str());
         ((MyHost::MyDoubleInstance *)param)->set(fValue);
     }
     else if(paraType==kOfxParamTypeBoolean)
     {
         int nValue = atoi(paraValue.c_str());
         ((MyHost::MyBooleanInstance *)param)->set(nValue);
     }
     else if(paraType==kOfxParamTypeChoice)
     {
         int nValue = atoi(paraValue.c_str());
         ((MyHost::MyChoiceInstance *)param)->set(nValue);
     }
     else if(paraType==kOfxParamTypeRGBA)
     {
         double value = atof(paraValue.c_str());
         double dValue[4];
         ((MyHost::MyRGBAInstance *)param)->get(dValue[0], dValue[1], dValue[2], dValue[3]);
         dValue[nValueIndex] = value;
         ((MyHost::MyRGBAInstance *)param)->set(dValue[0], dValue[1], dValue[2], dValue[3]);
     }
     else if(paraType==kOfxParamTypeRGB)
     {
         double value = atof(paraValue.c_str());
         double dValue[3];
         ((MyHost::MyRGBInstance *)param)->get(dValue[0], dValue[1], dValue[2]);
         dValue[nValueIndex] = value;
         ((MyHost::MyRGBInstance *)param)->set(dValue[0], dValue[1], dValue[2]);
     }
     else if(paraType==kOfxParamTypeDouble2D)
     {
         double value = atof(paraValue.c_str());
         double dValue[2];
         ((MyHost::MyDouble2DInstance *)param)->get(dValue[0], dValue[1]);
         dValue[nValueIndex] = value;
         ((MyHost::MyDouble2DInstance *)param)->set(dValue[0], dValue[1]);
     }
     else if(paraType==kOfxParamTypeInteger2D)
     {
         int value = atoi(paraValue.c_str());
         int dValue[2];
         ((MyHost::MyInteger2DInstance *)param)->get(dValue[0], dValue[1]);
         dValue[nValueIndex] = value;
         ((MyHost::MyInteger2DInstance *)param)->set(dValue[0], dValue[1]);
     }
     else if(paraType==kOfxParamTypeString)
     {
         ((MyHost::MyStringInstance *)param)->set(paraValue.c_str());
     }
     else return -1;
     /*else if(paraType==kOfxParamTypePushButton)
         MyHost::MyPushbuttonInstance(this,name,descriptor);
     else if(paraType==kOfxParamTypeGroup)
       return new OFX::Host::Param::GroupInstance(descriptor,this);
     else if(paraType==kOfxParamTypePage)
       return new OFX::Host::Param::PageInstance(descriptor,this);
     else if(paraType==kOfxParamTypeCustom)
         return new MyCustomInstance(this,name,descriptor);*/
    
    return 0;
}

int oxfHostSetParamValue(OFX_HOST_HANDLE ofxHandle,
                          int index, int nValueIndex, const std::string &paraValue)
{
    OFX::Host::ImageEffect::Instance *instance = (OFX::Host::ImageEffect::Instance *)ofxHandle;
    OFX::Host::Param::Instance* param = NULL;
    param = getParamFrom(instance, index);
    
    if(!param) return -1;
    
    OFX::Host::Property::TypeEnum propType;
    int propDim;
    
    std::string outParaType = param->getType();
    if(findType(outParaType, propType, propDim))
    {
        if(nValueIndex < 0 || nValueIndex >= propDim)
            return -3;
        
        setParamValue(param, outParaType, nValueIndex, paraValue);
    }
    return 0;
}

int oxfHostSetImageFrame(OFX_HOST_HANDLE ofxHandle,
                          unsigned char *pRGBABuf, int nWidth, int nHeight)
{
    OFX::Host::ImageEffect::Instance *instance = (OFX::Host::ImageEffect::Instance *)ofxHandle;
    MyHost::MyClipInstance* inputClip  = dynamic_cast<MyHost::MyClipInstance*>(instance->getClip("Source"));
    MyHost::MyClipInstance* outputClip = dynamic_cast<MyHost::MyClipInstance*>(instance->getClip("Output"));
    assert(inputClip);
    assert(outputClip);
    
    inputClip->setRGBAImageBuffer(nWidth, nHeight, pRGBABuf);
    outputClip->setRGBAImageBuffer(nWidth, nHeight);
    
    return 0;
}

int oxfHostProcess(OFX_HOST_HANDLE ofxHandle, unsigned char *pRGBABufOut, int nBufWidth, int nBufHeight)
{
    OFX::Host::ImageEffect::Instance *instance = (OFX::Host::ImageEffect::Instance *)ofxHandle;
    // current render scale of 1
    OfxPointD renderScale;
    renderScale.x = renderScale.y = 1.0;

    // The render window is in pixel coordinates
    // ie: render scale and a PAR of not 1
    OfxRectI  renderWindow;
    renderWindow.x1 = renderWindow.y1 = 0;
    renderWindow.x2 = nBufWidth;
    renderWindow.y2 = nBufHeight;

    /// RoI is in canonical coords,
    OfxRectD  regionOfInterest;
    regionOfInterest.x1 = regionOfInterest.y1 = 0;
    regionOfInterest.x2 = renderWindow.x2;// * instance->getProjectPixelAspectRatio();
    regionOfInterest.y2 = nBufHeight;
    
    int numFramesToRender = 1;

    // say we are about to render a bunch of frames
    OfxStatus stat = instance->beginRenderAction(0, numFramesToRender, 1.0, false, renderScale, /*sequential=*/true, /*interactive=*/false,
#                                        ifdef OFX_SUPPORTS_OPENGLRENDER
                                       /*openGLRender=*/false,
#                                        ifdef OFX_EXTENSIONS_NATRON
                                       /*contextData=*/NULL,
#                                        endif
#                                        endif
                                       /*draftRender=*/false
#                                        ifdef OFX_EXTENSIONS_NUKE
                                       , 0 /* view*/
#                                        endif
                                       );
    assert(stat == kOfxStatOK || stat == kOfxStatReplyDefault);

    // get the output clip
    MyHost::MyClipInstance* outputClip = dynamic_cast<MyHost::MyClipInstance*>(instance->getClip("Output"));
    assert(outputClip);
    
    // render a frame
#       ifdef OFX_EXTENSIONS_NUKE
      std::list<std::string> planes;
      planes.push_back(kOfxImagePlaneColour);
#       endif
      stat = instance->renderAction(0, //OfxTime      time,
                                    kOfxImageFieldBoth, // const std::string &  field,
                                    renderWindow, // const OfxRectI &renderRoI,
                                    renderScale, // OfxPointD   renderScale,
                                    true, // bool     sequentialRender,
                                    false, // bool     interactiveRender,
#                                    ifdef OFX_SUPPORTS_OPENGLRENDER
                                    false, // bool     openGLRender,
#                                     ifdef OFX_EXTENSIONS_NATRON
                                    NULL, // void*    contextData,
#                                     endif
#                                    endif
                                    false // bool     draftRender
#                                    if defined(OFX_EXTENSIONS_VEGAS) || defined(OFX_EXTENSIONS_NUKE)
                                    ,
                                    0 // int view
#                                    endif
#                                    ifdef OFX_EXTENSIONS_VEGAS
                                    ,
                                    1 // int nViews
#                                    endif
#                                    ifdef OFX_EXTENSIONS_NUKE
                                    ,
                                    planes // const std::list<std::string>& planes
#                                    endif
                                    );
    assert(stat == kOfxStatOK);
    
    // get the output image buffer
    MyHost::MyImage *outputImage = outputClip->getOutputImage();
    OfxRGBAColourB* pOutBuf = outputImage->pixel(0, 0);
    
    memcpy(pRGBABufOut, pOutBuf, nBufWidth * nBufHeight *4);
    
    instance->endRenderAction(0, numFramesToRender, 1.0, false, renderScale, /*sequential=*/true, /*interactive=*/false,
#                               ifdef OFX_SUPPORTS_OPENGLRENDER
                              /*openGLRender=*/false,
#                               ifdef OFX_EXTENSIONS_NATRON
                              /*contextData=*/NULL,
#                               endif
#                               endif
                              /*draftRender=*/false
#                               ifdef OFX_EXTENSIONS_NUKE
                              , 0 /* view*/
#                               endif
                              );
  
    return 0;
}

