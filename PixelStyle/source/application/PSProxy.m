#import "PSProxy.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSContent.h"
#import "PSResolution.h"
#import "PSMargins.h"
#import "PSScale.h"
#import "PSWhiteboard.h"
#import "PSLayer.h"
#import "PSOperations.h"
#import "PSSelection.h"
#import "PSController.h"
#import "PSTools.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSFlip.h"
#import "TextureExporter.h"
#import "PSAlignment.h"
#import "PSPlugins.h"
#import "PSRotation.h"
#import "PSDocRotation.h"
#import "TextTool.h"
#import "ColorSelectView.h"
#import "PSHelpers.h"
#import "PSWindowContent.h"
//#import "PSHoverButton.h"

@implementation PSProxy

//-(void)awakeFromNib
//{
//    [m_idMove setToolTip:NSLocalizedString(@"Move and Align Tool", nil)];
//    [m_idTransform setToolTip:NSLocalizedString(@"Transform Tool", nil)];
//    [m_idRectangle setToolTip:NSLocalizedString(@"Rectangular Marquee Tool", nil)];
//    [m_idEllipse setToolTip:NSLocalizedString(@"Elliptical Marquee Tool", nil)];
//    [m_idlasso setToolTip:NSLocalizedString(@"Lasso Tool", nil)];
//    [m_idPolyon setToolTip:NSLocalizedString(@"Polygonal Lasso Tool", nil)];
//    [m_idWand setToolTip:NSLocalizedString(@"Magic Wand Tool", nil)];
//    [m_idCrop setToolTip:NSLocalizedString(@"Crop Tool", nil)];
//    [m_idArtBrush setToolTip:NSLocalizedString(@"Art Brush Tool", nil)];
//    [m_idPencil setToolTip:NSLocalizedString(@"Pencil Tool", nil)];
//    [m_idBrush setToolTip:NSLocalizedString(@"Brush Tool", nil)];
//    [m_idEraser setToolTip:NSLocalizedString(@"Eraser Tool", nil)];
//    [m_idPick setToolTip:NSLocalizedString(@"Eyedropper Tool", nil)];
//    [m_idClone setToolTip:NSLocalizedString(@"Clone Stamp Tool", nil)];
//    [m_idBucket setToolTip:NSLocalizedString(@"Paint Bucket Tool", nil)];
//    [m_idGradient setToolTip:NSLocalizedString(@"Gradient Tool", nil)];
//    [m_idText setToolTip:NSLocalizedString(@"Text Tool", nil)];
//    [m_idZoom setToolTip:NSLocalizedString(@"Zoom Tool", nil)];
//    [m_idShape setToolTip:NSLocalizedString(@"Shape Tool", nil)];
//    [m_idVectorMove setToolTip:NSLocalizedString(@"Path Selection Tool", nil)];
//    [m_idVectorPen setToolTip:NSLocalizedString(@"Pen Tool", nil)];
//    [m_idVectorEraser setToolTip:NSLocalizedString(@"Path Eraser Tool", nil)];
//    [m_idRedEyeMove setToolTip:NSLocalizedString(@"Red Eye Remove Tool", nil)];
//    [m_idSmudge setToolTip:NSLocalizedString(@"Smudge Tool", nil)];
//    [m_idBurnDodge setToolTip:NSLocalizedString(@"Burn Tool", nil)];
//    
//    [(PSHoverButton *)m_idMove setHoverImage:[NSImage imageNamed:@"tools-17-h"]];
//    [(PSHoverButton *)m_idTransform setHoverImage:[NSImage imageNamed:@"tools-20-h"]];
//    [(PSHoverButton *)m_idRectangle setHoverImage:[NSImage imageNamed:@"tools-0-h"]];
////    [(PSHoverButton *)m_idEllipse setHoverImage:[NSImage imageNamed:@"tools-1-h"]];
////    [(PSHoverButton *)m_idlasso setHoverImage:[NSImage imageNamed:@"tools-2-h"]];
//    [(PSHoverButton *)m_idPolyon setHoverImage:[NSImage imageNamed:@"tools-3-h"]];
//    [(PSHoverButton *)m_idWand setHoverImage:[NSImage imageNamed:@"tools-4-h"]];
//    [(PSHoverButton *)m_idCrop setHoverImage:[NSImage imageNamed:@"tools-12-h"]];
//    [(PSHoverButton *)m_idArtBrush setHoverImage:[NSImage imageNamed:@"tools-19-h"]];
////    [(PSHoverButton *)m_idPencil setHoverImage:[NSImage imageNamed:@"tools-5-h"]];
////    [(PSHoverButton *)m_idBrush setHoverImage:[NSImage imageNamed:@"tools-6-h"]];
//    [(PSHoverButton *)m_idEraser setHoverImage:[NSImage imageNamed:@"tools-9-h"]];
//    [(PSHoverButton *)m_idPick setHoverImage:[NSImage imageNamed:@"tools-7-h"]];
//    [(PSHoverButton *)m_idClone setHoverImage:[NSImage imageNamed:@"tools-13-h"]];
//    [(PSHoverButton *)m_idBucket setHoverImage:[NSImage imageNamed:@"tools-10-h"]];
//    [(PSHoverButton *)m_idGradient setHoverImage:[NSImage imageNamed:@"tools-11-h"]];
//    [(PSHoverButton *)m_idText setHoverImage:[NSImage imageNamed:@"tools-8-h"]];
//    [(PSHoverButton *)m_idZoom setHoverImage:[NSImage imageNamed:@"tools-16-h"]];
//    [(PSHoverButton *)m_idShape setHoverImage:[NSImage imageNamed:@"tools-21-h"]];
//    [(PSHoverButton *)m_idVectorMove setHoverImage:[NSImage imageNamed:@"tools-22-h"]];
//    [(PSHoverButton *)m_idVectorPen setHoverImage:[NSImage imageNamed:@"tools-23-h"]];
//    [(PSHoverButton *)m_idVectorEraser setHoverImage:[NSImage imageNamed:@"tools-24-h"]];
//    [(PSHoverButton *)m_idRedEyeMove setHoverImage:[NSImage imageNamed:@"tools-25-h"]];
//    [(PSHoverButton *)m_idSmudge setHoverImage:[NSImage imageNamed:@"tools-14-h"]];
//    [(PSHoverButton *)m_idBurnDodge setHoverImage:[NSImage imageNamed:@"tools-26-h"]];
//}

