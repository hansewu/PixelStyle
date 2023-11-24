#include <string>
#include <vector>
#import "OfxSupportClass.h"


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

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define make_128(x) (x + 16 - (x % 16))

typedef struct
{
    char *filter_name;
    char *type;
    char *show_name;
}FILTER_INFO;

static FILTER_INFO s_enabledFilterId[] =
{
    {(char *)"eu.gmic.3DRandomObjects", (char *)"Generate",  (char *)"3D Random Objects"},
    {(char *)"eu.gmic.ArrayFaded",(char *)"Tile",  (char *)"Array Faded"},
    {(char *)"eu.gmic.ArrayMirrored",(char *)"Tile",  (char *)"Array Mirrored"},
    {(char *)"eu.gmic.ArrayRandom",(char *)"Tile",  (char *)"Array Random"},
    {(char *)"eu.gmic.ArrayRandomColors",(char *)"Tile",  (char *)"Array Random Colors"},
    {(char *)"eu.gmic.ArrayRegular",(char *)"Tile",  (char *)"Array Regular"},
  //  {(char *)"eu.gmic.BlackWhite",(char *)"Color Adjust",  (char *)"Black White"}, 暂时不要

   // (char *)"eu.gmic.BoostChromaticity", 暂时不要
    {(char *)"eu.gmic.Burn",(char *)"Artistic",  (char *)"Burn"},
    //(char *)"eu.gmic.Canvas",
    {(char *)"eu.gmic.Cartoon",(char *)"Artistic",  (char *)"Cartoon"},
    //{(char *)"eu.gmic.ChannelProcessing",(char *)"Generate",  (char *)""},
    {(char *)"eu.gmic.Charcoal",(char *)"Artistic",  (char *)"Charcoal"},
    {(char *)"eu.gmic.Chessboard",(char *)"Generate",  (char *)"Chessboard"},
    //{(char *)"eu.gmic.ChromaticAberrations",(char *)"Generate",  (char *)""},
    {(char *)"eu.gmic.CircleArt",(char *)"Generate",  (char *)"Circle Art"},
    {(char *)"eu.gmic.CircleTransform",(char *)"Distort",  (char *)"Circle Transform"},
    //(char *)"eu.gmic.ColorBlindess",(char *)"Generate",  (char *)""},
   // (char *)"eu.gmic.ColorizewithColormap",(char *)"Generate",  (char *)""},
    //(char *)"eu.gmic.Colormap",(char *)"Generate",  (char *)""},
    
 //   (char *)"eu.gmic.ColorPresets",
    {(char *)"eu.gmic.SelectReplaceColor",(char *)"Color Adjust",  (char *)"Replace Color"},
  //  (char *)"eu.gmic.ColorfulBlobs",
   // (char *)"eu.gmic.ChannelstoLayers",
  //  (char *)"eu.gmic.ColorBalance",
  //  (char *)"eu.gmic.ColorBlindness",
  //  (char *)"eu.gmic.Retinex",

    {(char *)"eu.gmic.LocalConstrast",(char *)"Enhance",  (char *)"Local Constrast"}, //color
        
    {(char *)"eu.gmic.HardSketch",(char *)"Artistic",  (char *)"Hard Sketch"},
    {(char *)"eu.gmic.Sketch",(char *)"Artistic",  (char *)"Sketch"},
    {(char *)"eu.gmic.VectorPainting",(char *)"Artistic",  (char *)"Vector Painting"},
    {(char *)"eu.gmic.Pencil", (char *)"Artistic",  (char *)"Pencil"},//4 slider
    {(char *)"eu.gmic.Edges",(char *)"Stylize",  (char *)"Edges"},
    {(char *)"eu.gmic.GradientRGB",(char *)"Stylize",  (char *)"Gradient Edges"},//3 slider 2 check

    {(char *)"eu.gmic.Ripple",(char *)"Distort",  (char *)"Ripple"},
    {(char *)"eu.gmic.Wind",(char *)"Blur",  (char *)"Wind"},
    {(char *)"eu.gmic.Wave",(char *)"Distort",  (char *)"Wave"},
   // (char *)"eu.gmic.Water",
   
   // {(char *)"eu.gmic.RainSnow",(char *)"Generate",  (char *)"RainSnow"},
   // (char *)"eu.gmic.DetailsEqualizer",出错
    //(char *)"eu.gmic.EqualizeLocalHistograms",//(slow)
  //  (char *)"eu.gmic.FreakyDetails",出错
    {(char *)"eu.gmic.LocalNormalization",(char *)"Enhance",  (char *)"Local Normalization"},
    {(char *)"eu.gmic.BlurAngular",(char *)"Blur",  (char *)"Blur Angular"},
    {(char *)"eu.gmic.BlurBloom",(char *)"Blur",  (char *)"Blur Bloom"},
    {(char *)"eu.gmic.BlurDepthofField",(char *)"Blur",  (char *)"Blur Depth of Field"},
    {(char *)"eu.gmic.BlurGlow",(char *)"Blur",  (char *)"Blur Glow"},
    {(char *)"eu.gmic.BlurLinear",(char *)"Blur",  (char *)"Blur Linear"},
    {(char *)"eu.gmic.BlurRadial",(char *)"Blur",  (char *)"Blur Radial"},
    //{(char *)"eu.gmic.BlurGaussian",(char *)"Generate",  (char *)""},
    
    {(char *)"cn.co.effectmatrix.OfxColor", (char *)"Color Adjust", (char *)"Color Balance"},
    {(char *)"cn.co.effectmatrix.levels", (char *)"Color Adjust", (char *)"Color Levels"},
};


