//
//  PSSmartFilterUtility.m
//  PixelStyle
//
//  Created by lchzh on 3/3/16.
//
//

#import "PSSmartFilterUtility.h"

#import "PSLayer.h"
#import "PSSmartFilterManager.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSController.h"
#import "UtilitiesManager.h"

#import "PSFilterInfoNode.h"
#import "PSTextFieldCell.h"
#import "MyCustomedSliderCell.h"
#import "PSFilterColorWell.h"
#import "MyTableRowView.h"

#import "PSBrowserCell.h"
#import "PSScrollView.h"

#import "LayerSettings.h"
#import "PegasusUtility.h"

@implementation PSSmartFilterUtility

#define PS_FILTER_PBOARD_TYPE 	@"Effectmatrix Filter Pasteboard Type"

#define FILTER_PARASTEP 10
#define FILTER_PARACOUNT_MAX 100
#define FILTER_STEP 1000 // FILTER_PARASTEP * FILTER_PARACOUNT_MAX

#define FILTER_TITLE_HEIGHT 25
#define FILTER_BUTTON_SIZE 16

#define FILTER_PARA_VOFFSET 10
#define FILTER_PARA_INOFFSET 5

#define FILTER_PARATITLE_HEIGHT 20
#define FILTER_PARATITLE_WIDTH 100

#define FILTER_PARAFIELD_HEIGHT 20
#define FILTER_PARAFIELD_WIDTH 70

#define FILTER_SLIDER_HEIGHT 20
#define FILTER_SLIDER_WIDTH 170

#define FILTER_COLOR_HEIGHT 20
#define FILTER_COLOR_WIDTH 60

#define Effect_Height ([[NSScreen mainScreen] frame].size.height - 110 - 400)

