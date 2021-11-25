#import "AbstractSelectOptions.h"
#import "PSSelection.h"
#import "PSDocument.h"

@implementation AbstractSelectOptions

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [[m_idView viewWithTag:100 + 0] setToolTip:NSLocalizedString(@"New selection", nil)];
    [[m_idView viewWithTag:100 + 1] setToolTip:NSLocalizedString(@"Add to selection", nil)];
    [[m_idView viewWithTag:100 + 2] setToolTip:NSLocalizedString(@"Subtract from selection", nil)];
    [[m_idView viewWithTag:100 + 3] setToolTip:NSLocalizedString(@"Intersect with selection", nil)];
    [[m_idView viewWithTag:100 + 4] setToolTip:NSLocalizedString(@"Invert the intersected selections", nil)];
    
    [m_texFieldFeather setToolTip:NSLocalizedString(@"Soften the edge of a selection", nil)];
    [m_labelFeather setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Feather", nil)]];
}

- (id)init
{
	self = [super init];
    
	m_nMode = kDefaultMode;
    m_nLastMode = m_nMode;
//    [self onSelectionModeBtn:[m_idView viewWithTag:100 + 0]];
	
	return self;
}

- (int)feather
{
    return [m_texFieldFeather intValue];
}

- (int)selectionMode
{
	return m_nMode;
}

- (void)updateSelectionMode:(int)newMode
{
    m_nMode = newMode;
    if(m_nMode == kDefaultMode){
        [self setIgnoresMove:NO];
    }else {
        [self setIgnoresMove:YES];
    }
}

- (void)setModeFromModifier:(unsigned int)modifier
{
	switch (modifier) {
        case kShiftControlModifier:
            [self changeSelectionMode:kSubtractProductMode];
            break;
        case kShiftAltModifier:
            [self changeSelectionMode:kMultiplyMode];
            break;
		case kNoModifier:
            [self changeSelectionMode:m_nLastMode];
			break;
		case kAltModifier:
            [self changeSelectionMode:kSubtractMode];
			break;
		case kShiftModifier:
            [self changeSelectionMode:kAddMode];
			break;
        case kControlModifier:
            [self changeSelectionMode:kDefaultMode];
            break;
		default:
			//[self setSelectionMode: kDefaultMode];
			break;
	}
}

- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];
	int modifier = [super modifier];
	[self setModeFromModifier: modifier];
}

-(IBAction)onSelectionModeBtn:(id)sender
{
    int nTag = [(NSButton *)sender tag];
    int nSelectionMode = nTag - 100;
    [self changeSelectionMode:nSelectionMode];
    
    m_nLastMode = nSelectionMode;
}

-(void)changeSelectionMode:(int)nSelectionMode
{
    if(m_nMode == nSelectionMode) return;
    
    [self updateSelectionMode:nSelectionMode];
    
    [self resumeButtonImage];
    
    NSButton *btn = [m_idView viewWithTag:100 + nSelectionMode];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"select-%d-a",nSelectionMode]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"select-%d-a",nSelectionMode]]];
}

-(void)resumeButtonImage
{
    NSButton *btn;
    
    for(int i = 0; i < 5; i++)
    {
        btn = [m_idView viewWithTag:100 + i];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"select-%d",i]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"select-%d",i]]];
    }
}

#pragma mark -TextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    
    int nFeather = [textField intValue];
    if(nFeather < 0) nFeather = 0;
    else if (nFeather > 200) nFeather = 200;
    [m_texFieldFeather setStringValue:[NSString stringWithFormat:LOCALSTR(@"feather", @"%d px"), nFeather]];
    
    return YES;
}

@end
