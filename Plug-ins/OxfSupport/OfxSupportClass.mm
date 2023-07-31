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

static char *s_enabledFilterId[] =
{
    (char *)"eu.gmic.LocalConstrast", //color
    (char *)"eu.gmic.GradientRGB",//3 slider 2 check
    (char *)"eu.gmic.HardSketch",
    (char *)"eu.gmic.ColorBalance",
    (char *)"eu.gmic.ColorBlindness",
    (char *)"eu.gmic.Sketch",
    (char *)"eu.gmic.VectorPainting",
    (char *)"eu.gmic.Charcoal",
    (char *)"eu.gmic.Pencil", //4 slider
    (char *)"eu.gmic.Retinex",
    (char *)"eu.gmic.Edges",
    (char *)"eu.gmic.Ripple",
    (char *)"eu.gmic.Wind",
    (char *)"eu.gmic.Wave",
  //  (char *)"eu.gmic.Water",
    (char *)"eu.gmic.RainSnow",
  //  (char *)"eu.gmic.DetailsEqualizer",
    (char *)"eu.gmic.EqualizeLocalHistograms",//(slow)
  //  (char *)"eu.gmic.FreakyDetails",
    (char *)"eu.gmic.LocalNormalization",
    (char *)"eu.gmic.BlurAngular",
    (char *)"eu.gmic.BlurBloom",
    (char *)"eu.gmic.BlurDepthofField",
    (char *)"eu.gmic.BlurGlow",
    (char *)"eu.gmic.BlurLinear",
    (char *)"eu.gmic.BlurRadial",
    
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
    
    _arrPlugins = [[[NSMutableArray alloc] init] autorelease];
    for(int i=0; i< count; i++)
    {
        int nret = getPluginInfo(hFilters, i, PluginLabel, PluginIdentifier);
        printf("Filter label = %s, id = %s\n", PluginLabel.c_str(), PluginIdentifier.c_str());
        for(int j=0; j< sizeof(s_enabledFilterId)/sizeof(char *); j++)
        {
            if(PluginIdentifier == std::string(s_enabledFilterId[j]))
            {
                OfxSupportClassItem *plugin = [[OfxSupportClassItem alloc] init];
                
                [plugin initWithManagerOxf:manager oxfHostHandle:hFilters stringId:[NSString stringWithUTF8String:s_enabledFilterId[j]]];
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

- (id)initWithManagerOxf:(PSPlugins *)manager oxfHostHandle:(void *)hostHandle stringId:(NSString *)strPluginId
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"OxfPluginInfo" owner:self];
	newdata = NULL;
    _hostHandle = hostHandle;
    _strPluginId = strPluginId;
    _effectHandle = nil;
	
    [self constructParasUI];
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
    return _strPluginId;//[gOurBundle localizedStringForKey:@"name" value:@"OfxSupport" table:NULL];
}

- (NSString *)groupName
{
    return @"OfxPlugins";//[gOurBundle localizedStringForKey:@"groupName" value:@"AI" table:NULL];
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
        if(nDim != 1)  continue;;
        
        if(outParaType == "OfxParamTypeDouble"|| outParaType == "OfxParamTypeInteger" || outParaType == "OfxParamTypeBoolean") //OfxParamTypeChoice
        {
            height += FILTER_PARATITLE_HEIGHT;
            height += FILTER_SLIDER_HEIGHT;
        }

    }
    
    return height;
}

- (void)sliderChanged:(id)sender
{
    NSSlider *slider = (NSSlider *)sender;
    int nIndex = [slider tag];
    
    std::string outParaName, outParaType;
    int nDim = oxfHostGetParamInfo(_effectHandle, nIndex, outParaName, outParaType);
    if(nDim < 0)  return;
    double value = slider.doubleValue;
    char cStrValue[512];
    if(outParaType == "OfxParamTypeDouble")
    {
        sprintf(cStrValue, "%.5f", value);
    }
    else if(outParaType == "OfxParamTypeInteger")
    {
        sprintf(cStrValue, "%d", (int)value);
    }
    const std::string paraValue = std::string(cStrValue);
    oxfHostSetParamValue(_effectHandle, nIndex, 0, paraValue);
    
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
        sprintf(cStrValue, "%d", nState);
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

- (void)constructParasUI
{
    _effectHandle = oxfHostLoad(_hostHandle, std::string(_strPluginId.UTF8String));
    if(!_effectHandle) return;

    
    int nParamCount = oxfHostGetParamsCount(_effectHandle);
    int ParaHeight = [self getFrameHeight];
    
    NSRect boundsRect = [panel  frame];
    boundsRect.size.height += ParaHeight;
    
    int height = 80;
    for(int i=0; i< nParamCount; i++)
    {
        std::string outParaName, outParaType;
        int nDim = oxfHostGetParamInfo(_effectHandle, i, outParaName, outParaType);
        
        if(outParaName == "Preview Type" || outParaName == "Advanced Options")  break;

        if(nDim != 1)  continue;;
        
        if(outParaType == "OfxParamTypeDouble" || outParaType == "OfxParamTypeInteger" || outParaType == "OfxParamTypeBoolean")
        {
            //for(int j=0; j< nDim; j++)
            {
                //printf("dim = %d\n", j);
                
                std::string outParaDefault, outParaMax, outParaMin;
                std::vector<std::string> choise;
                oxfHostGetParamDefaultInfo(_effectHandle, i, 0, outParaDefault, outParaMax, outParaMin, &choise);
                
                
                NSTextField *titleField = [NSTextField labelWithString:[NSString stringWithUTF8String:outParaName.c_str()]];
                [titleField setFrame:NSMakeRect(10, boundsRect.size.height - height, FILTER_PARATITLE_WIDTH, FILTER_PARATITLE_HEIGHT)];
                //height += FILTER_PARATITLE_HEIGHT;

                titleField.textColor = [NSColor whiteColor];
                [[panel contentView] addSubview:titleField];
                
                if(outParaType == "OfxParamTypeDouble" || outParaType == "OfxParamTypeInteger")
                {
                    double dValue       = atof(outParaDefault.c_str());
                    double dMaxValue    = atof(outParaMax.c_str());
                    double dMinValue    = atof(outParaMin.c_str());
                    NSSlider *slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(130, boundsRect.size.height - height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [slider setTag:i];
                    [slider setTarget:self];
                    [slider setAction:@selector(sliderChanged:)];
                    
                    height += 2*FILTER_SLIDER_HEIGHT;
                    [slider setMaxValue:dMaxValue];
                    [slider setMinValue:dMinValue];
                    slider.doubleValue = dValue;
                    [[panel contentView] addSubview:slider];
                }
                else if(outParaType == "OfxParamTypeBoolean")
                {
                    //height -= FILTER_PARATITLE_HEIGHT;
                    NSButton *checkBtn = [[[NSButton alloc] initWithFrame:NSMakeRect(130, boundsRect.size.height - height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [checkBtn setButtonType:NSButtonTypeSwitch];
                    [checkBtn setTitle:@""];
                    if(outParaDefault == "0")
                        [checkBtn setState:0];
                    else [checkBtn setState:1];
                    
                    [checkBtn setTag:i];
                    [checkBtn setTarget:self];
                    [checkBtn setAction:@selector(checkChanged:)];
                    
                    height += 2*FILTER_PARATITLE_HEIGHT;
                    [[panel contentView] addSubview:checkBtn];
                }
            }
        }
    }
    [panel setTitle:_strPluginId];
    [panel setFrame:boundsRect display:YES];
}
- (void)run
{
    
	PluginData *pluginData;
    
    refresh = YES;
	success = NO;
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self preview:self];
	[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
    
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
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
	[pluginData cancel];
	if (newdata) { free(newdata); newdata = NULL; }
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
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