-(void)awakeFromNib
{
    [[PSController utilitiesManager] setSmartFilterUtility:self  for:m_idDocument];
    [m_tableviewFilters setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
//    NSArray *views = [m_browserFilters subviews];
//    NSScrollView *view  = m_browserFilters.enclosingScrollView;
//    [view setBorderType:NSNoBorder];
    
    [m_browserFilters setAutohidesScroller:YES];
//    [m_browserFilters setBackgroundColor:[NSColor colorWithDeviceRed:0.3 green:0.3 blue:0.3 alpha:1.0]];
    NSColor *invertColor = [NSColor colorWithDeviceRed:0.97 green:0.97 blue:0.97 alpha:1.0];
    [m_browserFilters setBackgroundColor:invertColor];
    [m_browserFilters setCellClass:[PSBrowserCell class]];
    
    
    [m_tableviewFilters registerForDraggedTypes:[NSArray arrayWithObjects:PS_FILTER_PBOARD_TYPE, nil]];
    m_dragFiltersIndexSet = [[NSMutableIndexSet alloc] init];
    
    [m_btnAddEffects setTitle:NSLocalizedString(@"Add Effects", nil)];
    [m_btnFlattern setTitle:NSLocalizedString(@"Flattern", nil)];
    [m_btnOK setTitle:NSLocalizedString(@"OK", nil)];
    [m_btnCancel setTitle:NSLocalizedString(@"Cancel", nil)];
    
}

- (void)dealloc
{
    [m_tableviewFilters unregisterDraggedTypes];
    [m_dragFiltersIndexSet release];
    [super dealloc];
}

- (void)update
{
    [m_tableviewFilters reloadData];
    [self adjustPanelSize];
}

- (void)runWindow
{
    [NSApp runModalForWindow:m_idPanel];
    //[m_idPanel makeKeyAndOrderFront:NULL];
}


#pragma mark - filter show window event

- (IBAction)addButtonClicked:(id)sender
{
    [NSApp beginSheet:m_idFiltersPanel modalForWindow:m_idPanel modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
    //[m_idFiltersPanel runModalForWindow:m_idPanel];

}


- (IBAction)flatternButtonClicked:(id)sender
{
    [NSApp stopModal];
    [m_idPanel orderOut:self];
    [gColorPanel close];
    
    [[[[m_idDocument contents] activeLayer] getSmartFilterManager] filtersEditDidEnd];
    
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    [layer flatternSmartFilters];
    
    [[[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] layerSettings] updateEffectUI];
    
    
}

#pragma mark - filter choose window event

- (IBAction)cancelButtonClicked:(id)sender
{
    //[NSApp endSheet:m_idFiltersPanel];
    //[NSApp stopModal];
    [NSApp endSheet:m_idFiltersPanel];
    [m_idFiltersPanel orderOut:self];
}

- (IBAction)OKButtonClicked:(id)sender
{
    [NSApp endSheet:m_idFiltersPanel];
    [m_idFiltersPanel orderOut:self];
    
//    int column = [m_browserFilters selectedColumn];
//    int row = [m_browserFilters selectedRowInColumn:column];
    NSIndexPath *indexPath = [m_browserFilters selectionIndexPath];
    PSFilterInfoNode *node = [m_browserFilters itemAtIndexPath:indexPath];
    if (!node.isCatagory) {
        PSLayer* layer = [[m_idDocument contents] activeLayer];
        PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
        int filterIndex = [filterManager getSmartFiltersCount] - 2;
        [filterManager insertNewSmartFilter:node.name atIndex:filterIndex];
        [m_tableviewFilters reloadData];
        [layer refreshTotalToRender];
    }
    
    [self adjustPanelSize];
    
}

- (void)adjustPanelSize
{
    
    NSRect frame =  [m_idPanel frame];
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int count = [filterManager getSmartFiltersCount];
    float height = 0;
    for (int i = 0; i< count - 2; i++) {
        height += [m_tableviewFilters rectOfRow:i].size.height;
    }
    height = MIN(Effect_Height, height);
    frame.size.height = 400 + height;
    [(NSWindow*)m_idPanel setFrame:frame display:YES];
    
    frame = [m_scrollviewFilters frame];
    frame.size.height = height;
    [m_scrollviewFilters setFrame:frame];
}

#pragma mark - NSWindow delegate

- (void)windowWillClose:(NSNotification *)notification
{
    if (notification.object == m_idPanel) {
        [NSApp stopModal];
        [NSApp endSheet:m_idPanel];
        [m_idPanel orderOut:self];
    }
}

//- (void)windowDidResize:(NSNotification *)notification
//{
//    if (notification.object == m_idPanel) {
//        [self adjustPanelSize];
//    }
//}



#pragma mark - NSTableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    return [filterManager getSmartFiltersCount] - 2;
    
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    float height = 0;
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2 - row - 1;
    SMART_FILTER_INFO filterInfo = [filterManager getSmartFilterAtIndex:filterIndex];
    
    for (int i = 0; i < filterInfo.filterInfo.parametersCount; i++) {
        FILTER_PARAMETER_INFO praInfo = filterInfo.filterInfo.filterParameters[i];
        switch (praInfo.parameterType)
        {
            case V_FLOAT:{
                height += MAX(FILTER_SLIDER_HEIGHT, FILTER_PARATITLE_HEIGHT);
            }
                break;
                
            case V_INT:{
                height += MAX(FILTER_SLIDER_HEIGHT, FILTER_PARATITLE_HEIGHT);
            }
                break;
                
            case V_DWORDCOLOR:{
                height += MAX(FILTER_COLOR_HEIGHT, FILTER_PARATITLE_HEIGHT);
                
            }
                break;
            case V_CENTEROFFSET:{
                height += MAX(FILTER_SLIDER_HEIGHT, FILTER_PARATITLE_HEIGHT);
                height += FILTER_PARA_INOFFSET;
                height += MAX(FILTER_SLIDER_HEIGHT, FILTER_PARATITLE_HEIGHT);
            }
                break;
                
            default:
                break;
        }
        height += FILTER_PARA_VOFFSET;
    }
    
    height += FILTER_TITLE_HEIGHT;
    

    return height + 20;
}


#pragma mark - NSTableView delegate

//- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
//{
//    // Make the row view keep track of our main model object
//    MyTableRowView *result = [[MyTableRowView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, tableView.rowHeight)];
//    result.bDrawSperateLine = NO;
//    return [result autorelease];
//}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSRect rect = NSMakeRect(0, 0, [tableColumn width], [tableView rowHeight]);
    NSView *view  = [[[NSView alloc] initWithFrame:rect] autorelease];
    if ([tableColumn.identifier isEqualToString:@"FILTER_INFO"])
    {
        float height = 0;
        
        NSImage *sepLineImage = [NSImage imageNamed:@"filter_separator.png"];
        NSImageView *sepaLine = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, [tableColumn width], 2)] autorelease];
        [sepaLine setImageScaling:NSImageScaleAxesIndependently];
        [sepaLine setImage:sepLineImage];
        [view addSubview:sepaLine];
        height += 10;
        
        PSLayer* layer = [[m_idDocument contents] activeLayer];
        PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
        int filterIndex = [filterManager getSmartFiltersCount] - 2 - row - 1;
        SMART_FILTER_INFO filterInfo = [filterManager getSmartFilterAtIndex:filterIndex];
        
        for (int i = filterInfo.filterInfo.parametersCount - 1; i >= 0; i--)
        {
            FILTER_PARAMETER_INFO praInfo = filterInfo.filterInfo.filterParameters[i];
            
            NSTextField *titleField = [[[NSTextField alloc] initWithFrame:NSMakeRect(10, height, FILTER_PARATITLE_WIDTH, FILTER_PARATITLE_HEIGHT)] autorelease];
            [titleField setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 0];
            PSTextFieldLabelCell *tcell = [[PSTextFieldLabelCell alloc] init];
            [tcell setAlignment:NSTextAlignmentRight];
            [titleField setCell:tcell];
            [titleField setStringValue:[NSString stringWithFormat:@"%@:",NSLocalizedString([NSString stringWithUTF8String:praInfo.displayName], nil)]];
            [view addSubview:titleField];
            
            switch (praInfo.parameterType)
            {
                case V_FLOAT:{
                    
                    NSSlider *slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(130, height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [slider setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 1];
                    MyCustomedSliderCell *scell = [[MyCustomedSliderCell alloc] init];
                    [slider setCell:scell];
                    [slider setTarget:self];
                    [slider setAction:@selector(sliderChanged:)];
                    [slider setContinuous:YES];
                    if (praInfo.nValueEnable == 0x7) {
                        [slider setMaxValue:praInfo.maxValue.fFloatValue];
                        [slider setMinValue:praInfo.minValue.fFloatValue];
                    }
                    [slider setFloatValue:praInfo.value.fFloatValue];
                    [view addSubview:slider];
                    
                    NSTextField *editField = [[[NSTextField alloc] initWithFrame:NSMakeRect(320, height, FILTER_PARAFIELD_WIDTH, FILTER_PARAFIELD_HEIGHT)] autorelease];
                    [editField.cell setFont:[NSFont systemFontOfSize:11]];
                    [editField setFocusRingType:NSFocusRingTypeNone];
                    [editField setBordered:NO];
                    [editField setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 2];
                    [editField setDelegate:self];
                    [editField setEditable:YES];
                    [editField setEnabled:YES];
                    [editField setStringValue:[NSString stringWithFormat:@"%.2f", praInfo.value.fFloatValue]];
                    //[editField setFloatValue:praInfo.value.fFloatValue];
                    [view addSubview:editField];
                    
                    height += FILTER_SLIDER_HEIGHT;
                    
                }
                    break;
                    
                case V_INT:{
                    
                    NSSlider *slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(130, height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [slider setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 1];
                    MyCustomedSliderCell *scell = [[MyCustomedSliderCell alloc] init];
                    [slider setCell:scell];
                    [slider setTarget:self];
                    [slider setAction:@selector(sliderChanged:)];
                    [slider setContinuous:YES];
                    if (praInfo.nValueEnable == 0x7) {
                        [slider setMaxValue:praInfo.maxValue.nIntValue];
                        [slider setMinValue:praInfo.minValue.nIntValue];
                    }
                    [slider setIntValue:praInfo.value.nIntValue];
                    [view addSubview:slider];
                    
                    NSTextField *editField = [[[NSTextField alloc] initWithFrame:NSMakeRect(320, height, FILTER_PARAFIELD_WIDTH, FILTER_PARAFIELD_HEIGHT)] autorelease];
                    [editField.cell setFont:[NSFont systemFontOfSize:11]];
                    [editField setFocusRingType:NSFocusRingTypeNone];
                    [editField setBordered:NO];
                    [editField setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 2];
                    [editField setDelegate:self];
                    [editField setEditable:YES];
                    [editField setEnabled:YES];
                    [editField setStringValue:[NSString stringWithFormat:@"%d", praInfo.value.nIntValue]];
                    [view addSubview:editField];
                    
                    height += FILTER_SLIDER_HEIGHT;
                    
                    
                }
                    break;

                    
                case V_DWORDCOLOR:{
                    
                    PSFilterColorWell *well = [[[PSFilterColorWell alloc] initWithFrame:NSMakeRect(130, height, FILTER_COLOR_WIDTH, FILTER_COLOR_HEIGHT) delegate:self] autorelease];
                    [well setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 1];
                    
                    NSColor *color = [self makeNSColorFromColor4Value:praInfo.value];
                    [well changeUIColor:color];
                    [view addSubview:well];
                    
                    height += FILTER_COLOR_HEIGHT;
                    
                }
                    break;
                    
                case V_CENTEROFFSET:{
                    
                    NSRect frame = [titleField frame];
                    frame.origin.y += FILTER_PARAFIELD_HEIGHT + FILTER_PARA_INOFFSET;
                    [titleField setFrame:frame];
                    
                    NSSlider *slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(130, height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [slider setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 1];
                    MyCustomedSliderCell *scell = [[MyCustomedSliderCell alloc] init];
                    [slider setCell:scell];
                    [slider setTarget:self];
                    [slider setAction:@selector(sliderChanged:)];
                    [slider setContinuous:YES];
                    [slider setMaxValue:1.0];
                    [slider setMinValue:0.0];
                    [slider setFloatValue:praInfo.value.fOffsetXY[0]];
                    [view addSubview:slider];
                    
                    NSTextField *editField = [[[NSTextField alloc] initWithFrame:NSMakeRect(320, height, FILTER_PARAFIELD_WIDTH, FILTER_PARAFIELD_HEIGHT)] autorelease];
                    [editField.cell setFont:[NSFont systemFontOfSize:11]];
                    [editField setFocusRingType:NSFocusRingTypeNone];
                    [editField setBordered:NO];
                    [editField setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 2];
                    [editField setDelegate:self];
                    [editField setEditable:YES];
                    [editField setEnabled:YES];
                    [editField setStringValue:[NSString stringWithFormat:@"%.2f", praInfo.value.fOffsetXY[0]]];
                    [view addSubview:editField];
                    
                    height += FILTER_PARAFIELD_HEIGHT;
                    height += FILTER_PARA_INOFFSET;
                    
                    slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(130, height, FILTER_SLIDER_WIDTH, FILTER_SLIDER_HEIGHT)] autorelease];
                    [slider setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 3];
                    scell = [[MyCustomedSliderCell alloc] init];
                    [slider setCell:scell];
                    [slider setTarget:self];
                    [slider setAction:@selector(sliderChanged:)];
                    [slider setContinuous:YES];
                    [slider setMaxValue:1.0];
                    [slider setMinValue:0.0];
                    [slider setFloatValue:praInfo.value.fOffsetXY[1]];
                    [view addSubview:slider];
                    
                    editField = [[[NSTextField alloc] initWithFrame:NSMakeRect(320, height, FILTER_PARAFIELD_WIDTH, FILTER_PARAFIELD_HEIGHT)] autorelease];
                    [editField.cell setFont:[NSFont systemFontOfSize:11]];
                    [editField setFocusRingType:NSFocusRingTypeNone];
                    [editField setBordered:NO];
                    [editField setTag:filterIndex * FILTER_STEP + i * FILTER_PARASTEP + 4];
                    [editField setDelegate:self];
                    [editField setEditable:YES];
                    [editField setEnabled:YES];
                    [editField setStringValue:[NSString stringWithFormat:@"%.2f", praInfo.value.fOffsetXY[1]]];
                    [view addSubview:editField];
                    
                    height += FILTER_PARAFIELD_HEIGHT;
                    
                }
                    break;
                    
                default:
                    break;
            }
            
            height += FILTER_PARA_VOFFSET;
        }
        
        
        NSTextField *titleField = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, height, 250, FILTER_TITLE_HEIGHT)] autorelease];
        PSTextFieldLabelCell *tcell = [[PSTextFieldLabelCell alloc] init];
        [titleField setCell:tcell];
        [titleField setFont:[NSFont systemFontOfSize:13]];
        [titleField setStringValue:NSLocalizedString(filterInfo.filterName, nil)];
