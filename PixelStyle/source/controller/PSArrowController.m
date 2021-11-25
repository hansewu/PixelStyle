//
//  PSArrowController.m
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Steve Sprang
//

#import "WDArrowhead.h"
#import "PSArrowheadCell.h"
#import "PSArrowController.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"
#import "MyTableRowView.h"

@implementation PSArrowController

@synthesize drawingController = drawingController_;

//- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    
//    if (!self) {
//        return nil;
//    }
//    
//    
//    UIBarButtonItem *swap = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Swap", @"Swap")
//                                                             style:UIBarButtonItemStylePlain
//                                                            target:self
//                                                            action:@selector(swapArrowheads:)];
//    self.navigationItem.rightBarButtonItem = swap;
//    
//    return self;
//}


-(id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    if (!self) {
        return nil;
    }
    
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:self.window.contentView.frame];
    [self.window.contentView addSubview:imageView];
    [imageView release];
    
    return self;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(drawingController_) [drawingController_ release];
    
    [super dealloc];
}

- (void) setDrawingController:(WDDrawingController *)drawingController
{
    if(drawingController_) [drawingController_ release];
    drawingController_ = [drawingController retain];
}

- (NSArray *) arrows
{
    return @[WDStrokeArrowNone, @"arrow1", @"arrow2", @"arrow3",
             @"T shape", @"closed circle", @"closed square",
             @"closed diamond", @"open circle", @"open square", @"open diamond"];
}

- (IBAction)swapArrowheads:(id)sender
{
    WDStrokeStyle *strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
    
    NSString *start = strokeStyle.startArrow;
    NSString *end = strokeStyle.endArrow;
    
    [drawingController_ setValue:end forProperty:WDStartArrowProperty];
    [drawingController_ setValue:start forProperty:WDEndArrowProperty];
}

//- (void) loadView
//{
//    CGRect frame = CGRectZero;
////    frame.size = self.preferredContentSize;
//    
//    self.tableView = [[UITableView alloc] initWithFrame:frame];
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.tableView.allowsSelection = NO;
//    self.tableView.rowHeight = 46;
//}

-(void)windowDidLoad
{
    [super windowDidLoad];
    
    NSRect frame = self.window.contentView.frame;
//    m_tableViewArrow = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 50, frame.size.width, frame.size.height - 200 - 5)];
//    [self.window.contentView addSubview:m_tableViewArrow];
//    [m_tableViewArrow setAllowsTypeSelect:NO];
    [m_tableViewArrow allowsEmptySelection];
    [m_tableViewArrow setRowHeight:40];
//    [m_tableViewArrow setDelegate:self];
//    [m_tableViewArrow setDataSource:self];
//    [m_tableViewArrow release];
    
    
//    NSTableColumn *column=[[NSTableColumn alloc] initWithIdentifier:@"ArrowIndetify"];
//    [column setWidth:frame.size.width - 2*5];
//    [column setEditable:NO];
//    [column setResizingMask:NSTableColumnNoResizing];
//    [m_tableViewArrow addTableColumn:column];
//    [column release];
//    
//    
//    NSButton *btnSwap = [[NSButton alloc] initWithFrame:NSMakeRect(frame.size.width - 30 - 100, 5, 100, 45)];
//    [btnSwap setTitle:NSLocalizedString(@"Swap", nil)];
//    [btnSwap setTarget:self];
//    [btnSwap setAction:@selector(swapArrowheads:)];
//    [self.window.contentView addSubview:btnSwap];
//    [btnSwap release];
}

- (void)showPanelFrom:(NSPoint)p onWindow: (NSWindow *)parent
{
    [super showPanelFrom:p onWindow:parent];
    
    [m_tableViewArrow reloadData];
    
}

#pragma mark - NSTableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self arrows].count;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    // Make the row view keep track of our main model object
    MyTableRowView *result = [[MyTableRowView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, tableView.rowHeight)];
    result.bDrawSperateLine = NO;
    return [result autorelease];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSRect rect = NSMakeRect(0, 0, [tableColumn width], [tableView rowHeight]);
    NSView *view = [[[NSView alloc] initWithFrame:rect] autorelease];
    if ([tableColumn.identifier isEqualToString:@"ArrowIndetify"])
    {
        NSString        *arrowID = [self arrows][row];
        WDStrokeStyle   *strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
        
        PSArrowheadCell *cell = [[[PSArrowheadCell alloc] initWithFrame:rect] autorelease];
        [view addSubview:cell];
        cell.drawingController = self.drawingController;
        
        
        cell.arrowhead = arrowID;
        cell.startArrowButton.state = [strokeStyle.startArrow isEqualToString:arrowID];
        cell.endArrowButton.state = [strokeStyle.endArrow isEqualToString:arrowID];
    }
    return view;
}

@end
