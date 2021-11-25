//
//  MyBrushDrawView.m
//  PixelStyle
//
//  Created by wyl on 15/9/10.
//
//

#import "MyBrushDrawView.h"
#import "MyBrushUtility.h"
#import "ipaintapi.h"

#define CELL_HEIGHT 64
#define CELL_WIDTH 64

@implementation MyBrushDrawView

- (id)initWithMaster:(id)sender
{
    if (![super init])
        return NULL;
    
    m_idMaster = sender;
    [self initData];
    
    return self;
}


-(void)initData
{
    m_mdCellBuffer = [[NSMutableDictionary alloc] init];

    m_hCanvas = IP_CreateCanvas();
    IP_SetContext(m_hCanvas, self);
}

- (void)dealloc
{
    if(m_hCanvas) IP_DestroyCanvas(m_hCanvas);
    if(m_mdCellBuffer) [m_mdCellBuffer release];
    
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    [[NSColor whiteColor] set];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, self.frame.size.width, 115) xRadius:3.0 yRadius:3.0];
    [path fill];
   
    
    [self renderCells:context];
}

-(void)renderCells:(CGContextRef)context
{
    NSEnumerator * enumerator = [m_mdCellBuffer keyEnumerator];
    NSString *sKey;
    //遍历输出
    while(sKey = [enumerator nextObject])
    {
        NSData *data = [m_mdCellBuffer objectForKey:sKey];
        if (data)
        {
            unsigned char *pCellBuf = (unsigned char *)[data bytes];
            CGColorSpaceRef defaultColorSpace = CGColorSpaceCreateDeviceRGB();
            CGDataProviderRef dataProvider = CGDataProviderCreateWithData(self, pCellBuf, CELL_WIDTH * CELL_HEIGHT * 4, NULL);
            assert(dataProvider);
            CGImageRef cgImage = CGImageCreate(CELL_WIDTH, CELL_HEIGHT, 8, 8*4, CELL_WIDTH * 4, defaultColorSpace, kCGImageAlphaLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
            assert(cgImage);
            
            NSArray *array = [sKey componentsSeparatedByString:@"="];
            int nCellX = [[array objectAtIndex:1] intValue];
            int nCellY = [[array objectAtIndex:2] intValue];
            CGRect rect = CGRectMake(nCellX * CELL_WIDTH, self.frame.size.height - (nCellY+1) * CELL_HEIGHT, CELL_WIDTH, CELL_HEIGHT);
            CGContextDrawImage(context, rect, cgImage);
            
            CGImageRelease(cgImage);
            CGDataProviderRelease(dataProvider);
            CGColorSpaceRelease(defaultColorSpace);
        }
    }
}


-(void)update
{
    if(!m_hCanvas) return;
    
    
    [self freeAllocCellBuffer];
    
    [self drawBackground];
    [self beginDraw];
}

-(void)stopUpdate
{
    m_nDrawPositionX = 500;
}

- (BOOL)isString:(NSString*)fullString contains:(NSString*)other
{
    NSRange range = [fullString rangeOfString:other];
    return range.length != 0;
}

#pragma mark - drawTest -
-(void)drawBackground
{
    NSString *sBrushName = [m_idMaster activeMyBrushName];
    if ([self isString:sBrushName contains:@"Blur_"] || [self isString:sBrushName contains:@"eraser_"])
    {
        for (int nCellY = 1; nCellY < ceilf(self.bounds.size.height/CELL_HEIGHT) - 1; nCellY++)
        {
            for (int nCellX = 0; nCellX < ceilf(self.bounds.size.width/CELL_WIDTH); nCellX++)
            {
                unsigned char *pCellBuffer = IPD_GetTileMemory(self, nCellX, nCellY, false);
                for (int j = 0; j < CELL_HEIGHT; j++)
                {
                    for (int i = 0; i < CELL_WIDTH; i++)
                    {
//                        pCellBuffer[j*CELL_WIDTH*4 + i*4 ] = 0;
//                        pCellBuffer[j*CELL_WIDTH*4 + i*4 + 1] = 0;
//                        pCellBuffer[j*CELL_WIDTH*4 + i*4 + 2] = 0;
//                        pCellBuffer[j*CELL_WIDTH*4 + i*4 + 3] = 255;
                        
                        if( j < CELL_HEIGHT/2)
                        {
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 ] = 255;
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 + 1] = 0;
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 + 2] = 255;
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 + 3] = 255;
                        }
                        else
                        {
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 ] = 0;
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 + 1] = 255;
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 + 2] = 255;
                            pCellBuffer[j*CELL_WIDTH*4 + i*4 + 3] = 255;
                        }
                    }
                }
            }
            
        }
    }
}