//        [titleField setStringValue:filterInfo.filterName];
        [view addSubview:titleField];
        
        NSButton *enableButton = [[[NSButton alloc] initWithFrame:NSMakeRect(350, height, FILTER_BUTTON_SIZE, FILTER_BUTTON_SIZE)] autorelease];
        [enableButton setTag:filterIndex];
        [enableButton setBordered:NO];
        [enableButton setButtonType:NSMomentaryChangeButton];
        [enableButton setTarget:self];
        [enableButton setAction:@selector(enableButtonClicked:)];
        [(NSButtonCell*)enableButton.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
        if (filterInfo.isEnable) {
            [enableButton setImage:[NSImage imageNamed:@"filter_enable.png"]];
        }else{
            [enableButton setImage:[NSImage imageNamed:@"filter_disable.png"]];
        }
        [view addSubview:enableButton];
        
        NSButton *resetButton = [[[NSButton alloc] initWithFrame:NSMakeRect(375, height, FILTER_BUTTON_SIZE, FILTER_BUTTON_SIZE)] autorelease];
        [resetButton setTag:filterIndex];
        [resetButton setBordered:NO];
        [resetButton setButtonType:NSMomentaryChangeButton];
        [resetButton setTarget:self];
        [resetButton setAction:@selector(resetButtonClicked:)];
        [(NSButtonCell*)resetButton.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
        [resetButton setImage:[NSImage imageNamed:@"filter_reset.png"]];
        [view addSubview:resetButton];
        
        NSButton *deleteButton = [[[NSButton alloc] initWithFrame:NSMakeRect(400, height, FILTER_BUTTON_SIZE, FILTER_BUTTON_SIZE)] autorelease];
        [deleteButton setTag:filterIndex];
        [deleteButton setBordered:NO];
        [deleteButton setButtonType:NSMomentaryChangeButton];
        [deleteButton setTarget:self];
        [deleteButton setAction:@selector(deleteButtonClicked:)];
        [(NSButtonCell*)deleteButton.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
        [deleteButton setImage:[NSImage imageNamed:@"filter_delete.png"]];
        [view addSubview:deleteButton];
        
    }
    
    return view;
}

#pragma mark - filter parameter changed event

- (PARAMETER_VALUE)makeColor4ValueFromNSColor:(NSColor *)color
{
    PARAMETER_VALUE value;
    int red = color.redComponent * 255;
    int green = color.greenComponent * 255;
    int blue = color.blueComponent * 255;
    int alpha = color.alphaComponent * 255;
    value.nUnsignedValue = ( red| (green<<8) | (blue<<16) | (alpha<<24));
    return value;
}

- (NSColor*)makeNSColorFromColor4Value:(PARAMETER_VALUE)value
{
    unsigned int nUnsignedValue = value.nUnsignedValue;
    int red = nUnsignedValue & 0xFF;
    int green = (nUnsignedValue >> 8) & 0xFF;
    int blue = (nUnsignedValue >> 16) & 0xFF;
    int alpha = nUnsignedValue >> 24;
    return [NSColor colorWithCalibratedRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha / 255.0];
}


//colorWellClicked event
- (void)setColor:(NSColor*)color colorWell:(NSColorWell*)well
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [well tag] / FILTER_STEP;
    int paraIndex = ([well tag] % FILTER_STEP) / FILTER_PARASTEP;
    PARAMETER_VALUE value = [self makeColor4ValueFromNSColor:color];
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterIndex:paraIndex];
    
    [layer refreshTotalToRender];
}

