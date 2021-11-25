#import "PSDocument.h"
#import "PSContent.h"
#import "LayerCell.h"
#import "NSArray_Extensions.h"
#import "NSOutlineView_Extensions.h"
#import "PSLayer.h"
#import "PSHelpers.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "LayerSettings.h"
#import "EffectUtility.h"

#import "PSSmartFilterManager.h"

#import "LayerDataSource.h"
#import <CoreText/CoreText.h>

#import "PSSmartFilterUtility.h"

//#define SEA_LAYER_PBOARD_TYPE 	@"PixelStyle Layer Pasteboard Type"
#define LAYER_THUMB_NAME_COL @"Layer Thumbnail and Name Column"
#define LAYER_VISIBLE_COL @"Layer Visible Checkbox Column"
#define INFO_BUTTON_COL	@"Info Button Column"

@implementation LayerDataSource
- (void)awakeFromNib
{
	// Register to get our custom type, strings, and filenames. Try dragging each into the view!
    [m_idOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:SEA_LAYER_PBOARD_TYPE, NSStringPboardType, NSFilenamesPboardType, nil]];
	[m_idOutlineView setVerticalMotionCanBeginDrag: YES];

	[m_idOutlineView setIndentationPerLevel: 0.0];
	[m_idOutlineView setOutlineTableColumn:[m_idOutlineView tableColumnWithIdentifier:LAYER_THUMB_NAME_COL]];
    
    [m_idOutlineView setAllowsMultipleSelection:YES];

	m_arrDraggedNodes = nil;
    
    m_lastTimeClickCheck = -1.0;
}

- (void)dealloc
{
	[super dealloc];
}

- (NSArray *)draggedNodes { return m_arrDraggedNodes; }
- (NSMutableArray *)selectedNodes { return [m_idOutlineView allSelectedItems]; }

// ================================================================
// Target / action methods. (most wired up in IB)
// ================================================================

- (void)outlineViewAction:(id)olv
{
    // This message is sent from the outlineView as it's action (see the connection in IB).
    
    for (int nIndex = 0; nIndex < [[m_idDocument contents] layerCount]; nIndex++)
    {
        PSAbstractLayer *layer = [[m_idDocument contents] layer:nIndex];
        [layer setLinked:NO];
    }
    
    BOOL bChangeActiveLayer = YES;
    
    NSArray *selectedNodes = [self selectedNodes];
    for (int nIndex = 0; nIndex < [selectedNodes count]; nIndex ++)
    {
        PSLayer *selectedLayer = [selectedNodes objectAtIndex:nIndex];
        [selectedLayer setLinked:YES];
        
        if([[m_idDocument contents] activeLayerIndex] == [selectedLayer index])
            bChangeActiveLayer = false;
    }
    
    if(bChangeActiveLayer)
    {
        PSLayer *selectedLayer = [selectedNodes objectAtIndex:0];        
        [[m_idDocument contents] setActiveLayerIndexComplete:[selectedLayer index]];
    }
    
    
    [[m_idDocument helpers] layerAttributesChanged:kLinkedLayers hold:YES];
}

- (void)deleteSelections:(id)sender
{
    NSArray *selection = [self selectedNodes];
    
    // Tell all of the selected nodes to remove themselves from the model.
    [selection makeObjectsPerformSelector: @selector(removeFromParent)];
    [m_idOutlineView deselectAll:nil];
    [m_idOutlineView reloadData];
}

// ================================================================
//  NSOutlineView data source methods. (The required ones)
// ================================================================

// Required methods. These methods must handle the case of a "nil" item, which indicates the root item.
- (id)outlineView:(NSOutlineView *)olv child:(int)index ofItem:(id)item
{
	if(!m_idDocument)
		return 0;
	if(item != nil)
		NSLog(@"%@ says olv %@ requested a child at %d for %@ erroniously", self, olv, index, item);
	return [[m_idDocument contents] layer:index];
}

- (BOOL)outlineView:(NSOutlineView *)olv isItemExpandable:(id)item
{
	// For now, layers cannot have children
	return NO;
}

- (int)outlineView:(NSOutlineView *)olv numberOfChildrenOfItem:(id)item
{
	if(!m_idDocument)
		return 0;
	// The root node has the number of layers as children
	if(item == nil)
		return [[m_idDocument contents] layerCount];
	// Other layers do not have children
	return 0;
}

- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// There is only one colum so there's not much need to worry about this
    if ([[tableColumn identifier] isEqualToString:LAYER_THUMB_NAME_COL])
    {
		if([(PSLayer *)item floating])
			return @"Floating Layer";
		return [(PSLayer *)item name];
	}
    else if([[tableColumn identifier] isEqualToString:LAYER_VISIBLE_COL])
    {
   		return [NSNumber numberWithBool:[(PSLayer *)item visible]];
	}
    else if([[tableColumn identifier] isEqualToString:INFO_BUTTON_COL])
    {
		return [NSNumber numberWithBool:YES];
	}
    else
    {
		NSLog(@"Object value for unkown column: %@", tableColumn);
	}
	return nil;
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([[tableColumn identifier] isEqualToString:LAYER_THUMB_NAME_COL])
    {
		[(PSLayer *)item setName:object];
	}
    else if([[tableColumn identifier] isEqualToString:LAYER_VISIBLE_COL])
    {
		[[m_idDocument contents] setVisible:[object boolValue] forLayer:[(PSLayer *)item index]];
	}
    else if([[tableColumn identifier] isEqualToString:INFO_BUTTON_COL])
    {
/*
#ifdef PROPAINT_VERSION
#else
 */
        [[(PSLayer *)item getSmartFilterManager] filtersEditWillBegin];
        
        [[m_idDocument contents] setActiveLayerIndexComplete:[(PSLayer *)item index]];
        
        [(EffectUtility *)[[PSController utilitiesManager] effectUtilityFor :m_idDocument] update];
        [(PSSmartFilterUtility *)[[PSController utilitiesManager] smartFilterUtilityFor :m_idDocument] update];
        [(EffectUtility *)[[PSController utilitiesManager] effectUtilityFor :m_idDocument] runWindow];
        
//        [(PSSmartFilterUtility *)[[PSController utilitiesManager] smartFilterUtilityFor :m_idDocument] update];
//        [(PSSmartFilterUtility *)[[PSController utilitiesManager] smartFilterUtilityFor :m_idDocument] runWindow];

//#endif
	}
    else
    {
		NSLog(@"Setting the value for unknown column %@", tableColumn);
	}	
}

// We can return a different cell for each row, if we want
- (NSCell *)outlineView:(NSOutlineView *)ov dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	// But we choose to, for now, have one type of data cell
	return [tableColumn dataCell];
}

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:ov isGroupItem:(id)item
{
	// But it is not needed
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)olv shouldExpandItem:(id)item
{
	// Again, there should be no expanding right now
	return NO;
}

-(void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{ // Prevent row selection aNotification object] deselectAll:self];

}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    
}

- (void)outlineView:(NSOutlineView *)outlineView
didClickTableColumn:(NSTableColumn *)tableColumn
{
    
}



- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([[tableColumn identifier] isEqualToString:LAYER_THUMB_NAME_COL])
    {
		// Make sure the image and text cell has an image. 
		// We know that the cell at this column is our image and text cell, so grab it
		LayerCell *layerCell = (LayerCell *)cell;
		// Set the image here since the value returned from outlineView:objectValueForTableColumn:... didn't specify the image part...
        if([(PSLayer *)item layerFormat] == PS_TEXT_LAYER)
            [layerCell setImage:[NSImage imageNamed:@"text_thumbnail"]];
        else
            [layerCell setImage:[(PSLayer *)item thumbnail]];
        
        NSMutableArray *nodes = [self selectedNodes];
        if([nodes count] > 0 && [nodes objectAtIndex:0] == item)
        {
            [layerCell setSelected: YES];
        }
        else
        {
            [layerCell setSelected: NO];
        }
        [nodes removeAllObjects];
	}
    else if([[tableColumn identifier] isEqualToString:LAYER_VISIBLE_COL])
    {
		NSButtonCell *buttonCell = (NSButtonCell *)cell;
		if([(PSLayer *)item visible])
        {
			[buttonCell setImage:[NSImage imageNamed:@"checked"]];
		}
        else
        {
			[buttonCell setImage:[NSImage imageNamed:@"unchecked"]];
		}
        
        [buttonCell setImagePosition:NSImageOnly];
        [buttonCell setImageScaling:NSImageScaleAxesIndependently];
	}
    else if([[tableColumn identifier] isEqualToString:INFO_BUTTON_COL])
    {
/*#ifdef PROPAINT_VERSION
#else
 */
        NSButtonCell *buttonCell = (NSButtonCell *)cell;
        [buttonCell setImage:[NSImage imageNamed:@"layer-fx.png"]];
        [buttonCell setImagePosition:NSImageOnly];
        [buttonCell setImageScaling:NSImageScaleAxesIndependently];

//        NSFont *labelFont = [NSFont fontWithName:@"Athelas-Italic" size:16];
//        
//        NSMutableAttributedString *labelText = [[[NSMutableAttributedString alloc] initWithString:@"fx"] autorelease];
//        NSRange textRange = NSMakeRange(0, [labelText length]);
//        [labelText addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:textRange];
//        [labelText addAttribute:NSFontAttributeName value:labelFont range:textRange];
//        [labelText addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:textRange];
//        
//        [buttonCell setTitle:(NSString *)labelText];
//#endif
	}
    else
    {
		NSLog(@"Will display cell for unkown column %@", tableColumn);
	}
    
    
}


