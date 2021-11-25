#import "Globals.h"

/*!
	@class		OptionsUtility
	@abstract	Displays the options for the current tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface OptionsUtility : NSObject {
	// The options view
    IBOutlet id m_idView;
		
	// The last options view set 
	id m_idLastView;

	// The document which is the focus of this utility
	IBOutlet id m_idDocument;
	
	// The view to show when no document is active
	IBOutlet id m_idBlankView;
	
	// The various options objects
	IBOutlet id m_idLassoOptions;
	IBOutlet id m_idPolygonLassoOptions;
	IBOutlet id m_idPositionOptions;
	IBOutlet id m_idZoomOptions;
	IBOutlet id m_idPencilOptions;
	IBOutlet id m_idBrushOptions;
    IBOutlet id m_idMyBrushOptions;
    IBOutlet id m_idBucketOptions;
	IBOutlet id m_idTextOptions;
	IBOutlet id m_idEyedropOptions;
	IBOutlet id m_idRectSelectOptions;
	IBOutlet id m_idEllipseSelectOptions;
	IBOutlet id m_idEraserOptions;
	IBOutlet id m_idSmudgeOptions;
	IBOutlet id m_idGradientOptions;
	IBOutlet id m_idWandOptions;
	IBOutlet id m_idCloneOptions;
	IBOutlet id m_idCropOptions;
	IBOutlet id m_idEffectOptions;
	IBOutlet id m_idVectorOptions;
	IBOutlet id m_idTransformOptions;
    IBOutlet id m_idShapeOptions;
    IBOutlet id m_idVectorMoveOptions;
    IBOutlet id m_idVectorNodeEditorOptions;
    IBOutlet id m_idVectorPenOptions;
    IBOutlet id m_idVectorEraserOptions;
    IBOutlet id m_idRedEyeRemoveOptions;
    IBOutlet id m_idBurnOptions;
    IBOutlet id m_idDodgeOptions;
    IBOutlet id m_idSpongeOptions;
    
	IBOutlet id m_idToolboxUtility;
	
	// The currently active tool - not a reliable indication (see code)
	int m_nCurrentTool;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		awakeFromNib
	@discussion	Configures the utility's interface.
*/
- (void)awakeFromNib;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		activate
	@discussion	Activates this utility with its document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates this utility.
*/
- (void)deactivate;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

/*!
	@method		currentOptions
	@discussion	Returns the currently active options object.
	@result		Returns the currently active options object (NULL if none).
*/
- (id)currentOptions;

/*!
	@method		getOptions:
	@discussion	Returns the options object associated with a given tool.
	@param		whichTool
				The tool type whose options object you are seeking (see
				PSTools).
	@result		Returns the options object associated with the given index.
*/
- (id)getOptions:(int)whichTool;

/*!
	@method		update
	@discussion	Updates the utility and the active options object.
*/
- (void)update;

/*!
	@method		show:
	@discussion	Shows the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)show:(id)sender;

/*!
	@method		hide:
	@discussion	Hides the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)hide:(id)sender;

/*!
	@method		toggle:
	@discussion	Toggles the visibility of the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)toggle:(id)sender;


/*!
	@method		viewNeedsDisplay
	@discussion	Informs the view it needs display.
*/
- (void)viewNeedsDisplay;

/*!
	@method		visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
*/
- (BOOL)visible;

@end
