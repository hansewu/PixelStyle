#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  /Applications/CMake.app/Contents/bin/cmake -E cmake_symlink_library /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/Debug/libexpat.1.8.3.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/Debug/libexpat.1.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/Debug/libexpat.dylib
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  /Applications/CMake.app/Contents/bin/cmake -E cmake_symlink_library /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/Release/libexpat.1.8.3.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/Release/libexpat.1.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/Release/libexpat.dylib
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  /Applications/CMake.app/Contents/bin/cmake -E cmake_symlink_library /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/MinSizeRel/libexpat.1.8.3.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/MinSizeRel/libexpat.1.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/MinSizeRel/libexpat.dylib
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  /Applications/CMake.app/Contents/bin/cmake -E cmake_symlink_library /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/RelWithDebInfo/libexpat.1.8.3.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/RelWithDebInfo/libexpat.1.dylib /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/RelWithDebInfo/libexpat.dylib
fi

