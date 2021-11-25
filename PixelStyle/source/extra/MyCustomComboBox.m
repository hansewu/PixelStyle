//
//  MyCustomComboBox.m
//  PixelStyle
//
//  Created by wyl on 15/11/21.
//
//

#import "MyCustomComboBox.h"
#import "MyCustomPanel.h"
#import "MyCustomedSliderCell.h"
#import "ConfigureInfo.h"

@interface MyCustomComboBox()<NSTextFieldDelegate, MyCustomPanelDelegate>
{
    NSImageView *m_imageViewRight;
    NSSlider *m_slider;
    NSTextField *m_textField;
    NSButton *m_btn;
    MyCustomPanel *m_customPanel;
}

-(void)onBtn:(id)sender;
-(void)onSlider:(id)sender;

@end

@implementation MyCustomComboBox

//-(void)awakeFromNib
//{
//    [self initView];
//    //NSLog(@"MyCustomComboBox awakeFromNib");
//}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initView];
    }
    return self;
}

-(void)initView
{
    NSImageView *imageLeft = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 4, self.frame.size.height)] autorelease];
    [imageLeft setImage:[NSImage imageNamed:@"box-left"]];
    [imageLeft setImageScaling:NSImageScaleAxesIndependently];
    [imageLeft setAutoresizingMask:NSViewMaxXMargin| NSViewHeightSizable];
    [self addSubview:imageLeft];
    
    m_imageViewRight = [[NSImageView alloc] initWithFrame:NSMakeRect(self.frame.size.width-18, 0, 18, self.frame.size.height)];
    [m_imageViewRight setImage:[NSImage imageNamed:@"box-right"]];
    [m_imageViewRight setImageScaling:NSImageScaleAxesIndependently];
    [m_imageViewRight setAutoresizingMask:NSViewMinXMargin| NSViewHeightSizable];
    [self addSubview:m_imageViewRight];
    
    NSImageView *imageMiddle = [[[NSImageView alloc] initWithFrame:NSMakeRect(4, 0, self.frame.size.width-22, self.frame.size.height)] autorelease];
    [imageMiddle setImage:[NSImage imageNamed:@"box-midle"]];
    [imageMiddle setImageScaling:NSImageScaleAxesIndependently];
    [imageMiddle setAutoresizingMask:NSViewWidthSizable| NSViewHeightSizable];
    [self addSubview:imageMiddle];
    
    
    m_btn = [[NSButton alloc] initWithFrame:NSMakeRect(self.frame.size.width-18, 0, 18, self.frame.size.height)];
    [m_btn setImage:[NSImage imageNamed:@"box-down-arrow"]];
    [m_btn setAlternateImage:[NSImage imageNamed:@"box-down-arrow"]];
    [m_btn setBezelStyle:NSThickSquareBezelStyle];
    [m_btn setBordered:NO];
    [m_btn setButtonType:NSSwitchButton];
    [m_btn setImagePosition:NSImageOnly];
    NSButtonCell *btnCell = [m_btn cell];
    [btnCell setImageScaling:NSImageScaleAxesIndependently];
    [m_btn setAutoresizingMask:NSViewMinXMargin| NSViewHeightSizable];
    [m_btn setTarget:self];
    [m_btn setAction:@selector(onBtn:)];
    
    [self addSubview:m_btn];
    
    
    m_textField = [[NSTextField alloc] initWithFrame:NSMakeRect(2, (self.frame.size.height - 20)/2.0 - 4, self.frame.size.width-22, self.frame.size.height)];
    //[m_textField setLineBreakMode:NSLineBreakByCharWrapping];
    [[m_textField cell] setLineBreakMode:NSLineBreakByCharWrapping];
    [m_textField setBezeled:YES];
    [m_textField setBordered:NO];
    [m_textField setDrawsBackground:NO];
    [m_textField setFocusRingType:NSFocusRingTypeNone];
    [m_textField setTextColor:TEXT_COLOR];
    [m_textField setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
    [m_textField setAlignment:NSTextAlignmentLeft];
    m_textField.delegate = self;
    [self addSubview:m_textField];
//    [m_textField setMaximumNumberOfLines:1];
    
//    NSWindow
    m_customPanel = [[MyCustomPanel alloc] initWithContentRect:NSMakeRect(0, 0, 148, 34) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:NULL];
    [m_customPanel setBackgroundColor:[NSColor clearColor]];
    [m_customPanel setOpaque:NO];
    [m_customPanel setCustomDelegate:self];
    
    NSImageView *imageViewBg = [[[NSImageView alloc] initWithFrame:m_customPanel.contentView.bounds] autorelease];
    [imageViewBg setImage:[NSImage imageNamed:@"pop-view-bg"]];
    [imageViewBg setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [imageViewBg setImageScaling:NSImageScaleAxesIndependently];
    [m_customPanel.contentView addSubview:imageViewBg];
    
    
    MyCustomedSliderCell *myCustomSliderCell = [[[MyCustomedSliderCell alloc] init] autorelease];
    
    m_slider = [[NSSlider alloc] initWithFrame:NSMakeRect(14, (m_customPanel.frame.size.height - 14)/2.0, 120, 14)];
    [m_slider setCell:myCustomSliderCell];
    [[m_slider cell] setControlSize:NSMiniControlSize];
    [m_slider setAutoresizingMask:NSViewWidthSizable];
    [m_slider setTarget:self];
    [m_slider setAction:@selector(onSlider:)];
    [m_customPanel.contentView addSubview:m_slider];
}

-(void)dealloc
{
    [m_imageViewRight release];
    [m_btn release];
    [m_textField release];
    [m_customPanel release];
    [m_slider release];
    
    [super dealloc];
}

#pragma mark - actions
- (void)setDelegate:(nullable id <MyCustomComboBoxDelegate>)delegate;
{
    m_delegate = delegate;
}

-(void)setEnabled:(BOOL)bEnable
{
    [m_btn setEnabled:bEnable];
    [m_textField setEnabled:bEnable];
    
    
}

-(void)setSliderMaxValue:(float)fValue
{
    if (m_slider)
        [m_slider setMaxValue:fValue];
}

-(void)setSliderMinValue:(float)fValue
{
    if (m_slider)
        [m_slider setMinValue:fValue];
}

-(float)getSliderMaxValue
{
    if (m_slider)
        return [m_slider maxValue];
    return 1.0;
}

-(float)getSliderMinValue
{
    if (m_slider)
        return [m_slider minValue];
    return 0.0;
}

-(void)setStringValue:(NSString *)sValue
{
    [m_textField setStringValue:sValue];
    [m_slider setFloatValue:[m_textField floatValue]];
}

-(NSString *)getStringValue
{
    return [m_textField stringValue];
}

-(void)onBtn:(id)sender
{
    [m_btn setImage:[NSImage imageNamed:@"box-up-arrow"]];
    [m_btn setAlternateImage:[NSImage imageNamed:@"box-up-arrow"]];
    
    [m_imageViewRight setImage:[NSImage imageNamed:@"box-right-a"]];
    
    NSButton *btn = (NSButton *)sender;
    NSRect frame = NSMakeRect(btn.frame.origin.x - 126, btn.frame.origin.y - 32, 148, 34);
    
    NSDocument *currentDoucemnt = [[NSDocumentController sharedDocumentController] currentDocument];
    NSWindow *window = [currentDoucemnt window];
    frame = [self convertRect:frame toView:[window contentView]];
    frame.origin = NSMakePoint(frame.origin.x + window.frame.origin.x, frame.origin.y + window.frame.origin.y);
    [m_customPanel showPanel:frame];
}

-(void)onSlider:(id)sender
{
    [m_textField setFloatValue:m_slider.floatValue];
    
    [m_delegate valueDidChange:self value:[NSString stringWithFormat:@"%f",m_slider.floatValue]];
}

#pragma mark - TextField delegate - 
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    float fValue = [textField floatValue];
    
    
    if(fValue < [(NSSlider *)m_slider minValue]) fValue = [(NSSlider *)m_slider minValue];
    else if (fValue > [(NSSlider *)m_slider maxValue]) fValue = [(NSSlider *)m_slider maxValue];
    
    [textField setFloatValue:fValue];
    [m_slider setFloatValue:fValue];
    
    [m_delegate valueDidChange:self value:[NSString stringWithFormat:@"%f",m_slider.floatValue]];
   
    
    return YES;//[delegate control:control textShouldBeginEditing:fieldEditor];
}

#pragma mark - MyCustomView delegate -

-(void)panelDidDismiss:(NSNotification *)notification
{
    MyCustomPanel *customPanel = [notification object];
    if(customPanel == m_customPanel)
    {
        [m_btn setImage:[NSImage imageNamed:@"box-down-arrow"]];
        [m_btn setAlternateImage:[NSImage imageNamed:@"box-down-arrow"]];
        [m_imageViewRight setImage:[NSImage imageNamed:@"box-right"]];
    }
}

@end
