//
//  ChannelView.m
//  PixelStyle
//
//  Created by wyl on 15/10/20.
//
//

#import "ChannelView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "MyTableRowView.h"
#import "ConfigureInfo.h"

#import "PSSmartFilterManager.h"

#define CHANANEL_INDENTIFIER_NAME @"channelName"
#define CHANANEL_INDENTIFIER_VISIBLE @"channelVisible"
#define CHANANEL_INDENTIFIER_THUMBNAIL @"channelThumbnail"

@implementation ChannelView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)awakeFromNib
{
    [m_tableViewChannels setAllowsMultipleSelection:YES];
    
    NSTableColumn *column=[[NSTableColumn alloc] initWithIdentifier:CHANANEL_INDENTIFIER_VISIBLE];
    [column setWidth:20.0];
    [column setMinWidth:20];
    [column setEditable:NO];
    [column setResizingMask:NSTableColumnNoResizing];
    [m_tableViewChannels addTableColumn:column];
    [column release];
    
    NSTableColumn *column2=[[NSTableColumn alloc] initWithIdentifier:CHANANEL_INDENTIFIER_THUMBNAIL];
    [column2 setWidth:50.0];
    [column2 setMinWidth:50.0];
    [column2 setEditable:NO];
    [column2 setResizingMask:NSTableColumnNoResizing];
    [m_tableViewChannels addTableColumn:column2];
    [column2 release];
    
    NSTableColumn *column3=[[NSTableColumn alloc] initWithIdentifier:CHANANEL_INDENTIFIER_NAME];
    [column3 setWidth:100.0];
    [column3 setMinWidth:50];
    [column3 setEditable:NO];
    [column3 setResizingMask:NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask];
    [m_tableViewChannels addTableColumn:column3];
    [column3 release];
    
    [m_tableViewChannels setBackgroundColor:[NSColor clearColor]];    

}

- (void)dealloc
{
    [super dealloc];
}



#pragma mark - NSTableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 4;
}


-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return YES;
}

#pragma mark - NSTableView delegate

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    // Make the row view keep track of our main model object
    MyTableRowView *result = [[MyTableRowView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, tableView.rowHeight)];
    result.bDrawSperateLine = YES;
    return [result autorelease];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSRect rect = NSMakeRect(0, 0, [tableColumn width], [tableView rowHeight]);
    NSView *view  = [[[NSView alloc] initWithFrame:rect] autorelease];
    if ([tableColumn.identifier isEqualToString:CHANANEL_INDENTIFIER_VISIBLE])
    {
        PSLayer* layer = [[m_idDocument contents] activeLayer];
        PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
        int filterIndex = [filterManager getSmartFiltersCount] - 1;
        BOOL redVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"redVisible" UTF8String]].nIntValue;
        BOOL greenVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"greenVisible" UTF8String]].nIntValue;
        BOOL blueVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"blueVisible" UTF8String]].nIntValue;
        BOOL alphaVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"alphaVisible" UTF8String]].nIntValue;
        BOOL bVisible;
        if (row == 0)
            bVisible = redVisible;
        else if (row == 1)
            bVisible = greenVisible;
        else if (row == 2)
            bVisible = blueVisible;
        else
            bVisible = alphaVisible;
        
        NSButton *btn= [[[NSButton alloc] initWithFrame:rect] autorelease];
        NSButtonCell *btnCell = btn.cell;
        [btn setTitle:@""];
        [btn setImage:[NSImage imageNamed:@"unchecked"]];
        [btn setAlternateImage:[NSImage imageNamed:@"checked"]];
        [btn setState:NSOffState];
        [btn setBordered:NO];
        [btn setImagePosition:NSImageOnly];
        [btnCell setBezelStyle:NSThickSquareBezelStyle];
        [btnCell setButtonType:NSSwitchButton];
        [btnCell setImageScaling:NSImageScaleAxesIndependently];
        [btn setTag:100 + row];
        [btn setTarget:self];
        [btn setAction:@selector(onShowChannel:)];
        
        if(bVisible)  [btn setState:NSOnState];
        
        [view addSubview:btn];
    }
    else if ([tableColumn.identifier isEqualToString:CHANANEL_INDENTIFIER_THUMBNAIL])
    {
        int channel = row;
        NSImage *thumbImage = [[[m_idDocument contents] activeLayer] thumbnailForChannel:channel];
        
        float fScreenScale = [[NSScreen mainScreen] backingScaleFactor];
        NSImage *imageBackground = [[[NSImage alloc] initWithSize:NSMakeSize(thumbImage.size.width, thumbImage.size.height)] autorelease];
        [imageBackground lockFocus];
        CGContextScaleCTM([[NSGraphicsContext currentContext] graphicsPort], 1/fScreenScale, 1/fScreenScale);
        [[NSColor colorWithPatternImage:[NSImage imageNamed:@"checkerboard1"]] set];
        NSRectFill(NSMakeRect(0, 0, thumbImage.size.width, thumbImage.size.height));
        [imageBackground unlockFocus];
        
        
        NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(thumbImage.size.width + 3, thumbImage.size.height + 3)] autorelease];
        [image lockFocus];
        
        CGContextSaveGState([[NSGraphicsContext currentContext] graphicsPort]);
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset: NSMakeSize(1, 1)];
        [shadow setShadowBlurRadius:2];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow set];
    
       
        [imageBackground drawInRect:NSMakeRect(0, 0, thumbImage.size.width * fScreenScale, thumbImage.size.height * fScreenScale) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:0 yBy:thumbImage.size.height];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform set];
        
