#import "Globals.h"

/*!
	@class		PSProxy
	@abstract	Passes various messages to the current document.
	@discussion	The PSProxy passes various messages on to the current document
				allowing objects in the MainMenu NIB file to interact with the
				current document. Most methods in this class are undocumented.
				The class carries out menu item validation.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSProxy : NSObject {
    IBOutlet id m_idMove;
    IBOutlet id m_idTransform;
    IBOutlet id m_idRectangle;
    IBOutlet id m_idEllipse;
    IBOutlet id m_idlasso;
    IBOutlet id m_idPolyon;
    IBOutlet id m_idWand;
    IBOutlet id m_idCrop;
    IBOutlet id m_idArtBrush;
    IBOutlet id m_idPencil;
    IBOutlet id m_idBrush;
    IBOutlet id m_idSmudge;
    IBOutlet id m_idEraser;
    IBOutlet id m_idPick;
    IBOutlet id m_idClone;
    IBOutlet id m_idBucket;
    IBOutlet id m_idGradient;
    IBOutlet id m_idText;
    IBOutlet id m_idZoom;
    IBOutlet id m_idShape;
    IBOutlet id m_idVectorMove;
    IBOutlet id m_idVectorPen;
    IBOutlet id m_idVectorEraser;
    IBOutlet id m_idRedEyeMove;
    IBOutlet id m_idBurnDodge;
}

// To methods in TextureExporter...
- (IBAction)exportAsTexture:(id)sender;

// To methods in PSView...
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomNormal:(id)sender;
- (IBAction)zoomOut:(id)sender;

// To methods in PSWhiteboard...
- (IBAction)toggleCMYKPreview:(id)sender;
#ifdef PERFORMANCE
- (IBAction)resetPerformance:(id)sender;
#endif

// To methods in PSContent....
- (IBAction)importLayer:(id)sender;
- (IBAction)copyMerged:(id)sender;
- (IBAction)flatten:(id)sender;
- (IBAction)mergeLinked:(id)sender;
- (IBAction)mergeDown:(id)sender;
- (IBAction)raiseLayer:(id)sender;
- (IBAction)bringToFront:(id)sender;
- (IBAction)lowerLayer:(id)sender;
- (IBAction)sendToBack:(id)sender;
- (IBAction)deleteLayer:(id)sender;
- (IBAction)addLayer:(id)sender;
- (IBAction)addShapeLayer:(id)sender;
- (IBAction)duplicateLayer:(id)sender;
- (IBAction)layerAbove:(id)sender;
- (IBAction)layerBelow:(id)sender;
- (IBAction)setColorSpace:(id)sender;
- (IBAction)toggleLinked:(id)sender;
- (IBAction)clearAllLinks:(id)sender;
- (IBAction)toggleFloatingSelection:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)toggleCMYKSave:(id)sender;
- (IBAction)changeSelectedChannel:(id)sender;
- (IBAction)changeTrueView:(id)sender;
- (IBAction)onRaster:(id)sender;

// To methods in PSLayer...
- (IBAction)toggleLayerAlpha:(id)sender;

// To methods in PSAlignment...
- (IBAction)alignLeft:(id)sender;
- (IBAction)alignRight:(id)sender;
- (IBAction)alignHorizontalCenters:(id)sender;
- (IBAction)alignTop:(id)sender;
- (IBAction)alignBottom:(id)sender;
- (IBAction)alignVerticalCenters:(id)sender;
- (IBAction)centerLayerHorizontally:(id)sender;
- (IBAction)centerLayerVertically:(id)sender;

// To methods in PSResolution...
- (IBAction)setResolution:(id)sender;

// To methods in PSMargins...
- (IBAction)setMargins:(id)sender;
- (IBAction)setLayerMargins:(id)sender;
- (IBAction)condenseLayer:(id)sender;
- (IBAction)condenseToSelection:(id)sender;
- (IBAction)expandLayer:(id)sender;
- (IBAction)cropImage:(id)sender;
- (IBAction)maskImage:(id)sender;

// To methods in PSScale...
- (IBAction)setScale:(id)sender;
- (IBAction)setLayerScale:(id)sender;

// To methods in PSDocRotation...
- (IBAction)rotateDocLeft:(id)sender;
- (IBAction)rotateDocRight:(id)sender;

// To method in PSRotation...
- (IBAction)setLayerRotation:(id)sender;

// To methods in PSFlip...
- (IBAction)flipDocHorizontally:(id)sender;
- (IBAction)flipDocVertically:(id)sender;
- (IBAction)flipHorizontally:(id)sender;
- (IBAction)flipVertically:(id)sender;

// To methods in PSPlugins...
- (IBAction)reapplyEffect:(id)sender;

// To methods in Utilities...
- (IBAction)selectTool:(id)sender;
- (IBAction)toggleLayers:(id)sender;
- (IBAction)toggleInformation:(id)sender;
- (IBAction)toggleOptions:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;

// To the ColorView
- (IBAction)activateForegroundColor:(id)sender;
- (IBAction)activateBackgroundColor:(id)sender;
- (IBAction)swapColors:(id)sender;
- (IBAction)defaultColors:(id)sender;

// To ColorSync API...
- (IBAction)openColorSyncPanel:(id)sender;

// To crashing...
- (IBAction)crash:(id)sender;
- (BOOL)validateMenuItem:(id)menuItem;

@end
