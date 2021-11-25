#import "PSTools.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "AbstractTool.h"

@implementation PSTools

//be careful, gCurrentDocument may be mot equal to m_idDocument
- (id)currentTool
{
    int tool = [[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] tool];
	return [self getTool:tool];
}


- (id)getTool:(int)whichOne
{
	switch (whichOne) {
		case kRectSelectTool:
			return m_idRectSelectTool;
		break;
		case kEllipseSelectTool:
			return m_idEllipseSelectTool;
		break;
		case kLassoTool:
			return m_idLassoTool;
		break;
		case kPolygonLassoTool:
			return m_idPolygonLassoTool;
		break;
		case kWandTool:
			return m_idWandTool;
		break;
		case kPencilTool:
			return m_idPencilTool;
		break;
		case kBrushTool:
			return m_idBrushTool;
		break;
		case kBucketTool:
			return m_idBucketTool;
		break;
		case kTextTool:
			return m_idTextTool;
		break;
		case kEyedropTool:
			return m_idEyedropTool;
		break;
		case kEraserTool:
			return m_idEraserTool;
		break;
		case kPositionTool:
			return m_idPositionTool;
		break;
		case kGradientTool:
			return m_idGradientTool;
		break;
		case kSmudgeTool:
			return m_idSmudgeTool;
		break;
		case kCloneTool:
			return m_idCloneTool;
		break;
		case kCropTool:
			return m_idCropTool;
		break;
		case kEffectTool:
			return m_idEffectTool;
        break;
        case kVectorTool:
            return m_idVectorTool;
        case kMyBrushTool:
            return m_idMyBrushTool;
        case kTransformTool:
            return m_idTransformTool;
        case kZoomTool:
            return m_idZoomTool;
        case kShapeTool:
            return m_idShapeTool;
        case kVectorMoveTool:
            return m_idVectorMoveTool;
        case kVectorNodeEditorTool:
            return m_idVectorNodeEditorTool;
        case kVectorPenTool:
            return m_idVectorPenTool;
        case kVectorEraserTool:
            return m_idVectorEraserTool;
        case kRedEyeRemoveTool:
            return m_idRedEyeRemoveTool;
        case kBurnTool:
            return m_idBurnTool;
        case kDodgeTool:
            return m_idDodgeTool;
        case kSpongeTool:
            return m_idSpongeTool;
            
        default:
            return nil;
       		
	}
	
	return NULL;
}

- (NSArray *)allTools
{
    return [NSArray arrayWithObjects: m_idRectSelectTool, m_idEllipseSelectTool, m_idLassoTool, m_idPolygonLassoTool, m_idWandTool, m_idPencilTool, m_idBrushTool, m_idBucketTool, m_idTextTool, m_idEyedropTool, m_idEraserTool, m_idPositionTool, m_idGradientTool, m_idSmudgeTool, m_idCloneTool, m_idCropTool, m_idEffectTool, m_idVectorTool, m_idMyBrushTool, m_idTransformTool, m_idZoomTool, m_idShapeTool, m_idVectorMoveTool, m_idVectorPenTool, m_idVectorEraserTool, m_idRedEyeRemoveTool, m_idBurnTool, m_idDodgeTool, m_idSpongeTool,m_idVectorNodeEditorTool, nil];
}
@end