NSFont * GetVariationOfFontWithTrait(NSFont *baseFont,CTFontSymbolicTraits trait)
{
    CGFloat fontSize = [baseFont pointSize];
    
    CFStringRef baseFontName = (__bridge CFStringRef)[baseFont fontName];
    CTFontRef baseCTFont = CTFontCreateWithName(baseFontName, fontSize, NULL);
    CTFontRef ctFont = CTFontCreateCopyWithSymbolicTraits(baseCTFont, 0, NULL, trait, trait);
    
    NSString *variantFontName = CFBridgingRelease(CTFontCopyName(ctFont,kCTFontPostScriptNameKey));
    
    NSFont *variantFont = [NSFont fontWithName:variantFontName size:fontSize];
    
    CFRelease(ctFont);
    CFRelease(baseCTFont);
    
    return variantFont;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(nullable NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation
{
    if([[tableColumn identifier] isEqualToString:LAYER_VISIBLE_COL])
    {
        return NSLocalizedString(@"Show/Hide Layers", nil);
    }
    else if([[tableColumn identifier] isEqualToString:INFO_BUTTON_COL])
    {
/*#ifdef PROPAINT_VERSION
#else
*/        return NSLocalizedString(@"Add Layer Effects", nil);
// #endif
    }
    else if ([[tableColumn identifier] isEqualToString:LAYER_THUMB_NAME_COL])
    {
        if([(PSLayer *)item layerFormat] == PS_TEXT_LAYER)
            return NSLocalizedString(@"Indicate Text Layers", nil);
   //     else
   //         return NSLocalizedString(@"Layer Thumbnail", nil);
    }
    
    return @"";
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
	// All items should be selectable
	return YES;
}

//为什么使用这个来toggle layer 是否可见？ wzq
//似乎没有简洁的方法  http://cocoadev.com/CheckboxInTableWithoutSelectingRow
- (BOOL)outlineView:(NSOutlineView *)ov shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	// We want to allow tracking for all the button cells, even if we don't allow selecting that particular row.
    if([[tableColumn identifier] isEqualToString:LAYER_VISIBLE_COL])
    {
        if(m_lastTimeClickCheck > 0 &&[[NSDate date] timeIntervalSince1970] - m_lastTimeClickCheck < 0.2)
            return NO;
        
        m_lastTimeClickCheck = [[NSDate date] timeIntervalSince1970];
        bool bVisble = [(PSLayer *)item visible];
        [[m_idDocument contents] setVisible:!bVisble forLayer:[(PSLayer *)item index]];
       
        return NO;
    }
    else
        return YES;
}

// ================================================================
//  NSOutlineView data source methods. (dragging related)
// ================================================================

// Create a fileHandle for writing to a new file located in the directory specified by 'dirpath'.  If the file basename.extension already exists at that location, then append "-N" (where N is a whole number starting with 1) until a unique basename-N.extension file is found.  On return oFilename contains the name of the newly created file referenced by the returned NSFileHandle.
NSFileHandle *NewFileHandleForWritingFile(NSString *dirpath, NSString *basename, NSString *extension, NSString **oFilename)
{
    NSString *filename = nil;
    BOOL done = NO;
    int fdForWriting = -1, uniqueNum = 0;
    
    while (!done)
    {
        filename = [NSString stringWithFormat:@"%@%@.%@", basename, (uniqueNum ? [NSString stringWithFormat:@"-%ld", (long)uniqueNum] : @""), extension];
        fdForWriting = open([[NSString stringWithFormat:@"%@/%@", dirpath, filename] UTF8String], O_WRONLY | O_CREAT | O_EXCL, 0666);
        if (fdForWriting < 0 && errno == EEXIST)
        {
            // Try another name.
            uniqueNum++;
        }
        else
        {
            done = YES;
        }
    }
	
    NSFileHandle *fileHandle = nil;
    if (fdForWriting>0)
    {
        fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fdForWriting closeOnDealloc:YES];
    }
    
    if (oFilename)
    {
        *oFilename = (fileHandle ? filename : nil);
    }
    
    return fileHandle;
}

