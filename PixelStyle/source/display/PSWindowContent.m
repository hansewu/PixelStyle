#import "PSWindowContent.h"

#import "PSDocument.h"

@interface NSView(DisableSubsAdditions)
- (void)disableSubViews;
- (void)enableSubViews;

@end

@implementation NSView(DisableSubsAdditions)

- (void)disableSubViews
{
    [self setSubViewsEnabled:NO];
}

- (void)enableSubViews
{
    [self setSubViewsEnabled:YES];
}

- (void)setSubViewsEnabled:(BOOL)enabled
{
    NSView* currentView = NULL;
    NSEnumerator* viewEnumerator = [[self subviews] objectEnumerator];
    
    while( currentView = [viewEnumerator nextObject] )
    {
        if( [currentView respondsToSelector:@selector(setEnabled:)] )
        {
            [(NSControl*)currentView setEnabled:enabled];
        }
        [currentView setSubViewsEnabled:enabled];
        
        [currentView display];
    }
}

@end


@implementation PSWindowContent

-(void)awakeFromNib
{
	m_dict = [[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", m_ovOptionsBar, @"view", m_vNonOptionsBar, @"nonView", @"above", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kOptionsBar],
             
             [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", m_tbvMyToolBar, @"view", m_vNonSidebar, @"nonView", @"left", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kMyToolsBar],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", m_vSidebar, @"view", m_vNonSidebar, @"nonView", @"right", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kSidebar],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", m_vPointInformation, @"view", m_svLayers, @"nonView", @"above", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kPointInformation],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", m_bvWarningsBar, @"view", m_vMainDocumentView, @"nonView", @"above", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kWarningsBar],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", m_cvStatusBar, @"view", m_vMainDocumentView, @"nonView", @"below", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kStatusBar],
			 nil] retain];
	
	int i;
	for(i = kOptionsBar; i <= kStatusBar; i++){
		NSString *key = [NSString stringWithFormat:@"region%dvisibility", i];
		if([gUserDefaults objectForKey: key] && ![gUserDefaults boolForKey:key]){
			// We need to hide it
			[self setVisibility: NO forRegion: i];
		}
	}
	
	// by default, the warning bar should be hidden. we will only show it iff we need it
	[self setVisibility:NO forRegion:kWarningsBar];
 
    [self addLocalMonitorForEvents];

//    [m_scrollViewToolBar setDocumentView:m_tbvMyToolBar];
}

-(void)addLocalMonitorForEvents
{
    if(!m_idEventLocalMonitor)
    {
        m_idEventLocalMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSRightMouseDownMask | NSKeyUpMask) handler:^NSEvent *(NSEvent* event)
         {
             if(CGRectContainsPoint([[self window] frame],  [NSEvent mouseLocation]))
             {
                 bool bResponse = [self responseSubViews:event];
                 if(!bResponse) return nil;
             }
             return event;
         }];
    }

}

-(bool)responseSubViews:(NSEvent *)event
{
    if([event window] != self.window) return true;
    if(!m_idDocument) return true;
    
    
    NSPoint point = [event locationInWindow];
    
    //以后可以对所有view判断
    NSPoint tempPoint = [self convertPoint:point toView:m_svLayers];
    if(NSPointInRect(tempPoint, [m_svLayers bounds]))
        return [m_idDocument canResponseForView:m_svLayers];
    
    
    return true;
}

-(void)dealloc
{
    if(m_idEventLocalMonitor)
    {
        [NSEvent removeMonitor:m_idEventLocalMonitor];
        m_idEventLocalMonitor = nil;
    }
    
    [super dealloc];
}

