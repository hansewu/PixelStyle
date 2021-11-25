#import "AbstractScaleOptions.h"
#import "AspectRatio.h"

@implementation AbstractScaleOptions

-(void)awakeFromNib
{
    [super awakeFromNib];
}

- (id)init
{
	self = [super init];
	if(self){
		m_nAspectType = kNoAspectType;
		m_bIgnoresMove = NO;
	}
	return self;
}


- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];

	if ([super modifier] == kShiftModifier) {
		m_nAspectType = kRatioAspectType;
	} else {
		m_nAspectType = kNoAspectType;
	}

}

- (NSSize)ratio
{
	if(m_nAspectType == kRatioAspectType){
		return NSMakeSize(1, 1);
	}
	return NSZeroSize;
}

- (int)aspectType
{
	return m_nAspectType;
}

- (void)setIgnoresMove:(BOOL)ignoring
{
	m_bIgnoresMove = ignoring;
}

- (BOOL)ignoresMove
{
	return m_bIgnoresMove;
}

@end
