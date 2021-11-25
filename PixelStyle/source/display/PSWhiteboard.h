#import "Globals.h"
#import "PSCompositor.h"

/*!
	@enum		k...ChannelsView
	@constant	kAllChannelsView
				Indicates that all channels are being viewed.
	@constant	kPrimaryChannelsView
				Indicates that just the primary channel(s) are being viewed.
	@constant	kAlphaChannelView
				Indicates that just the alpha channel is being viewed.
	@constant	kCMYKPreviewView
				Indicates that all channels are being viewed in CMYK previewing mode.
*/
enum {
	kAllChannelsView,
	kPrimaryChannelsView,
	kAlphaChannelView,
	kCMYKPreviewView
};


/*!
	@enum		k...Behaviour
	@constant	kNormalBehaviour
				Indicates the overlay is to be composited on to the underlying layer.
	@constant	kErasingBehaviour
				Indicates the overlay is to erase the underlying layer.
	@constant	kReplacingBehaviour
				Indicates the overlay is to replace the underling layer where specified.
	@constant	kMaskingBehaviour
				Indicates the overlay is to be composited on to the underlying layer with the
				replace data being used as a mask.
*/
enum {
	kNormalBehaviour,
	kErasingBehaviour,
	kReplacingBehaviour,
	kMaskingBehaviour
};


/*!
	@class		PSWhiteboard
	@abstract	Combines the layers together to formulate a single bitmap that
				can be presented to the user.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
				Copyright (c) 2005 Daniel Jalkut
*/

#import "PSSecureImageData.h"

@interface PSWhiteboard : NSObject {

	// The document associated with this whiteboard
	id m_idDocument;
	
	// The compositor for this whiteboard
	id m_idCompositor;
    
    
	// The width and height of the whitebaord
	int m_nWidth, m_nHeight;
	
	// The whiteboard's data
	unsigned char *m_pData;
    NSRecursiveLock *m_dataLock;
    
	unsigned char *m_pAltData;
	
	// The whiteboard's images
	NSImage *m_imgWhiteboard;
	
	// The overlay for the current layer
	//unsigned char *m_pOverlay;
    PSSecureImageData *m_pOverlayData;
	
	// The replace mask for the current layer
	unsigned char *m_pReplace;
	
	// The behaviour of the overlay
	int m_nOverlayBehaviour;
	
	// The opacity for the overlay
	int m_nOverlayOpacity;
	
	// The colour world for colour space conversions
	CMWorldRef m_cwColourSpace;
	
	// The whiteboard's samples per pixel
	int m_nSpp;
	
	// Remembers whether is or is not active
	BOOL m_bCMYKPreview;
	
	// One of the above constants to specify what is seen by the user
	int m_nViewType;
	
	// The rectangle the update is needed in (useUpdateRect may be NO in which case the entire whiteboard is updated)
	BOOL m_bUseUpdateRect;
	IntRect m_sUpdateRect;
	
	// Used for multi-threading
	NSRect m_recThreadUpdate;
	
	// The thread that is locking or NULL otherwise
	NSThread *m_thrLockingThread;
	
	// The display profile
	CMProfileRef m_cpDisplayProf;
	CGColorSpaceRef m_ccsDisplayProf;
  
        
    CGLayerRef m_cgLayerTotal;
    CGLayerRef m_cgLayerTempOverlayer;
    
    //The canvas for the document
    void *m_hCanvas;
    // A long list of the stroke buffer we can write/read
    NSMutableDictionary *m_mdStrokeBufferCache;
}

// CREATION METHODS

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
	@method		compositor
	@discussion	Returns the instance of the compositor
*/
- (PSCompositor *)compositor;

// OVERLAY METHODS

/*!
	@method		setOverlayBehaviour:
	@discussion	Sets the overlay behaviour.
	@param		value
				The new overlay behaviour (see PSWhiteboard).
*/
- (void)setOverlayBehaviour:(int)value;

/*!
	@method		getOverlayBehaviour:
	@discussion	Gets the overlay behaviour.
	@param		value
 The new overlay behaviour (see PSWhiteboard).
 */
- (int)getOverlayBehaviour;

/*!
	@method		setOverlayOpacity:
	@discussion	Sets the opacity of the overlay.
	@param		value
				An integer from 0 to 255 representing the revised opacity of the
				overlay.
*/
- (void)setOverlayOpacity:(int)value;
- (int)getOverlayOpacity;

/*!
	@method		applyOverlay
	@discussion	Applies and clears the overlay.
	@result		Returns a rectangle representing the changed content in the
				document's co-ordinates. This rectangle can then be passed to
				update:.
*/
- (IntRect)applyOverlay;

/*!
	@method		clearOverlay
	@discussion	Clears the overlay without applying it.
*/
- (void)clearOverlay;

/*!
	@method		overlay
	@discussion	Returns the bitmap data of the overlay.
	@result		Returns a pointer to the bitmap data of the overlay.
*/

- (PSSecureImageData*)overlaySecureData;

//- (unsigned char *)overlay;

/*!
	@method		replace
	@discussion	Returns the replace mask of the overlay.
	@result		Returns a pointer to the 8 bits per pixel replace mask of the
				overlay.
*/
- (unsigned char *)replace;

// READJUSTING METHODS

