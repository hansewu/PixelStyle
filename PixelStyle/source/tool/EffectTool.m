#import "EffectTool.h"
#import "PSController.h"
#import "PSPlugins.h"
#import "PluginClass.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSTools.h"
#import "EffectOptions.h"

@implementation EffectTool

- (int)toolId
{
	return kEffectTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Effect Tool", nil);
}

-(NSString *)toolShotKey
{
    return @" ";
}

- (id)init
{
	if(![super init])
		return NULL;
	m_nCount = 0;
	m_idPSPlugins = [PSController seaPlugins];
	return self;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id pointEffect = [m_idPSPlugins activePointEffect];
	float xScale, yScale;
	IntPoint layerOff;
	
	if (m_nCount < kMaxEffectToolPoints) {
		m_aPoints[m_nCount] = where;
		m_nCount++;
		layerOff.x = [[[m_idDocument contents] activeLayer] xoff];
		layerOff.y = [[[m_idDocument contents] activeLayer] yoff];
		xScale = [[m_idDocument contents] xscale];
		yScale = [[m_idDocument contents] yscale];
		[[m_idDocument docView] setNeedsDisplayInRect:NSMakeRect((where.x + layerOff.x) * xScale - 4, (where.y + layerOff.y) * yScale - 4, 8, 8)];
	}
	
	if (m_nCount == [pointEffect points]) {
		[pointEffect run];
		[m_idPSPlugins cancelReapply];
		m_nCount = 0;
	}
	
	[(EffectOptions *)m_idOptions updateClickCount:self];
}

- (void)reset
{
	m_nCount = 0;
	[(EffectOptions *)m_idOptions updateClickCount:self];
}

- (IntPoint)point:(int)index
{
	return m_aPoints[index];
}

- (int)clickCount
{
	return m_nCount;
}

- (IntRect) selectionRect
{
	NSLog(@"Effect tool invalidly getting asked its selection rect");
	return IntMakeRect(0, 0, 0, 0);
}

@end
