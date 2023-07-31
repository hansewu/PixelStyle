/*
Software License :

Copyright (c) 2007, The Open Effects Association Ltd. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
   * Neither the name The Open Effects Association Ltd, nor the names of its 
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.
   
   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
   ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
   ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


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
   
////////////////////////////////////////////////////////////////////////////////
// This example code can only work with the example 'invert' plugin built
// with the OFX C++ support library. With some programming you may be able to
// get it to work with another plug-in.
//
//
// It's job is purely to show you what functions you need to fill in to provide
// an OFX image effect plugin host. It is (as we say in England) a 'noddy' example.
// 
// Run this in a debugger and step through to see what it does. Also be sure to
// build the invert example and set OFX_PLUGIN_PATH so that it can see it.
//
// It works by hard coding progressive PAL SD imagery to input and output clips,
// the images are black going in (and should be white coming out of the plugin).
//
// There is no file io to work with this.

// Convenience wrapper to get private data
/*
static MyClipInstance* getMyClipInstance(MyEffectInstance *handle)
{
 OfxImageEffectHandle effect = (OfxImageEffectHandle)handle;
    // get the property handle for the plugin
    OfxPropertySetHandle effectProps;
    gEffectHost->getPropertySet(effect, &effectProps);

    // get my data pointer out of that
    MyInstanceData* myData = NULL;
    gPropHost->propGetPointer(effectProps, kOfxPropInstanceData, 0, (void **)&myData);
    
    MyClipInstance *clipInstance = reinterpret_cast<MyClipInstance*>(myData->output);
    return myData;
}
*/



void exportToPPM(const std::string& fname, MyHost::MyImage* im)
{
  std::ofstream op(fname.c_str());
  OfxRectI rod = im->getROD();
  op << "P3" << "\t# FORMAT" << std::endl;
  op << rod.x2 - rod.x1 << "\t#WIDTH" << std::endl;
  op << rod.y2 - rod.y1 << "\t#HEIGHT" <<std::endl;
  //This assumes 8-bit.
  op << "255" << std::endl;
  for (int y = rod.y1; y< rod.y2; ++y)
  {
    for (int x = rod.x1; x < rod.x2; ++x)
    {
      OfxRGBAColourB* pix = im->pixel(x,y);
      if(pix)
        op << (int)pix->r << " " << (int)pix->g << " " << (int)pix->b << " " << std::endl;
      else
        op << "0 0 0" << std::endl;
    }
  }
}

typedef void * OFX_HOST_HANDLE;
typedef void * HOST_FILTERS_MANAGER;
HOST_FILTERS_MANAGER oxfInit(const std::string &pluginPath);
int getPluginsCount(HOST_FILTERS_MANAGER hostFilters);
int getPluginInfo(HOST_FILTERS_MANAGER hostFilters, int nIndex, std::string &outPluginLabel, std::string &outPluginIdentifier);

