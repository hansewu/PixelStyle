//
//  PSMenuManager.h
//  PixelStyle
//
//  Created by wyl on 9/2/16.
//
//
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface PSMenuManager : NSObject
{
    //NSMenu
    IBOutlet NSMenu         *m_menuFile;
    IBOutlet NSMenu         *m_menuEdit;
    IBOutlet NSMenu         *m_menuImage;
    IBOutlet NSMenu         *m_menuLayer;
    IBOutlet NSMenu         *m_menuShape;
    IBOutlet NSMenu         *m_menuSelect;
    IBOutlet NSMenu         *m_menuFilter;
    IBOutlet NSMenu         *m_menuView;
    IBOutlet NSMenu         *m_menuWindow;
    IBOutlet NSMenu         *m_menuHelp;
    
    IBOutlet NSMenuItem     *m_menuItemAbout;
    IBOutlet NSMenuItem     *m_menuItemHide;
    IBOutlet NSMenuItem     *m_menuItemQuit;
    IBOutlet NSMenuItem     *m_menuItemPreferences;
    
    IBOutlet NSMenuItem     *m_menuItemNew;
    IBOutlet NSMenuItem     *m_menuItemNewFromClipboard;
    IBOutlet NSMenuItem     *m_menuItemOpen;
    IBOutlet NSMenuItem     *m_menuItemOpenRecent;
    IBOutlet NSMenuItem     *m_menuItemClose;
    IBOutlet NSMenuItem     *m_menuItemSave;
    IBOutlet NSMenuItem     *m_menuItemSaveAs;
    IBOutlet NSMenuItem     *m_menuItemRevert;
    IBOutlet NSMenuItem     *m_menuItemImport;
    IBOutlet NSMenuItem     *m_menuItemExport;
    IBOutlet NSMenuItem     *m_menuItemPageSetup;
    IBOutlet NSMenuItem     *m_menuItemPrint;
    
    
    
    IBOutlet NSMenuItem     *m_menuItemUndo;
    IBOutlet NSMenuItem     *m_menuItemRedo;
    IBOutlet NSMenuItem     *m_menuItemCut;
    IBOutlet NSMenuItem     *m_menuItemCopy;
    IBOutlet NSMenuItem     *m_menuItemCopyMerged;
    IBOutlet NSMenuItem     *m_menuItemPaste;
    IBOutlet NSMenuItem     *m_menuItemDuplicate;
    IBOutlet NSMenuItem     *m_menuItemFill;
    IBOutlet NSMenuItem     *m_menuItemTransform;
    IBOutlet NSMenuItem     *m_menuItemStartDictation;
    IBOutlet NSMenuItem     *m_menuItemEmoji;
    
    
    
    IBOutlet NSMenuItem     *m_menuItemZoomIn;
    IBOutlet NSMenuItem     *m_menuItemZoomOut;
    IBOutlet NSMenuItem     *m_menuItemNormal;
    IBOutlet NSMenuItem     *m_menuItemShowRulers;
    IBOutlet NSMenuItem     *m_menuItemShowGuides;
    IBOutlet NSMenuItem     *m_menuItemHideLayers;
    IBOutlet NSMenuItem     *m_menuItemHidePointInformation;
    IBOutlet NSMenuItem     *m_menuItemHideOptionsBar;
    IBOutlet NSMenuItem     *m_menuItemHideStatusBar;
    IBOutlet NSMenuItem     *m_menuItemColors;
    IBOutlet NSMenuItem     *m_menuItemEnterFullScreen;
    
    
    IBOutlet NSMenuItem     *m_menuItemResizeImage;
    IBOutlet NSMenuItem     *m_menuItemResolution;
    IBOutlet NSMenuItem     *m_menuItemImageBoundaries;
    IBOutlet NSMenuItem     *m_menuItemRotate90Clockwise;
    IBOutlet NSMenuItem     *m_menuItemRotate90Anticlockwise;
    IBOutlet NSMenuItem     *m_menuItemFlipHorizontal;
    IBOutlet NSMenuItem     *m_menuItemFlipVertical;
    IBOutlet NSMenuItem     *m_menuItemExportAsTexture;
    
    
    IBOutlet NSMenuItem     *m_menuItemShapeAlignment;
    IBOutlet NSMenuItem     *m_menuItemShapeArrange;
    IBOutlet NSMenuItem     *m_menuItemShapeFlipHorizontally;
    IBOutlet NSMenuItem     *m_menuItemShapeFlipVertically;
    IBOutlet NSMenuItem     *m_menuItemUnitePaths;
    IBOutlet NSMenuItem     *m_menuItemIntersectPaths;
    IBOutlet NSMenuItem     *m_menuItemSubtractFromPaths;
    IBOutlet NSMenuItem     *m_menuItemExcludePaths;
    IBOutlet NSMenuItem     *m_menuItemCombinePaths;
    IBOutlet NSMenuItem     *m_menuItemSeparatePaths;
    IBOutlet NSMenuItem     *m_menuItemDeletePaths;
    
    
    IBOutlet NSMenuItem     *m_menuItemResizeLayer;
    IBOutlet NSMenuItem     *m_menuItemRotateLayer;
    IBOutlet NSMenuItem     *m_menuItemLayerBoundaries;
    IBOutlet NSMenuItem     *m_menuItemTrimToEdges;
    IBOutlet NSMenuItem     *m_menuItemNewLayer;
    IBOutlet NSMenuItem     *m_menuItemNewShapeLayer;
    IBOutlet NSMenuItem     *m_menuItemDuplicateLayer;
    IBOutlet NSMenuItem     *m_menuItemDelete;
    IBOutlet NSMenuItem     *m_menuItemBringtoFront;
    IBOutlet NSMenuItem     *m_menuItemBringForward;
    IBOutlet NSMenuItem     *m_menuItemSendBackward;
    IBOutlet NSMenuItem     *m_menuItemSendToBack;
    IBOutlet NSMenuItem     *m_menuItemAlignment;
    IBOutlet NSMenuItem     *m_menuItemRasterise;
    IBOutlet NSMenuItem     *m_menuItemConvertToShape;
    IBOutlet NSMenuItem     *m_menuItemMergeDown;
    IBOutlet NSMenuItem     *m_menuItemMergeSelectedLayers;
    IBOutlet NSMenuItem     *m_menuItemFlattenImage;
    
    
    IBOutlet NSMenuItem     *m_menuItemSelectAll;
    IBOutlet NSMenuItem     *m_menuItemSelectAlpha;
    IBOutlet NSMenuItem     *m_menuItemDeselect;
    IBOutlet NSMenuItem     *m_menuItemInverse;
    IBOutlet NSMenuItem     *m_menuItemSelectFlipHorizontal;
    IBOutlet NSMenuItem     *m_menuItemSelectFlipVertical;

    IBOutlet NSMenuItem     *m_menuItemLastFilter;
    
    IBOutlet NSMenuItem     *m_menuItemMinimize;
    IBOutlet NSMenuItem     *m_menuItemZoom;
    IBOutlet NSMenuItem     *m_menuItemBringAllToFront;
    
    
    IBOutlet NSMenuItem     *m_menuItemSearch;
    IBOutlet NSMenuItem     *m_menuItemSendFeedbackToApple;
    IBOutlet NSMenuItem     *m_menuItemPSHelp;
    IBOutlet NSMenuItem     *m_menuItemForum;
    IBOutlet NSMenuItem     *m_menuItemFeedbackWithEmail;
    
    IBOutlet NSMenuItem     *m_menuItemPromotionSuperVectorizer2;
    IBOutlet NSMenuItem     *m_menuItemPromotionSuperPhtocutPro;
    IBOutlet NSMenuItem     *m_menuItemPromotionSuperEraserPro;
    IBOutlet NSMenuItem     *m_menuItemPromotionAfterFocus;
    IBOutlet NSMenuItem     *m_menuItemPromotionPhotoSizeOptimizer;
    IBOutlet NSMenuItem     *m_menuItemPromotionSuperDenoising;
    
    
    IBOutlet NSMenuItem     *m_menuItemCondenseToContent;
    IBOutlet NSMenuItem     *m_menuItemCondenseToSelection;
    IBOutlet NSMenuItem     *m_menuItemExpandToDocument;
    
    IBOutlet NSMenuItem     *m_menuItemLayerAlignLeft;
    IBOutlet NSMenuItem     *m_menuItemLayerAlignRight;
    IBOutlet NSMenuItem     *m_menuItemLayerAlignHorizontalCenter;
    IBOutlet NSMenuItem     *m_menuItemLayerAlignTop;
    IBOutlet NSMenuItem     *m_menuItemLayerAlignBottom;
    IBOutlet NSMenuItem     *m_menuItemLayerAlignVerticalCenter;
    IBOutlet NSMenuItem     *m_menuItemLayerCenterHorizontally;
    IBOutlet NSMenuItem     *m_menuItemLayerCenterVertically;
    
    IBOutlet NSMenuItem     *m_menuItemShapeAlignLeft;
    IBOutlet NSMenuItem     *m_menuItemShapeAlignRight;
    IBOutlet NSMenuItem     *m_menuItemShapeAlignHorizontalCenter;
    IBOutlet NSMenuItem     *m_menuItemShapeAlignTop;
    IBOutlet NSMenuItem     *m_menuItemShapeAlignBottom;
    IBOutlet NSMenuItem     *m_menuItemShapeAlignVerticalCenter;
    
    IBOutlet NSMenuItem     *m_menuItemShapeBringToFront;
    IBOutlet NSMenuItem     *m_menuItemShapeBringForward;
    IBOutlet NSMenuItem     *m_menuItemShapeSendBackward;
    IBOutlet NSMenuItem     *m_menuItemShapeSendToBack;
    
    IBOutlet NSMenuItem     *m_menuItemForegroundColor;
    IBOutlet NSMenuItem     *m_menuItemBackgroundColor;
    IBOutlet NSMenuItem     *m_menuItemSwapColors;
    IBOutlet NSMenuItem     *m_menuItemDefaultColors;
    IBOutlet NSMenuItem     *m_menuItemRotateSelectionShading;
    
    IBOutlet NSMenuItem     *m_menuItemShape;
    
    
}
@end
