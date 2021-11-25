//
//  PSLongTapButton.m
//  PixelStyle
//
//  Created by wyl on 16/3/10.
//
//

#import "PSLongTapButton.h"

#define LONG_TIME 3.0
@implementation PSLongTapButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initData];
}

-(id)init
{
    self = [super init];
    if(!self) return nil;
    
    [self initData];
    
    return self;
}

-(void)initData
{
    m_bTap = NO;
    
    m_delegate = nil;
    
    NSRect rect = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height);
    NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:rect options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited owner:self userInfo:nil] autorelease];
    [self addTrackingArea:trackingArea];
}

-(void)dealloc
{
    [super dealloc];
}

#pragma mark - Delegate
-(void)setDelegate:(id<PSLongTapButtonDelegate>)delegate
{
    m_delegate = delegate;
}

-(id<PSLongTapButtonDelegate>)delegate
{
    return m_delegate;
}

#pragma mark - Mouse Events
-(void)mouseDown:(NSEvent *)theEvent
{
    m_bTap = YES;
    m_dBeginTime = [NSDate timeIntervalSinceReferenceDate];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    double fCurTime = [NSDate timeIntervalSinceReferenceDate];
    if(m_bTap && (fCurTime - m_dBeginTime > LONG_TIME))
    {
        m_bTap = NO;
        
        if(m_delegate)
            [m_delegate longTapDelegate:self];
    }
}

-(void)mouseUp:(NSEvent *)theEvent
{
    double fCurTime = [NSDate timeIntervalSinceReferenceDate];
    if(m_bTap && (fCurTime - m_dBeginTime > LONG_TIME))
    {
        m_bTap = NO;
        [m_delegate longTapDelegate:self];
    }
}

-(void)mouseExited:(NSEvent *)theEvent
{
    m_bTap = NO;
}

@end