/*!
	@method		whiteboardIsLayerSpecific
	@discussion	Returns whether after the active layer is changed the alternate
				data must be readjusted.
	@result		YES if the alternate data must be readjusted after the active
				layer is changed, NO otherwise.
*/
- (BOOL)whiteboardIsLayerSpecific;

/*!
	@method		readjust
	@discussion	Readjusts and updates the whiteboard after the document's type
				or boundaries are changed.
*/
- (void)readjust;

/*!
	@method		readjustLayer
	@discussion	Readjusts and updates the whiteboard after one or more layers'
				boundaries are changed.
     @param		update
     YES if the document should be updated after the readjustment, NO
     otherwise.
*/
- (void)readjustLayer:(BOOL)update;

/*!
	@method		readjustAltData
	@discussion	Readjusts the whiteboard's alternate data after the view type is
				changed. (Also called by readjust.)
	@param		update
				YES if the document should be updated after the readjustment, NO
				otherwise.
*/
- (void)readjustAltData:(BOOL)update;

// CMYK PREVIEWING METHODS

/*!
	@method		CMYKPreview
	@discussion	Returns whether or not CMYK previewing is active.
	@result		Returns YES if the CMYK previewing is active, NO otherwise.
*/
- (BOOL)CMYKPreview;


/*!
	@method		canToggleCMYKPreview
	@discussion	Returns whether or not CMYK previewing can be toggled for this
				document.
	@result		Returns YES if CMYK previewing can be toggled, NO otherwise.
*/
- (BOOL)canToggleCMYKPreview;

/*!
	@method		toggleCMYKPreview
	@discussion	Toggles whether or not CMYK previewing is active.
*/
- (void)toggleCMYKPreview;

/*!
	@method		matchColor:
	@discussion	Returns the appropriately matched colour given an unmatched
				colour.
	@param		color
				The unmatched RGBA color.
	@result		The matched RGBA color. 
*/
- (NSColor *)matchColor:(NSColor *)color;

// UPDATING METHODS

/*!
	@method		update
	@discussion	Updates the full contents of the whiteboard.
*/
- (void)update;

/*!
	@method		update:inThread:
	@discussion	Updates a specified rectangle of the whiteboard.
	@param		rect
				The rectangle to be updated.
	@param		thread
				YES if drawing should be done in thread, NO otherwise.
*/
- (void)update:(IntRect)rect inThread:(BOOL)thread;

/*!
	@method		Refresh:
	@discussion	Refresh a specified rectangle of the whiteboard.
	@param		rect
                 The rectangle to be updated.
    @param		bAllContent
                YES if refresh all, NO otherwise.
 */
- (void)Refresh:(IntRect)rect isAllContent:(BOOL)bAllContent;

/*!
	@method		updateColorWorld
	@discussion	Called to inform the whiteboard that the user has changed the
				ColorSync system settings. Updates the CMYK preview to reflect
				the changes.
*/
- (void)updateColorWorld;

// ACCESSOR METHODS

/*!
	@method		imageRect
	@discussion	Returns the rectangle in which the whiteboard's image should be
				plotted. This is only not equal to the document rectangle if
				whiteboardIsLayerSpecific returns YES.
	@result		Returns an IntRect indicating the rectangle in which the
				whiteboard's image should be plotted. 
*/
- (IntRect)imageRect;

/*!
	@method		image
	@discussion	Returns an image representing the whiteboard (which may be CMYK
				or channel-specific depending on user settings).
	@result		Returns an NSImage representing the whiteboard.
*/
- (NSImage *)image;

/*!
	@method		printableImage
	@discussion	Returns an image representing the whiteboard as it should be
				printed. The representation is never channel-specific.
	@result		Returns an NSImage representing the whiteboard as it should be
				printed.
*/
- (NSImage *)printableImage;

/*!
	@method		data
	@discussion	Returns the bitmap data for the whiteboard.
	@result		Returns a pointer to the bitmap data for the whiteboard.
*/
- (unsigned char *)data;

/*!
	@method		altData
	@discussion	Returns the alternate bitmap data for the whiteboard.
	@result		Returns a pointer to the alternate bitmap data for the
				whiteboard.
*/
- (unsigned char *)altData;

/*!
	@method		displayProf
	@discussion	Returns the current display profile.
	@result		Returns a CMProfileRef representing the ColorSync display profile
				PixelStyle is using.
*/
- (CGColorSpaceRef)displayProf;

/*!
 @method		getCanvas
	@discussion	Return the canvas.
 */
-(void *)getCanvas;

/*!
	@method		allocCellBuffer: cellX: cellY: read:
	@discussion	Alloc the buffer of cell.
	@param		pCellBuf
 The address of the buffer.
	@param		nCellX
 the index of cell in horizontal direction.
    @param		nCellY
 the index of cell in vertical direction.
	@param		bReadOnly
 YES if reading the buffer only, NO otherwise.
 */
-(void)allocCellBuffer:(unsigned char **)pCellBuf cellX:(int)nCellX cellY:(int)nCellY read:(BOOL)bReadOnly;

/*!
 @method		freeAllocCellBuffer
	@discussion	Free the buffer of cell.
 */
-(void)freeAllocCellBuffer;

-(CGLayerRef)getCGLayerTempOverLayer;
-(CGLayerRef)getCGLayerTotoal;


- (PSSecureImageData*)getOverlayImageData;

@end
