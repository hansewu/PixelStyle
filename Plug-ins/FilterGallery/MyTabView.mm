#import "MyTabView.h"
#import "MyTabCell.h"
#import "AImageFilter.h"

@implementation MyTabView

-(id)initWithFrame:(NSRect)frameRect  ItemCount:(int)count
{
    if(self = [super initWithFrame:frameRect])
    {
        segmentedControl = [[NSSegmentedControl alloc] init];
        [segmentedControl setCell:[[[MyTabCell alloc] init] autorelease]];
        [segmentedControl setSegmentCount:count];//self.numberOfTabViewItems;
        [segmentedControl setTarget:self];
        [segmentedControl setAction:@selector(ctrlSelected:)];
        [segmentedControl setSelectedSegment:0];
        [segmentedControl setSegmentStyle:NSSegmentStyleTexturedSquare];
        [self setTabViewType:NSNoTabsNoBorder];
        [segmentedControl setAutoresizingMask:NSViewMaxYMargin];
        [self addSubview:segmentedControl];
        [self setDrawsBackground:NO];
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithDeviceRed:60.0 / 255 green:60.0 / 255 blue:60.0 / 255 alpha:1].CGColor;
    }
    return  self;
}

-(void)initialSegmentControl
{
    [self setLabelToSegmentedControl];
    [self setSetmentControlFrame];
}

-(void)setSetmentControlFrame
{
    float fTotalWidth = 0.0;
    for(int i = 0; i < segmentedControl.segmentCount; i++)
    {
        fTotalWidth += [self calcSegmentWidth:i];
    }
    [segmentedControl setFrame:NSMakeRect(0, 0, fTotalWidth, fHeightOfTabScrollView)];
}

-(float)calcSegmentWidth:(int)segment
{
    NSString* label = [segmentedControl labelForSegment:segment];
    NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    style.alignment = NSTextAlignmentCenter;
    NSDictionary * attr = @{NSParagraphStyleAttributeName : style, NSForegroundColorAttributeName : [NSColor colorWithWhite:1.0 alpha:1.0], NSFontAttributeName : [NSFont fontWithName:@"Helvetica" size:15]};
    NSAttributedString* attrLabel = [[[NSAttributedString alloc] initWithString:label attributes:attr]autorelease];
    NSSize size = [attrLabel size];
    [segmentedControl setWidth:size.width + 23 forSegment:segment];
    return size.width + 23;
}

-(void)setLabelToSegmentedControl
{
    for (int i=0; i < self.numberOfTabViewItems; i++) {
        [segmentedControl  setLabel:[self tabViewItemAtIndex:i].label forSegment:i];
    }
}

//- (NSSize)minimumSize {
//    return NSMakeSize(0, barImage.size.height);
//}

//- (NSRect)contentRect {
//    return NSMakeRect(0, barImage.size.height, self.frame.size.width, self.frame.size.height-barImage.size.height);
//}


-(void)ctrlSelected:(NSSegmentedControl *)sender {
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    animation.duration = 0.5;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.fromValue = [NSNumber numberWithFloat:segmentedControl.layer.position.x];
    
    float fWidth = 0.0;
    for (int i = 0; i < [segmentedControl segmentCount]; i++) {
        fWidth += [segmentedControl widthForSegment:i];
    }
    float stepWidth = (fWidth - self.frame.size.width);
    int nIndex = (int)[sender selectedSegment];
    [super selectTabViewItemAtIndex:[sender selectedSegment]];
    float fWidthOfSelected = 0.0;
    for (int i = 0; i < nIndex; i++) {
        fWidthOfSelected += [segmentedControl widthForSegment:i];
    }
    int nCount = -segmentedControl.frame.origin.x / stepWidth;

    fWidthOfSelected -= nCount * stepWidth;
    
    if(nCount > 0 && fWidthOfSelected < self.frame.size.width / 3)
    {
        segmentedControl.frame = NSMakeRect(segmentedControl.frame.origin.x + stepWidth, segmentedControl.frame.origin.y, segmentedControl.frame.size.width, segmentedControl.frame.size.height);
    }
    if(nCount == 0 && fWidthOfSelected > self.frame.size.width * 2 / 3 && fWidthOfSelected < self.frame.size.width)
    {
        segmentedControl.frame = NSMakeRect(segmentedControl.frame.origin.x - stepWidth, segmentedControl.frame.origin.y, segmentedControl.frame.size.width, segmentedControl.frame.size.height);
    }
    
    animation.toValue = [NSNumber numberWithFloat:segmentedControl.layer.position.x ];
    [segmentedControl.layer addAnimation:animation forKey:@"positon.x"];
}

#pragma mark segment control and tabview sync methods

-(void)selectTabViewItem:(NSTabViewItem *)tabViewItem {
    [super selectTabViewItem:tabViewItem];
    [segmentedControl setSelectedSegment:[self indexOfTabViewItem:[self selectedTabViewItem]]];
    [(MyTabCell*)segmentedControl.cell setHighlightedSegment:[self indexOfTabViewItem:[self selectedTabViewItem]]];
}

-(void)selectTabViewItemAtIndex:(NSInteger)index {
    [super selectTabViewItemAtIndex:index];
    
    [segmentedControl setSelectedSegment:[self indexOfTabViewItem:[self selectedTabViewItem]]];
}

-(void)selectTabViewItemWithIdentifier:(id)identifier {
    [super selectTabViewItemWithIdentifier:identifier];
    
    [segmentedControl setSelectedSegment:[self indexOfTabViewItem:[self selectedTabViewItem]]];    
}
// skipping selectNext/PreviousTabViewItem - hoping they use above.

-(void)addTabViewItem:(NSTabViewItem *)anItem {
   [super addTabViewItem:anItem];
   [self awakeFromNib];
   [self setNeedsDisplay:YES];
}

-(void)removeTabViewItem:(NSTabViewItem *)anItem {
   [super removeTabViewItem:anItem];
   [self awakeFromNib];
   [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}
@end
