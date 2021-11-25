#import "PSDocument.h"
#import "PSLayerUndo.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "PSDocRotation.h"

@implementation PSDocRotation

- (void)flipDocHorizontally
{
	int i, layerCount;
	
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] flipDocHorizontally];
	[[m_idDocument selection] clearSelection];
	layerCount = [[m_idDocument contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[m_idDocument contents] layer:i] flipHorizontally];
	}
	[[m_idDocument helpers] boundariesAndContentChanged:NO];
}

- (void)flipDocVertically
{
	int i, layerCount;
	
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] flipDocVertically];
	[[m_idDocument selection] clearSelection];
	layerCount = [[m_idDocument contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[m_idDocument contents] layer:i] flipVertically];
	}
	[[m_idDocument helpers] boundariesAndContentChanged:NO];
}

- (void)rotateDocLeft
{
	int i, layerCount, width, height;
	
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] rotateDocRight];
	[[m_idDocument selection] clearSelection];
	layerCount = [[m_idDocument contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[m_idDocument contents] layer:i] rotateLeft];
	}
	width = [(PSContent *)[m_idDocument contents] width];
	height = [(PSContent *)[m_idDocument contents] height];
	[[m_idDocument contents] setWidth:height height:width];
	[[m_idDocument helpers] boundariesAndContentChanged:NO];
}

- (void)rotateDocRight
{
	int i, layerCount, width, height;
	
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] rotateDocLeft];
	[[m_idDocument selection] clearSelection];
	layerCount = [[m_idDocument contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[m_idDocument contents] layer:i] rotateRight];
	}
	width = [(PSContent *)[m_idDocument contents] width];
	height = [(PSContent *)[m_idDocument contents] height];
	[[m_idDocument contents] setWidth:height height:width];
	[[m_idDocument helpers] boundariesAndContentChanged:NO];
}

@end
