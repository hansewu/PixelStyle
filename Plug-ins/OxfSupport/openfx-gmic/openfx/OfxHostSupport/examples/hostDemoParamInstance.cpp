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

namespace MyHost {

  //
  // MyIntegerInstance
  //

  MyIntegerInstance::MyIntegerInstance(MyEffectInstance* effect, 
                                       const std::string& name, 
                                       OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::IntegerInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      _value = properties.getIntProperty(kOfxParamPropDefault);
  }

  OfxStatus MyIntegerInstance::get(int&n)
  {
      n = _value;
    return kOfxStatOK;
  }

  OfxStatus MyIntegerInstance::get(OfxTime time, int&n)
  {
      n = _value;
    return kOfxStatOK;
  }

  OfxStatus MyIntegerInstance::set(int n)
  {
      _value = n;
    return kOfxStatOK;
  }

  OfxStatus MyIntegerInstance::set(OfxTime time, int n) {
      _value = n;
    return kOfxStatOK;
  }

  //
  // MyDoubleInstance
  //

  MyDoubleInstance::MyDoubleInstance(MyEffectInstance* effect, 
                                     const std::string& name, 
                                     OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::DoubleInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      _value = properties.getDoubleProperty(kOfxParamPropDefault);
  }

  OfxStatus MyDoubleInstance::get(double& d)
  {
    // values for the Basic OFX plugin to work
    d = _value;
    return kOfxStatOK;
  }

  OfxStatus MyDoubleInstance::get(OfxTime time, double& d)
  {
    // values for the Basic OFX plugin to work
    d = _value;
    return kOfxStatOK;
  }

  OfxStatus MyDoubleInstance::set(double d)
  {
      _value = d;
    return kOfxStatOK;
  }

  OfxStatus MyDoubleInstance::set(OfxTime time, double d)
  {
      _value = d;
    return kOfxStatOK;
  }

  OfxStatus MyDoubleInstance::derive(OfxTime time, double&d)
  {
    return kOfxStatErrMissingHostFeature;
  }

  OfxStatus MyDoubleInstance::integrate(OfxTime time1, OfxTime time2, double&)
  {
    return kOfxStatErrMissingHostFeature;
  }

  //
  // MyBooleanInstance
  //

  MyBooleanInstance::MyBooleanInstance(MyEffectInstance* effect, 
                                       const std::string& name, 
                                       OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::BooleanInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      int defaultV = properties.getIntProperty(kOfxParamPropDefault);
      if(defaultV) _value = true;
      else _value = false;
  }

  OfxStatus MyBooleanInstance::get(bool& b)
  {
    b = _value;
    return kOfxStatOK;
  }

  OfxStatus MyBooleanInstance::get(OfxTime time, bool& b)
  {
      b = _value;
    return kOfxStatOK;
  }

  OfxStatus MyBooleanInstance::set(bool b)
  {
      _value = b;
    return kOfxStatOK;
  }

  OfxStatus MyBooleanInstance::set(OfxTime time, bool b) {
      _value = b;
    return kOfxStatOK;
  }

  //
  // MyChoiceInteger
  //

  MyChoiceInstance::MyChoiceInstance(MyEffectInstance* effect, 
                                     const std::string& name, 
                                     OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::ChoiceInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      _value = properties.getIntProperty(kOfxParamPropDefault);
  }

  OfxStatus MyChoiceInstance::get(int&n)
{
    n = _value;
    return kOfxStatOK;
  }

  OfxStatus MyChoiceInstance::get(OfxTime time, int&n)
  {
      n = _value;
    return kOfxStatOK;
  }

  OfxStatus MyChoiceInstance::set(int n)
  {
      _value = n;
    return kOfxStatOK;
  }

  OfxStatus MyChoiceInstance::set(OfxTime time, int n)
  {
      _value = n;
    return kOfxStatOK;
  }

  //
  // MyRGBAInstance
  //

  MyRGBAInstance::MyRGBAInstance(MyEffectInstance* effect, 
                                 const std::string& name, 
                                 OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::RGBAInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      properties.getDoublePropertyN(kOfxParamPropDefault, _values, 4);
  }

  OfxStatus MyRGBAInstance::get(double&d1,double&d2,double&d3,double&d4)
  {
      d1 = _values[0];
      d2 = _values[1];
      d3 = _values[2];
      d4 = _values[3];
    return kOfxStatOK;
  }

  OfxStatus MyRGBAInstance::get(OfxTime time, double&d1,double&d2,double&d3,double&d4)
  {
      d1 = _values[0];
      d2 = _values[1];
      d3 = _values[2];
      d4 = _values[3];
    return kOfxStatOK;
  }

  OfxStatus MyRGBAInstance::set(double d1,double d2,double d3,double d4)
  {
      _values[0] =  d1;
      _values[1] =  d2;
      _values[2] =  d3;
      _values[3] =  d4;
    return kOfxStatOK;
  }

  OfxStatus MyRGBAInstance::set(OfxTime time, double d1,double d2,double d3,double d4)
  {
      _values[0] =  d1;
      _values[1] =  d2;
      _values[2] =  d3;
      _values[3] =  d4;
    return kOfxStatOK;
  }

  //
  // MyRGBInstance
  //

