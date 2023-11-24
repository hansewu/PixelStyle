


/*
  From Ofx Example plugin that show a very simple plugin that inverts an image.

  It is meant to illustrate certain features of the API, as opposed to being a perfectly
  crafted piece of image processing software.

  The main features are
    - basic plugin definition
    - basic property usage
    - basic image access and rendering
 */
#include <cstring>
#include <stdexcept>
#include <new>
#include <math.h>

#include "ofxImageEffect.h"
#include "ofxMemory.h"
#include "ofxMultiThread.h"
#include "ofxPixels.h"

#include "ofxUtilities.H"

#if defined __APPLE__ || defined linux || defined __FreeBSD__
#  define EXPORT __attribute__((visibility("default")))
#elif defined _WIN32
#  define EXPORT OfxExport
#else
#  error Not building on your operating system quite yet
#endif

#define gfloat float
#define gdouble double
#define gboolean bool
static inline double CLAMP(double value, double min, double max)
{
    return (value < min) ? min : (value > max) ? max : value;
}




static inline gdouble
gimp_operation_levels_map (gdouble  value,
                           gdouble  low_input,
                           gdouble  high_input,
                           gboolean clamp_input,
                           gdouble  inv_gamma,
                           gdouble  low_output,
                           gdouble  high_output,
                           gboolean clamp_output)
{
  /*  determine input intensity  */
  if (high_input != low_input)
    value = (value - low_input) / (high_input - low_input);
  else
    value = (value - low_input);

  if (clamp_input)
    value = CLAMP (value, 0.0, 1.0);

  if (inv_gamma != 1.0 && value > 0)
    value =  pow (value, inv_gamma);

  /*  determine the output intensity  */
  if (high_output >= low_output)
    value = value * (high_output - low_output) + low_output;
  else if (high_output < low_output)
    value = low_output - value * (low_output - high_output);

  if (clamp_output)
    value = CLAMP (value, 0.0, 1.0);

  return value;
}


#define RED 0
#define GREEN 1
#define BLUE 2
#define ALPHA 3

static bool
color_levels_process (
                                      unsigned char             *src,
                                      unsigned char            *dest,
                                      double config_low_input[5],
                                        double config_high_input[5],
                                        double inv_gamma[5],
                                        double config_low_output[5],
                                        double config_high_output[5],
                                        bool config_clamp_input,
                                        bool config_clamp_output
                                      )
{
    
    for (int channel = 0; channel < 3; channel++)
    {
        gdouble value;

        value = gimp_operation_levels_map (src[channel]/255.0,
                                           config_low_input[channel + 1],
                                           config_high_input[channel + 1],
                                           config_clamp_input,
                                           inv_gamma[channel + 1],
                                           config_low_output[channel + 1],
                                           config_high_output[channel + 1],
                                           config_clamp_output);

        /* don't apply the overall curve to the alpha channel */
        if (channel != ALPHA)
          value = gimp_operation_levels_map (value,
                                             config_low_input[0],
                                             config_high_input[0],
                                             config_clamp_input,
                                             inv_gamma[0],
                                             config_low_output[0],
                                             config_high_output[0],
                                             config_clamp_output);

        dest[channel] = (unsigned char)(value*255.0);
      }

    dest[ALPHA] = src[ALPHA];


      return true;
}

