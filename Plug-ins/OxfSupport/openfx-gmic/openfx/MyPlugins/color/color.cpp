


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

static inline double CLAMP(double value, double min, double max)
{
    return (value < min) ? min : (value > max) ? max : value;
}

struct GimpHSV {
  gdouble h, s, v, a;
};

struct GimpHSL {
  gdouble h, s, l, a;
};

struct GimpRGB {
  gdouble r, g, b, a;
};

#define GIMP_HSL_UNDEFINED -1.0

gdouble
gimp_rgb_max (const GimpRGB *rgb)
{
  //g_return_val_if_fail (rgb != NULL, 0.0);

  if (rgb->r > rgb->g)
    return (rgb->r > rgb->b) ? rgb->r : rgb->b;
  else
    return (rgb->g > rgb->b) ? rgb->g : rgb->b;
}

gdouble
gimp_rgb_min (const GimpRGB *rgb)
{
  //g_return_val_if_fail (rgb != NULL, 0.0);

  if (rgb->r < rgb->g)
    return (rgb->r < rgb->b) ? rgb->r : rgb->b;
  else
    return (rgb->g < rgb->b) ? rgb->g : rgb->b;
}

/*  GimpRGB functions  */


/**
 * gimp_rgb_to_hsv:
 * @rgb: A color value in the RGB colorspace
 * @hsv: (out caller-allocates): The value converted to the HSV colorspace
 *
 * Does a conversion from RGB to HSV (Hue, Saturation,
 * Value) colorspace.
 **/
void
gimp_rgb_to_hsv (const GimpRGB *rgb,
                 GimpHSV       *hsv)
{
  gdouble max, min, delta;

  //g_return_if_fail (rgb != NULL);
  //g_return_if_fail (hsv != NULL);

  max = gimp_rgb_max (rgb);
  min = gimp_rgb_min (rgb);

  hsv->v = max;
  delta = max - min;

  if (delta > 0.0001)
    {
      hsv->s = delta / max;

      if (rgb->r == max)
        {
          hsv->h = (rgb->g - rgb->b) / delta;
          if (hsv->h < 0.0)
            hsv->h += 6.0;
        }
      else if (rgb->g == max)
        {
          hsv->h = 2.0 + (rgb->b - rgb->r) / delta;
        }
      else
        {
          hsv->h = 4.0 + (rgb->r - rgb->g) / delta;
        }

      hsv->h /= 6.0;
    }
  else
    {
      hsv->s = 0.0;
      hsv->h = 0.0;
    }

  hsv->a = rgb->a;
}

/**
 * gimp_hsv_to_rgb:
 * @hsv: A color value in the HSV colorspace
 * @rgb: (out caller-allocates): The returned RGB value.
 *
 * Converts a color value from HSV to RGB colorspace
 **/
void
gimp_hsv_to_rgb (const GimpHSV *hsv,
                 GimpRGB       *rgb)
{
  int    i;
  gdouble f, w, q, t;

  gdouble hue;

  //g_return_if_fail (rgb != NULL);
  //g_return_if_fail (hsv != NULL);

  if (hsv->s == 0.0)
    {
      rgb->r = hsv->v;
      rgb->g = hsv->v;
      rgb->b = hsv->v;
    }
  else
    {
      hue = hsv->h;

      if (hue == 1.0)
        hue = 0.0;

      hue *= 6.0;

      i = (int) hue;
      f = hue - i;
      w = hsv->v * (1.0 - hsv->s);
      q = hsv->v * (1.0 - (hsv->s * f));
      t = hsv->v * (1.0 - (hsv->s * (1.0 - f)));

      switch (i)
        {
        case 0:
          rgb->r = hsv->v;
          rgb->g = t;
          rgb->b = w;
          break;
        case 1:
          rgb->r = q;
          rgb->g = hsv->v;
          rgb->b = w;
          break;
        case 2:
          rgb->r = w;
          rgb->g = hsv->v;
          rgb->b = t;
          break;
        case 3:
          rgb->r = w;
          rgb->g = q;
          rgb->b = hsv->v;
          break;
        case 4:
          rgb->r = t;
          rgb->g = w;
          rgb->b = hsv->v;
          break;
        case 5:
          rgb->r = hsv->v;
          rgb->g = w;
          rgb->b = q;
          break;
        }
    }

  rgb->a = hsv->a;
}


