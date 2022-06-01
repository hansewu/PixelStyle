#import "Globals.h"

/*!
	@enum		k...Tool
	@constant	kRectSelectTool
				The rectangular selection tool.
	@constant	kEllipseSelectTool
				The elliptical selection tool.
	@constant	kLassoTool
				The lasso tool.
	@constant	kPolygonLassoTool
				The polygon lasso tool.
	@constant   kWandTool
				The wand selection tool.
	@constant	kPencilTool
				The pencil tool.
	@constant	kBrushTool
				The paintbrush tool.
	@constant	kEyedropTool
				The colour sampling tool.
	@constant	kTextTool
				The text tool.
	@constant	kEraserTool
				The eraser tool.
	@constant	kBucketTool
				The paint bucket tool.
	@constant	kGradientTool
				The gradient tool.
	@constant	kCropTool
				The crop tool.
	@constant	kCloneTool
				The clone tool.
	@constant	kSmudgeTool
				The smudging tool.
	@constant	kEffectTool
				The effect tool.
	@constant	kZoomTool
				The zoom tool.
	@constant	kPositionTool
				The layer positioning tool.
	@constant	kFirstSelectionTool
				The first selection tool.
	@constant	kLastSelectionTool
				The last selection tool.
*/
enum {
	kRectSelectTool = 0,
	kEllipseSelectTool = 1,
	kLassoTool = 2,
	kPolygonLassoTool = 3,
	kWandTool = 4,
	kPencilTool = 5, 
	kBrushTool = 6,
	kEyedropTool = 7,
	kTextTool = 8,
	kEraserTool = 9,
	kBucketTool = 10,
	kGradientTool = 11,
	kCropTool = 12,
	kCloneTool = 13,
	kSmudgeTool = 14,
	kEffectTool = 15,
	kZoomTool = 16,
	kPositionTool = 17,
    kVectorTool = 18,
    kMyBrushTool = 19,
    kTransformTool = 20,
    kShapeTool = 21,
    kVectorMoveTool = 22,
    kVectorPenTool = 23,
    kVectorEraserTool = 24,
    kRedEyeRemoveTool = 25,
    kBurnTool = 26,
    kDodgeTool = 27,
    kSpongeTool = 28,
    kVectorNodeEditorTool = 29,
    kInpaintTool = 30,
    
	kFirstSelectionTool = 0,
	kLastSelectionTool = 4,
//    kFirstShapeTool = 22,
//    kLastShapeTool = 27,
	kLastTool = 30
};

@class AbstractTool;

/*!
	@class		PSTools
	@abstract	Acts as a gateway to all the tools of PixelStyle.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSTools : NSObject {

	// Various objects representing various tools
	IBOutlet id m_idRectSelectTool;
	IBOutlet id m_idEllipseSelectTool;	
	IBOutlet id m_idLassoTool;
	IBOutlet id m_idPolygonLassoTool;
	IBOutlet id m_idWandTool;
	IBOutlet id m_idPencilTool;
	IBOutlet id m_idBrushTool;
	IBOutlet id m_idBucketTool;
	IBOutlet id m_idTextTool;
	IBOutlet id m_idEyedropTool;
	IBOutlet id m_idEraserTool;
    IBOutlet id m_idPositionTool;
	IBOutlet id m_idGradientTool;
	IBOutlet id m_idSmudgeTool;
	IBOutlet id m_idCloneTool;
	IBOutlet id m_idCropTool;
	IBOutlet id m_idEffectTool;
	IBOutlet id m_idVectorTool;
    IBOutlet id m_idMyBrushTool;
    IBOutlet id m_idTransformTool;
    IBOutlet id m_idZoomTool;
    IBOutlet id m_idShapeTool;
    IBOutlet id m_idVectorMoveTool;
    IBOutlet id m_idVectorNodeEditorTool;
    IBOutlet id m_idVectorPenTool;
    IBOutlet id m_idVectorEraserTool;
    IBOutlet id m_idRedEyeRemoveTool;
    IBOutlet id m_idBurnTool;
    IBOutlet id m_idDodgeTool;
    IBOutlet id m_idSpongeTool;
}

/*!
	@method		currentTool
	@discussion	Returns the currently active tool according to the toolbox
				utility.
	@result		Returns an object that is a subclass of AbstractTool.
*/
- (id)currentTool;


/*!
	@method		getTool:
	@discussion	Given a tool type returns the corresponding tool.
	@param		whichOne
				The tool type for the tool you are seeking.
	@result		Returns an object that is a subclass of AbstractTool.
*/
- (id)getTool:(int)whichOne;

/*!
	@method		allTools
	@discussion	This is purely for initialization to connect the options to the tools.
	@result		Returns an array of AbstractTools.
*/
- (NSArray *)allTools;

@end