@implementation OfxSupportClass
- (id)initWithManager:(PSPlugins *)manager
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *pluginPath = [bundle.builtInPlugInsPath stringByAppendingPathComponent:@"/ofx"];
    
    HOST_FILTERS_MANAGER hFilters = oxfInit(std::string(pluginPath.UTF8String));
    int count = getPluginsCount(hFilters);
    if(count <=0)  return nil;
    
    std::string PluginLabel, PluginIdentifier;
    
    _arrPlugins = [[NSMutableArray alloc] init];// autorelease];
    for(int i=0; i< count; i++)
    {
        int nret = getPluginInfo(hFilters, i, PluginLabel, PluginIdentifier);
        printf("Filter label = %s, id = %s\n", PluginLabel.c_str(), PluginIdentifier.c_str());
        for(int j=0; j< sizeof(s_enabledFilterId)/sizeof(FILTER_INFO); j++)
        {
            if(PluginIdentifier == std::string(s_enabledFilterId[j].filter_name))
            {
                OfxSupportClassItem *plugin = [[OfxSupportClassItem alloc] init];
                
                [plugin initWithManagerOxf:manager oxfHostHandle:hFilters
                    stringId:[NSString stringWithUTF8String:s_enabledFilterId[j].filter_name]
                    stringType:[NSString stringWithUTF8String:s_enabledFilterId[j].type]
                    stringName:[NSString stringWithUTF8String:s_enabledFilterId[j].show_name]
                ];
                [_arrPlugins addObject:plugin];
            }
        }
    }
    
    return self;
}

-(NSMutableArray *)getPlugins
{
    return _arrPlugins;
}
@end

@implementation OfxSupportClassItem

- (id)initWithManagerOxf:(PSPlugins *)manager oxfHostHandle:(void *)hostHandle stringId:(NSString *)strPluginId stringType:(NSString *)strPluginType  stringName:(NSString *)strPluginName
{
	seaPlugins = manager;
	//[NSBundle loadNibNamed:@"OxfPluginInfo" owner:self];
	newdata = NULL;
    _hostHandle = hostHandle;
    _strPluginId = [NSString stringWithString:strPluginId];
    [_strPluginId retain];
    _strPluginType = [NSString stringWithString:strPluginType];
    [_strPluginType retain];
    _strPluginName = [NSString stringWithString:strPluginName];
    [_strPluginName retain];
    
    _effectHandle = nil;
	
  //  [self constructParasUI];
	return self;
}