- (IBAction)exportAsTexture:(id)sender
{
	[[gCurrentDocument textureExporter] exportAsTexture:sender];
}

- (IBAction)zoomIn:(id)sender
{
	[[gCurrentDocument docView] zoomIn:sender];
}

- (IBAction)zoomNormal:(id)sender
{
	[[gCurrentDocument docView] zoomNormal:sender];
}

- (IBAction)zoomOut:(id)sender
{
	[[gCurrentDocument docView] zoomOut:sender];
}

- (IBAction)toggleCMYKPreview:(id)sender
{
	[[gCurrentDocument whiteboard] toggleCMYKPreview];
}

#ifdef PERFORMANCE
- (IBAction)resetPerformance:(id)sender
{
	[[gCurrentDocument whiteboard] resetPerformance];
}
#endif

- (IBAction)importLayer:(id)sender
{
	[[gCurrentDocument contents] importLayer];
}

- (IBAction)copyMerged:(id)sender
{
	[[gCurrentDocument contents] copyMerged];
}

- (IBAction)flatten:(id)sender
{
	// Warn before flattening the image
	if (NSRunAlertPanel(LOCALSTR(@"flatten title", @"Information will be lost"), LOCALSTR(@"flatten body", @"Parts of the document that are not currently visible will be lost. Are you sure you wish to continue?"), LOCALSTR(@"flatten", @"Flatten"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn)
		[[gCurrentDocument contents] flatten];
}

- (IBAction)mergeLinked:(id)sender
{
	[[gCurrentDocument contents] mergeLinked];
}

- (IBAction)mergeDown:(id)sender
{
	[[gCurrentDocument contents] mergeDown];
}

- (IBAction)raiseLayer:(id)sender
{
	[(PSContent *)[gCurrentDocument contents] raiseLayer:kActiveLayer];
}

- (IBAction)bringToFront:(id)sender
{
	[(PSContent *)[gCurrentDocument contents] moveLayerOfIndex:kActiveLayer toIndex: 0];
}

- (IBAction)lowerLayer:(id)sender
{
	[(PSContent *)[gCurrentDocument contents] lowerLayer:kActiveLayer];
}

- (IBAction)sendToBack:(id)sender
{
	[(PSContent *)[gCurrentDocument contents] moveLayerOfIndex:kActiveLayer toIndex: [(PSContent *)[gCurrentDocument contents] layerCount]];	
}

- (IBAction)deleteLayer:(id)sender
{
	id document = gCurrentDocument;
	
	if ([[document contents] layerCount] > 1)
		[(PSContent *)[document contents] deleteLayer:kActiveLayer];
	else
		NSBeep();
}

- (IBAction)addLayer:(id)sender
{
	PSContent *contents = [gCurrentDocument contents];
	[contents addLayer:kActiveLayer];
}

- (IBAction)addShapeLayer:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    [contents addVectorLayer:kActiveLayer];
}

- (IBAction)duplicateLayer:(id)sender
{
	id selection = [gCurrentDocument selection];
	
	if (![selection floating]) {
		[(PSContent *)[gCurrentDocument contents] duplicateLayer:kActiveLayer];
	}
}

- (IBAction)layerAbove:(id)sender
{
	[(PSContent *)[gCurrentDocument contents] layerAbove];
}

- (IBAction)layerBelow:(id)sender
{
	[(PSContent *)[gCurrentDocument contents] layerBelow];
}

- (IBAction)setColorSpace:(id)sender
{
	[[gCurrentDocument contents] convertToType:[sender tag] - 240];
}

- (IBAction)toggleLinked:(id)sender
{
	[[gCurrentDocument contents] setLinked: ![[[gCurrentDocument contents] activeLayer] linked] forLayer: kActiveLayer];
}

- (IBAction)clearAllLinks:(id)sender
{
	[[gCurrentDocument contents] clearAllLinks];
}

- (IBAction)toggleFloatingSelection:(id)sender
{
	id selection = [gCurrentDocument selection];
	id contents = [gCurrentDocument contents];
	
	if ([selection floating]) {
		[contents anchorSelection];
	}
	else {
		[contents makeSelectionFloat:NO];
	}
}

- (IBAction)duplicate:(id)sender
{
	[[gCurrentDocument contents] makeSelectionFloat: YES];
}

- (IBAction)toggleCMYKSave:(id)sender
{
	id contents = [gCurrentDocument contents];
	
	[contents setCMYKSave:![contents cmykSave]];
}

- (IBAction)toggleLayerAlpha:(id)sender
{
	[[[gCurrentDocument contents] activeLayer] toggleAlpha];
}

- (IBAction)changeSelectedChannel:(id)sender
{
	[[gCurrentDocument contents] setSelectedChannel: [sender tag] % 10];
	[[gCurrentDocument helpers] channelChanged];	
}

- (IBAction)changeTrueView:(id)sender
{
	[[gCurrentDocument contents] setTrueView: ![sender state]];
	[[gCurrentDocument helpers] channelChanged];
}

-(IBAction)onRaster:(id)sender
{
    PSAbstractLayer *pLayer = [[gCurrentDocument contents] activeLayer];
    if(pLayer.layerFormat == PS_TEXT_LAYER || (pLayer.layerFormat == PS_VECTOR_LAYER))
    {
        int nActiveLayerIndex = [[gCurrentDocument contents] activeLayerIndex];
        [[gCurrentDocument contents] convertVectorLayerToRaster:nActiveLayerIndex];
        
        [(PSHelpers *)[gCurrentDocument helpers] updateLayerThumbnailInHelper];
    }
    
}

-(IBAction)onConvertToShape:(id)sender
{
    PSAbstractLayer *pLayer = [[gCurrentDocument contents] activeLayer];
    if(pLayer.layerFormat == PS_TEXT_LAYER)
    {
        int nActiveLayerIndex = [[gCurrentDocument contents] activeLayerIndex];
        [[gCurrentDocument contents] convertTextLayerToShape:nActiveLayerIndex];
        
        [(PSHelpers *)[gCurrentDocument helpers] updateLayerThumbnailInHelper];
    }
    
}

- (IBAction)alignLeft:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] alignLeft:sender];
}

