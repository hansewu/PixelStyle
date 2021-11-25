#import "PSShadowView.h"
#import "PSController.h"
#import "PSPrefs.h"

#import "Globals.h"

#import "PSContent.h"
#import "PSDocument.h"

@implementation PSShadowView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        m_bAreRulersVisible = NO;
        
        // Register for drag operations
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NSFilenamesPboardType, nil]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[[(PSPrefs *)[PSController m_idPSPrefs] windowBack] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"DRAWTOOLEXTRAEXTENT" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DRAWOUTERSELECTION" object:self];
    
	NSRect scrollRect = [[scrollView contentView] bounds];
	NSRect shadowRect = NSMakeRect(-scrollRect.origin.x + m_bAreRulersVisible * 22, -scrollRect.origin.y + [scrollView hasHorizontalScroller] * 15, scrollRect.size.width + 2 * scrollRect.origin.x , scrollRect.size.height + 2 * scrollRect.origin.y);
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowOffset: NSMakeSize(1, -1)];
	[shadow setShadowBlurRadius: 5];
	[shadow setShadowColor:[NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:0.6]];
	[shadow set];
	[[NSBezierPath bezierPathWithRect:shadowRect] fill];
    
    
}

- (void)setRulersVisible:(BOOL)isVisible
{
	if(isVisible != m_bAreRulersVisible){
		m_bAreRulersVisible = isVisible;
		[self setNeedsDisplay:YES];
	}
}


- (NSDragOperation)draggingEntered:(id)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSArray *files;
    id layer;
    int i;
    BOOL success;
    
    // Determine the pasteboard and acceptable dragging operations
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ([sender draggingSource] && [[sender draggingSource] respondsToSelector:@selector(source)])
        layer = [[sender draggingSource] source];
    else
        layer = NULL;
    
    // Accept copy operations if possible
    if (sourceDragMask & NSDragOperationCopy) {
        if ([[pboard types] containsObject:NSTIFFPboardType] || [[pboard types] containsObject:NSPICTPboardType]) {
            if (layer != [[m_idDocument contents] activeLayer] && ![m_idDocument locked] && ![[m_idDocument selection] floating] ) {
                return NSDragOperationCopy;
            }
        }
        if ([[pboard types] containsObject:NSFilenamesPboardType]) {
            if (layer != [[m_idDocument contents] activeLayer] && ![m_idDocument locked] && ![[m_idDocument selection] floating]) {
                files = [pboard propertyListForType:NSFilenamesPboardType];
                success = YES;
                for (i = 0; i < [files count]; i++)
                    success = success && [[m_idDocument contents] canImportLayerFromFile:[files objectAtIndex:i]];
                if (success) {
                    return NSDragOperationCopy;
                }
            }
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSArray *files;
    BOOL success;
    id layer;
    int i;
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSPoint point = [sender draggingLocation];
    point = [[m_idDocument docView] convertPoint:point fromView:NULL];
    point.x = point.x / xScale;
    point.y = point.y / yScale;
    
    // Determine the pasteboard and acceptable dragging operations
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ([sender draggingSource] && [[sender draggingSource] respondsToSelector:@selector(source)])
        layer = [[sender draggingSource] source];
    else
        layer = NULL;
    
    if (sourceDragMask & NSDragOperationCopy) {
        
        // Accept TIFFs as new layers
        if ([[pboard types] containsObject:NSTIFFPboardType]) {
            if (layer != NULL) {
                [[m_idDocument contents] copyLayer:layer];
                return YES;
            }
            else {
                [[m_idDocument contents] addLayerFromPasteboard:pboard centerPointInCanvas:point];
                return YES;
            }
        }
        
        // Accept PICTs as new layers
        if ([[pboard types] containsObject:NSPICTPboardType]) {
            [[m_idDocument contents] addLayerFromPasteboard:pboard centerPointInCanvas:point];
            return YES;
        }
        
        // Accept files as new layers
        if ([[pboard types] containsObject:NSFilenamesPboardType]) {
            files = [pboard propertyListForType:NSFilenamesPboardType];
            success = YES;
            for (i = 0; i < [files count]; i++)
                success = success && [[m_idDocument contents] importLayerFromFile:[files objectAtIndex:i]];
            return success;
        }
        
    }
    
    return NO;
}


@end