- (void) initFisrt
{
    if(_effectHandle == nil)
    {
        [NSBundle loadNibNamed:@"OxfPluginInfo" owner:self];
        newdata = NULL;
        [self constructParasUI];
    }
}

- (int)type
{
    if([_strPluginType isEqual:@"Color Adjust"])
        return 3;
    else return 0;
}

- (NSString *)name
{
    return _strPluginName;
   /* if([_strPluginId isEqualToString:@"cn.co.effectmatrix.OfxColor"])
        return @"Color Balance";
    else if([_strPluginId isEqualToString:@"cn.co.effectmatrix.levels"])
        return @"Color Levels";
    else
        return _strPluginId;//[gOurBundle localizedStringForKey:@"name" value:@"OfxSupport" table:NULL];*/
}

- (NSString *)groupName
{
    return _strPluginType;
    //if([_strPluginId isEqualToString:@"cn.co.effectmatrix.OfxColor"]
    //   || [_strPluginId isEqualToString:@"cn.co.effectmatrix.levels"])
    //    return @"Color Adjust";
    //else
    //    return @"OfxPlugins";//[gOurBundle localizedStringForKey:@"groupName" value:@"AI" table:NULL];
}

- (NSString *)sanity
{
	return @"PixelStyle Approved (Bobo)";
}

#define FILTER_TITLE_HEIGHT 25
#define FILTER_BUTTON_SIZE 16

#define FILTER_PARA_VOFFSET 10
#define FILTER_PARA_INOFFSET 5

#define FILTER_PARATITLE_HEIGHT 20
#define FILTER_PARATITLE_WIDTH 100

#define FILTER_PARAFIELD_HEIGHT 20
#define FILTER_PARAFIELD_WIDTH 70

#define FILTER_SLIDER_HEIGHT 20
#define FILTER_SLIDER_WIDTH 170
- (int)getFrameHeight
{
    if(!_effectHandle) return;
    
    int nParamCount = oxfHostGetParamsCount(_effectHandle);
    int height = 80;
    for(int i=0; i< nParamCount; i++)
    {
        std::string outParaName, outParaType;
        int nDim = oxfHostGetParamInfo(_effectHandle, i, outParaName, outParaType);
        
        if(outParaName == "Preview Type" || outParaName == "Advanced Options")  break;
        if(nDim < 0)  continue;
        if(nDim >1 && outParaType != "OfxParamTypeRGBA" && outParaType != "OfxParamTypeRGB"
           && outParaType != "OfxParamTypeDouble2D")  continue;
        
        if(outParaType == "OfxParamTypeDouble"|| outParaType == "OfxParamTypeInteger" || outParaType == "OfxParamTypeBoolean"|| outParaType == "OfxParamTypeChoice" || outParaType == "OfxParamTypeRGBA" || outParaType == "OfxParamTypeRGB")
        {
            height += FILTER_PARATITLE_HEIGHT;
            height += FILTER_SLIDER_HEIGHT;
        }
        
        if(outParaType == "OfxParamTypeDouble2D")
        {
               height += 2*FILTER_PARATITLE_HEIGHT;
               height += 2*FILTER_SLIDER_HEIGHT;
        }
    }
    
    return height;
}

- (void)sliderChanged:(id)sender
{
    NSSlider *slider = (NSSlider *)sender;
    int nIndex = [slider tag];
    
    std::string outParaName, outParaType;
    int nDim = oxfHostGetParamInfo(_effectHandle, nIndex&0xffff, outParaName, outParaType);
    if(nDim < 0)  return;
    double value = slider.doubleValue;
    char cStrValue[512];
    
    if(outParaType == "OfxParamTypeDouble" )//||(outParaType == "OfxParamTypeDouble2D" && outParaName == "center"))
    {
        snprintf(cStrValue, 512, "%.5f", value);
    }
    else if(outParaType == "OfxParamTypeDouble2D")
    {
        PluginData *pluginData = [(PSPlugins *)seaPlugins data];
        if(!(nIndex>>16))
        {
            snprintf(cStrValue, 512, "%.5f", value*[pluginData width]);
        }
        else
            snprintf(cStrValue, 512, "%.5f", value*[pluginData height]);
    }
    else if(outParaType == "OfxParamTypeInteger")
    {
        snprintf(cStrValue, 512, "%d", (int)value);
    }
    const std::string paraValue = std::string(cStrValue);
    oxfHostSetParamValue(_effectHandle, nIndex&0xffff, (nIndex>>16), paraValue);
    
    refresh = YES;
    [self preview:self];
}