- (void)sliderChanged:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [sender tag] / FILTER_STEP;
    int paraIndex = ([sender tag] % FILTER_STEP) / FILTER_PARASTEP;
    FILTER_PARAMETER_INFO paraInfo = [filterManager getSmartFilterParameterInfo:filterIndex parameterIndex:paraIndex];
    
    PARAMETER_VALUE value;
    switch (paraInfo.parameterType) {
        case V_FLOAT:{
            value.fFloatValue = [(NSSlider*)sender floatValue];
        }
            break;
        case V_INT:{
            value.nIntValue = [(NSSlider*)sender intValue];
        }
            break;
        case V_CENTEROFFSET:{
            value = paraInfo.value;
            float realValue = [(NSSlider*)sender floatValue];
            int index = [sender tag] - FILTER_STEP * filterIndex - FILTER_PARASTEP * paraIndex;
            if (index == 1) {
                value.fOffsetXY[0] = realValue;
            }else if (index == 3){
                value.fOffsetXY[1] = realValue;
            }
        }
            break;
            
        default:
            break;
    }
    
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterIndex:paraIndex];
    int row = [filterManager getSmartFiltersCount] - 2 - filterIndex - 1;
    NSView *rowView = [m_tableviewFilters viewAtColumn:0 row:row makeIfNecessary:NO];
    NSArray *subViews = [rowView subviews];
    for (int i = 0; i < [subViews count]; i++) {
        NSView *tempView = [subViews objectAtIndex:i];
        if ([tempView tag] == [sender tag] + 1 && [tempView isKindOfClass:[NSTextField class]])
        {
            switch (paraInfo.parameterType) {
                case V_INT:{
                    [(NSTextField*)tempView setIntValue:value.nIntValue];
                }
                    break;
                    
                case V_FLOAT:{
                    [(NSTextField*)tempView setStringValue:[NSString stringWithFormat:@"%.2f", value.fFloatValue]];
                }
                    break;
                case V_CENTEROFFSET:{
                    int index = [sender tag] - FILTER_STEP * filterIndex - FILTER_PARASTEP * paraIndex;
                    if (index == 1) {
                        [(NSTextField*)tempView setStringValue:[NSString stringWithFormat:@"%.2f", value.fOffsetXY[0]]];
                    }else if (index == 3){
                        [(NSTextField*)tempView setStringValue:[NSString stringWithFormat:@"%.2f", value.fOffsetXY[1]]];
                    }
                    
                }
                    break;
                    
                default:
                    break;
            }

        }
    }
    
    SEL sel = @selector(refreshTotalToRenderInThread);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
     sel object: nil];
    //[self performSelector: sel withObject: nil afterDelay: 0.05];
    [self performSelector:sel withObject:nil afterDelay:0.05 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];
    
    //[layer refreshTotalToRender];
}

