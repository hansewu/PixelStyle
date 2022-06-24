#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  make -f /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  make -f /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  make -f /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode
  make -f /Volumes/D/wzq/2019/gmic-3.1.2/openfx-gmic-master/openfx/HostSupport/expat-2.4.3/xcode/CMakeScripts/ReRunCMake.make
fi