- (BOOL)windowWillResizeTo:(NSSize)frameSize;
{
//    NSRect windowFrame = self.window.frame;
//    [self.window setFrame:NSMakeRect(windowFrame.origin.x, windowFrame.origin.y, windowFrame.size.width, 724) display:NO];
    [[(NSView *)m_tbvMyToolBar superview] setAutoresizingMask:NSViewNotSizable];
    [[(NSView *)m_tbvMyToolBar superview] setFrame:NSMakeRect(0, 0, 45, 664)]; //664
    if(frameSize.height < 724)
    {
        [(NSView *)m_tbvMyToolBar setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        for(NSView *view in ((NSView *)m_tbvMyToolBar).subviews)
        {
            if([view autoresizingMask] != (NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable | NSViewMaxXMargin | NSViewMaxYMargin))
                [view setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable | NSViewMaxXMargin | NSViewMaxYMargin];
        }
        
        
    }
    else if(frameSize.height > 724)
    {
        [(NSView *)m_tbvMyToolBar setAutoresizingMask:NSViewMinYMargin];

        for(NSView *view in ((NSView *)m_tbvMyToolBar).subviews)
        {
            if( [view autoresizingMask] != NSViewMinYMargin)
                [view setAutoresizingMask:NSViewMinYMargin];
            
        }
    }
    float optionHeight = ((NSView *)m_ovOptionsBar).frame.size.height;
    if ([(NSView *)m_ovOptionsBar isHidden] ) {
        optionHeight = 0;
    }
    float statusHeight = ((NSView *)m_cvStatusBar).frame.size.height;
    if ([(NSView *)m_cvStatusBar isHidden] ) {
        statusHeight = 0;
    }
    float windowTitleHieght = 20;
    
    [[(NSView *)m_tbvMyToolBar superview] setFrame:NSMakeRect(0, statusHeight, 45, frameSize.height - optionHeight - statusHeight - windowTitleHieght + 1)];
    
    return YES;
}

-(BOOL)visibilityForRegion:(int)region
{
	return [[[m_dict objectForKey:[NSNumber numberWithInt:region]] objectForKey:@"visibility"] boolValue];
}

-(void)setVisibility:(BOOL)visibility forRegion:(int)region
{
	NSMutableDictionary *thisDict = [m_dict objectForKey:[NSNumber numberWithInt:region]];
	BOOL currentVisibility = [[thisDict objectForKey:@"visibility"] boolValue];
	
	// Check to see if we are already in the proper state
	if(currentVisibility == visibility){
		return;
	}
	
	float oldValue = [[thisDict objectForKey:@"oldValue"] floatValue];
	NSView *view = [thisDict objectForKey:@"view"];
	NSView *nonView = [thisDict objectForKey:@"nonView"];
	NSString *side = [thisDict objectForKey:@"side"];
    
	if(!visibility)
    {
		
		if([side isEqual:@"above"] || [side isEqual:@"below"])
        {
			oldValue = [view frame].size.height;
		}
        else
        {
			oldValue = [view frame].size.width;
		}

		NSRect oldRect = [view frame];
		
		
		if([side isEqual:@"above"] || [side isEqual:@"below"])
        {
			oldRect.size.height = 0;
		}
        else
        {
			oldRect.size.width = 0;
		}
		
//		[view setFrame:oldRect];
        [view setHidden:YES];
		
		oldRect = [nonView frame];
		
		if([side isEqual:@"above"])
        {
			oldRect.size.height += oldValue;
		}
        else if([side isEqual:@"below"])
        {
			oldRect.origin.y = [view frame].origin.y;
			oldRect.size.height += oldValue;
		}
        else if([side isEqual:@"left"])
        {
			oldRect.origin.x = [view frame].origin.x;
			oldRect.size.width += oldValue;
		}
        else if([side isEqual:@"right"])
        {
			oldRect.size.width += oldValue;
		}
		
		[nonView setFrame:oldRect];
				
		[nonView setNeedsDisplay:YES];
		
		[thisDict setObject:[NSNumber numberWithFloat:oldValue] forKey:@"oldValue"];
		[gUserDefaults setObject: @"NO" forKey:[NSString stringWithFormat:@"region%dvisibility", region]];
        
	}
    else
    {
		NSRect newRect = [view frame];
		
        if([side isEqual:@"above"] || [side isEqual:@"below"])
        {
			newRect.size.height = oldValue;
		}
        else
        {
			newRect.size.width = oldValue;
            
            if([side isEqual:@"right"])
            {
                newRect.origin.x = [nonView frame].size.width - oldValue;
            }
		}
		
		[view setFrame:newRect];
        [view setHidden:NO];
		
		newRect = [nonView frame];

		if([side isEqual:@"above"])
        {
			newRect.size.height -= oldValue;
		}
        else if([side isEqual:@"below"])
        {
			newRect.origin.y += oldValue;
			newRect.size.height -= oldValue;
		}
        else if([side isEqual:@"left"])
        {
			newRect.origin.x += oldValue;
			newRect.size.width -= oldValue;
		}
        else if([side isEqual:@"right"])
        {
			newRect.size.width -= oldValue;
		}
		
		[nonView setFrame:newRect];
				
		[nonView setNeedsDisplay:YES];
		
		[gUserDefaults setObject: @"YES" forKey:[NSString stringWithFormat:@"region%dvisibility", region]];
	}
    
	[thisDict setObject:[NSNumber numberWithBool:visibility] forKey:@"visibility"];
    
    [self windowWillResizeTo:((NSWindow*)[m_idDocument window]).frame.size];
}

-(float)sizeForRegion:(int)region
{
	if([self visibilityForRegion:region]){
		NSMutableDictionary *thisDict = [m_dict objectForKey:[NSNumber numberWithInt:region]];
		NSString *side = [thisDict objectForKey:@"side"];
		NSView *view = [thisDict objectForKey: @"view"];
        
		if([side isEqual: @"above"] || [side isEqual: @"below"])
        {
			return [view frame].size.height;
		}
        else
        {
			return [view frame].size.width;
		}
	}
	return 0.0;
}

@end