/**
 * gimp_rgb_to_hsl:
 * @rgb: A color value in the RGB colorspace
 * @hsl: (out caller-allocates): The value converted to HSL
 *
 * Convert an RGB color value to a HSL (Hue, Saturation, Lightness)
 * color value.
 **/
void
gimp_rgb_to_hsl (const GimpRGB *rgb,
                 GimpHSL       *hsl)
{
  gdouble max, min, delta;

 // g_return_if_fail (rgb != NULL);
  //g_return_if_fail (hsl != NULL);

  max = gimp_rgb_max (rgb);
  min = gimp_rgb_min (rgb);

  hsl->l = (max + min) / 2.0;

  if (max == min)
    {
      hsl->s = 0.0;
      hsl->h = GIMP_HSL_UNDEFINED;
    }
  else
    {
      if (hsl->l <= 0.5)
        hsl->s = (max - min) / (max + min);
      else
        hsl->s = (max - min) / (2.0 - max - min);

      delta = max - min;

      if (delta == 0.0)
        delta = 1.0;

      if (rgb->r == max)
        {
          hsl->h = (rgb->g - rgb->b) / delta;
        }
      else if (rgb->g == max)
        {
          hsl->h = 2.0 + (rgb->b - rgb->r) / delta;
        }
      else
        {
          hsl->h = 4.0 + (rgb->r - rgb->g) / delta;
        }

      hsl->h /= 6.0;

      if (hsl->h < 0.0)
        hsl->h += 1.0;
    }

  hsl->a = rgb->a;
}

static inline gdouble
gimp_hsl_value (gdouble n1,
                gdouble n2,
                gdouble hue)
{
  gdouble val;

  if (hue > 6.0)
    hue -= 6.0;
  else if (hue < 0.0)
    hue += 6.0;

  if (hue < 1.0)
    val = n1 + (n2 - n1) * hue;
  else if (hue < 3.0)
    val = n2;
  else if (hue < 4.0)
    val = n1 + (n2 - n1) * (4.0 - hue);
  else
    val = n1;

  return val;
}


/**
 * gimp_hsl_to_rgb:
 * @hsl: A color value in the HSL colorspace
 * @rgb: (out caller-allocates): The value converted to a value
 *       in the RGB colorspace
 *
 * Convert a HSL color value to an RGB color value.
 **/
void
gimp_hsl_to_rgb (const GimpHSL *hsl,
                 GimpRGB       *rgb)
{
  //g_return_if_fail (hsl != NULL);
  //g_return_if_fail (rgb != NULL);

  if (hsl->s == 0)
    {
      /*  achromatic case  */
      rgb->r = hsl->l;
      rgb->g = hsl->l;
      rgb->b = hsl->l;
    }
  else
    {
      gdouble m1, m2;

      if (hsl->l <= 0.5)
        m2 = hsl->l * (1.0 + hsl->s);
      else
        m2 = hsl->l + hsl->s - hsl->l * hsl->s;

      m1 = 2.0 * hsl->l - m2;

      rgb->r = gimp_hsl_value (m1, m2, hsl->h * 6.0 + 2.0);
      rgb->g = gimp_hsl_value (m1, m2, hsl->h * 6.0);
      rgb->b = gimp_hsl_value (m1, m2, hsl->h * 6.0 - 2.0);
    }

  rgb->a = hsl->a;
}


static inline gfloat
gimp_operation_color_balance_map (gfloat  value,
                                  gdouble lightness,
                                  gdouble shadows,
                                  gdouble midtones,
                                  gdouble highlights)
{
  /* Apply masks to the corrections for shadows, midtones and
   * highlights so that each correction affects only one range.
   * Those masks look like this:
   *     ‾\___
   *     _/‾\_
   *     ___/‾
   * with ramps of width a at x = b and x = 1 - b.
   *
   * The sum of these masks equals 1 for x in 0..1, so applying the
   * same correction in the shadows and in the midtones is equivalent
   * to applying this correction on a virtual shadows_and_midtones
   * range.
   */
  static const gdouble a = 0.25, b = 0.333, scale = 0.7;

  shadows    *= CLAMP ((lightness - b) / -a + 0.5, 0, 1) * scale;
  midtones   *= CLAMP ((lightness - b) /  a + 0.5, 0, 1) *
                CLAMP ((lightness + b - 1) / -a + 0.5, 0, 1) * scale;
  highlights *= CLAMP ((lightness + b - 1) /  a + 0.5, 0, 1) * scale;

  value += shadows;
  value += midtones;
  value += highlights;
  value = CLAMP (value, 0.0, 1.0);

  return value;
}

