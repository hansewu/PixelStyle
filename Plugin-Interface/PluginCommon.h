//
//  PluginCommon.h
//  GraphicsMagickImporter
//
//  Created by lchzh on 6/2/17.
//  Copyright © 2017 lchzh. All rights reserved.
//

#ifndef PluginCommon_h
#define PluginCommon_h

#include "ImporterGlobalDefine.h"


//host回调函数，向某层写入数据，doc多文档下方便区分，layerIndex -1新建层，暂时先不用
typedef int (*WriteBufferToLayerProc) (void* doc, int layerIndex, GM_IMAGE_BUFFER* buffer);
typedef int (*FreeImageBufferProc) (GM_IMAGE_BUFFER* imageBuffer);
typedef GM_IMAGE_BUFFER* (*MallocImageBufferProc) (int nImageWidth, int nImageHeight, int nChannel);
typedef int (*GetPluginPathProc) (char* path);
typedef int (*GetCachePathProc) (char* path);
typedef int (*GetDocumentLayerCount) (void* doc);
typedef GM_LAYER_INFO* (*GetDocumentLayerInfo) (void* doc, int layerIndex);

//host提供给插件的回调函数
typedef struct PS_HostProcs
{
    MallocImageBufferProc mallocBufferProc;
    FreeImageBufferProc freeBufferProc;
    WriteBufferToLayerProc writeProc;
    GetPluginPathProc getPluginPathProc;
    GetCachePathProc getCachePathProc;
} PS_HostProcs;



//判断是否支持type格式
typedef bool (*IsSupportFileTypeProc) (const char* type);
//获取支持的所有文件格式
typedef GM_FORMAT_INFO ** (*GetSupportFileTypeProc) (int *count);
//根据文件读取buffer信息，现在的都是传入文件路径，以后扩展的话，可能不会使用这个函数，由插件自己回调给host
typedef GM_IMAGE_BUFFER* (*GetFileBufferInfoProc)(char* filePath);

typedef int (*WriteBufferInfoToFileProc)(GM_IMAGE_BUFFER* bufferInfo, char* filePath);
typedef int (*WriteMultiLayerToFileProc)(char* filePath);

//支持的层类型（位图、矢量等）
typedef enum
{
    PS_LayerType_BITMAP, //Cocoalayer
    PS_LayerType_VECTOR, //SVGLayer
}PS_LayerType;
//获取指定文件对应的层类型
typedef PS_LayerType (*GETLayerTypeProc) (char* type);

//importer插件提供给host的函数
typedef struct PS_ImporterProcs
{
    IsSupportFileTypeProc isSupportProc;
    GetSupportFileTypeProc getSupportProc;
    GetFileBufferInfoProc getBufferProc;
} PS_ImporterProcs;

//exporter插件提供给host的函数
typedef struct PS_ExporterProcs
{
    IsSupportFileTypeProc isSupportProc;
    GetSupportFileTypeProc getSupportProc;
    WriteBufferInfoToFileProc writeBufferProc;
} PS_ExporterProcs;



//插件与host之间的主要通信信息，暂时主要是一些函数指针
typedef struct PS_AcquireParaInfo
{
    void* doc;
    char pluginPath[512];
    PS_HostProcs* hostProcs;
    PS_ImporterProcs *importerProcs;
    PS_ExporterProcs *exporterProcs;
}PS_AcquireParaInfo;


//入口函数参数，调用类型
typedef enum
{
    PS_SelectorType_About, //插件信息，暂未设计
    PS_SelectorType_Prepare, //初始化和准备,设置回调指针
    PS_SelectorType_Start,  //开始处理，暂不用
    PS_SelectorType_Continue, //继续处理，更新数据，暂不用
    PS_SelectorType_Finish, //处理完成,释放内存
}PS_SelectorType;

//插件入口主函数，必须实现
typedef void (*PluginMainEntryPro) (PS_SelectorType selectorType, PS_AcquireParaInfo *acquireParam, int *result);



#endif /* PluginCommon_h */
