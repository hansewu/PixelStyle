#import "OptionsUtility.h"
#import "ToolboxUtility.h"
#import "AbstractOptions.h"
#import "PSTools.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "ZoomOptions.h"
#import "AbstractSelectOptions.h"
#import "UtilitiesManager.h"
#import "PSDocument.h"
#import "AbstractTool.h"
#import "PSWindowContent.h"

@implementation OptionsUtility

- (id)init
{
	m_nCurrentTool = -1;
	
	return self;
}

- (void)awakeFromNib
{
	[m_idView addSubview:m_idBlankView];
	m_idLastView = m_idBlankView;
	
	NSArray *allTools = [[m_idDocument tools] allTools];
	NSEnumerator *e = [allTools objectEnumerator];
	AbstractTool *tool;
	while(tool = [e nextObject]){
		[tool setOptions: [self getOptions:[tool toolId]]];
	}
	
	[[PSController utilitiesManager] setOptionsUtility: self for:m_idDocument];
}

- (void)dealloc
{
	[super dealloc];
}

- (void)activate
{
	[self update];
}

- (void)deactivate
{
	[self update];
}

- (void)shutdown
{
	int i = 0;
	id options = NULL;
	
	do {
		options = [self getOptions:i];
		[options shutdown];
		i++;
	} while (options != NULL);
}

- (id)currentOptions
{
	if (m_idDocument == NULL)
		return NULL;
	else
		return [self getOptions:[m_idToolboxUtility tool]];
}

- (id)getOptions:(int)whichTool
{
	switch (whichTool) {
		case kRectSelectTool:
			return m_idRectSelectOptions;
		break;
		case kEllipseSelectTool:
			return m_idEllipseSelectOptions;
		break;
		case kLassoTool:
			return m_idLassoOptions;
		break;
		case kPolygonLassoTool:
			return m_idPolygonLassoOptions;
		break;
		case kPositionTool:
			return m_idPositionOptions;
		break;
		case kZoomTool:
			return m_idZoomOptions;
		break;
		case kPencilTool:
			return m_idPencilOptions;
		break;
		case kBrushTool:
			return m_idBrushOptions;
		break;
		case kBucketTool:
			return m_idBucketOptions;
		break;
		case kTextTool:
			return m_idTextOptions;
		break;
		case kEyedropTool:
			return m_idEyedropOptions;
		break;
		case kEraserTool:
			return m_idEraserOptions;
		break;
		case kSmudgeTool:
			return m_idSmudgeOptions;
		break;
		case kGradientTool:
			return m_idGradientOptions;
		break;
		case kWandTool:
			return m_idWandOptions;
		break;
		case kCloneTool:
			return m_idCloneOptions;
		break;
		case kCropTool:
			return m_idCropOptions;
		break;
		case kEffectTool:
			return m_idEffectOptions;
		break;
        case kVectorTool:
            return m_idVectorOptions;
        case kMyBrushTool:
            return m_idMyBrushOptions;
        case kTransformTool:
            return m_idTransformOptions;
        case kShapeTool:
            return m_idShapeOptions;
        case kVectorMoveTool:
            return m_idVectorMoveOptions;
        case kVectorNodeEditorTool:
            return m_idVectorNodeEditorOptions;
        case kVectorPenTool:
            return m_idVectorPenOptions;
        case kVectorEraserTool:
            return m_idVectorEraserOptions;
        case kRedEyeRemoveTool:
            return m_idRedEyeRemoveOptions;
        case kBurnTool:
            return m_idBurnOptions;
        case kDodgeTool:
            return m_idDodgeOptions;
        case kSpongeTool:
            return m_idSpongeOptions;
            break;
	}
	
	return NULL;
}

- (void)update
{
	id currentOptions = [self currentOptions];
	
	// If there are no current options put up a blank view
	if (currentOptions == NULL) {
		[m_idView replaceSubview:m_idLastView with:m_idBlankView];
		m_idLastView = m_idBlankView;
		m_nCurrentTool = -1;
		return;
	}
	
	// Otherwise select the current options are up-to-date with the current tool
	if (m_nCurrentTool != [m_idToolboxUtility tool]) {
        [[(AbstractOptions *)currentOptions view] setFrameSize:[m_idView frame].size];
        [m_idView replaceSubview:m_idLastView with:[(AbstractOptions *)currentOptions view]];
		m_idLastView = [(AbstractOptions *)currentOptions view];
		m_nCurrentTool = [m_idToolboxUtility tool];
	}
	
	// Update the options
	[(AbstractOptions *)currentOptions activate:m_idDocument];
	[currentOptions update];
}

- (IBAction)show:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility:YES forRegion:kOptionsBar];
}

- (IBAction)hide:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility:NO forRegion:kOptionsBar];
}


- (IBAction)toggle:(id)sender
{
	if([self visible]){
		[self hide:sender];
	}else{
		[self show:sender];
	}
}

- (void)viewNeedsDisplay
{
	[m_idView setNeedsDisplay: YES];
}

- (BOOL)visible
{
	return [[[m_idDocument window] contentView] visibilityForRegion: kOptionsBar];
}

@end
