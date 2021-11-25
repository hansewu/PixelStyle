#import "PSAlignment.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSHelpers.h"

@implementation PSAlignment

- (IBAction)alignLeft:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer xoff];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset, oldOffsets.y)];
			[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignRight:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer xoff] + [(PSLayer *)layer width];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset - [(PSLayer *)layer width], oldOffsets.y)];
			[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignHorizontalCenters:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer xoff] + [(PSLayer *)layer width] / 2;
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(offset - [(PSLayer *)layer width] / 2, oldOffsets.y)];
			[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}

}

- (IBAction)alignTop:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer yoff];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(oldOffsets.x, offset)];
			[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignBottom:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer yoff] + [(PSLayer *)layer height];
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(oldOffsets.x, offset - [(PSLayer *)layer height])];
			[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (IBAction)alignVerticalCenters:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	int offset, i, layerCount;
	IntPoint oldOffsets;
	
	// Get the required offset
	offset = [layer yoff] + [(PSLayer *)layer height] / 2;
	
	// Make the changes
	layerCount = [contents layerCount];
	for (i = 0; i < layerCount; i++) {
		layer = [contents layer:i];
		if ([layer linked]) {
			oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
			[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
			[layer setOffsets:IntMakePoint(oldOffsets.x, offset - [(PSLayer *)layer height] / 2)];
			[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
		}
	}
}

- (void)centerLayerHorizontally:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	IntPoint oldOffsets;
	int i, layerCount, shift;
	IntRect rect;
	
	// Check if layer is linked
	if (![layer linked]) {
		
		// Allow the undo
		oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
		[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:[contents activeLayerIndex]];
		
		// Make the change
		[layer setOffsets:IntMakePoint(([(PSContent *)contents width] - [(PSLayer *)layer width]) / 2, oldOffsets.y)];
		
		// Do the update
		[[m_idDocument helpers] layerOffsetsChanged:[contents activeLayerIndex] from:oldOffsets];
	
	}
	else {
	
		// Start with an initial bounding rectangle
		rect.origin.x = [layer xoff];
		rect.origin.y = [layer yoff];
		rect.size.width = [(PSLayer *)layer width];
		rect.size.height = [(PSLayer *)layer height];
		
		// Determine the bounding rectangle
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				rect.origin.x = MIN([layer xoff], rect.origin.x);
				rect.origin.y = MIN([layer yoff], rect.origin.y);
				rect.size.width = MAX([layer xoff] + [(PSLayer *)layer width] - rect.origin.x, rect.size.width);
				rect.size.height = MAX([layer yoff] + [(PSLayer *)layer height] - rect.origin.y, rect.size.height); 
			}
		}
		
		// Calculate the required shift
		shift = ([(PSContent *)contents width] / 2 - rect.size.width / 2) - rect.origin.x;
		
		// Make the changes
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
				[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
				[layer setOffsets:IntMakePoint(oldOffsets.x + shift, oldOffsets.y)];
				[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
			}
		}
		
	}
        
}

- (void)centerLayerVertically:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
	IntPoint oldOffsets;
	int i, layerCount, shift;
	IntRect rect;
	
	// Check if layer is linked
	if (![layer linked]) {
	
		// Allow the undo
		oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
		[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:[contents activeLayerIndex]];
		
		// Make the change
		[layer setOffsets:IntMakePoint(oldOffsets.x, ([(PSContent *)contents height] - [(PSLayer *)layer height]) / 2)];
		
		// Do the update
		[[m_idDocument helpers] layerOffsetsChanged:[contents activeLayerIndex] from:oldOffsets];
		
	}
	else {
	
		// Start with an initial bounding rectangle
		rect.origin.x = [layer xoff];
		rect.origin.y = [layer yoff];
		rect.size.width = [(PSLayer *)layer width];
		rect.size.height = [(PSLayer *)layer height];
		
		// Determine the bounding rectangle
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				rect.origin.x = MIN([layer xoff], rect.origin.x);
				rect.origin.y = MIN([layer yoff], rect.origin.y);
				rect.size.width = MAX([layer xoff] + [(PSLayer *)layer width] - rect.origin.x, rect.size.width);
				rect.size.height = MAX([layer yoff] + [(PSLayer *)layer height] - rect.origin.y, rect.size.height); 
			}
		}
		
		// Calculate the required shift
		shift = ([(PSContent *)contents height] / 2 - rect.size.height / 2) - rect.origin.y;
		
		// Make the changes
		layerCount = [contents layerCount];
		for (i = 0; i < layerCount; i++) {
			layer = [contents layer:i];
			if ([layer linked]) {
				oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
				[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:i];
				[layer setOffsets:IntMakePoint(oldOffsets.x, oldOffsets.y + shift)];
				[[m_idDocument helpers] layerOffsetsChanged:i from:oldOffsets];
			}
		}
		
	}
}

- (void)undoOffsets:(IntPoint)offsets layer:(int)index
{
	id contents = [m_idDocument contents];
	id layer = [contents layer:index];
	IntPoint oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
	
	// Allow the redo
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOffsets:oldOffsets layer:index];
	
	// Make the change
	[layer setOffsets:offsets];
	
	// Do the update
	[[m_idDocument helpers] layerOffsetsChanged:index from:oldOffsets];
}

@end