-(void)beginDraw
{
    if(!m_hCanvas) return;
    
    IP_BeginOneStroke(m_hCanvas);
    
    void *hBrush = [m_idMaster activeMyBrush];   assert(hBrush);
    int nCurrentColor = ( 128| (128<<8) | (128<<16));
    m_nDrawPositionX = 0;
    int nPosX = m_nDrawPositionX;
    int nPosY = sin(nPosX*2*M_PI/320) * self.frame.size.height/4.0 + 100;
    IP_StrokeTo(m_hCanvas, hBrush, nCurrentColor, nPosX, nPosY, 0.5, 5.1);
    
    [self performSelector:@selector(drawTest) withObject:nil afterDelay:0.1];
}

-(void)drawTest
{
    if(!m_hCanvas) return;
    if(m_nDrawPositionX > 500) return;
    
    void *hBrush = [m_idMaster activeMyBrush]; assert(hBrush);
    int nCurrentColor = ( 128| (128<<8) | (128<<16));
    m_nDrawPositionX += 20;
    int nPosX = m_nDrawPositionX;
    int nPosY = sin(nPosX*2*M_PI/320) * self.frame.size.height/4.0 + 100;
    
    if(nPosX >= 500)
    {
        IP_StrokeTo(m_hCanvas, hBrush, nCurrentColor, nPosX, nPosY, 0.5, -1.0);
        IP_EndOneStroke(m_hCanvas);
    }
    else
        IP_StrokeTo(m_hCanvas, hBrush, nCurrentColor, nPosX, nPosY, 0.5, 0.05);
   
    [self performSelector:@selector(drawTest) withObject:nil afterDelay:0.1];
    
    [self setNeedsDisplay:YES];
}

#pragma mark - memory -
-(void)allocCellBuffer:(unsigned char **)pCellBuf cellX:(int)nCellX cellY:(int)nCellY read:(BOOL)bReadOnly
{
    NSData *data = [m_mdCellBuffer objectForKey:[NSString stringWithFormat:@"cellX = %d,cellY = %d",nCellX,nCellY]];
    if(data)
    {
        *pCellBuf = (unsigned char *)[data bytes];
        return;
    }
    
    unsigned char *pCell = malloc(CELL_WIDTH * CELL_HEIGHT * 4);
    memset(pCell, 0, CELL_WIDTH * CELL_HEIGHT * 4);
    
    *pCellBuf = pCell;
    
    data = [NSData dataWithBytesNoCopy:*pCellBuf length:CELL_WIDTH * CELL_HEIGHT * 4 freeWhenDone:NO];
    [m_mdCellBuffer setObject:data forKey:[NSString stringWithFormat:@"cellX = %d,cellY = %d",nCellX,nCellY]];
}

-(void)freeAllocCellBuffer
{
    NSEnumerator * enumerator = [m_mdCellBuffer keyEnumerator];
    NSString *sKey;
    //遍历输出
    while(sKey = [enumerator nextObject])
    {
        NSData *data = [m_mdCellBuffer objectForKey:sKey];
        if (data)
        {
            unsigned char *pCellBuf = (unsigned char *)[data bytes];
            free(pCellBuf);
        }
    }
    [m_mdCellBuffer removeAllObjects];
}

#pragma mark - Mouse Events -
-(void)mouseDown:(NSEvent *)theEvent
{
    if(!m_hCanvas) return;
    m_nDrawPositionX = 500;
    
    NSPoint point = [theEvent locationInWindow];
    point = [[[self window] contentView] convertPoint:point toView:self];
    point.y = self.frame.size.height - point.y;
    
    IP_BeginOneStroke(m_hCanvas);
    
    void *hBrush = [m_idMaster activeMyBrush];   assert(hBrush);
    int nCurrentColor = ( 128| (128<<8) | (128<<16));
    IP_StrokeTo(m_hCanvas, hBrush, nCurrentColor, point.x, point.y, 0.5, 5.1);
    
    [self setNeedsDisplay:YES];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    if(!m_hCanvas) return;
    
    NSPoint point = [theEvent locationInWindow];
    point = [[[self window] contentView] convertPoint:point toView:self];
    point.y = self.frame.size.height - point.y;
    
    void *hBrush = [m_idMaster activeMyBrush];   assert(hBrush);
    int nCurrentColor = ( 128| (128<<8) | (128<<16));
    IP_StrokeTo(m_hCanvas, hBrush, nCurrentColor, point.x, point.y, 0.5, 0.01);
    
    [self setNeedsDisplay:YES];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    if(!m_hCanvas) return;
    
    NSPoint point = [theEvent locationInWindow];
    NSDocument *currentDoucemnt = [[NSDocumentController sharedDocumentController] currentDocument];
    NSWindow *window = [currentDoucemnt window];
    point = [[window contentView] convertPoint:point fromView:self];
    point.y = self.frame.size.height - point.y;
    
    void *hBrush = [m_idMaster activeMyBrush]; assert(hBrush);
    int nCurrentColor = ( 128| (128<<8) | (128<<16));
   
    
    IP_StrokeTo(m_hCanvas, hBrush, nCurrentColor, point.x, point.y, 0.5, -1.0);
    IP_EndOneStroke(m_hCanvas);
    
    [self setNeedsDisplay:YES];
}

@end