//        CGContextDrawImage([[NSGraphicsContext currentContext] graphicsPort], NSRectToCGRect(NSMakeRect(0, 0, thumbImage.size.width, thumbImage.size.height)), [imageBackground CGImageForProposedRect:nil context:nil hints:nil]);
       
        
        
        CGContextRestoreGState([[NSGraphicsContext currentContext] graphicsPort]);
        [thumbImage drawInRect:NSMakeRect(0, 0, thumbImage.size.width, thumbImage.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        
        [image unlockFocus];
        
        NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(5, (rect.size.height - image.size.height)/2.0, image.size.width, image.size.height)] autorelease];
        [imageView setImage:image];
        
        [view addSubview:imageView];
        
    }
    else if ([tableColumn.identifier isEqualToString:CHANANEL_INDENTIFIER_NAME])
    {
        NSString *sText;
        if (row == 0)
            sText = NSLocalizedString(@"Red", nil);
        else if (row == 1)
            sText = NSLocalizedString(@"Green", nil);
        else if (row == 2)
            sText = NSLocalizedString(@"Blue", nil);
        else if (row == 3)
            sText = NSLocalizedString(@"Alpha", nil);
        else
            sText = NULL;
        
        NSTextField *textFieldChannel = [[[NSTextField alloc] initWithFrame:NSMakeRect(5, (rect.size.height - 14)/2.0, rect.size.width, 14)] autorelease];
        [textFieldChannel setTextColor:TEXT_COLOR];
        [textFieldChannel setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
        textFieldChannel.stringValue = sText;
        textFieldChannel.bordered = NO;
        textFieldChannel.backgroundColor = [NSColor clearColor];
        textFieldChannel.editable = NO;
        [textFieldChannel setRefusesFirstResponder:YES];
        
        [view addSubview:textFieldChannel];
    }
    return view;
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    if ([tableColumn.identifier isEqualToString:CHANANEL_INDENTIFIER_VISIBLE])
    {
        return NSLocalizedString(@"Show/Hide Channels", nil);
    }
    
    return @"";
}

