//
//  PSFontPanel.m
//  PixelStyle
//
//  Created by wzq on 15/11/5.
//
//

#import "PSFontPanel.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"
#import "WDText.h"
#import "WDTextPath.h"
#import "WDFontManager.h"
#import "WDColor.h"
#import "NSString+Additions.h"

@implementation PSFontPanel

- (instancetype)initWithRect:(NSRect)contentRect selectedFont:(NSString *)fontFamilyyName
{
    self = [super initWithContentRect:contentRect  styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(00, 00, (self.frame.size.width -00), (self.frame.size.height -00))];
    m_familyTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 364, 200)];
    // create columns for our table
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"Col1"];
    [column1 setWidth:self.frame.size.width];
    [m_familyTable addTableColumn:column1];
    [m_familyTable setDelegate:self];
    [m_familyTable setDataSource:self];
    [m_familyTable reloadData];
    //  [m_faceTable setBackgroundColor:[NSColor blackColor]];
    [tableContainer setDocumentView:m_familyTable];
    [tableContainer setHasVerticalScroller:YES];
    [[self contentView] addSubview:tableContainer];
    [tableContainer release];
    
    [column1 release];
    [m_familyTable setHeaderView:nil];
    
    
    tableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect((self.frame.size.width +10 )/2, 10, (self.frame.size.width -20)/2, (self.frame.size.width -20))];
    m_faceTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 364, 200)];
    // create columns for our table
    column1 = [[NSTableColumn alloc] initWithIdentifier:@"Col1"];
    [column1 setWidth:252];
    [m_faceTable addTableColumn:column1];
    [m_faceTable setDelegate:self];
    [m_faceTable setDataSource:self];
    [m_faceTable reloadData];
    //  [m_faceTable setBackgroundColor:[NSColor blackColor]];
    [tableContainer setDocumentView:m_faceTable];
    [tableContainer setHasVerticalScroller:YES];
    //  [[self contentView] addSubview:tableContainer];
    [tableContainer release];
    
    [column1 release];
    [m_faceTable setHeaderView:nil];
    
    self.hidesOnDeactivate = YES;
    self.hasShadow = YES;
    [m_faceTable setHidden:YES];
    
    [self showPanel];
    m_indexSelectedLast = [[NSMutableIndexSet alloc] init];
    m_bInitScroll       = NO;
    m_delegateFontFamilyNotify  = nil;
    
    if(fontFamilyyName == nil)  fontFamilyyName = @"Arial";
    m_strFamilyName = [NSString stringWithString:fontFamilyyName];
    [m_strFamilyName retain];
    
    [self scrollToSelectionInit];
    
    return self;
}

- (void)scrollToSelectionInit
{
    if(m_bInitScroll == NO)
    {
        int nCount = [[[WDFontManager sharedInstance] supportedFamilies] count];
        
        for(int i=0; i< nCount; i++)
        {
            NSString *familyName = [[WDFontManager sharedInstance] supportedFamilies][i];
            
            if([familyName isEqualToString:m_strFamilyName])
            {

                NSIndexSet *indexSelected = [NSIndexSet indexSetWithIndex:i];
                [m_familyTable selectRowIndexes:indexSelected byExtendingSelection:YES];
                
                [m_familyTable scrollRowToVisible:i];
                break;
            }
        }
    }
    
    m_bInitScroll = YES;
    
}

- (void)setDelegateFontFamilyNotify:(id)delegateFontFamilyNotify
{
    m_delegateFontFamilyNotify = delegateFontFamilyNotify;
}

- (void)showPanel:(NSRect)contentRect selectedFont:(NSString *)fontFamilyyName
{
     NSRect rectFrame = [self frameRectForContentRect:contentRect];
    
    [self setFrame:rectFrame display:YES];
    [self showPanel];
    
    if(fontFamilyyName == nil) fontFamilyyName = @"Arial";
    [m_strFamilyName release];
    m_strFamilyName = [NSString stringWithString:fontFamilyyName];
    [m_strFamilyName  retain];
    
    m_bInitScroll = NO;
    [self scrollToSelectionInit];
}

-(void)hidePanel
{

    if(m_idEventLocalMonitor)
    {
        [NSEvent removeMonitor:m_idEventLocalMonitor];
    }
    
    if(m_idEventGlobalMonitor)
    {
        [NSEvent removeMonitor:m_idEventGlobalMonitor];
    }
    
    m_idEventLocalMonitor = nil;
    m_idEventGlobalMonitor = nil;
    self.isVisible = NO;
}

-(void)showPanel
{
    self.isVisible = YES;
    if(!m_idEventLocalMonitor)
    {
        m_idEventLocalMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler:^NSEvent *(NSEvent* event)
                            {
                               // NSLog(@"NSLeftMouseDownMask notification");
                                if(CGRectContainsPoint([self frame],  [NSEvent mouseLocation]) == false)
                                {
                                    [self hidePanel];
                                    return nil;
                                }
                                else
                                    return event;
                            }];
    }
    
    if(!m_idEventGlobalMonitor)
    {
        m_idEventGlobalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler:^void(NSEvent* event)
                                 {
                                     // NSLog(@"NSLeftMouseDownMask notification");
                                     if(CGRectContainsPoint([self frame],  [NSEvent mouseLocation]) == false)
                                     {
                                         [self hidePanel];
                                     }
                                    
                                 }];
    }
    
    self.alphaValue = 0.8;

}

