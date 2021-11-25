#import "ThresholdView.h"
#import "ThresholdClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation ThresholdClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"Threshold" owner:self];
	
	return self;
}

- (int)type
{
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Threshold" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"PixelStyle Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;

	refresh = YES;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	
	topValue = 0;
	bottomValue = 255;
	
	[rangeLabel setStringValue:[NSString stringWithFormat:@"%d - %d", topValue, bottomValue]];
	
	[topSlider setIntValue:topValue];
	[bottomSlider setIntValue:bottomValue];
	[view calculateHistogram:pluginData];
	
	success = NO;
	[self preview:self];
	[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	if (refresh) [self adjust];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	[self adjust];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	if (refresh) [self adjust];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	topValue = [topSlider intValue];
	bottomValue = [bottomSlider intValue];
	
	if (topValue < bottomValue)
		[rangeLabel setStringValue:[NSString stringWithFormat:@"%d - %d", topValue, bottomValue]];
	else
		[rangeLabel setStringValue:[NSString stringWithFormat:@"%d - %d", bottomValue, topValue]];
	
	[panel setAlphaValue:1.0];
	refresh = YES;
	
	[view setNeedsDisplay:YES];
	[self preview:self];
}

- (void)adjust
{
	PluginData *pluginData;
	IntRect selection;
	int i, j, k, t1, t2, spp, width, channel, mid;
	unsigned char *data, *overlay, *replace;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			if (channel == kAllChannels || channel == kPrimaryChannels) {
				
				mid = 0;
				for (k = 0; k < spp - 1; k++)
					mid += data[(j * width + i) * spp + k];
				mid /= (spp - 1);
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * spp]), 255, spp - 1);
				else
					memset(&(overlay[(j * width + i) * spp]), 0, spp - 1);
				
				overlay[(j * width + i + 1) * spp - 1] = data[(j * width + i + 1) * spp - 1];
				
				replace[j * width + i] = 255;
				
			}
			
			else if (channel == kAlphaChannel) {
			
				mid = data[(j * width + i + 1) * spp - 1];
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * spp]), 255, spp - 1);
				else
					memset(&(overlay[(j * width + i) * spp]), 0, spp - 1);
				
				overlay[(j * width + i + 1) * spp - 1] = 255;
				
				replace[j * width + i] = 255;
				
			}
			
		}
	}
}

- (int)topValue
{
	return topValue;
}

- (int)bottomValue
{
	return bottomValue;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
