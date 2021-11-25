//
//  PSRecentFileUtility.m
//  PixelStyle
//
//  Created by wyl on 16/6/21.
//
//

#import "PSRecentFileUtility.h"
#import "PSTextFieldCell.h"
#import "MyTableRowView.h"
#import <QuickLook/QuickLook.h>
#import "ConfigureInfo.h"

#define RecentFileInfo  @"RecentFileInfo"

#define ImageWidth 50
#define ImageHeight 50
@implementation PSRecentFileUtility

-(void)awakeFromNib
{
    [m_tableViewRecentFile setTarget:self];
    [m_tableViewRecentFile setDoubleAction:@selector(doubleClick:)];
}

-(void)updateRecentFile
{
    [m_tableViewRecentFile reloadData];
}

#pragma mark - TableView DataSource
- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    // Make the row view keep track of our main model object
    MyTableRowView *result = [[MyTableRowView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, tableView.rowHeight)];
    result.bDrawSperateLine = YES;
    return [result autorelease];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSString *sPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/samples"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *arrSampleFiles = [fileManager subpathsAtPath:sPath];
    
    int nCount = [arrSampleFiles count];
    NSArray *recentDocs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    
    for(NSURL *url in recentDocs)
    {
        if ([[url path] rangeOfString:sPath].length == 0)
            nCount++;
    }
    
    return nCount;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 50;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSRect rect = NSMakeRect(0, 0, [tableColumn width], [tableView rowHeight]);
    NSView *view  = [[[NSView alloc] initWithFrame:rect] autorelease];
    if ([tableColumn.identifier isEqualToString:RecentFileInfo])
    {
        NSString *sPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/samples"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSArray *arrSampleFiles = [fileManager subpathsAtPath:sPath];
        
        NSString *sFilePath;
        NSString *filename;
        NSColor *colorText = TEXT_COLOR;
        if(row < [arrSampleFiles count])
        {
            sFilePath = [sPath stringByAppendingPathComponent:[arrSampleFiles objectAtIndex:row]];
            filename = [[sFilePath pathComponents] objectAtIndex:[[sFilePath pathComponents] count] -1];
            filename = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Sample1", nil), filename];
//            filename = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Sample", nil), filename];
            
            colorText = [NSColor orangeColor];
        }
        else
        {
            NSArray *recentDocs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
            
            NSMutableArray *muArrRecentFiles = [NSMutableArray arrayWithCapacity:[recentDocs count]];
            for (int nIndex = 0; nIndex < [recentDocs count]; nIndex++)
            {
                if ([[[recentDocs objectAtIndex:nIndex] path] rangeOfString:sPath].length == 0)
                    [muArrRecentFiles addObject:[recentDocs objectAtIndex:nIndex]];
            }
            
            sFilePath = [[muArrRecentFiles objectAtIndex:(row - [arrSampleFiles count])] path];

            filename = [[sFilePath pathComponents] objectAtIndex:[[sFilePath pathComponents] count] -1];
        }
        
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile: sFilePath];
        
        NSImageView *fileImageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, ImageWidth, ImageHeight)] autorelease];
        [fileImageView setImageScaling:NSImageScaleNone];
        [fileImageView setImage:image];
        [view addSubview:fileImageView];
        
        NSTextField *titleField = [[[NSTextField alloc] initWithFrame:NSMakeRect(50, 0, view.frame.size.width - fileImageView.frame.size.width - 20, 50)] autorelease];
        PSTextFieldLabelCell *tcell = [[[PSTextFieldLabelCell alloc] init] autorelease];
        [tcell setAlignment:NSTextAlignmentLeft];
        [tcell setTextColor:colorText];
        [titleField setCell:tcell];
        [titleField setStringValue:filename];
        [view addSubview:titleField];
    }
    
    return view;
}

#pragma mark - Actions
-(void)doubleClick:(id)sender
{
    int nRow = [m_tableViewRecentFile clickedRow];
    NSString *sPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/samples"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *arrSampleFiles = [fileManager subpathsAtPath:sPath];
    
    NSString *sFilePath;
    if(nRow < [arrSampleFiles count])
    {
        sFilePath = [sPath stringByAppendingPathComponent:[arrSampleFiles objectAtIndex:nRow]];
    }
    else
    {
        NSArray *recentDocs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
        
        NSMutableArray *muArrRecentFiles = [NSMutableArray arrayWithCapacity:[recentDocs count]];
        for (int nIndex = 0; nIndex < [recentDocs count]; nIndex++)
        {
            if ([[[recentDocs objectAtIndex:nIndex] path] rangeOfString:sPath].length == 0)
                [muArrRecentFiles addObject:[recentDocs objectAtIndex:nIndex]];
        }
        
        sFilePath = [[muArrRecentFiles objectAtIndex:(nRow - [arrSampleFiles count])] path];
    }
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:sFilePath] display:YES completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error){
        if(documentWasAlreadyOpen)
            [[m_tableViewRecentFile window] orderOut:nil];
    }];

}

@end