- (void)refreshTotalToRenderInThread
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    [layer refreshTotalToRender];
}

#pragma mark - nstextfield delegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [textField tag] / FILTER_STEP;
    int paraIndex = ([textField tag] % FILTER_STEP) / FILTER_PARASTEP;
    
    PARAMETER_VALUE value;
    FILTER_PARAMETER_INFO paraInfo = [filterManager getSmartFilterParameterInfo:filterIndex parameterIndex:paraIndex];
    switch (paraInfo.parameterType) {
        case V_INT:{
            int realValue = [textField intValue];
            if (paraInfo.nValueEnable == 0x7) {
                realValue = MAX(paraInfo.minValue.nIntValue, MIN(paraInfo.maxValue.nIntValue, realValue));
            }
            value.nIntValue = realValue;
            [textField setIntValue:realValue];
        }
            break;
            
        case V_FLOAT:{
            float realValue = [textField floatValue];
            if (paraInfo.nValueEnable == 0x7) {
                realValue = MAX(paraInfo.minValue.fFloatValue, MIN(paraInfo.maxValue.fFloatValue, realValue));
            }
            value.fFloatValue = realValue;
            [textField setStringValue:[NSString stringWithFormat:@"%.2f", value.fFloatValue]];
        }
            break;
            
        case V_CENTEROFFSET:{
            value = paraInfo.value;
            float realValue = [textField floatValue];
            int index = [textField tag] - FILTER_STEP * filterIndex - FILTER_PARASTEP * paraIndex;
            if (index == 2) {
                value.fOffsetXY[0] = realValue;
            }else if (index == 4){
                value.fOffsetXY[1] = realValue;
            }
            [textField setStringValue:[NSString stringWithFormat:@"%.2f", value.fFloatValue]];
        }
            break;
            
        default:
            break;
    }
    
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterIndex:paraIndex];
    int row = [filterManager getSmartFiltersCount] - 2 - filterIndex - 1;
    NSView *rowView = [m_tableviewFilters viewAtColumn:0 row:row makeIfNecessary:NO];
    NSArray *subViews = [rowView subviews];
    for (int i = 0; i < [subViews count]; i++) {
        NSView *tempView = [subViews objectAtIndex:i];
        if ([tempView tag] == [textField tag] - 1 && [tempView isKindOfClass:[NSSlider class]])
        {
            switch (paraInfo.parameterType) {
                case V_INT:
                    [(NSSlider*)tempView setIntValue:value.nIntValue];
                    break;
                case V_FLOAT:
                    [(NSSlider*)tempView setFloatValue:value.fFloatValue];
                    break;
                case V_CENTEROFFSET:{
                    int index = [textField tag] - FILTER_STEP * filterIndex - FILTER_PARASTEP * paraIndex;
                    if (index == 2) {
                        [(NSSlider*)tempView setFloatValue:value.fOffsetXY[0]];
                    }else if (index == 4){
                        [(NSSlider*)tempView setFloatValue:value.fOffsetXY[1]];
                    }
                    
                }
                    break;
                    
                default:
                    break;
            }
        }
    }
    
    SEL sel = @selector(refreshTotalToRenderInThread);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
     sel object: nil];
    //[self performSelector: sel withObject: nil afterDelay: 0.05];
    [self performSelector:sel withObject:nil afterDelay:0.05 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];
    
    
    return YES;
}