#pragma mark ***** Notifications *****

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    BOOL redVisible1 = false;
    BOOL greenVisible1 = false;
    BOOL blueVisible1 = false;
    BOOL alphaVisible1 = false;
    
    NSIndexSet * selectedRows = [m_tableViewChannels selectedRowIndexes];
    NSUInteger idx = [selectedRows firstIndex];
    while (idx != NSNotFound)
    {
        // do work with "idx"
        //NSLog (@"The current index is %lu", idx);
        
        if (idx == 0)
        {
            redVisible1 = true;
        }
        else if (idx == 1)
        {
            greenVisible1 = true;
        }
        else if (idx == 2)
        {
            blueVisible1 = true;
        }
        else if (idx == 3)
        {
            alphaVisible1 = true;
        }
        // get the next index in the set
        idx = [selectedRows indexGreaterThanIndex:idx];
    }
    
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 1;
    BOOL redVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"redVisible" UTF8String]].nIntValue;
    BOOL greenVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"greenVisible" UTF8String]].nIntValue;
    BOOL blueVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"blueVisible" UTF8String]].nIntValue;
    BOOL alphaVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"alphaVisible" UTF8String]].nIntValue;
    
    
    if(redVisible1 == redVisible
       && (greenVisible1 == greenVisible)
       && (blueVisible1 == blueVisible)
       && (alphaVisible1 == alphaVisible))
        return;
    PARAMETER_VALUE value;
    value.nIntValue = redVisible1;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"redVisible" UTF8String]];
    value.nIntValue = greenVisible1;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"greenVisible" UTF8String]];
    value.nIntValue = blueVisible1;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"blueVisible" UTF8String]];
    value.nIntValue = alphaVisible1;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"alphaVisible" UTF8String]];
    
    [layer refreshTotalToRender];
    
    [m_tableViewChannels reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    
    
}

#pragma mark - tabView delegate
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem
{
    NSInteger nIndex = [tabView indexOfTabViewItem:tabViewItem];
    if(nIndex == 0)
    {
        [m_tableViewChannels deselectAll:nil]; //if has error
        PSLayer* layer = [[m_idDocument contents] activeLayer];
        PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
        int filterIndex = [filterManager getSmartFiltersCount] - 1;
        BOOL redVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"redVisible" UTF8String]].nIntValue;
        BOOL greenVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"greenVisible" UTF8String]].nIntValue;
        BOOL blueVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"blueVisible" UTF8String]].nIntValue;
        BOOL alphaVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"alphaVisible" UTF8String]].nIntValue;
        if (redVisible && greenVisible && blueVisible && alphaVisible) {
            return;
        }
        PARAMETER_VALUE value;
        value.nIntValue = 1;
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"redVisible" UTF8String]];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"greenVisible" UTF8String]];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"blueVisible" UTF8String]];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"alphaVisible" UTF8String]];
        [layer refreshTotalToRender];
    }
    else if (nIndex == 1)
    {
        [m_tableViewChannels reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    }
}


#pragma mark - actions
-(void)onShowChannel:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    int nRow = btn.tag - 100;
    
    
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 1;
    BOOL redVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"redVisible" UTF8String]].nIntValue;
    BOOL greenVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"greenVisible" UTF8String]].nIntValue;
    BOOL blueVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"blueVisible" UTF8String]].nIntValue;
    BOOL alphaVisible = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"alphaVisible" UTF8String]].nIntValue;

    if (nRow == 0)
    {
        redVisible = !redVisible;
    }
    else if (nRow == 1)
    {
        greenVisible = !greenVisible;
    }
    else if (nRow == 2)
    {
        blueVisible = !blueVisible;
    }
    else if (nRow == 3)
    {
        alphaVisible = !alphaVisible;
    }

    PARAMETER_VALUE value;
    value.nIntValue = redVisible;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"redVisible" UTF8String]];
    value.nIntValue = greenVisible;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"greenVisible" UTF8String]];
    value.nIntValue = blueVisible;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"blueVisible" UTF8String]];
    value.nIntValue = alphaVisible;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"alphaVisible" UTF8String]];
    
    [layer refreshTotalToRender];

}

-(void)updateUI
{
    [m_tableViewChannels reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    
}
@end
