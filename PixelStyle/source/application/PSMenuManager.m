//
//  PSMenuManager.m
//  PixelStyle
//
//  Created by wyl on 9/2/16.
//
//

#import "PSMenuManager.h"

@implementation PSMenuManager

PSMenuManager *m_menuManagerId;

+(PSMenuManager *)getMenuManager
{
    return m_menuManagerId;
}

-(NSMenu *)getMenuSelection
{
    return m_menuSelect;
}

-(void)awakeFromNib
{
    m_menuManagerId     = self;
    
    m_menuFile.title    = NSLocalizedString(@"File", nil);
    m_menuEdit.title    = NSLocalizedString(@"Edit", nil);
    m_menuImage.title   = NSLocalizedString(@"Image", nil);
    m_menuLayer.title   = NSLocalizedString(@"Layer", nil);
    m_menuShape.title   = NSLocalizedString(@"Shape", nil);
    m_menuSelect.title  = NSLocalizedString(@"Select", nil);
    m_menuFilter.title    = NSLocalizedString(@"Filter", nil);
    m_menuView.title    = NSLocalizedString(@"View", nil);
    m_menuWindow.title  = NSLocalizedString(@"Window", nil);
    m_menuHelp.title    = NSLocalizedString(@"Help", nil);
    
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    m_menuItemAbout.title = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"About", nil), sProductName];
    [m_menuItemHide setTitle:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Hide", nil),sProductName]];
    [m_menuItemQuit setTitle:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Quit", nil),sProductName]];
    m_menuItemPreferences.title = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Preferences", nil)];
    
    m_menuItemNew.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"New", nil)];
    m_menuItemNewFromClipboard.title    = NSLocalizedString(@"New from Clipboard", nil);
    m_menuItemOpen.title   = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Open", nil)];
    m_menuItemOpenRecent.title   = NSLocalizedString(@"Open Recent", nil);
    m_menuItemClose.title   = NSLocalizedString(@"Close", nil);
    m_menuItemSave.title  = NSLocalizedString(@"Save", nil);
    m_menuItemSaveAs.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Save As", nil)];
    m_menuItemRevert.title  = NSLocalizedString(@"Revert", nil);
    m_menuItemImport.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Import as a new layer", nil)];
    m_menuItemExport.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Export", nil)];
    m_menuItemPageSetup.title  = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Page Setup", nil)];
    m_menuItemPrint.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Print", nil)];
    

    m_menuItemUndo.title    = NSLocalizedString(@"Undo", nil);
    m_menuItemRedo.title    = NSLocalizedString(@"Redo", nil);
    m_menuItemCut.title   = NSLocalizedString(@"Cut", nil);
    m_menuItemCopy.title   = NSLocalizedString(@"Copy1", nil);
    m_menuItemCopyMerged.title   = NSLocalizedString(@"Copy Merged", nil);
    m_menuItemPaste.title  = NSLocalizedString(@"Paste", nil);
    m_menuItemDuplicate.title    = NSLocalizedString(@"Duplicate", nil);
    m_menuItemFill.title  = NSLocalizedString(@"Fill", nil);
    m_menuItemTransform.title    = NSLocalizedString(@"Transform", nil);
    m_menuItemStartDictation.title    = NSLocalizedString(@"Start Dictation", nil);
    m_menuItemEmoji.title  = NSLocalizedString(@"Emoji", nil);

    
    m_menuItemZoomIn.title    = NSLocalizedString(@"Zoom In", nil);
    m_menuItemZoomOut.title    = NSLocalizedString(@"Zoom Out", nil);
    m_menuItemNormal.title   = NSLocalizedString(@"100%", nil);
    m_menuItemShowRulers.title   = NSLocalizedString(@"Show Rulers", nil);
    m_menuItemShowGuides.title   = NSLocalizedString(@"Show Guides", nil);
    m_menuItemHideLayers.title  = NSLocalizedString(@"Hide Layers", nil);
    m_menuItemHidePointInformation.title    = NSLocalizedString(@"Hide Point Information", nil);
    m_menuItemHideOptionsBar.title  = NSLocalizedString(@"Hide Options Bar", nil);
    m_menuItemHideStatusBar.title    = NSLocalizedString(@"Hide Status Bar", nil);
    m_menuItemColors.title    = NSLocalizedString(@"Colors", nil);
    m_menuItemEnterFullScreen.title  = NSLocalizedString(@"Enter Full Screen", nil);

    
    m_menuItemResizeImage.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Resize Image", nil)];
    m_menuItemResolution.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Resolution", nil)];
    m_menuItemImageBoundaries.title   = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Image Boundaries", nil)];
    m_menuItemRotate90Clockwise.title   = NSLocalizedString(@"Rotate 90° Clockwise", nil);
    m_menuItemRotate90Anticlockwise.title   = NSLocalizedString(@"Rotate 90° Anticlockwise", nil);
    m_menuItemSelectFlipHorizontal.title  = NSLocalizedString(@"Flip Horizontal", nil);
    m_menuItemSelectFlipVertical.title    = NSLocalizedString(@"Flip Vertical", nil);
    m_menuItemExportAsTexture.title  = NSLocalizedString(@"Export as Texture", nil);
    
    
    m_menuItemShapeAlignment.title    = NSLocalizedString(@"Alignment", nil);
    m_menuItemShapeArrange.title    = NSLocalizedString(@"Arrange", nil);
    m_menuItemShapeFlipHorizontally.title   = NSLocalizedString(@"Flip Horizontally", nil);
    m_menuItemShapeFlipVertically.title   = NSLocalizedString(@"Flip Vertically", nil);
    m_menuItemUnitePaths.title  = NSLocalizedString(@"Unite Paths", nil);
    m_menuItemIntersectPaths.title   = NSLocalizedString(@"Intersect Paths", nil);
    m_menuItemSubtractFromPaths.title  = NSLocalizedString(@"Subtract From Paths", nil);
    m_menuItemExcludePaths.title    = NSLocalizedString(@"Exclude Paths", nil);
    m_menuItemCombinePaths.title  = NSLocalizedString(@"Combine Paths", nil);
    m_menuItemSeparatePaths.title    = NSLocalizedString(@"Separate Paths", nil);
    m_menuItemDeletePaths.title    = NSLocalizedString(@"Delete Paths", nil);
    
    
    m_menuItemResizeLayer.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Resize Layer", nil)];
    m_menuItemRotateLayer.title    = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Rotate Layer", nil)];
    m_menuItemLayerBoundaries.title   = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Layer Boundaries", nil)];
    m_menuItemTrimToEdges.title  = NSLocalizedString(@"Trim to Edges", nil);
    m_menuItemNewLayer.title   = NSLocalizedString(@"New Layer", nil);
    m_menuItemNewShapeLayer.title  = NSLocalizedString(@"New Shape Layer", nil);
    m_menuItemDuplicateLayer.title    = NSLocalizedString(@"Duplicate", nil);
    m_menuItemDelete.title  = NSLocalizedString(@"Delete", nil);
    m_menuItemBringtoFront.title    = NSLocalizedString(@"Bring to Front", nil);
    m_menuItemBringForward.title    = NSLocalizedString(@"Bring Forward", nil);
    m_menuItemSendBackward.title    = NSLocalizedString(@"Send Backward", nil);
    m_menuItemSendToBack.title    = NSLocalizedString(@"Send to Back", nil);
    m_menuItemAlignment.title   = NSLocalizedString(@"Alignment", nil);
    m_menuItemRasterise.title   = NSLocalizedString(@"Rasterise", nil);
    m_menuItemConvertToShape.title  = NSLocalizedString(@"Convert to Shape", nil);
    m_menuItemMergeDown.title   = NSLocalizedString(@"Merge Down", nil);
    m_menuItemMergeSelectedLayers.title  = NSLocalizedString(@"Merge Selected Layers", nil);
    m_menuItemFlattenImage.title    = NSLocalizedString(@"Flatten Image", nil);
    
    
    
    m_menuItemSelectAll.title    = NSLocalizedString(@"Select All", nil);
    m_menuItemSelectAlpha.title    = NSLocalizedString(@"Select From Alpha Channel", nil);
    m_menuItemDeselect.title   = NSLocalizedString(@"Deselect", nil);
    m_menuItemInverse.title  = NSLocalizedString(@"Inverse", nil);
    m_menuItemFlipHorizontal.title   = NSLocalizedString(@"Flip Horizontal", nil);
    m_menuItemFlipVertical.title  = NSLocalizedString(@"Flip Vertical", nil);
    
    m_menuItemLastFilter.title    = NSLocalizedString(@"Last Filter", nil);
    
    m_menuItemMinimize.title  = NSLocalizedString(@"Minimize", nil);
    m_menuItemZoom.title    = NSLocalizedString(@"Zoom", nil);
    m_menuItemBringAllToFront.title    = NSLocalizedString(@"Bring All to Front", nil);
    
    m_menuItemSearch.title    = NSLocalizedString(@"Search", nil);
    m_menuItemSendFeedbackToApple.title    = NSLocalizedString(@"SendFeedbackToApple", nil);
    m_menuItemPSHelp.title   = [NSString stringWithFormat:@"%@ %@",sProductName, NSLocalizedString(@"Help", nil)];
    m_menuItemForum.title  = [NSString stringWithFormat:@"%@ %@",sProductName,NSLocalizedString(@"Forum", nil)];
    m_menuItemFeedbackWithEmail.title   = NSLocalizedString(@"Feedback with email", nil);
    
    
    
    m_menuItemCondenseToContent.title = NSLocalizedString(@"Condense to Content", nil);
    m_menuItemCondenseToSelection.title = NSLocalizedString(@"Condense to Selection", nil);
    m_menuItemExpandToDocument.title = NSLocalizedString(@"Expand to Document", nil);
    
    
    m_menuItemLayerAlignLeft.title = NSLocalizedString(@"Align Left", nil);
    m_menuItemLayerAlignRight.title = NSLocalizedString(@"Align Right", nil);
    m_menuItemLayerAlignHorizontalCenter.title = NSLocalizedString(@"Align Horizontal Center", nil);
    m_menuItemLayerAlignTop.title = NSLocalizedString(@"Align Top", nil);
    m_menuItemLayerAlignBottom.title = NSLocalizedString(@"Align Bottom", nil);
    m_menuItemLayerAlignVerticalCenter.title = NSLocalizedString(@"Align Vertical Center", nil);
    m_menuItemLayerCenterHorizontally.title = NSLocalizedString(@"Center Horizontally", nil);
    m_menuItemLayerCenterVertically.title = NSLocalizedString(@"Center Vertically", nil);
    
    
    m_menuItemShapeAlignLeft.title = NSLocalizedString(@"Align Left", nil);
    m_menuItemShapeAlignRight.title = NSLocalizedString(@"Align Right", nil);
    m_menuItemShapeAlignHorizontalCenter.title = NSLocalizedString(@"Align Horizontal Center", nil);
    m_menuItemShapeAlignTop.title = NSLocalizedString(@"Align Top", nil);
    m_menuItemShapeAlignBottom.title = NSLocalizedString(@"Align Bottom", nil);
    m_menuItemShapeAlignVerticalCenter.title = NSLocalizedString(@"Align Vertical Center", nil);
    
    m_menuItemShapeBringToFront.title = NSLocalizedString(@"Bring to Front", nil);
    m_menuItemShapeBringForward.title = NSLocalizedString(@"Bring Forward", nil);
    m_menuItemShapeSendBackward.title = NSLocalizedString(@"Send Backward", nil);
    m_menuItemShapeSendToBack.title = NSLocalizedString(@"Send to Back", nil);
    
    m_menuItemForegroundColor.title = NSLocalizedString(@"Foreground Color", nil);
    m_menuItemBackgroundColor.title = NSLocalizedString(@"Background Color", nil);
    m_menuItemSwapColors.title = NSLocalizedString(@"Swap Colors", nil);
    m_menuItemDefaultColors.title = NSLocalizedString(@"Default Colors", nil);
    m_menuItemRotateSelectionShading.title = NSLocalizedString(@"Rotate Selection Shading", nil);
    
    
    [m_menuItemPromotionSuperVectorizer2 setHidden:YES];
    [m_menuItemPromotionSuperPhtocutPro setHidden:YES];
    [m_menuItemPromotionSuperEraserPro setHidden:YES];
    [m_menuItemPromotionAfterFocus setHidden:YES];
    [m_menuItemPromotionPhotoSizeOptimizer setHidden:YES];
    [m_menuItemPromotionSuperDenoising setHidden:YES];
    
#ifdef FREE_VERSION
    [m_menuItemShape setHidden:YES];
    
    [m_menuItemPromotionSuperVectorizer2 setHidden:NO];
    [m_menuItemPromotionSuperPhtocutPro setHidden:NO];
    [m_menuItemPromotionSuperEraserPro setHidden:NO];
    [m_menuItemPromotionAfterFocus setHidden:NO];
    [m_menuItemPromotionPhotoSizeOptimizer setHidden:NO];
    [m_menuItemPromotionSuperDenoising setHidden:NO];
    
#endif
}

@end