#define GIMP_TRANSFER_SHADOWS  0
#define GIMP_TRANSFER_MIDTONES  1
#define GIMP_TRANSFER_HIGHLIGHTS 2
#define RED 0
#define GREEN 1
#define BLUE 2
#define ALPHA 3

static bool
gimp_operation_color_balance_process (
                                      unsigned char             *src,
                                      unsigned char            *dest,
                                      double config_cyan_red[3],
                                      double config_magenta_green[3],
                                      double config_yellow_blue[3],
                                      bool config_preserve_luminosity
                                      )
{

         gfloat r = src[RED]/255.0;
          gfloat g = src[GREEN]/255.0;
          gfloat b = src[BLUE]/255.0;
          gfloat r_n;
          gfloat g_n;
          gfloat b_n;

          GimpRGB rgb = { r, g, b};
          GimpHSL hsl;

          gimp_rgb_to_hsl (&rgb, &hsl);

          r_n = gimp_operation_color_balance_map (r, hsl.l,
                                                  config_cyan_red[GIMP_TRANSFER_SHADOWS],
                                                  config_cyan_red[GIMP_TRANSFER_MIDTONES],
                                                  config_cyan_red[GIMP_TRANSFER_HIGHLIGHTS]);

          g_n = gimp_operation_color_balance_map (g, hsl.l,
                                                  config_magenta_green[GIMP_TRANSFER_SHADOWS],
                                                  config_magenta_green[GIMP_TRANSFER_MIDTONES],
                                                  config_magenta_green[GIMP_TRANSFER_HIGHLIGHTS]);

          b_n = gimp_operation_color_balance_map (b, hsl.l,
                                                  config_yellow_blue[GIMP_TRANSFER_SHADOWS],
                                                  config_yellow_blue[GIMP_TRANSFER_MIDTONES],
                                                  config_yellow_blue[GIMP_TRANSFER_HIGHLIGHTS]);

          if (config_preserve_luminosity)
            {
              GimpHSL hsl2;

              rgb.r = r_n;
              rgb.g = g_n;
              rgb.b = b_n;
              gimp_rgb_to_hsl (&rgb, &hsl);

              rgb.r = r;
              rgb.g = g;
              rgb.b = b;
              gimp_rgb_to_hsl (&rgb, &hsl2);

              hsl.l = hsl2.l;

              gimp_hsl_to_rgb (&hsl, &rgb);

              r_n = rgb.r;
              g_n = rgb.g;
              b_n = rgb.b;
            }

          dest[RED]   = r_n*255.0;
          dest[GREEN] = g_n*255.0;
          dest[BLUE]  = b_n*255.0;
          dest[ALPHA] = src[ALPHA];


      return true;
}



