#import "NSTextViewRedirect.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "PSTools.h"
#import "TextTool.h"

@implementation NSTextViewRedirect

- (IBAction)changeSpecialFont:(id)sender
{
	[[[[PSController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions:kTextTool] changeFont:sender];
}

@end
