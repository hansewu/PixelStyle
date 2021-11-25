#import "PSTipsUtility.h"
#import "PSWindowContent.h"
#import "BannerView.h"
#import "PSWarning.h"
#import "PSContent.h"
#import "PSController.h"
#import "PSDocument.h"

@implementation PSTipsUtility

- (id)init
{
	self = [super init];
	if(self ){
		m_nMostRecentImportance = -1;
	}
	return self;	
}

- (void)setWarning:(NSString *)message ofImportance:(int)importance
{
	[m_idView setBannerText:message defaultButtonText:NSLocalizedString(@"Close", nil) alternateButtonText:NULL andImportance:importance];
	m_nMostRecentImportance = importance;
//	[m_psWindowContent setVisibility:YES forRegion:kWarningsBar];
    [m_idView setHidden:NO];
}


- (void)showBanner
{
//	[m_idView setBannerText:@"Drag the floating layer to position it, then click Anchor to merge it into the layer below." defaultButtonText:@"Anchor" alternateButtonText:@"New Layer" andImportance:kUIImportance];
	m_nMostRecentImportance = kUIImportance;
//	[m_psWindowContent setVisibility:YES forRegion:kWarningsBar];
    [m_idView setHidden:NO];
}

- (void)hideBanner
{
	m_nMostRecentImportance = -1;
//	[m_psWindowContent setVisibility:NO forRegion:kWarningsBar];
    [m_idView setHidden:YES];
}

- (void)keyTriggered
{
	if(m_nMostRecentImportance != -1){
		[self defaultAction: self];
	}
}

- (IBAction)defaultAction:(id)sender
{
    [m_idView setHidden:YES];
    return;
    
	if(m_nMostRecentImportance == kUIImportance){
		m_nMostRecentImportance = -1;
		[m_psWindowContent setVisibility:NO forRegion:kWarningsBar];
		[[m_idDocument contents] toggleFloatingSelection];
	}else{
		m_nMostRecentImportance = -1;
		[m_psWindowContent setVisibility:NO forRegion:kWarningsBar];
		[[PSController seaWarning] triggerQueue: m_idDocument];
	}
}


- (IBAction)alternateAction:(id)sender
{
	if(m_nMostRecentImportance == kUIImportance){
		m_nMostRecentImportance = -1;
		[m_psWindowContent setVisibility:NO forRegion:kWarningsBar];	
		[[m_idDocument contents] addLayer:kActiveLayer];
	}
}

- (int)activeWarningImportance
{
	return m_nMostRecentImportance;
}

-(id)contentView
{
    return m_idView;
}

@end