#pragma mark - tableview event

- (void)enableButtonClicked:(NSButton*)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = sender.tag;
    SMART_FILTER_INFO filterInfo = [filterManager getSmartFilterAtIndex:filterIndex];
    filterInfo.isEnable = !filterInfo.isEnable;
    if (filterInfo.isEnable) {
        [sender setImage:[NSImage imageNamed:@"filter_enable.png"]];
    }else{
        [sender setImage:[NSImage imageNamed:@"filter_disable.png"]];
    }
    [filterManager setSmartFilter:filterInfo AtIndex:filterIndex];
    
    [m_tableviewFilters reloadData];
    [layer refreshTotalToRender];
}

- (void)resetButtonClicked:(NSButton*)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    
    int filterIndex = sender.tag;
    [filterManager resetSmartFilter:filterIndex];
    
    int row = [filterManager getSmartFiltersCount] - 2 - filterIndex - 1;
    [m_tableviewFilters reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]  columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    //[m_tableviewFilters reloadData];
    
    [layer refreshTotalToRender];
    
}

- (void)deleteButtonClicked:(NSButton*)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = sender.tag;
    [filterManager removeSmartFilter:filterIndex];
    
    [m_tableviewFilters reloadData];
    [layer refreshTotalToRender];
    
    [self adjustPanelSize];
}