//typedef void * OFX_HOST_HANDLE;
OFX_HOST_HANDLE oxfHostLoad(HOST_FILTERS_MANAGER hostFilters, const std::string &pluginIdentifier);
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
int test()
{
    HOST_FILTERS_MANAGER hFilters = oxfInit(std::string("/Volumes/osx1013/Users/Shared/project/2023/PixelStyle/Plug-ins/OxfSupport/openfx-gmic/GMIC_OFX/release"));
    
    OFX_HOST_HANDLE effectIn = oxfHostLoad(hFilters, "eu.gmic.Ripple");
    int nParamCount = oxfHostGetParamsCount(effectIn);
    for(int i=0; i< nParamCount; i++)
    {
        std::string outParaName, outParaType;
        int nDim = oxfHostGetParamInfo(effectIn, i, outParaName, outParaType);
        printf("outParaName = %s, outParaType = %s, nDim = %d\n", outParaName.c_str(), outParaType.c_str(), nDim);
        for(int j=0; j< nDim; j++)
        {
            printf("dim = %d\n", j);
            
            std::string outParaDefault, outParaMax, outParaMin;
            std::vector<std::string> choise;
            oxfHostGetParamDefaultInfo(effectIn, i, j, outParaDefault, outParaMax, outParaMin, &choise);
            
            printf("outParaDefault = %s, outParaMax = %s, outParaMin = %s\n", outParaDefault.c_str(), outParaMax.c_str(), outParaMin.c_str());
            
            for(int k = 0; k< choise.size(); k++)
                printf("choise = %s", choise[k].c_str());
            
            printf("\n");
        }
    }
    return 0;
}
int main(int argc, char **argv) 
{
    test();
  //_CrtSetBreakAlloc(3168);
#ifdef _WIN32
  _CrtSetDbgFlag ( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
#endif
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
  std::ifstream ifs("hostDemoPluginCache.xml");
  try {
    OFX::Host::PluginCache::getPluginCache()->readCache(ifs);
  } catch (const std::exception &e) {
    std::cerr << "Error while reading XML cache: " << e.what() << std::endl;
  }
    OFX::Host::PluginCache::getPluginCache()->addFileToPath("/Users/apple/Library/Developer/Xcode/DerivedData/HostSupport-fqanezsqoesezlfisjqyirptjlkx/Build/Products/Debug", false);
  OFX::Host::PluginCache::getPluginCache()->scanPluginFiles();
  ifs.close();

  /// flush out the current cache
  std::ofstream of("hostDemoPluginCache.xml");
  OFX::Host::PluginCache::getPluginCache()->writePluginCache(of);
  of.close();

  // get the invert example plugin which uses the OFX C++ support code
    OFX::Host::ImageEffect::ImageEffectPlugin* plugin = imageEffectPluginCache.getPluginById("eu.gmic.GradientRGB");//uk.co.thefoundry.OfxInvertExample");//eu.gmic.AddGrain");//com.blackmagicdesign.ResolveSimpleGainOpenCLPlugin");//");//net.sf.openfx:invertPlugin");

  imageEffectPluginCache.dumpToStdOut();

  if(plugin) {
    // create an instance of it as a filter
    // the first arg is the context, the second is client data we are allowed to pass down the call chain

    OFX::Host::auto_ptr<OFX::Host::ImageEffect::Instance> instance(plugin->createInstance(kOfxImageEffectContextFilter, NULL));

    if(instance.get())
    {
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
      
      // current render scale of 1
      OfxPointD renderScale;
      renderScale.x = renderScale.y = 1.0;

      // The render window is in pixel coordinates
      // ie: render scale and a PAR of not 1
      OfxRectI  renderWindow;
      renderWindow.x1 = renderWindow.y1 = 0;
      renderWindow.x2 = 720;
      renderWindow.y2 = 576;

      /// RoI is in canonical coords, 
      OfxRectD  regionOfInterest;
      regionOfInterest.x1 = regionOfInterest.y1 = 0;
      regionOfInterest.x2 = renderWindow.x2 * instance->getProjectPixelAspectRatio();
      regionOfInterest.y2 = 576;
      
      int numFramesToRender = OFXHOSTDEMOCLIPLENGTH;

      // say we are about to render a bunch of frames 
      stat = instance->beginRenderAction(0, numFramesToRender, 1.0, false, renderScale, /*sequential=*/true, /*interactive=*/false,
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

      for(int t = 0; t <= numFramesToRender; ++t) 
      {
        // call get region of interest on each of the inputs
        OfxTime frame = t;

        // get the RoI for each input clip
        // the regions of interest for each input clip are returned in a std::map
        // on a real host, these will be the regions of each input clip that the
        // effect needs to render a given frame (clipped to the RoD).
        //
        // In our example we are doing full frame fetches regardless.
        std::map<OFX::Host::ImageEffect::ClipInstance *, OfxRectD> rois;
        stat = instance->getRegionOfInterestAction(frame, renderScale,
#ifdef OFX_EXTENSIONS_NUKE
                                                   /*view=*/0,
#endif
                                                   regionOfInterest, rois);
        assert(stat == kOfxStatOK || stat == kOfxStatReplyDefault);

#if defined(OFX_EXTENSIONS_VEGAS) || defined(OFX_EXTENSIONS_NUKE)
        // render a stereoscopic frame
        { // left view
          stat = instance->renderAction(t,kOfxImageFieldBoth,renderWindow, renderScale, /*sequential=*/true, /*interactive=*/false,
#                                        ifdef OFX_SUPPORTS_OPENGLRENDER
                                        /*openGLRender=*/false,
#                                        ifdef OFX_EXTENSIONS_NATRON
                                        /*contextData=*/NULL,
#                                        endif
#                                        endif
                                        /*draft=*/false,
                                        0 /*view*/
#                                       ifdef OFX_EXTENSIONS_VEGAS
                                        , 2 /*nViews*/
#                                       endif
#                                       ifdef OFX_EXTENSIONS_NUKE
                                        , std::list<std::string>() /*planes*/
#                                       endif
                                        );
          assert(stat == kOfxStatOK);

          // get the output image buffer
          MyHost::MyImage *outputImage = outputClip->getOutputImage();
          assert(outputImage);

          std::ostringstream ss;
          ss << "Output." << t << "l.ppm";
          exportToPPM(ss.str(), outputImage);
        }
        {  // right view
          instance->renderAction(t,kOfxImageFieldBoth,renderWindow, renderScale, /*sequential=*/true, /*interactive=*/false,
#                                ifdef OFX_SUPPORTS_OPENGLRENDER
                                 /*openGLRender=*/false,
#                                ifdef OFX_EXTENSIONS_NATRON
                                 /*contextData=*/NULL,
#                                endif
#                                endif
                                 /*draft=*/false,
                                 1 /*view*/
#                                ifdef OFX_EXTENSIONS_VEGAS
                                 , 2 /*nViews*/
#                                endif
#                                ifdef OFX_EXTENSIONS_NUKE
                                 , std::list<std::string>() /*planes*/
#                                endif
                                 );
          assert(stat == kOfxStatOK);

          // get the output image buffer
          MyHost::MyImage *outputImage = outputClip->getOutputImage();
          assert(outputImage);

          std::ostringstream ss;
          ss << "Output." << t << "r.ppm";
          exportToPPM(ss.str(), outputImage);
        }
#else
        // render a frame
#       ifdef OFX_EXTENSIONS_NUKE
          std::list<std::string> planes;
          planes.push_back(kOfxImagePlaneColour);
#       endif
          stat = instance->renderAction(t, //OfxTime      time,
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

        std::ostringstream ss;
        ss << "Output." << t << ".ppm";
        exportToPPM(ss.str(), outputImage);
#endif
      }

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
    }
  }
  OFX::Host::PluginCache::clearPluginCache();
  return 0;
}
