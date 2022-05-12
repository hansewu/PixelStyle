#import "Globals.h"
#import "AbstractOptions.h"
#import "MyCustomComboBox.h"

/*!
	@class		GradientOptions
	@abstract	Handles the options pane for the gradient tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@class PSColorWell;
@class PSFillController;

@interface GradientOptions : AbstractOptions<MyCustomComboBoxDelegate>
{

	// The pop-up menu indicating the gradient's type
	IBOutlet id m_idTypePopup;
	
	// The pop-up menu indicating the repeating style for the gradient
	IBOutlet id m_idRepeatPopup;
    
    IBOutlet NSButton *m_btnLockGradients45;
    
    int m_nGradientType;
    int m_nWaveType;
    
    PSColorWell *m_fillWell;
    PSFillController *m_fillController;
    
    
    IBOutlet id m_idGradientLinear;
	IBOutlet id m_idGradientRadius;
    IBOutlet id m_idGradientSymmetry;
    IBOutlet id m_idGradientDiamond;
    IBOutlet id m_idGradientCone;
    IBOutlet id m_idGradientAngle;
    IBOutlet id m_idGradientClockwiseSpiral;
    IBOutlet id m_idGradientCounterClockwiseSpiral;
    
    IBOutlet id m_idTypeTile;
    IBOutlet id m_idTypeSymmetryTile;
    
    IBOutlet MyCustomComboBox *m_myCustomComboOpacity;
    
    IBOutlet NSTextField *m_labelOpacity;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		type
	@discussion	Returns the gradient type to be used with the gradient tool.
	@result		Returns an integer representing the gradient type to be used see
				GIMPCore).
*/
- (int)type;

/*!
	@method		repeat
	@discussion	Returns the repeating style to be used with the gradient tool.
	@result		Returns an integer representing the repeating style to be used
				see GIMPCore).
*/
- (int)repeat;

/*!
	@method		supersample
	@discussion Returns whether adaptive supersampling should take place on the
				gradient.
	@result		Returns YES if adaptive supersampling should take place, NO
				otherwise.
*/
- (BOOL)supersample;

/*!
	@method		maximumDepth
	@discussion Returns the maximum depth of the recursive supersampling
				algorithm.
	@result		An integer indicating the maximum depth of the recursive
				supersampling algorithm.
*/
- (int)maximumDepth;

/*!
	@method		threshold
	@discussion The threshold to be used with supersampling.
	@result		A double indicating the threshold to be used with supersampling.
*/
- (double)threshold;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

-(IBAction)onBtnGradientType:(id)sender;

-(IBAction)onWaveType:(id)sender;

-(IBAction)onLockGradients45:(id)sender;

- (float)getOpacityValue;

-(NSGradient *)gradient;

@end