- (IBAction)alignRight:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] alignRight:sender];
}

- (IBAction)alignHorizontalCenters:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] alignHorizontalCenters:sender];
}

- (IBAction)alignTop:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] alignTop:sender];
}

- (IBAction)alignBottom:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] alignBottom:sender];
}

- (IBAction)alignVerticalCenters:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] alignVerticalCenters:sender];
}

- (IBAction)centerLayerHorizontally:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] centerLayerHorizontally:sender];
}

- (IBAction)centerLayerVertically:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaAlignment] centerLayerVertically:sender];
}

- (IBAction)setResolution:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaResolution] run];
}

- (IBAction)setMargins:(id)sender
{
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] run:YES];
}

- (IBAction)setLayerMargins:(id)sender
{
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] run:NO];
}

- (IBAction)flipDocHorizontally:(id)sender;
{
	[[(PSOperations *)[gCurrentDocument operations] seaDocRotation] flipDocHorizontally];
}

- (IBAction)flipDocVertically:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaDocRotation] flipDocVertically];
}

- (IBAction)rotateDocLeft:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaDocRotation] rotateDocLeft];
}

- (IBAction)rotateDocRight:(id)sender
{
	[[(PSOperations *)[gCurrentDocument operations] seaDocRotation] rotateDocRight];
}