// We promised the files, so now lets make good on that promise!
- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
    int i = 0, count = [items count];
    NSMutableArray *filenames = [NSMutableArray array];
    
    for (i=0; i<count; i++)
    {
        PSLayer *layer = (PSLayer *)[items objectAtIndex:i];
        NSString *filename  = nil;
        NSFileHandle *fileHandle = NewFileHandleForWritingFile([dropDestination path], [layer name], @"tif", &filename);
        
        if (fileHandle)
        {
            [fileHandle writeData: [layer TIFFRepresentation]];
            [fileHandle release];
            fileHandle = nil;
            [filenames addObject: filename];
        }
    }
    
    return ([filenames count] ? filenames : nil);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
    m_arrDraggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.
    
//    // Provide data for our custom type, and simple NSStrings.
//    [pboard declareTypes:[NSArray arrayWithObjects:SEA_LAYER_PBOARD_TYPE, NSTIFFPboardType, NSFilesPromisePboardType, NSStringPboardType, nil] owner:self];
//
//    // the actual data doesn't matter since DragDropSimplePboardType drags aren't recognized by anyone but us!.
//    [pboard setData:[NSData data] forType:SEA_LAYER_PBOARD_TYPE]; 
//	[pboard setData:[[m_arrDraggedNodes objectAtIndex:0] TIFFRepresentation] forType:NSTIFFPboardType];
//
//    // Put the promised type we handle on the pasteboard.
//    [pboard setPropertyList:[NSArray arrayWithObjects:@"tif", nil] forType:NSFilesPromisePboardType];
//	
//    // Put string data on the pboard... notice you candrag into TextEdit!
//    [pboard setString: [[m_arrDraggedNodes objectAtIndex: 0] name] forType: NSStringPboardType];
    
    [pboard declareTypes:[NSArray arrayWithObjects:SEA_LAYER_PBOARD_TYPE,NSTIFFPboardType, nil] owner:self];
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver =[[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
    [archiver encodeObject:items forKey:@"draggedLayers"];
    [archiver finishEncoding];
    
    [pboard setData:data forType:SEA_LAYER_PBOARD_TYPE];
    
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)childIndex
{
   // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
    BOOL targetNodeIsValid = YES;
	BOOL isOnDropTypeProposal = childIndex==NSOutlineViewDropOnItemIndex;
		
	// Refuse if: dropping "on" the view itself unless we have no data in the view.
	if (item==nil && childIndex==NSOutlineViewDropOnItemIndex){
		// Somehow, we will need to figure out how to handle these types of drops
		targetNodeIsValid = NO;
	}
	// Refuse if: this is a drop on, those are not meaningful to us
	if (targetNodeIsValid && isOnDropTypeProposal==YES){
		targetNodeIsValid = NO;
	}
    
    // Set the item and child index in case we computed a retargeted one.
    [m_idOutlineView setDropItem:item dropChildIndex:childIndex];
    
    return targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)childIndex
{
	if(m_arrDraggedNodes){
		PSLayer *layer = [m_arrDraggedNodes objectAtIndex:0];
		[[m_idDocument contents] moveLayer: layer toIndex:childIndex];
		[self update];
		m_arrDraggedNodes = nil;
		return YES;
	}else{
		return NO;
	}
}

- (IBAction)useGroupGrowLook:(id)sender
{
    [m_idOutlineView setNeedsDisplay:YES];
}

- (void)update
{
    NSMutableIndexSet *selectedIndexes = [NSMutableIndexSet indexSet];
    
    for (int nIndex = 0; nIndex < [[m_idDocument contents] layerCount]; nIndex++)
    {
        PSAbstractLayer *layer = [[m_idDocument contents] layer:nIndex];
        bool bLinked = [layer linked];
        if (bLinked)
        {
            [selectedIndexes addIndex:nIndex];
        }
    }
    
    [m_idOutlineView reloadData];
    [m_idOutlineView selectRowIndexes:selectedIndexes byExtendingSelection:NO];
    
	//[m_idOutlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    
}

@end