- (void)checkChanged:(id)sender
{
    NSButton *btnCheck = (NSButton *)sender;
    int nIndex = [btnCheck tag];
    
    std::string outParaName, outParaType;
    int nDim = oxfHostGetParamInfo(_effectHandle, nIndex, outParaName, outParaType);
    if(nDim < 0)  return;
    
    int nState = btnCheck.state;
    char cStrValue[512];
    if(nState == 0)
    {
        snprintf(cStrValue, 512, "%d", nState);
    }
    else
    {
        strcpy(cStrValue, "1");
    }
    const std::string paraValue = std::string(cStrValue);
    oxfHostSetParamValue(_effectHandle, nIndex, 0, paraValue);
    
    refresh = YES;
    [self preview:self];
}

- (void)choiseChanged:(id)sender
{
    NSPopUpButton *btnPop = (NSButton *)sender;
    int nIndex = [btnPop tag];
    
    std::string outParaName, outParaType;
    int nDim = oxfHostGetParamInfo(_effectHandle, nIndex, outParaName, outParaType);
    if(nDim < 0)  return;
    
    int index =btnPop.indexOfSelectedItem;
    btnPop.title = btnPop.selectedItem.title;
    
    char cStrValue[512];
    snprintf(cStrValue, 512, "%d", index);

    const std::string paraValue = std::string(cStrValue);
    oxfHostSetParamValue(_effectHandle, nIndex, 0, paraValue);
    
    refresh = YES;
    [self preview:self];
}

- (void)colorChanged:(id)sender
{
    NSColorWell *colorWell = (NSColorWell *)sender;
    int nIndex = [colorWell tag];
    
    std::string outParaName, outParaType;
    int nDim = oxfHostGetParamInfo(_effectHandle, nIndex, outParaName, outParaType);
    if(nDim < 0)  return;
    
    NSColor *color = colorWell.color;
    for(int i=0; i<nDim; i++)
    {
        char cStrValue[512];
        switch(i)
        {
            case 0:                 snprintf(cStrValue, 512, "%f", color.redComponent);  break;
            case 1:                 snprintf(cStrValue, 512, "%f", color.greenComponent);  break;
            case 2:                 snprintf(cStrValue, 512, "%f", color.blueComponent);  break;
            case 3:                 snprintf(cStrValue, 512, "%f", color.alphaComponent);  break;
        }
    
        const std::string paraValue = std::string(cStrValue);
        oxfHostSetParamValue(_effectHandle, nIndex, i, paraValue);
    }
    
    refresh = YES;
    [self preview:self];
}

