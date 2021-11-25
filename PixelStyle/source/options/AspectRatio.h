#import "Globals.h"

/*!
	@enum		k...AspectType
	@constant	kNoAspectType
				Indicates no specification.
	@constant	kRatioAspectType
				Indicates ratio specification.
	@constant	kExactPixelAspectType
				Indicates exact specification in pixels.
	@constant	kExactInchAspectType
				Indicates exact specification in inches.
	@constant	kExactMillimeterAspectType
				Indicates exact specification in millimetres.
*/
enum {
	kNoAspectType = -2,
	kRatioAspectType = -1,
	kExactPixelAspectType = 0,
	kExactInchAspectType = 1,
	kExactMillimeterAspectType = 2
};

/*		
	@class		AspectRatio
	@abstract	Collects common aspect ratio code.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2007 Mark Pazolli
*/

@interface AspectRatio : NSObject {
	// The host document
	IBOutlet id m_idDocument;

	// The controlling object
	id m_idMaster;

	// The controlling object's identifier (used for preferences)
	id m_idPrefString;

	// When checked indicates the cropping aspect ratio should be restricted
	IBOutlet id m_idRatioCheckbox;
	
	// A popup menu indicating the aspect ratio
	IBOutlet id m_idRatioPopup;
	
	// A panel for selecting the custom aspect ratio
	IBOutlet id m_idPanel;
	
	// Text boxes for custom ratio values
    IBOutlet id m_idXRatioValue;
    IBOutlet id m_idYRatioValue;
	
	// Various items associated with the aspect type
	IBOutlet id m_idToLabel;
	IBOutlet id m_idAspectTypePopup;
	
    IBOutlet id m_idRatioLabel;
    IBOutlet id m_idSet;
	// Custom ratio values
	float m_fRatioX, m_fRatioY;
	
	// Forgotten values
	float m_fForgotX, m_fForgotY;
	
	// The type of aspect ratio
	int m_nAspectType;
	
}

- (void)awakeWithMaster:(id)imaster andString:(id)iprefString;

/*!
	@method		setCustomItem:
	@discussion	Presents dialog for setting the custom item.
	@param		sender
				Ignored.
*/
- (IBAction)setCustomItem:(id)sender;

/*!
	@method		applyCustomItem:
	@discussion	Applies dialog changes to the custom item.
	@param		sender
				Ignored.
*/
- (IBAction)applyCustomItem:(id)sender;

/*!
	@method		changeCustomAspectType:
	@discussion	Changes the aspect type in the dialog.
	@param		sender
				Ignored.
*/
- (IBAction)changeCustomAspectType:(id)sender;

/*!
	@method		ratioX
	@discussion	Returns the ratio/size for the crop.
	@return		Returns a NSSize for the crop in the aspect type's
				units. If it is a ratio the width = X / Y and the 
				height = Y / X.
*/
- (NSSize)ratio;

/*!
	@method		aspectType
	@discussion	Returns the type of aspect ratio.
	@return		Returns a constant representing the type of aspect ratio
				(see AspectRatio).
*/
- (int)aspectType;

/*!
	@method		update:
	@discussion	Updates the options panel.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