  MyRGBInstance::MyRGBInstance(MyEffectInstance* effect, 
                               const std::string& name, 
                               OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::RGBInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      properties.getDoublePropertyN(kOfxParamPropDefault, _values, 3);
  }

  OfxStatus MyRGBInstance::get(double&d1,double&d2,double&d3)
  {
      d1 = _values[0];
      d2 = _values[1];
      d3 = _values[2];
    return kOfxStatOK;
  }

  OfxStatus MyRGBInstance::get(OfxTime time, double&d1,double&d2,double&d3)
  {
      d1 = _values[0];
      d2 = _values[1];
      d3 = _values[2];
    return kOfxStatOK;
  }

  OfxStatus MyRGBInstance::set(double d1,double d2,double d3)
  {
      _values[0] =  d1;
      _values[1] =  d2;
      _values[2] =  d3;
    return kOfxStatOK;
  }

  OfxStatus MyRGBInstance::set(OfxTime time, double d1,double d2,double d3)
  {
      _values[0] =  d1;
      _values[1] =  d2;
      _values[2] =  d3;
    return kOfxStatOK;
  }

  //
  // MyDouble2DInstance
  //

  MyDouble2DInstance::MyDouble2DInstance(MyEffectInstance* effect, 
                                         const std::string& name, 
                                         OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::Double2DInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      properties.getDoublePropertyN(kOfxParamPropDefault, _values, 2);
  }

  OfxStatus MyDouble2DInstance::get(double&d1,double&d2)
  {
      d1 = _values[0];
      d2 = _values[1];
    return kOfxStatOK;
  }

  OfxStatus MyDouble2DInstance::get(OfxTime time,double&d1,double&d2)
  {
      d1 = _values[0];
      d2 = _values[1];
    return kOfxStatOK;
  }

  OfxStatus MyDouble2DInstance::set(double d1,double d2)
  {
      _values[0] =  d1;
      _values[1] =  d2;
    return kOfxStatOK;
  }

  OfxStatus MyDouble2DInstance::set(OfxTime time,double d1,double d2)
  {
      _values[0] =  d1;
      _values[1] =  d2;
    return kOfxStatOK;
  }

  //
  // MyInteger2DInstance
  //

  MyInteger2DInstance::MyInteger2DInstance(MyEffectInstance* effect, 
                                           const std::string& name, 
                                           OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::Integer2DInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
      const OFX::Host::Property::Set &properties = descriptor.getProperties();
      properties.getIntPropertyN(kOfxParamPropDefault, _values, 2);
  }

  OfxStatus MyInteger2DInstance::get(int&n1,int&n2)
  {
      n1 = _values[0];
      n2 = _values[1];
    return kOfxStatOK;
  }

  OfxStatus MyInteger2DInstance::get(OfxTime time,int&n1,int&n2)
  {
      n1 = _values[0];
      n2 = _values[1];
    return kOfxStatOK;
  }

  OfxStatus MyInteger2DInstance::set(int n1,int n2)
  {
      _values[0] = n1;
      _values[1] = n2;
    return kOfxStatOK;
  }

  OfxStatus MyInteger2DInstance::set(OfxTime time,int n1,int n2)
  {
      _values[0] = n1;
      _values[1] = n2;
    return kOfxStatOK;
  }

  //
  // MyInteger2DInstance
  //

  MyPushbuttonInstance::MyPushbuttonInstance(MyEffectInstance* effect, 
                                             const std::string& name, 
                                             OFX::Host::Param::Descriptor& descriptor)
    : OFX::Host::Param::PushbuttonInstance(descriptor), _effect(effect), _descriptor(descriptor)
  {
  }

MyStringInstance::MyStringInstance(MyEffectInstance* effect,  const std::string& name, OFX::Host::Param::Descriptor& descriptor)
   : OFX::Host::Param::StringInstance(descriptor), _effect(effect), _descriptor(descriptor)
   {
       const OFX::Host::Property::Set &properties = descriptor.getProperties();
       _strValue = properties.getStringProperty(kOfxParamPropDefault);
   }
   OfxStatus MyStringInstance::get(std::string &str){
       str = _strValue;
       return kOfxStatOK;
     }
    OfxStatus MyStringInstance::get(OfxTime time, std::string &str){
        str = _strValue;
        return kOfxStatOK;
      }
    OfxStatus MyStringInstance::set(const char*cstr){
        _strValue = std::string(cstr);
        return kOfxStatOK;
      }
    OfxStatus MyStringInstance::set(OfxTime time, const char*cstr){
        _strValue = std::string(cstr);
        return kOfxStatOK;
      }

 MyCustomInstance::MyCustomInstance(MyEffectInstance* effect,  const std::string& name, OFX::Host::Param::Descriptor& descriptor)
    : MyStringInstance(effect, name, descriptor)
    {
    }
/*
    OfxStatus MyCustomInstance::get(std::string &){
        return kOfxStatErrMissingHostFeature;
      }
     OfxStatus MyCustomInstance::get(OfxTime time, std::string &){
         return kOfxStatErrMissingHostFeature;
       }
     OfxStatus MyCustomInstance::set(const char*){
         return kOfxStatErrMissingHostFeature;
       }
     OfxStatus MyCustomInstance::set(OfxTime time, const char*){
         return kOfxStatErrMissingHostFeature;
       }
*/

}
