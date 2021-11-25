#! /bin/bash 
echo abc
work_path=/Users/lchzh/Documents/testproject/testLoadCBundle/testLoadCBundle/GraphicsMagickImporter/GraphicsMagickImporter/GraphicsMagick/gm_resource/modules-Q8/coders
cd $work_path
for file in `ls *.so`
do
echo ./$file
install_name_tool -change /usr/local/lib/libGraphicsMagick.3.dylib @rpath/libGraphicsMagick.3.dylib ./$file
install_name_tool -change /usr/local/opt/little-cms2/lib/liblcms2.2.dylib @rpath/liblcms2.2.dylib ./$file
install_name_tool -change /usr/local/opt/libtool/lib/libltdl.7.dylib @rpath/libltdl.7.dylib ./$file
install_name_tool -change /usr/local/opt/ghostscript/lib/libgs.9.21.dylib @rpath/libgs.9.21.dylib ./$file
install_name_tool -change /usr/local/opt/jpeg/lib/libjpeg.8.dylib @rpath/libjpeg.8.dylib ./$file
install_name_tool -change /usr/local/opt/libpng/lib/libpng16.16.dylib @rpath/libpng16.16.dylib ./$file
install_name_tool -change /usr/local/opt/libtiff/lib/libtiff.5.dylib @rpath/libtiff.5.dylib ./$file
done
