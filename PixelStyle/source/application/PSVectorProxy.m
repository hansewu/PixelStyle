//
//  PSVectorProxy.m
//  PixelStyle
//
//  Created by wyl on 16/3/18.
//
//

#import "PSVectorProxy.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSTools.h"
#import "PSAbstractLayer.h"
#import "WDDrawingController.h"


@implementation PSVectorProxy

#pragma mark -
#pragma mark Path Operations
- (IBAction)unitePaths:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController unitePaths:sender];
}

- (IBAction)intersectPaths:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController intersectPaths:sender];
}

- (IBAction)subtractPaths:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController subtractPaths:sender];
}

- (IBAction)excludePaths:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController excludePaths:sender];
}


#pragma mark - Shape Menu -Arrange

- (IBAction)bringShapeToFront:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController bringToFront:sender];
}

- (IBAction)bringShapeForward:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController bringForward:sender];
}

- (IBAction)sendShapeBackward:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController sendBackward:sender];
}

- (IBAction)sendShapeToBack:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController sendToBack:sender];
}


#pragma mark - Shape Menu - Align

- (IBAction)alignShape:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDAlignment alignment = ((NSMenuItem *)sender).tag -500;
    [wdDrawingController align:alignment];
}

- (IBAction)flipShapeHorizontally:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController flipHorizontally:sender];
}

- (IBAction)flipShapeVertically:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController flipVertically:sender];
}

#pragma mark -
#pragma mark Compound Paths
- (IBAction)combinePaths:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController makeCompoundPath:sender];
}
- (IBAction)separatePaths:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController releaseCompoundPath:sender];
    
}

- (IBAction)deletePaths:(id)sender
{
    PSContent *contents = [gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController deleteSelectedPath:sender];
}

- (BOOL)validateMenuItem:(id)menuItem
{
    NSMenuItem *item = (NSMenuItem *)menuItem;
    id document = gCurrentDocument;
    if (document == NULL) return NO;
    // Never when the document is locked
    if ([document locked]) return NO;
    
    
    id contents = [document contents];
    if ([[contents activeLayer] layerFormat] != PS_VECTOR_LAYER) return NO;
    
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    BOOL hasSelection = (wdDrawingController.selectedObjects.count > 0) ? YES : NO;
    
    if (item.action == @selector(alignShape:))
    {
        item.enabled = (wdDrawingController.selectedObjects.count >= 2);
    }
    else if (item.action == @selector(flipShapeHorizontally:) ||
        item.action == @selector(flipShapeVertically:))
    {
        item.enabled = hasSelection && !wdDrawingController.activePath;
    }
    else if (item.action == @selector(sendShapeToBack:) ||
               item.action == @selector(sendShapeBackward:) ||
               item.action == @selector(bringShapeForward:) ||
               item.action == @selector(bringShapeToFront:))
    {
        item.enabled = hasSelection;
    }
    
    // PATH
    else if (item.action == @selector(combinePaths:) ||
               item.action == @selector(unitePaths:) ||
               item.action == @selector(intersectPaths:) ||
               item.action == @selector(subtractPaths:) ||
               item.action == @selector(excludePaths:))
    {
        item.enabled = [wdDrawingController canMakeCompoundPath];
    } else if (item.action == @selector(separatePaths:)) {
        item.enabled = [wdDrawingController canReleaseCompoundPath];
    } else if (item.action == @selector(deletePaths:)) {
        item.enabled = [[wdDrawingController orderedSelectedObjects] count] > 0;
    }
    if(!item.enabled) return item.enabled;
    
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


@end