static int getConfigValue(OfxImageEffectHandle  instance,
                   double config_cyan_red[3],
                   double config_magenta_green[3],
                   double config_yellow_blue[3],
                   bool *config_preserve_luminosity)
{
    OfxParamSetHandle paramSet;
    gEffectHost->getParamSet(instance, &paramSet);
    
    double dValue;
    OfxParamHandle rParam;
    
    gParamHost->paramGetHandle(paramSet, "Shadows-Cyarn-Red", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_cyan_red[0] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Shadows-Magenta-Green", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_magenta_green[0] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Shadows-Yellow-Blue", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_yellow_blue[0] = dValue/100.0;
    
    gParamHost->paramGetHandle(paramSet, "Midtones-Cyarn-Red", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_cyan_red[1] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Midtones-Magenta-Green", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_magenta_green[1] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Midtones-Yellow-Blue", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_yellow_blue[1] = dValue/100.0;
    
    gParamHost->paramGetHandle(paramSet, "Highlights-Cyarn-Red", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_cyan_red[2] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Highlights-Magenta-Green", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_magenta_green[2] = dValue/100.0;
    gParamHost->paramGetHandle(paramSet, "Highlights-Yellow-Blue", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &dValue);
    config_yellow_blue[2] = dValue/100.0;

    bool nValue;
    gParamHost->paramGetHandle(paramSet, "Preserve Luminosity", &rParam, 0);
    gParamHost->paramGetValue(rParam,  &nValue);
    
    *config_preserve_luminosity = nValue;
    
    return 0;
}


// pointers to various bits of the host
OfxHost               *gHost;
OfxImageEffectSuiteV1 *gEffectHost = 0;
OfxPropertySuiteV1    *gPropHost = 0;
OfxParameterSuiteV1   *gParamHost = 0;
OfxMemorySuiteV1      *gMemoryHost = 0;
OfxMultiThreadSuiteV1 *gThreadHost = 0;
OfxMessageSuiteV1     *gMessageSuite = 0;
OfxInteractSuiteV1    *gInteractHost = 0;


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

      double config_cyan_red[3];
      double config_magenta_green[3];
      double config_yellow_blue[3];
      bool config_preserve_luminosity;
      getConfigValue(instance,
                          config_cyan_red,
                          config_magenta_green,
                          config_yellow_blue,
                     &config_preserve_luminosity);
      
    // cast data pointers to 8 bit RGBA
    OfxRGBAColourB *src = (OfxRGBAColourB *) srcPtr;
    OfxRGBAColourB *dst = (OfxRGBAColourB *) dstPtr;

    // and do some inverting
    for(int y = renderWindow.y1; y < renderWindow.y2; y++) {
      if(gEffectHost->abort(instance)) break;

      OfxRGBAColourB *dstPix = pixelAddress(dst, dstRect, renderWindow.x1, y, dstRowBytes);

      for(int x = renderWindow.x1; x < renderWindow.x2; x++) {
        
        OfxRGBAColourB *srcPix = pixelAddress(src, srcRect, x, y, srcRowBytes);

        if(srcPix) {
            gimp_operation_color_balance_process((unsigned char *)srcPix, (unsigned char *)dstPix, config_cyan_red,
                                                 config_magenta_green,
                                                 config_yellow_blue,
                                                 config_preserve_luminosity);

        }
        else {
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

    defineDoubleParam(paramSet, "Shadows-Cyarn-Red", "Shadows-Cyarn-Red", "Shadows-Cyarn-Red",
            "Shadows-Cyarn-Red", 0.0, -100.0, 100.0);
    defineDoubleParam(paramSet, "Shadows-Magenta-Green", "Shadows-Magenta-Green", "Shadows-Magenta-Green",
            "Shadows-Magenta-Green", 0.0, -100.0, 100.0);
    defineDoubleParam(paramSet, "Shadows-Yellow-Blue", "Shadows-Yellow-Blue", "Shadows-Yellow-Blue",
            "Shadows-Yellow-Blue", 0.0, -100.0, 100.0);
    
    defineDoubleParam(paramSet, "Midtones-Cyarn-Red", "Midtones-Cyarn-Red", "Midtones-Cyarn-Red",
            "Midtones-Cyarn-Red", 0.0, -100.0, 100.0);
    defineDoubleParam(paramSet, "Midtones-Magenta-Green", "Midtones-Magenta-Green", "Midtones-Magenta-Green",
            "Midtones-Magenta-Green", 0.0, -100.0, 100.0);
    defineDoubleParam(paramSet, "Midtones-Yellow-Blue", "Midtones-Yellow-Blue", "Midtones-Yellow-Blue",
            "Midtones-Yellow-Blue", 0.0, -100.0, 100.0);
    
    defineDoubleParam(paramSet, "Highlights-Cyarn-Red", "Highlights-Cyarn-Red", "Highlights-Cyarn-Red",
            "Highlights-Cyarn-Red", 0.0, -100.0, 100.0);
    defineDoubleParam(paramSet, "Highlights-Magenta-Green", "Highlights-Magenta-Green", "Highlights-Magenta-Green",
            "Highlights-Magenta-Green", 0.0, -100.0, 100.0);
    defineDoubleParam(paramSet, "Highlights-Yellow-Blue", "Highlights-Yellow-Blue", "Highlights-Yellow-Blue",
            "Highlights-Yellow-Blue", 0.0, -100.0, 100.0);
    
    defineBoolParam(paramSet, "Preserve Luminosity", "Preserve Luminosity", "Preserve Luminosity",
                    "Preserve Luminosity", true);
    
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
static OfxPlugin basicPlugin = 
{       
  kOfxImageEffectPluginApi,
  1,
  "cn.co.effectmatrix.OfxColor",
  1,
  0,
  setHostFunc,
  pluginMain
};
   
extern OfxPlugin levelsPlugin;

// the two mandated functions
EXPORT OfxPlugin *
OfxGetPlugin(int nth)
{
    if(nth == 0)
        return &basicPlugin;
    else if(nth == 1)
        return &levelsPlugin;
  return 0;
}
 
EXPORT int
OfxGetNumberOfPlugins(void)
{       
  return 2;
}