- (IBAction)setLayerRotation:(id)sender
{
	[(PSRotation *)[(PSOperations *)[gCurrentDocument operations] seaRotation] run];
}

- (IBAction)condenseLayer:(id)sender
{
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] condenseLayer:sender];
}

- (IBAction)condenseToSelection:(id)sender
{
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] condenseToSelection:sender];
}

- (IBAction)expandLayer:(id)sender
{
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] expandLayer:sender];
}

- (IBAction)cropImage:(id)sender
{
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] cropImage:sender];
}

- (IBAction)maskImage:(id)sender
{
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] maskImage:sender];
}

- (IBAction)setScale:(id)sender
{
	[(PSScale *)[(PSOperations *)[gCurrentDocument operations] seaScale] run:YES];
}

- (IBAction)setLayerScale:(id)sender
{
	[(PSScale *)[(PSOperations *)[gCurrentDocument operations] seaScale] run:NO];
}

- (IBAction)flipHorizontally:(id)sender
{
	[(PSFlip *)[(PSOperations *)[gCurrentDocument operations] seaFlip] run:kHorizontalFlip];
}

- (IBAction)flipVertically:(id)sender
{
	[(PSFlip *)[(PSOperations *)[gCurrentDocument operations] seaFlip] run:kVerticalFlip];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [gCurrentDocument undoManager];
}

- (IBAction)reapplyEffect:(id)sender
{
	[[PSController seaPlugins] reapplyEffect:sender];
}

// To Utitilies
- (IBAction)selectTool:(id)sender
{
	[[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] selectToolUsingTag:sender];
}

- (IBAction)toggleLayers:(id)sender
{
	[[[PSController utilitiesManager] pegasusUtilityFor:gCurrentDocument] toggleLayers:sender];
}

- (IBAction)toggleInformation:(id)sender
{
	[[[PSController utilitiesManager] infoUtilityFor:gCurrentDocument] toggle: sender];
}

- (IBAction)toggleOptions:(id)sender
{
	[[[PSController utilitiesManager] optionsUtilityFor:gCurrentDocument] toggle: sender];
}

- (IBAction)toggleStatusBar:(id)sender
{
	[[[PSController utilitiesManager] statusUtilityFor:gCurrentDocument] toggle: sender];
}

// To the ColorView
- (IBAction)activateForegroundColor:(id)sender
{
	[(ColorSelectView *)[[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] colorView] activateForegroundColor: sender];
}

- (IBAction)activateBackgroundColor:(id)sender
{
	[[[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] colorView] activateBackgroundColor: sender];
}

- (IBAction)swapColors:(id)sender
{
	[[[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] colorView] swapColors: sender];
}

- (IBAction)defaultColors:(id)sender
{
	[[[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] colorView] defaultColors: sender];
}

- (IBAction)openColorSyncPanel:(id)sender
{
	CMLaunchControlPanel(0);
}

- (IBAction)fillQuick:(id)sender
{
    [(PSContent *)[gCurrentDocument contents] fillQuick];
}