- (void)constructParasUI
{
    _contentView = nil;
    _effectHandle = oxfHostLoad(_hostHandle, std::string(_strPluginId.UTF8String));
    if(!_effectHandle) return;

    [_btShowOriginal sendActionOn: NSEventMaskLeftMouseDown];//
     
    int nParamCount = oxfHostGetParamsCount(_effectHandle);
    int ParaHeight = [self getFrameHeight];
    
    NSRect boundsRect = [panel  frame];
    NSView *pareatView = [panel contentView];
    NSScrollView *scrollView = nil;
    
    int viewHeight = boundsRect.size.height;
    if(ParaHeight > 600)
    {
        //ParaHeight -= 80;
         scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 50, (boundsRect.size.width -20), 600)];
        [scrollView autorelease];
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, boundsRect.size.width, ParaHeight)];
        scrollView.backgroundColor = [NSColor colorWithWhite:0.3 alpha:1];;
        [contentView autorelease];
        [scrollView setDocumentView:contentView];
        [scrollView setHasVerticalScroller:YES];
        
        [pareatView addSubview:scrollView];
        pareatView = contentView;
        boundsRect.size.height += 600;
        viewHeight = ParaHeight;
        [[scrollView contentView] scrollToPoint:NSMakePoint(0, ParaHeight-600)];
        //scrollView.documentVisibleRect.origin.y = ParaHeight-600;
        _contentView = pareatView;
        [_contentView retain];
    }
    else
    {
        boundsRect.size.height += ParaHeight;
        viewHeight = boundsRect.size.height;
        _contentView = [panel contentView];
    }
    
    int height = 80;
    for(int i=0; i< nParamCount; i++)
    {
        std::string outParaName, outParaType;
        int nDim = oxfHostGetParamInfo(_effectHandle, i, outParaName, outParaType);
        
        if(outParaName == "Preview Type" || outParaName == "Advanced Options")  break;

        if(nDim < 1) continue;
        if(nDim >1 && outParaType != "OfxParamTypeRGBA" && outParaType != "OfxParamTypeRGB"
           && outParaType != "OfxParamTypeDouble2D")  continue;
        
        if(outParaType == "OfxParamTypeDouble" || outParaType == "OfxParamTypeInteger" || outParaType == "OfxParamTypeBoolean" || outParaType == "OfxParamTypeChoice"|| outParaType == "OfxParamTypeRGBA" || outParaType == "OfxParamTypeRGB"
           || outParaType == "OfxParamTypeDouble2D")
        {
            for(int j=0; j< nDim; j++)
            {
                if(j>=1 && outParaType != "OfxParamTypeDouble2D")
                    continue;
                //printf("dim = %d\n", j);
                
                std::string outParaDefault, outParaMax, outParaMin;
                std::vector<std::string> choise;
                oxfHostGetParamDefaultInfo(_effectHandle, i, j, outParaDefault, outParaMax, outParaMin, &choise);
                
                
                NSTextField *titleField = [NSTextField labelWithString:[NSString stringWithUTF8String:outParaName.c_str()]];
                [titleField setFrame:NSMakeRect(10, viewHeight - height, FILTER_PARATITLE_WIDTH+20, FILTER_PARATITLE_HEIGHT)];
                //height += FILTER_PARATITLE_HEIGHT;

                titleField.textColor = [NSColor whiteColor];
                if([_strPluginId isEqualToString:@"cn.co.effectmatrix.OfxColor"])
                    titleField.font = [NSFont systemFontOfSize:8];
                else
                    titleField.font = [NSFont systemFontOfSize:10];
                [titleField setTag:-1];
                [pareatView addSubview:titleField];
                
                if(outParaType == "OfxParamTypeDouble" || outParaType == "OfxParamTypeInteger"
                   || outParaType == "OfxParamTypeDouble2D")
                {
                    double dValue       = atof(outParaDefault.c_str());
                    double dMaxValue    = atof(outParaMax.c_str());
                    double dMinValue    = atof(outParaMin.c_str());
                    NSSlider *slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(130, viewHeight - height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [slider setTag:(i|(j<<16))];
                    [slider setTarget:self];
                    [slider setAction:@selector(sliderChanged:)];
                    
                    height += 2*FILTER_SLIDER_HEIGHT;
                    if(outParaType == "OfxParamTypeDouble2D")
                    {
                        dMinValue = -1.0;
                        dMaxValue = 2.0;
                    }
                    else
                    {
                        if(dMaxValue > 10000.0)
                        {
                            dMaxValue = 10000.0;
                        }
                        if(dMinValue < -10000.0)
                        {
                            dMinValue = -10000.0;
                        }
                    }
                    [slider setMaxValue:dMaxValue];
                    [slider setMinValue:dMinValue];
                    slider.doubleValue = dValue;
                    [pareatView addSubview:slider];
                }
                else if(outParaType == "OfxParamTypeBoolean")
                {
                    //height -= FILTER_PARATITLE_HEIGHT;
                    NSButton *checkBtn = [[[NSButton alloc] initWithFrame:NSMakeRect(130, viewHeight - height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [checkBtn setButtonType:NSButtonTypeSwitch];
                    [checkBtn setTitle:@""];
                    if(outParaDefault == "0")
                        [checkBtn setState:0];
                    else [checkBtn setState:1];
                    
                    [checkBtn setTag:i];
                    [checkBtn setTarget:self];
                    [checkBtn setAction:@selector(checkChanged:)];
                    
                    height += 2*FILTER_PARATITLE_HEIGHT;
                    [pareatView addSubview:checkBtn];
                }
                else if(outParaType == "OfxParamTypeChoice")
                {
                    
                    NSPopUpButton *choiseCmb =  [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(130, viewHeight - height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT) pullsDown:NO] autorelease];
                    
                    for(int i=0; i< choise.size(); i++)
                    {
                        NSString *strItem = [NSString stringWithUTF8String:choise[i].c_str()];
                        [choiseCmb addItemWithTitle:strItem];
                    }
                    int nDefaultIndex = atoi(outParaDefault.c_str());
                    if(nDefaultIndex >= 0 && nDefaultIndex < choise.size())
                        choiseCmb.title = [NSString stringWithUTF8String:choise[atoi(outParaDefault.c_str())].c_str()];
                    
                    [choiseCmb setTag:i];
                    [choiseCmb setTarget:self];
                    [choiseCmb setAction:@selector(choiseChanged:)];
                    
                    height += 2*FILTER_PARATITLE_HEIGHT;
                    [pareatView addSubview:choiseCmb];
                }
                else if(outParaType == "OfxParamTypeRGBA" || outParaType == "OfxParamTypeRGB")
                {
                    NSColorWell* colorWell = [[[NSColorWell alloc] initWithFrame:NSMakeRect(130, viewHeight - height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [colorWell setTag:i];
                    [colorWell setTarget:self];
                    [colorWell setAction:@selector(colorChanged:)];
                    
                    height += 2*FILTER_PARATITLE_HEIGHT;
                    [pareatView addSubview:colorWell];
                    
                    double dcolor[4];
                    for(int k=0; k<nDim; k++)
                    {
                        oxfHostGetParamDefaultInfo(_effectHandle, i, k, outParaDefault, outParaMax, outParaMin, &choise);
                        dcolor[k] = atof(outParaDefault.c_str());
                    }
                    if(nDim <4) dcolor[3] = 255;
                    NSColor *nColor = [NSColor colorWithRed:dcolor[0] green:dcolor[1] blue:dcolor[2] alpha:dcolor[3]];
                    [colorWell setColor:nColor];
                }
                
            }
        }
    }
    
    [panel setTitle:[self name]];
    [panel setFrame:boundsRect display:YES];

}
- (void)run
{
    [self initFisrt];
	PluginData *pluginData;
    
    refresh = YES;
	success = NO;
    _needCalc = 0;
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self preview:self];
	[NSApp runModalForWindow:panel];
}

static dispatch_queue_t  s_queue;

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
    
    dispatch_barrier_sync(s_queue, ^{});
	if (refresh) [self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) { free(newdata); newdata = NULL; }
		
	//[gUserDefaults setInteger:radius forKey:@"OCBilaterClass.radius"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
    
    dispatch_barrier_sync(s_queue, ^{});
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
}

- (BOOL)canReapply
{
	return success;
}


- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
	if (refresh)
    {
        if(!s_queue)
        s_queue = dispatch_queue_create("com.effectmatrix.ofxprocess.queue", NULL);
        _needCalc++;
        if(_needCalc > 2)  _needCalc=2;
        else
            dispatch_async(s_queue,
                           ^{[self execute];
                            dispatch_async(dispatch_get_main_queue(),
                                ^{
                                    [pluginData preview];
                                    refresh = NO;
                                    _needCalc--;
            });});
    }
    else
    {
        [pluginData preview];
        refresh = NO;
    }
	
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
    
    dispatch_barrier_sync(s_queue, ^{});

    if (newdata) { free(newdata); newdata = NULL; }

}

- (NSView *)getSubView:(int)tagId
{
    for (NSView *view in _contentView.subviews)
    {
        if(tagId == view.tag)
            return view;
    }
    return nil;
}

- (IBAction)reset:(id)sender
{
    if(!_effectHandle) return;
     
    int nParamCount = oxfHostGetParamsCount(_effectHandle);
    for(int i=0; i< nParamCount; i++)
    {
        std::string outParaName, outParaType;
        int nDim = oxfHostGetParamInfo(_effectHandle, i, outParaName, outParaType);
        
        if(outParaName == "Preview Type" || outParaName == "Advanced Options")  break;

        if(nDim < 1)  continue;
        
        if(outParaType == "OfxParamTypeDouble" || outParaType == "OfxParamTypeInteger" || outParaType == "OfxParamTypeBoolean" || outParaType == "OfxParamTypeChoice"|| outParaType == "OfxParamTypeDouble2D" || outParaType == "OfxParamTypeRGBA" || outParaType == "OfxParamTypeRGB")
        {
            //for(int j=0; j< nDim; j++)
            {
                //printf("dim = %d\n", j);
                
                std::string outParaDefault, outParaMax, outParaMin;
                std::vector<std::string> choise;
                oxfHostGetParamDefaultInfo(_effectHandle, i, 0, outParaDefault, outParaMax, outParaMin, &choise);
                oxfHostSetParamValue(_effectHandle, i, 0, outParaDefault);
                
                if(outParaType == "OfxParamTypeDouble" || outParaType == "OfxParamTypeInteger")
                {
                    double dValue       = atof(outParaDefault.c_str());
                    NSSlider *slider = (NSSlider *)[self getSubView:i];
                    slider.doubleValue = dValue;
                }
                else if(outParaType == "OfxParamTypeDouble2D")
                {
                    double dValue       = atof(outParaDefault.c_str());
                    NSSlider *slider = (NSSlider *)[self getSubView:i];
                    slider.doubleValue = dValue;
                    oxfHostGetParamDefaultInfo(_effectHandle, i, 1, outParaDefault, outParaMax, outParaMin, &choise);
                    oxfHostSetParamValue(_effectHandle, i, 1, outParaDefault);
                    dValue       = atof(outParaDefault.c_str());
                    slider = (NSSlider *)[self getSubView:i|(1<<16)];
                    slider.doubleValue = dValue;
                }
                else if(outParaType == "OfxParamTypeBoolean")
                {
                    NSButton *checkBtn = (NSButton *)[self getSubView:i];
                    if(outParaDefault == "0")
                        [checkBtn setState:0];
                    else [checkBtn setState:1];
                }
                else if(outParaType == "OfxParamTypeChoice")
                {
                    
                    NSPopUpButton *choiseCmb =  (NSPopUpButton *)[self getSubView:i];

                    int nDefaultIndex = atoi(outParaDefault.c_str());
                    if(nDefaultIndex >= 0 && nDefaultIndex < choise.size())
                        choiseCmb.title = [NSString stringWithUTF8String:choise[atoi(outParaDefault.c_str())].c_str()];
                }
                else if(outParaType == "OfxParamTypeRGBA" || outParaType == "OfxParamTypeRGB")
                {
                    for(int k=0; k< nDim; k++)
                    {
                        oxfHostGetParamDefaultInfo(_effectHandle, i, k, outParaDefault, outParaMax, outParaMin, &choise);
                        oxfHostSetParamValue(_effectHandle, i, k, outParaDefault);
                    }
                }
                
            }
        }
    }
    refresh = YES;
    [self preview:self];
}

- (IBAction)showOriginal:(id)sender
{
    dispatch_barrier_sync(s_queue, ^{});
    static int flag = 0;
    PluginData *pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
    int width = [pluginData width];
    int height = [pluginData height];
    unsigned char *replace = [pluginData replace];
    unsigned char *overlay = [pluginData overlay];
    
    if(flag == 0)
    {
        [_btShowOriginal sendActionOn: NSEventMaskLeftMouseUp];//

        memset(replace, 0xFF, width * height);
        [pluginData setOverlayOpacity:0];
        [pluginData setOverlayBehaviour:kReplacingBehaviour];
        [pluginData preview];
        flag = 1;
    }
    else
    {
        [_btShowOriginal sendActionOn: NSEventMaskLeftMouseDown];
        memset(replace, 0xFF, width * height);
        [pluginData setOverlayOpacity:255];
        [pluginData setOverlayBehaviour:kReplacingBehaviour];
        [pluginData preview];
        flag = 0;

    }
    
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	radius = roundf([radiusSlider floatValue]);
		
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	refresh = YES;
	[self preview:self];
}

- (void)execute
{
	PluginData *pluginData;

	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	if ([pluginData spp] == 2)
    {
		[self executeGrey:pluginData];
	}
	else
    {
		[self executeColor:pluginData];
	}
}

- (void)executeGrey:(PluginData *)pluginData
{
	IntRect selection;
	int i, spp, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	int max;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
    
	data    = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	// Convert from GA to RGBA
	for (i = 0; i < width * height; i++)
    {
		newdata[i * 4]     = data[i * 2 ];
		newdata[i * 4 + 1] = data[i * 2];
		newdata[i * 4 + 2] = data[i * 2];
		newdata[i * 4 + 3] = data[i * 2 +1];
	}
	
	// Run CoreImage effect
	resdata = [self executeChannel:pluginData withBitmap:newdata];
	
	// Convert output to GA
//	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
//		max = selection.size.width * selection.size.height;
//	else
    max = width * height;
    
	for (i = 0; i < max; i++)
    {
		newdata[i * 2] = resdata[i * 4];
		newdata[i * 2 + 1] = resdata[i * 4 + 3];
	}
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
		for (i = 0; i < selection.size.height; i++)
        {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 2]), &(newdata[(width * (selection.origin.y + i) + selection.origin.x) * 2]), selection.size.width * 2);
		}
	}
	else
    {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, newdata, width * height * 2);
	}
    
    free(resdata);
}

