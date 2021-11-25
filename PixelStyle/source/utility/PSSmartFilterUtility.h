//
//  PSSmartFilterUtility.h
//  PixelStyle
//
//  Created by lchzh on 3/3/16.
//
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class PSFilterInfoNode;

@interface PSSmartFilterUtility : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSBrowserDelegate, NSWindowDelegate, NSTextFieldDelegate>
{
    IBOutlet id m_idDocument;
    IBOutlet id m_idPanel;
    IBOutlet NSScrollView *m_scrollviewFilters;
    IBOutlet NSTableView *m_tableviewFilters;
    
    IBOutlet id m_idFiltersPanel;
    IBOutlet NSBrowser *m_browserFilters;
    
    IBOutlet NSButton  *m_btnAddEffects;
    IBOutlet NSButton  *m_btnFlattern;
    IBOutlet NSButton  *m_btnOK;
    IBOutlet NSButton  *m_btnCancel;
    
    PSFilterInfoNode *m_rootNode;
    
    NSMutableIndexSet *m_dragFiltersIndexSet;
    
}

- (void)update;
- (void)runWindow;
- (void)adjustPanelSize;

- (IBAction)addButtonClicked:(id)sender;
- (IBAction)flatternButtonClicked:(id)sender;

- (IBAction)cancelButtonClicked:(id)sender;
- (IBAction)OKButtonClicked:(id)sender;

@end
