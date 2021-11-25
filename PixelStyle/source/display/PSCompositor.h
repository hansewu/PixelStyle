#import "Globals.h"
#import "StandardMerge.h"
#import "PSLayer.h"

/*!
	@struct		CompositorOptions
	@discussion	Allows the easy exchange of options between the whiteboard and
				compositor.
	@field		forceNormal
				YES if the layer should be composited using the normal mode
				regardless of its own mode), NO otherwise.
	@field		rect
				The rectangle within which to composite the layer. Only parts of
				the layer that reside in this rectangle will be drawn,
				rectangles that extend beyond the layer's boundaries are also
				acceptable.
	@field		destRect
				The rectangle 
	@field		insertOverlay
				YES if the overlay should be composited on top of the layer, NO
				otherwise.
	@field		useSelection
				YES if the selection should be used during compositing, NO
				otherwise.
	@field		overlayOpacity
				A value between 0 and 255 indicating the opacity with which the
				overlay should be drawn.
	@field		overlayBehaviour
				The behaviour of the overlay (see PSWhiteboard).
	@field		spp
				The samples per pixel to be used during compositing.
*/
typedef struct {
	BOOL forceNormal;
	IntRect rect;
	IntRect destRect;
	BOOL insertOverlay;
	BOOL useSelection;
	int overlayOpacity;
	BOOL overlayBehaviour;
	int spp;    
} CompositorOptions;

/*!
	@class		PSCompositor
	@abstract	Handles layer compositing for SeaWhitebaord.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

//@class PSLayer;

@interface PSCompositor : NSObject {

	// The document associated with this compositor
	id m_idDocument;
	
	// The random table
	int m_aRandomTable[RANDOM_TABLE_SIZE];
	
}

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		compositeLayer:withOptions:
	@discussion	Composites a layer on to the document's whiteboard using the
				specified options.
	@param		layer
				The layer to composite.
	@param		options
				The options for compositing.
*/
- (void)compositeLayer:(PSLayer *)layer withOptions:(CompositorOptions)options;

/*!
	@method		compositeLayer:withOptions:andData:
	@discussion	Composites a layer on to the document's whiteboard using the
				specified options.
	@param		layer
				The layer to composite.
	@param		options
				The options for compositing.
	@param		andData
				A pointer to the data the layer should be composited onto.
*/
- (void)compositeLayer:(PSLayer *)layer withOptions:(CompositorOptions)options andData:(unsigned char *)destPtr;

/*!
	@method		compositeLayer:withFloat:withOptions:
	@discussion	Composites a layer on to the document's whiteboard using the
				specified options with the specified floating layer.
	@param		layer
				The layer to composite.
	@param		floatingLayer
				The floating layer.
	@param		options
				The options for compositing.
*/
- (void)compositeLayer:(PSLayer *)layer withFloat:(PSLayer *)floatingLayer andOptions:(CompositorOptions)options;



- (void)renderOneLayerToCGLayer:(PSLayer *)layer withOptions:(CompositorOptions)options;

- (void)renderTempLayerToCGLayer:(PSLayer *)layer withOptions:(CompositorOptions)options;

- (void)compositeTempLayerToBufferInRect:(PSLayer *)layer withOptions:(CompositorOptions)options :(IntRect)rect bufferOut:(unsigned char *)pBufferOut;

- (void)compositeLayersToContext:(CGContextRef)context inRect:(CGRect)rect isBitmap:(BOOL)isBitmap;
- (void)compositeLayersToContextFull:(CGContextRef)context;
- (void)compositeLayersToContext:(RENDER_CONTEXT_INFO)contextInfo;

@end