#pragma mark - NSBrowserView delegate

// This method is optional, but makes the code much easier to understand
- (id)rootItemForBrowser:(NSBrowser *)browser {
    if (m_rootNode == nil) {
        m_rootNode = [[PSFilterInfoNode alloc] initWithName:@"RootNode" isCatagory:YES];
    }
    return m_rootNode;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
    PSFilterInfoNode *node = (PSFilterInfoNode *)item;
    return node.children.count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
    PSFilterInfoNode *node = (PSFilterInfoNode *)item;
    return [node.children objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item {
    PSFilterInfoNode *node = (PSFilterInfoNode *)item;
    return !node.isCatagory;
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
    PSFilterInfoNode *node = (PSFilterInfoNode *)item;
    NSAttributedString *string = [[[NSAttributedString alloc] initWithString:NSLocalizedString(node.name, nil) attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:11],NSForegroundColorAttributeName:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.8]}] autorelease];
//    NSAttributedString *string = [[[NSAttributedString alloc] initWithString:node.name attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:11],NSForegroundColorAttributeName:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.8]}] autorelease];
    return string;
}

- (CGFloat)browser:(NSBrowser *)browser heightOfRow:(NSInteger)row inColumn:(NSInteger)columnIndex
{
    return 20;
}

- (void)browser:(NSBrowser *)browser willDisplayCell:(PSBrowserCell *)cell atRow:(NSInteger)row column:(NSInteger)column {
    //NSLog(@"willDisplayCell");
    // Find the item and set the image.
    NSIndexPath *indexPath = [browser indexPathForColumn:column];
    indexPath = [indexPath indexPathByAddingIndex:row];
    PSFilterInfoNode *node = [browser itemAtIndexPath:indexPath];
    cell.node = node;
    
}


#pragma mark - nstableview  drag drop delegate



- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    int index = [m_dragFiltersIndexSet firstIndex];
    if (index != NSNotFound) {
        //NSLog(@"tableView %d %ld",index,row);
        
        PSLayer* layer = [[m_idDocument contents] activeLayer];
        PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
        int filterIndexFrom = [filterManager getSmartFiltersCount] - 2 - index - 1;
        int filterIndexTo = [filterManager getSmartFiltersCount] - 2 - row - 1;
        if (filterIndexFrom > filterIndexTo) {
            filterIndexTo++;
        }
        [filterManager moveSmartFilterFrom:filterIndexFrom to:filterIndexTo];
        [m_tableviewFilters reloadData];
        [layer refreshTotalToRender];
    }
    [m_dragFiltersIndexSet removeAllIndexes];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    [m_dragFiltersIndexSet removeAllIndexes];
    [m_dragFiltersIndexSet addIndexes:rowIndexes];
    
    [pboard setData:[NSData data] forType:PS_FILTER_PBOARD_TYPE];
    return YES;
}

@end
