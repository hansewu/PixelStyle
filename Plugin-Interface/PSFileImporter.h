//
//  PSFileImporter.hpp
//  PixelStyle
//
//  Created by lchzh on 6/6/17.
//
//

#ifndef PSFileImporter_hpp
#define PSFileImporter_hpp

#include <stdio.h>
#include "PluginCommon.h"

#ifdef __cplusplus
extern "C"
{
#endif
    
    int plugin_ImportImageToDocument(const char* filePath, void* document);  //导入图片
    char** plugin_GetAllSupportedTypes(int* count);
    
    int plugin_ExportBufferToFile(const char* filePath, void* document);
    char** plugin_exporter_GetAllSupportedTypes(int* count);
    
#ifdef __cplusplus
}
#endif

#endif /* PSFileImporter_hpp */