- (void)executeColor:(PluginData *)pluginData
{
    
	IntRect selection;
	int i, width, height;
	unsigned char *data, *resdata, *overlay, *replace;

	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];

	data            = [pluginData data];
	overlay     = [pluginData overlay];
	replace     = [pluginData replace];
    memcpy(newdata, data, width * height*4);

	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
    @try {
        resdata = [self executeChannel:pluginData withBitmap:newdata];
    }
    @catch (NSException *exception) {

        NSLog([exception reason]);
        return;
    }
    
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
		//unpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	}else {
		//unpremultiplyBitmap(4, resdata, resdata, width * height);
	}

	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
		for (i = 0; i < selection.size.height; i++)
        {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]),          &(resdata[(width * (selection.origin.y + i) + selection.origin.x) * 4]),            selection.size.width * 4);
		}
	}
	else
    {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, resdata, width * height * 4);
	}
    
    free(resdata);
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
    unsigned char  *resdata = [self matting:pluginData withBitmap:data];
    return resdata;
  
}

- (unsigned char *)matting:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
    int nInputWidth = [pluginData width];
    int nInputHeight = [pluginData height];
    
    if(!_effectHandle)
       _effectHandle = oxfHostLoad(_hostHandle, std::string(_strPluginId.UTF8String));
    
    oxfHostSetImageFrame(_effectHandle, data, nInputWidth, nInputHeight);
    unsigned char  *resdata = (unsigned char *)malloc(nInputWidth*nInputHeight*4);
    
    oxfHostProcess(_effectHandle, resdata, nInputWidth, nInputHeight);
    
    return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
