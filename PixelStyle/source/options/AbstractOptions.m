#import "AbstractOptions.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSPrefs.h"
#import "PSDocument.h"
#import "AspectRatio.h"

static int lastTool = -1;
static BOOL forceAlt = NO;

@implementation AbstractOptions

-(void)awakeFromNib
{
    [(NSView *)m_idView setAutoresizingMask:NSViewWidthSizable];
}

-(id)init
{
    self = [super init];
    m_enumLastModifier = kNoModifier;
    
    return self;
}

- (void)activate:(id)sender
{
	int curTool;
	
	m_idDocument = sender;
	curTool = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	if (lastTool != curTool) {
		[self updateModifiers:0];
		lastTool = curTool;
	}
}

- (void)update
{
}

- (void)forceAlt
{
	int index;
	
    m_enumModifier = kAltModifier;
	
	forceAlt = YES;
}

- (void)unforceAlt
{
	if (forceAlt) {
		[self updateModifiers:0];
		forceAlt = NO;
	}
}

- (void)updateModifiers:(unsigned int)modifiers
{
	int index;
	
//	if (m_idModifierPopup) {
//	
//		if ((modifiers & NSAlternateKeyMask) >> 19 && (modifiers & NSControlKeyMask) >> 18) {
//			index = [m_idModifierPopup indexOfItemWithTag:kAltControlModifier];
//			if (index > 0) [m_idModifierPopup selectItemAtIndex:index];
//		}
//		else if ((modifiers & NSShiftKeyMask) >> 17 && (modifiers & NSControlKeyMask) >> 18) {
//			index = [m_idModifierPopup indexOfItemWithTag:kShiftControlModifier];
//			if (index > 0) [m_idModifierPopup selectItemAtIndex:index];
//		}
//        else if ((modifiers & NSShiftKeyMask) >> 17 && (modifiers & NSAlternateKeyMask) >> 19) {
//            index = [m_idModifierPopup indexOfItemWithTag:kShiftAltModifier];
//            if (index > 0) [m_idModifierPopup selectItemAtIndex:index];
//        }
//		else if ((modifiers & NSControlKeyMask) >> 18) {
//			index = [m_idModifierPopup indexOfItemWithTag:kControlModifier];
//			if (index > 0) [m_idModifierPopup selectItemAtIndex:index];
//		}
//		else if ((modifiers & NSShiftKeyMask) >> 17) {
//			index = [m_idModifierPopup indexOfItemWithTag:kShiftModifier];
//			if (index > 0) [m_idModifierPopup selectItemAtIndex:index];
//		}
//		else if ((modifiers & NSAlternateKeyMask) >> 19) {
//			index = [m_idModifierPopup indexOfItemWithTag:kAltModifier];
//			if (index > 0) [m_idModifierPopup selectItemAtIndex:index];
//		}
//		else {
//			[m_idModifierPopup selectItemAtIndex:kNoModifier];
//		}
//	}
    
    if ((modifiers & NSAlternateKeyMask) >> 19 && (modifiers & NSControlKeyMask) >> 18) {
        m_enumModifier = kAltControlModifier;
    }
    else if ((modifiers & NSShiftKeyMask) >> 17 && (modifiers & NSControlKeyMask) >> 18) {
        m_enumModifier = kShiftControlModifier;
    }
    else if ((modifiers & NSShiftKeyMask) >> 17 && (modifiers & NSAlternateKeyMask) >> 19) {
        m_enumModifier = kShiftAltModifier;
    }
    else if ((modifiers & NSControlKeyMask) >> 18) {
        m_enumModifier = kControlModifier;
    }
    else if ((modifiers & NSShiftKeyMask) >> 17) {
        m_enumModifier = kShiftModifier;
    }
    else if ((modifiers & NSAlternateKeyMask) >> 19) {
        m_enumModifier = kAltModifier;
    }
    else {
        m_enumModifier = kNoModifier;
    }
    
    
	// We now need to update all of the documents because the modifiers, and thus possibly
	// the cursors and guides may have changed.
	int i;
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
	
}

- (int)modifier
{
    return m_enumModifier;
//	return [[m_idModifierPopup selectedItem] tag];
}



- (BOOL)useTextures
{
	return NO;
}

- (void)shutdown
{
    SEL sel = @selector(delayInitView);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
     sel object: nil];
    
    sel = @selector(initView);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
     sel object: nil];
}

- (id)view
{
	return m_idView;
}

@end