static int getConfigValue(OfxImageEffectHandle  instance,
                          double config_gamma[5],
                          double config_low_input[5],
                          double config_high_input[5],
                          double config_low_output[5],
                          double config_high_output[5],
                          bool *config_clamp_input,
                          bool *config_clamp_output)
{
    OfxParamSetHandle paramSet;
    gEffectHost->getParamSet(instance, &paramSet);
    
    double dValue;
    OfxParamHandle rParam;
  
    gParamHost->paramGetHandle(paramSet, "All-Input-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_input[0] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "All-Input-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_input[0] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "All-Input-Gama", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_gamma[0] = dValue;
    gParamHost->paramGetHandle(paramSet, "All-Output-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_output[0] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "All-Output-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_output[0] = dValue/100.0;
    
    gParamHost->paramGetHandle(paramSet, "Red-Input-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_input[1] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Red-Input-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_input[1] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Red-Input-Gama", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_gamma[1] = dValue;
    gParamHost->paramGetHandle(paramSet, "Red-Output-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_output[1] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Red-Output-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_output[1] = dValue/100.0;
    
    gParamHost->paramGetHandle(paramSet, "Green-Input-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_input[2] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Green-Input-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_input[2] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Green-Input-Gama", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_gamma[2] = dValue;
    gParamHost->paramGetHandle(paramSet, "Green-Output-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_output[2] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Green-Output-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_output[2] = dValue/100.0;
    
    gParamHost->paramGetHandle(paramSet, "Blue-Input-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_input[3] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Blue-Input-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_input[3] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Blue-Input-Gama", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_gamma[3] = dValue;
    gParamHost->paramGetHandle(paramSet, "Blue-Output-Low", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_low_output[3] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Blue-Output-High", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_high_output[3] = dValue/100.0;
    
    for(int i=0; i<4; i++)
    {
        if(config_gamma[i]< 50.0)
        {
            config_gamma[i]/=50.0;
            if(config_gamma[i]< 0.1) config_gamma[i]=0.1;
        }
        else
            config_gamma[i] = (config_gamma[i]-50.0)/50.0*4.5+1.0;
    }
    
    *config_clamp_input = true;
    *config_clamp_output = true;
    /*bool nValue;
    gParamHost->paramGetHandle(paramSet, "Preserve Luminosity", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &nValue);
    
    *config_preserve_luminosity = nValue;*/
    
    return 0;
}


//defined in color.cpp  pointers to various bits of the host
extern OfxHost               *gHost;
extern OfxImageEffectSuiteV1 *gEffectHost;
extern OfxPropertySuiteV1    *gPropHost;
extern OfxParameterSuiteV1   *gParamHost;
extern OfxMemorySuiteV1      *gMemoryHost;
extern OfxMultiThreadSuiteV1 *gThreadHost;
extern OfxMessageSuiteV1     *gMessageSuite;
extern OfxInteractSuiteV1    *gInteractHost;


// look up a pixel in the image, does bounds checking to see if it is in the image rectangle
inline OfxRGBAColourB *
pixelAddress(OfxRGBAColourB *img, OfxRectI rect, int x, int y, int bytesPerLine)
{  
  if(x < rect.x1 || x >= rect.x2 || y < rect.y1 || y > rect.y2)
    return 0;
  OfxRGBAColourB *pix = (OfxRGBAColourB *) (((char *) img) + (y - rect.y1) * bytesPerLine);
  pix += x - rect.x1;  
  return pix;
}

// throws this if it can't fetch an image
class NoImageEx {};

// the process code  that the host sees
static OfxStatus render(OfxImageEffectHandle  instance,
                        OfxPropertySetHandle inArgs,
                        OfxPropertySetHandle /*outArgs*/)
{
  // get the render window and the time from the inArgs
  OfxTime time;
  OfxRectI renderWindow;
  OfxStatus status = kOfxStatOK;
  
  gPropHost->propGetDouble(inArgs, kOfxPropTime, 0, &time);
  gPropHost->propGetIntN(inArgs, kOfxImageEffectPropRenderWindow, 4, &renderWindow.x1);

  // fetch output clip
  OfxImageClipHandle outputClip;
  gEffectHost->clipGetHandle(instance, kOfxImageEffectOutputClipName, &outputClip, 0);
    

  OfxPropertySetHandle outputImg = NULL, sourceImg = NULL;
  try {
    // fetch image to render into from that clip
    if(gEffectHost->clipGetImage(outputClip, time, NULL, &outputImg) != kOfxStatOK) {
      throw NoImageEx();
    }
      
    // fetch output image info from that handle
    int dstRowBytes;
    OfxRectI dstRect;
    void *dstPtr;
    gPropHost->propGetInt(outputImg, kOfxImagePropRowBytes, 0, &dstRowBytes);
    gPropHost->propGetIntN(outputImg, kOfxImagePropBounds, 4, &dstRect.x1);
    gPropHost->propGetInt(outputImg, kOfxImagePropRowBytes, 0, &dstRowBytes);
    gPropHost->propGetPointer(outputImg, kOfxImagePropData, 0, &dstPtr);
      
    // fetch main input clip
    OfxImageClipHandle sourceClip;
    gEffectHost->clipGetHandle(instance, kOfxImageEffectSimpleSourceClipName, &sourceClip, 0);
      
    // fetch image at render time from that clip
    if (gEffectHost->clipGetImage(sourceClip, time, NULL, &sourceImg) != kOfxStatOK) {
      throw NoImageEx();
    }
      
    // fetch image info out of that handle
    int srcRowBytes;
    OfxRectI srcRect;
    void *srcPtr;
    gPropHost->propGetInt(sourceImg, kOfxImagePropRowBytes, 0, &srcRowBytes);
    gPropHost->propGetIntN(sourceImg, kOfxImagePropBounds, 4, &srcRect.x1);
    gPropHost->propGetInt(sourceImg, kOfxImagePropRowBytes, 0, &srcRowBytes);
    gPropHost->propGetPointer(sourceImg, kOfxImagePropData, 0, &srcPtr);

      double config_gamma[5];
      double config_low_input[5];
      double config_high_input[5];
      bool config_clamp_input;
      double inv_gamma[5];
      double config_low_output[5];
      double config_high_output[5];
      bool config_clamp_output;
      
      getConfigValue(instance,
                     config_gamma,
                     config_low_input,
                     config_high_input,
                     config_low_output,
                     config_high_output,
                     &config_clamp_input,
                     &config_clamp_output);
      
      for (int channel = 0; channel < 4; channel++)
      {
         // g_return_val_if_fail (config->gamma[channel] != 0.0, FALSE);

          inv_gamma[channel] = 1.0 / config_gamma[channel];
      }
      
    // cast data pointers to 8 bit RGBA
    OfxRGBAColourB *src = (OfxRGBAColourB *) srcPtr;
    OfxRGBAColourB *dst = (OfxRGBAColourB *) dstPtr;

    // and do some inverting
    for(int y = renderWindow.y1; y < renderWindow.y2; y++)
    {
      if(gEffectHost->abort(instance)) break;

      OfxRGBAColourB *dstPix = pixelAddress(dst, dstRect, renderWindow.x1, y, dstRowBytes);

      for(int x = renderWindow.x1; x < renderWindow.x2; x++)
      {
        
        OfxRGBAColourB *srcPix = pixelAddress(src, srcRect, x, y, srcRowBytes);

        if(srcPix)
        {
            color_levels_process ((unsigned char *)srcPix, (unsigned char *)dstPix, config_low_input,
                                  config_high_input, inv_gamma,config_low_output, config_high_output,
                                  config_clamp_input,config_clamp_output
                                  );
        }
        else
        {
          dstPix->r = 0;
          dstPix->g = 0;
          dstPix->b = 0;
          dstPix->a = 0;
        }
        dstPix++;
      }
    }

    // we are finished with the source images so release them
  }
  catch(NoImageEx &) {
    // if we were interrupted, the failed fetch is fine, just return kOfxStatOK
    // otherwise, something weird happened
    if(!gEffectHost->abort(instance)) {
      status = kOfxStatFailed;
    }      
  }

  if(sourceImg)
    gEffectHost->clipReleaseImage(sourceImg);
  if(outputImg)
    gEffectHost->clipReleaseImage(outputImg);
  
  // all was well
  return status;
}

static void
defineDoubleParam( OfxParamSetHandle effectParams,
         const char *name,
         const char *label,
         const char *scriptName,
         const char *hint,
         //const char *parent,
        double defaultValue,
                  double minValue,
                  double maxValue)
{
    //OfxParamHandle param;
    OfxPropertySetHandle props;
    gParamHost->paramDefine(effectParams, kOfxParamTypeDouble, name, &props);

    // say we are a scaling parameter
    gPropHost->propSetString(props, kOfxParamPropDoubleType, 0, kOfxParamDoubleTypeScale);
    gPropHost->propSetDouble(props, kOfxParamPropDefault, 0, defaultValue);
    gPropHost->propSetDouble(props, kOfxParamPropMin, 0, minValue);
    gPropHost->propSetDouble(props, kOfxParamPropMax, 0, maxValue);
    gPropHost->propSetDouble(props, kOfxParamPropDisplayMin, 0, minValue);
    gPropHost->propSetDouble(props, kOfxParamPropDisplayMax, 0, maxValue);
    gPropHost->propSetDouble(props, kOfxParamPropIncrement, 0, 0.01);
    gPropHost->propSetString(props, kOfxParamPropHint, 0, hint);
    gPropHost->propSetString(props, kOfxParamPropScriptName, 0, scriptName);
    gPropHost->propSetString(props, kOfxPropLabel, 0, label);
    //if(parent)
    //gPropHost->propSetString(props, kOfxParamPropParent, 0, parent);
}

static void
defineBoolParam( OfxParamSetHandle effectParams,
         const char *name,
         const char *label,
         const char *scriptName,
         const char *hint,
        bool defaultValue)
{
    //OfxParamHandle param;
    OfxPropertySetHandle props;
    gParamHost->paramDefine(effectParams, kOfxParamTypeBoolean, name, &props);

    if(defaultValue)
        gPropHost->propSetInt(props, kOfxParamPropDefault, 0, 1);
    else gPropHost->propSetInt(props, kOfxParamPropDefault, 0, 0);

    gPropHost->propSetString(props, kOfxParamPropHint, 0, hint);
    gPropHost->propSetString(props, kOfxParamPropScriptName, 0, scriptName);
    gPropHost->propSetString(props, kOfxPropLabel, 0, label);
    //if(parent)
    //gPropHost->propSetString(props, kOfxParamPropParent, 0, parent);
}

//  describe the plugin in context
static OfxStatus
describeInContext( OfxImageEffectHandle  effect,  OfxPropertySetHandle /*inArgs*/)
{
  OfxPropertySetHandle props;
  // define the single output clip in both contexts
  gEffectHost->clipDefine(effect, kOfxImageEffectOutputClipName, &props);

  // set the component types we can handle on out output
  gPropHost->propSetString(props, kOfxImageEffectPropSupportedComponents, 0, kOfxImageComponentRGBA);

  // define the single source clip in both contexts
  gEffectHost->clipDefine(effect, kOfxImageEffectSimpleSourceClipName, &props);

  // set the component types we can handle on our main input
  gPropHost->propSetString(props, kOfxImageEffectPropSupportedComponents, 0, kOfxImageComponentRGBA);

    OfxParamSetHandle paramSet;
    gEffectHost->getParamSet(effect, &paramSet);

    defineDoubleParam(paramSet, "All-Input-Low", "All Input:Low", "All-Input-Low",
            "All-Input-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "All-Input-High", "All Input:High", "All-Input-High",
            "All-Input-High", 100.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "All-Input-Gama", "All Input:Gama", "All-Input-Gama",
            "All-Input-Gama", 50.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "All-Output-Low", "All Output:Low", "All-Output-Low",
            "All-Output-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "All-Output-High", "All Output:High", "All-Output-High",
            "All-Output-High", 100.0, 0.0, 100.0);

    defineDoubleParam(paramSet, "Red-Input-Low", "Red Input:Low", "Red-Input-Low",
            "Red-Input-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Red-Input-High", "Red Input:High", "Red-Input-High",
            "Red-Input-High", 100.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Red-Input-Gama", "Red Input:Gama", "Red-Input-Gama",
            "Red-Input-Gama", 50.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Red-Output-Low", "Red Output:Low", "Red-Output-Low",
            "Red-Output-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Red-Output-High", "Red Output:High", "Red-Output-High",
            "Red-Output-High", 100.0, 0.0, 100.0);
    
    defineDoubleParam(paramSet, "Green-Input-Low", "Green Input:Low", "Green-Input-Low",
            "Green-Input-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Green-Input-High", "Green Input:High", "Green-Input-High",
            "Green-Input-High", 100.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Green-Input-Gama", "Green Input:Gama", "Green-Input-Gama",
            "Green-Input-Gama", 50.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Green-Output-Low", "Green Output:Low", "Green-Output-Low",
            "Green-Output-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Green-Output-High", "Green Output:High", "Green-Output-High",
            "Green-Output-High", 100.0, 0.0, 100.0);

    defineDoubleParam(paramSet, "Blue-Input-Low", "Blue Input:Low", "Blue-Input-Low",
            "Blue-Input-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Blue-Input-High", "Blue Input:High", "Blue-Input-High",
            "Blue-Input-High", 100.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Blue-Input-Gama", "Blue Input:Gama", "Blue-Input-Gama",
            "Blue-Input-Gama", 50.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Blue-Output-Low", "Blue Output:Low", "Blue-Output-Low",
            "Blue-Output-Low", 0.0, 0.0, 100.0);
    defineDoubleParam(paramSet, "Blue-Output-High", "Blue Output:High", "Blue-Output-High",
            "Blue-Output-High", 100.0, 0.0, 100.0);
    
    //defineBoolParam(paramSet, "Preserve Luminosity", "Preserve Luminosity", "Preserve Luminosity",
    //                "Preserve Luminosity", true);
    
  return kOfxStatOK;
}

////////////////////////////////////////////////////////////////////////////////
// the plugin's description routine
static OfxStatus
describe(OfxImageEffectHandle effect)
{
    OfxStatus stat;
    if((stat = ofxuFetchHostSuites()) != kOfxStatOK)
      return stat;
    
  // get the property handle for the plugin
  OfxPropertySetHandle effectProps;
  gEffectHost->getPropertySet(effect, &effectProps);

  // say we cannot support multiple pixel depths and let the clip preferences action deal with it all.
  gPropHost->propSetInt(effectProps, kOfxImageEffectPropSupportsMultipleClipDepths, 0, 0);
  
  // set the bit depths the plugin can handle
  gPropHost->propSetString(effectProps, kOfxImageEffectPropSupportedPixelDepths, 0, kOfxBitDepthByte);

  // set plugin label and the group it belongs to
  gPropHost->propSetString(effectProps, kOfxPropLabel, 0, "OFX Color Balance");
  gPropHost->propSetString(effectProps, kOfxImageEffectPluginPropGrouping, 0, "Color");

  // define the contexts we can be used in
  gPropHost->propSetString(effectProps, kOfxImageEffectPropSupportedContexts, 0, kOfxImageEffectContextFilter);
  
  return kOfxStatOK;
}

////////////////////////////////////////////////////////////////////////////////
// Called at load
static OfxStatus
onLoad(void)
{
    // fetch the host suites out of the global host pointer
    if(!gHost) return kOfxStatErrMissingHostFeature;
    
    gEffectHost     = (OfxImageEffectSuiteV1 *) gHost->fetchSuite(gHost->host, kOfxImageEffectSuite, 1);
    gPropHost       = (OfxPropertySuiteV1 *)    gHost->fetchSuite(gHost->host, kOfxPropertySuite, 1);
    if(!gEffectHost || !gPropHost)
        return kOfxStatErrMissingHostFeature;
    return kOfxStatOK;
}

////////////////////////////////////////////////////////////////////////////////
// The main entry point function
static OfxStatus
pluginMain(const char *action,  const void *handle, OfxPropertySetHandle inArgs,  OfxPropertySetHandle outArgs)
{
  try {
  // cast to appropriate type
  OfxImageEffectHandle effect = (OfxImageEffectHandle) handle;

  if(strcmp(action, kOfxActionLoad) == 0) {
    return onLoad();
  }
  else if(strcmp(action, kOfxActionDescribe) == 0) {
    return describe(effect);
  }
  else if(strcmp(action, kOfxImageEffectActionDescribeInContext) == 0) {
    return describeInContext(effect, inArgs);
  }
  else if(strcmp(action, kOfxImageEffectActionRender) == 0) {
    return render(effect, inArgs, outArgs);
  }    
  } catch (std::bad_alloc) {
    // catch memory
    //std::cout << "OFX Plugin Memory error." << std::endl;
    return kOfxStatErrMemory;
  } catch ( const std::exception& e ) {
    // standard exceptions
    //std::cout << "OFX Plugin error: " << e.what() << std::endl;
    return kOfxStatErrUnknown;
  } catch (int err) {
    // ho hum, gone wrong somehow
    return err;
  } catch ( ... ) {
    // everything else
    //std::cout << "OFX Plugin error" << std::endl;
    return kOfxStatErrUnknown;
  }
    
  // other actions to take the default value
  return kOfxStatReplyDefault;
}

// function to set the host structure
static void
setHostFunc(OfxHost *hostStruct)
{
  gHost = hostStruct;
}

////////////////////////////////////////////////////////////////////////////////
// the plugin struct 
OfxPlugin levelsPlugin =
{       
  kOfxImageEffectPluginApi,
  1,
  "cn.co.effectmatrix.levels",
  1,
  0,
  setHostFunc,
  pluginMain
};
   