- (IBAction)tansformQuick:(id)sender
{
    [[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] changeToolTo:kTransformTool];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	id document = gCurrentDocument;
	id contents = [document contents];
	
	// Never when there is no document
	if (document == NULL)
		return NO;
	
	// End the line drawing
	[[document helpers] endLineDrawing];
	
	// Sometimes we always enable
	if ([menuItem tag] == 999)
		return YES;
	
	// Never when the document is locked
	if ([document locked])
		return NO;
	
	// Sometimes in other cases
	switch ([menuItem tag]) {
		case 200:
			if([[[document window] contentView] visibilityForRegion: kSidebar])
				[menuItem setTitle:NSLocalizedString(@"Hide Layers", nil)];
			else
				[menuItem setTitle:NSLocalizedString(@"Show Layers", nil)];
			return YES;
		break;
		case 192:
			if([[[document window] contentView] visibilityForRegion:kPointInformation])
				[menuItem setTitle:NSLocalizedString(@"Hide Point Information", nil)];
			else
				[menuItem setTitle:NSLocalizedString(@"Show Point Information", nil)];
			return YES;
		break;
		case 191:
			if([[[document window] contentView] visibilityForRegion: kOptionsBar])
				[menuItem setTitle:NSLocalizedString(@"Hide Options Bar", nil)];
			else
				[menuItem setTitle:NSLocalizedString(@"Show Options Bar", nil)];
			return YES;			
		break;
		case 194:
			if([[[document window] contentView] visibilityForRegion:kStatusBar])
				[menuItem setTitle:NSLocalizedString(@"Hide Status Bar", nil)];
			else
				[menuItem setTitle:NSLocalizedString(@"Show Status Bar", nil)];
			return YES;			
		break;
		case 210:
		case 211:			
        case 212:
            if (![[document docView] canZoomOut])
                return NO;
            break;
		case 213:
		case 214:
			if ([contents canRaise:kActiveLayer] == NO)
				return NO;
		break;
		case 215:
		case 216:
			if ([contents canLower:kActiveLayer] == NO)
				return NO;
		break;
		case 219:
			if ([[document contents] layerCount] <= 1)
				return NO;
		break;
		case 220:
			if ([contents canFlatten] == NO)
				return NO;
		break;
		case 230:
			[menuItem setState:[[document whiteboard] CMYKPreview]];
			if (![[document whiteboard] canToggleCMYKPreview])
				return NO;
		break;
		case 232:
			[menuItem setState:[[document contents] cmykSave]];
		break;
		case 240:
		case 241:
			[menuItem setState:[menuItem tag] == 240 + [(PSContent *)contents type]];
		break;
		case 250:
			if ([[contents activeLayer] hasAlpha])
				[menuItem setTitle:LOCALSTR(@"disable alpha", @"Disable Alpha Channel")];
			else
				[menuItem setTitle:LOCALSTR(@"enable alpha", @"Enable Alpha Channel")];
			if (![[contents activeLayer] canToggleAlpha])
				return NO;
		break;
		case 264:
			if(![[document selection] active] || [[document selection] floating])
				return NO;
		break;
		case 300:
			if ([[document selection] floating])
				[menuItem setTitle:LOCALSTR(@"anchor selection", @"Anchor Selection")];
			else
				[menuItem setTitle:LOCALSTR(@"float selection", @"Float Selection")];
			if (![[document selection] active])
				return NO;
		break;
		case 320:
		case 321:
		case 322:
		case 330:
		case 331:
		case 360:
		case 361:
		case 362:
		case 410:
		case 411:
		case 412:
		case 413:
			if ([[document selection] floating])
				return NO;
		break;
		case 450:
		case 451:
		case 452:
			if([[document selection] floating])
				return NO;
			[menuItem setState: [[document contents] selectedChannel] == [menuItem tag] % 10];
		break;
		case 460:
			[menuItem setState: [contents trueView]];
		break;
		case 340:
		case 341:
		case 342:
		case 345:
		case 346:
		case 347:
		case 349:
			if (![[contents activeLayer] linked])
				return NO;
		break;
		case 382:
			if ([[contents activeLayer] linked]){
				[menuItem setTitle:@"Unlink Layer"];
			}else{
				[menuItem setTitle:@"Link Layer"];
			}
		break;
		case 380:
			if (![[PSController seaPlugins] hasLastEffect])
				return NO;
		break;
	}
    
    
    BOOL bValidate = YES;
    //根据当前工具确定
    bValidate = [[[gCurrentDocument tools] currentTool] validateMenuItem:menuItem];
   	
    if(bValidate)
    {
        //根据选中层确定菜单是否可用
        bValidate = [[gCurrentDocument contents] validateMenuItem:menuItem];
    }
    
	return bValidate;
}

- (IBAction)crash:(id)sender
{
	int i;
	
	for (i = 0; i < 5000; i++) {
		*((char *)i) = 0xFF;
	}
}

@end
