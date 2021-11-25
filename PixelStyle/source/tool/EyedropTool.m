#import "EyedropTool.h"
#import "PSLayer.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"
#import "EyedropOptions.h"
#import "PSWhiteboard.h"
#import "PSView.h"
#import "PSTools.h"
#import "Bitmap.h"
#import "PSHelpers.h"

@implementation EyedropTool

- (int)toolId
{
	return kEyedropTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Eyedropper Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"I";
}

- (id)init
{
    self = [super init];
    if(self)
    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eyedrop-cursor"] hotSpot:NSMakePoint(1, 14)];
    }
    return self;
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id toolboxUtility = (ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
	NSColor *color = [self getColor];
	
	if (color != NULL) {
//		if ([(EyedropOptions *)m_idOptions modifier] == kAltModifier)
//			[toolboxUtility setBackground:[self getColor]];
//		else
//			[toolboxUtility setForeground:[self getColor]];
        if ([(EyedropOptions *)m_idOptions dropAsBackgroundColor])
            [toolboxUtility setBackground:[self getColor]];
        else
            [toolboxUtility setForeground:[self getColor]];
		[toolboxUtility update:NO];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EYEDROPCOLORCHANGED" object:color];
}

- (int)sampleSize
{
	return [m_idOptions sampleSize];
}



- (NSColor *)getColor
{
	id layer = [[m_idDocument contents] activeLayer];
	unsigned char *data;
	int spp = [[m_idDocument contents] spp];
	int lwidth, lheight, width, height;
	IntPoint newPos, pos;
	unsigned char t[4];
	int radius = [m_idOptions sampleSize] - 1;
	int channel = [[m_idDocument contents] selectedChannel];
	
	lwidth = [(PSLayer *)layer width];
	lheight = [(PSLayer *)layer height];
	width = [(PSContent *)[m_idDocument contents] width];
	height = [(PSContent *)[m_idDocument contents] height];
	
	pos = [[m_idDocument docView] getMousePosition:NO];
	if ([m_idOptions mergedSample]) {
//		data = [(PSWhiteboard *)[m_idDocument whiteboard] data];
//		newPos = pos;
//		if (newPos.x < 0 || newPos.x >= width || newPos.y < 0 || newPos.y >= height)
//			return NULL;
//		if (spp == 2) {
//			t[0] = averagedComponentValue(2, data, width, height, 0, radius, newPos);
//			t[1] = averagedComponentValue(2, data, width, height, 1, radius, newPos);
//			unpremultiplyBitmap(2, t, t, 1);
//			return [NSColor colorWithDeviceWhite:(float)t[0] / 255.0 alpha:(float)t[1] / 255.0];
//		}
//		else {
//			t[0] = averagedComponentValue(4, data, width, height, 0, radius, newPos);
//			t[1] = averagedComponentValue(4, data, width, height, 1, radius, newPos);
//			t[2] = averagedComponentValue(4, data, width, height, 2, radius, newPos);
//			t[3] = averagedComponentValue(4, data, width, height, 3, radius, newPos);
//			unpremultiplyBitmap(4, t, t, 1);
//			return [NSColor colorWithDeviceRed:(float)t[0] / 255.0 green:(float)t[1] / 255.0 blue:(float)t[2] / 255.0 alpha:(float)t[3] / 255.0];
//		}
                
        return [[m_idDocument docView] getScreenColor:spp];
        
	}
	else {
//		data = [(PSLayer *)layer getRawData];
//        if (data == NULL) {
//            return NULL;
//        }
		newPos.x = pos.x - [layer xoff];
		newPos.y = pos.y - [layer yoff];
		if (newPos.x < 0 || newPos.x >= lwidth || newPos.y < 0 || newPos.y >= lheight)
			return NULL;
        
        data = [(PSLayer *)layer getRawData];
        if (data == NULL) {return NULL;}
            
		if (spp == 2)
        {
			if (channel != kAlphaChannel) t[0] = averagedComponentValue(2, data, lwidth, lheight, 0, radius, newPos);
			if (channel == kPrimaryChannels) t[1] = 255;
			else t[1] = averagedComponentValue(2, data, lwidth, lheight, 1, radius, newPos);
			if (channel == kAlphaChannel) { t[0] = t[1]; t[1] = 255; }
            
            [(PSLayer *)layer unLockRawData];
			return [NSColor colorWithDeviceWhite:(float)t[0] / 255.0 alpha:(float)t[1] / 255.0];
		}
		else
        {
			if (channel != kAlphaChannel)
            {
				t[0] = averagedComponentValue(4, data, lwidth, lheight, 0, radius, newPos);
				t[1] = averagedComponentValue(4, data, lwidth, lheight, 1, radius, newPos);
				t[2] = averagedComponentValue(4, data, lwidth, lheight, 2, radius, newPos);
			}
			if (channel == kPrimaryChannels) t[3] = 255;
			else t[3] = averagedComponentValue(4, data, lwidth, lheight, 3, radius, newPos);
			if (channel == kAlphaChannel) { t[0] = t[1] = t[2] = t[3]; t[3] = 255; }
            
            [(PSLayer *)layer unLockRawData];
			return [NSColor colorWithDeviceRed:(float)t[0] / 255.0 green:(float)t[1] / 255.0 blue:(float)t[2] / 255.0 alpha:(float)t[3] / 255.0];
		}
        
        [(PSLayer *)layer unLockRawData];
	}
}

@end