-(void)dealloc
{
    
    [self hidePanel];
    [m_familyTable release];
    [m_faceTable release];
    [m_indexSelectedLast release];
 //   [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

-(void)windowDidResignKey:(NSNotification *)note
{
    self.isVisible = NO;
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)isString:(NSString*)fullString contains:(NSString*)other
{
    NSRange range = [fullString rangeOfString:other];
    return range.length != 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
    //NSLog(@"making view for table...");
    
    NSTextField *textValue = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    
    [textValue autorelease];
    [textValue setBezeled:NO];
    textValue.editable = NO;
    
    
    NSString *fontName;
    
    if (tableView == m_familyTable)
    {
        int currentIndex = -1;
        NSIndexSet *indexSelected = m_familyTable.selectedRowIndexes;
        if(indexSelected.count != 0)
            currentIndex = (int)[indexSelected firstIndex];
        
        if(currentIndex == row)
        {
            [textValue setBackgroundColor:[NSColor blueColor]];
            [textValue setTextColor:[NSColor whiteColor]];
        }
        
        // Set the text to the font family name
        NSString *familyName = [[WDFontManager sharedInstance] supportedFamilies][row];
        
        
        fontName = [[WDFontManager sharedInstance] defaultFontForFamily:familyName];
        
        NSFontManager *manager = [NSFontManager sharedFontManager];
        familyName = [manager localizedNameForFamily:familyName face:nil];
        
        textValue.stringValue = familyName;
        
        [textValue setFont:[NSFont fontWithName:fontName size:12]];
    }
    else
    {
        NSIndexSet *indexSelected = m_familyTable.selectedRowIndexes;
        
        if(indexSelected.count == 0) return 0;
    
        NSUInteger currentIndex = [indexSelected firstIndex];
        NSString *familyName = [[WDFontManager sharedInstance] supportedFamilies][currentIndex];
        fontName = [[WDFontManager sharedInstance] fontsInFamily:familyName][row];
        
        NSFontManager *manager = [NSFontManager sharedFontManager];
        NSString *faceType = [[WDFontManager sharedInstance] typefaceNameForFont:fontName];
        NSString *fontNameLocal = [manager localizedNameForFamily:familyName face:nil];
        
        if([self isString:faceType contains:fontNameLocal] == NO)
        {
            fontNameLocal = [fontNameLocal stringByAppendingString:@" "];
            fontNameLocal = [fontNameLocal stringByAppendingString:faceType];
        }
        else
            fontNameLocal = faceType;

        
        textValue.stringValue = fontNameLocal;
        [textValue setFont:[NSFont fontWithName:fontName size:16]];
    }

    
   // fontName.contentVerticalAlignment = NSControlContentVerticalAlignmentCenter;
    
    return textValue;
}
/*
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSLog(@"getting data...");
    //return @{ @"myKey": @"myValue" };
    return @"My Cool Text";
}
*/



- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == m_familyTable)
    {
        return [[[WDFontManager sharedInstance] supportedFamilies] count];
    }

    NSIndexSet *indexSelected = m_familyTable.selectedRowIndexes;
    
    if(indexSelected.count == 0) return 0;
    
    NSUInteger currentIndex = [indexSelected firstIndex];
    NSString *familyName = [[WDFontManager sharedInstance] supportedFamilies][currentIndex];
    
    return [[[WDFontManager sharedInstance] fontsInFamily:familyName] count];

}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    return YES;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if (tableView == m_familyTable)
        return 25.0;
    
    return 40.0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if(notification.object == m_familyTable)
    {
        [m_faceTable reloadData];
        
        if(m_familyTable.selectedRowIndexes.count > 0)
        {
            NSUInteger currentIndex = [m_familyTable.selectedRowIndexes firstIndex];
            NSString *familyName = [[WDFontManager sharedInstance] supportedFamilies][currentIndex];

            
            [m_strFamilyName release];
            m_strFamilyName = [NSString stringWithString:familyName];
            [m_strFamilyName  retain];
            
            
            if(m_delegateFontFamilyNotify)
            {
                NSString *fontName = [[WDFontManager sharedInstance] defaultFontForFamily:familyName];
                [m_delegateFontFamilyNotify fontFramilySelected:m_strFamilyName fontName:fontName];
            }
        }
        NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
        [set addIndexes:m_familyTable.selectedRowIndexes];
        [set addIndexes:m_indexSelectedLast];
        
        [m_indexSelectedLast removeAllIndexes];
        [m_indexSelectedLast addIndexes:m_familyTable.selectedRowIndexes];
        
        [m_familyTable reloadDataForRowIndexes: set columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [set release];
    }
}

@end
