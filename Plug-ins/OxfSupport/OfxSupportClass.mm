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
    (char *)"eu.gmic.GradientRGB",
    (char *)"eu.gmic.HardSketch",
    (char *)"eu.gmic.ColorBalance",
    (char *)"eu.gmic.ColorBlindness",
    (char *)"eu.gmic.Sketch",
    (char *)"eu.gmic.VectorPainting",
    (char *)"eu.gmic.Charcoal",
    (char *)"eu.gmic.Pencil",
    (char *)"eu.gmic.Retinex",
    (char *)"eu.gmic.Edges",
    (char *)"eu.gmic.Ripple",
    (char *)"eu.gmic.Wind",
    (char *)"eu.gmic.Wave",
    (char *)"eu.gmic.Water",
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

- (void)run
{
    _effectHandle = oxfHostLoad(_hostHandle, std::string(_strPluginId.UTF8String));
    
	PluginData *pluginData;
	/*
	if ([gUserDefaults objectForKey:@"AIPortraitMatting.radius"])
		radius = [gUserDefaults integerForKey:@"AIPortraitMatting.radius"];
	else
		radius = 10;
	
	
	if (radius < 1 || radius > 100)
		radius = 10;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	
	[radiusSlider setIntValue:radius];
	*/
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
