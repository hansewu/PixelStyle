//
//  PSVectorEraserTool.h
//  PixelStyle
//
//  Created by lchzh on 31/3/16.
//
//

#import "PSAbstractVectorSelectTool.h"
#import "WDPath.h"

@interface PSVectorEraserTool : PSAbstractVectorSelectTool
{
    WDPath              *m_pathTemp;
    WDPath              *m_eraserPath;
}

@end
