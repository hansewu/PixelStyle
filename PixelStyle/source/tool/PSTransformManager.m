//
//  PSTransformManager.m
//  PixelStyle
//
//  Created by lchzh on 29/10/15.
//
//

#import "PSTransformManager.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSSelection.h"
#import "PSContent.h"
#import "PSAbstractLayer.h"
#import "PSLayer.h"
#import "PSLayerUndo.h"
#import "PSLayerTransformInfo.h"
#import "PSAffinePerspectiveTransform.h"

#import "PSTools.h"
#import "AbstractTool.h"

#import <Accelerate/Accelerate.h>
#import "PSTextLayer.h"
#import "ThressPointsAffine.h"

#import "PSPerspectiveTransform.h"
#import "PSTransformTool.h"

@implementation PSTransformManager

- (id)initWithDocument:(id)document
{
    self = [super init];
    m_idDocument = document;
    m_transformedLayerInfoArray = [[NSMutableArray alloc] init];
    m_hasBeginTransform = NO;
    m_needUpdateCenterPoint = YES;
    
    //[NSThread detachNewThreadSelector:@selector(processTransformInThread) toTarget:self withObject:NULL];
    
    m_topLeftPoint = NSMakePoint(-50000.0, 0);
    m_topLeftPointOriginal = NSMakePoint(-50000.0, 0);
    
    
    m_lockNewCGLayerLock = [[NSRecursiveLock alloc] init];

    
    return self;
}

-(void)dealloc
{
    if(m_transformedLayerInfoArray) {[m_transformedLayerInfoArray release]; m_transformedLayerInfoArray = nil;}
    
    if (m_lockNewCGLayerLock) {
        [m_lockNewCGLayerLock release];
        m_lockNewCGLayerLock = NULL;
    }
    
    [super dealloc];
}

- (void)lockNewCGLayer:(BOOL)isLock
{
    if (isLock) {
        [m_lockNewCGLayerLock lock];
    }else{
        [m_lockNewCGLayerLock unlock];
    }
}

/*
- (void)initialAffineInfo
{
    [m_transformedLayerInfoArray removeAllObjects];
    IntRect selectRect = [[m_idDocument selection] localRect];
    BOOL useSelection = [[m_idDocument selection] active];
    m_useSelection = useSelection;
    PSLayer *activelayer = [[m_idDocument contents] activeLayer];
    PSContent *contents = [m_idDocument contents];
    if (useSelection) {
        PSLayerTransformInfo *info = [[PSLayerTransformInfo alloc] init];
        info.transformedLayer = activelayer;
        info.selectedRect = selectRect;
        int xoffset = [activelayer xoff];
        int yoffset = [activelayer yoff];
        
        m_topLeftPoint = NSMakePoint(selectRect.origin.x + xoffset, selectRect.origin.y + yoffset);
        m_topRightPoint = NSMakePoint(selectRect.origin.x + xoffset + selectRect.size.width, selectRect.origin.y + yoffset);
        m_bottumRightPoint = NSMakePoint(selectRect.origin.x + xoffset + selectRect.size.width, selectRect.origin.y + yoffset + selectRect.size.height);
        m_bottumLeftPoint = NSMakePoint(selectRect.origin.x + xoffset, selectRect.origin.y + yoffset + selectRect.size.height);
        m_centerPoint = NSMakePoint(m_topLeftPoint.x + (m_topRightPoint.x - m_topLeftPoint.x) / 2.0, m_topLeftPoint.y + (m_bottumLeftPoint.y - m_topLeftPoint.y) / 2.0);
        
        if (m_hasBeginTransform) {
            //best to do it in thread
            int spp = [activelayer spp];
            int width = [activelayer width];
            int height = [activelayer height];
            unsigned char *selectedData = malloc(selectRect.size.width * selectRect.size.height * spp);
            unsigned char *rawData = [activelayer getRawData];
            unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
            for (int j = 0; j < selectRect.size.height; j++) {
                int srcPos = ((selectRect.origin.y + j) * width + selectRect.origin.x) * spp;
                int desPos = (j * selectRect.size.width) * spp;
                memcpy(selectedData + desPos, rawData + srcPos, selectRect.size.width * spp);
            }
            unsigned char *stayedData = malloc(width * height * spp);
            for (int j = 0; j < height; j++) {
                int srcPos = j * width * spp;
                int desPos = j * width * spp;
                memcpy(stayedData + desPos, rawData + srcPos, width * spp);
            }
            for (int j = selectRect.origin.y; j < selectRect.origin.y + selectRect.size.height; j++) {
                int srcPos = (j * width + selectRect.origin.x) * spp;
                memset(stayedData + srcPos, 0, selectRect.size.width * spp);
            }
            
            CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
            CGDataProviderRef dataProvider = CGDataProviderCreateWithData(self, stayedData, width * height * spp, NULL);
            assert(dataProvider);
            CGImageRef stayedImageRef = CGImageCreate(width, height, 8, 8 * spp, width * spp, defaultColorSpace, kCGImageAlphaLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
            assert(stayedImageRef); //stayedData 不能释放
            CGColorSpaceRelease(defaultColorSpace);
            CGDataProviderRelease(dataProvider);
            info.stayedImageRef = stayedImageRef;
            
            PSAffinePerspectiveTransform *transformController = [[PSAffinePerspectiveTransform alloc] init];
            [transformController initWithSrcData:selectedData FromRect:selectRect spp:spp opaque:NO colorSpace:CGColorSpaceCreateDeviceRGB() backColor:NULL];
            info.transformController = transformController;
            [transformController release];
            
            free(selectedData);
            [m_transformedLayerInfoArray addObject:info];
        }
        
    }else{
        int minx = 50000;
        int maxx = -50000;
        int miny = 50000;
        int maxy = -50000;
        for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
            id tempLayer = [contents layer:whichLayer];
            if ([tempLayer linked]) {
                int xoffset = [(PSAbstractLayer*)tempLayer xoff];
                int yoffset = [(PSAbstractLayer*)tempLayer yoff];
                int width = [(PSAbstractLayer*)tempLayer width];
                int height = [(PSAbstractLayer*)tempLayer height];
                int spp = [(PSLayer*)tempLayer spp];
                unsigned char* rawData = [(PSLayer*)tempLayer getRawData];
                if (m_hasBeginTransform) {
                    PSLayerTransformInfo *info = [[PSLayerTransformInfo alloc] init];
                    info.transformedLayer = tempLayer;
                    
                    PSAffinePerspectiveTransform *transformController = [[PSAffinePerspectiveTransform alloc] init];
                    [transformController initWithSrcData:rawData FromRect:IntMakeRect(xoffset, yoffset, width, height) spp:spp opaque:NO colorSpace:CGColorSpaceCreateDeviceRGB() backColor:NULL];
                    info.transformController = transformController;
                    [transformController release];
                    
                    [m_transformedLayerInfoArray addObject:info];
                }
                
                if (xoffset < minx) {
                    minx = xoffset;
                }
                if (xoffset + width > maxx) {
                    maxx = xoffset + width;
                }
                if (yoffset < miny) {
                    miny = yoffset;
                }
                if (yoffset + height > maxy) {
                    maxy = yoffset + height;
                }
            }
        }
        if (minx == 50000) {
            return;
        }
        m_topLeftPoint = NSMakePoint(minx, miny);
        m_topRightPoint = NSMakePoint(maxx, miny);
        m_bottumRightPoint = NSMakePoint(maxx, maxy);
        m_bottumLeftPoint = NSMakePoint(minx, maxy);
        m_centerPoint = NSMakePoint(minx + (maxx - minx) / 2.0, miny + (maxy - miny) / 2.0);        
        
    }
    m_topLeftPointOriginal = m_topLeftPoint;
    m_topRightPointOriginal = m_topRightPoint;
    m_bottumRightPointOriginal = m_bottumRightPoint;
    m_bottumLeftPointOriginal = m_bottumLeftPoint;
    
}
 
 */

- (void)initialAffineInfo
{
    [m_transformedLayerInfoArray removeAllObjects];
    IntRect selectRect = [[m_idDocument selection] localRect];
    BOOL useSelection = [[m_idDocument selection] active];
    PSLayer *activelayer = [[m_idDocument contents] activeLayer];
    PSContent *contents = [m_idDocument contents];
    
    m_useSelection = useSelection && [activelayer layerFormat] == PS_RASTER_LAYER;
    
    if (m_useSelection ) {
        PSLayerTransformInfo *info = [[PSLayerTransformInfo alloc] init];
        info.transformedLayer = activelayer;
        info.selectedRect = selectRect;
        int xoffset = [activelayer xoff];
        int yoffset = [activelayer yoff];
        
        m_topLeftPoint = NSMakePoint(selectRect.origin.x + xoffset, selectRect.origin.y + yoffset);
        m_topRightPoint = NSMakePoint(selectRect.origin.x + xoffset + selectRect.size.width, selectRect.origin.y + yoffset);
        m_bottumRightPoint = NSMakePoint(selectRect.origin.x + xoffset + selectRect.size.width, selectRect.origin.y + yoffset + selectRect.size.height);
        m_bottumLeftPoint = NSMakePoint(selectRect.origin.x + xoffset, selectRect.origin.y + yoffset + selectRect.size.height);
        m_centerPoint = NSMakePoint(m_topLeftPoint.x + (m_topRightPoint.x - m_topLeftPoint.x) / 2.0, m_topLeftPoint.y + (m_bottumLeftPoint.y - m_topLeftPoint.y) / 2.0);
        
        if (m_hasBeginTransform)
        {
            //best to do it in thread
            int spp = [activelayer spp];
            int width = [activelayer width];
            int height = [activelayer height];
            unsigned char *selectedData = malloc(selectRect.size.width * selectRect.size.height * spp);
            unsigned char *rawData = [activelayer getRawData];
            unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
            BOOL premultied = (((PSAbstractLayer*)activelayer).layerFormat == PS_TEXT_LAYER);
            
            for (int j = 0; j < selectRect.size.height; j++)
            {
                for (int i = 0; i < selectRect.size.width; i++)
                {
                    
                    int srcPos = ((selectRect.origin.y + j) * width + selectRect.origin.x + i) * spp;
                    int desPos = (j * selectRect.size.width + i) * spp;
                    
                    if (selectRect.origin.y + j < 0 || selectRect.origin.y + j >= height || selectRect.origin.x + i < 0 || selectRect.origin.x + i >= width) {
                        memset(selectedData + desPos, 0, spp);
                        continue;
                    }
                    
                    memcpy(selectedData + desPos, rawData + srcPos, spp - 1);
                    int t1;
                    int  alpha = int_mult(rawData[srcPos + spp - 1], mask[j * selectRect.size.width + i], t1);
                    selectedData[desPos + spp - 1] = alpha;
                }
                
            }
            
//            for (int j = 0; j < selectRect.size.height; j++) {
//                int srcPos = ((selectRect.origin.y + j) * width + selectRect.origin.x) * spp;
//                int desPos = (j * selectRect.size.width) * spp;
//                memcpy(selectedData + desPos, rawData + srcPos, selectRect.size.width * spp);
//            }
            unsigned char *stayedData = malloc(width * height * spp);
            for (int j = 0; j < height; j++) {
                int srcPos = j * width * spp;
                int desPos = j * width * spp;
                memcpy(stayedData + desPos, rawData + srcPos, width * spp);
            }
            for (int j = selectRect.origin.y; j < selectRect.origin.y + selectRect.size.height; j++) {
                for (int i = selectRect.origin.x; i < selectRect.origin.x + selectRect.size.width; i++) {
                    
                    if (j < 0 || j >= height || i < 0 || i >= width) {
                        continue;
                    }
                    int srcPos = (j * width + i) * spp;
                    int t1;
                    int  alpha = int_mult(rawData[srcPos + spp - 1], 255 - mask[(j - selectRect.origin.y) * selectRect.size.width + i - selectRect.origin.x], t1);
                    
                    stayedData[srcPos + spp - 1] = alpha;
                }
               
            }
            
            [activelayer unLockRawData];
            
            CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
            CGDataProviderRef dataProvider = CGDataProviderCreateWithData(self, stayedData, width * height * spp, CGDataProviderReleaseData);
            assert(dataProvider);
            CGImageRef stayedImageRef = CGImageCreate(width, height, 8, 8 * spp, width * spp, defaultColorSpace, kCGImageAlphaLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
            assert(stayedImageRef); //stayedData 不能释放
            CGColorSpaceRelease(defaultColorSpace);
            CGDataProviderRelease(dataProvider);
            
            info.stayedImageRef = stayedImageRef;
            
            PSAffinePerspectiveTransform *transformController = [[PSAffinePerspectiveTransform alloc] init];
            [transformController initWithSrcData:selectedData FromRect:selectRect spp:spp opaque:NO colorSpace:CGColorSpaceCreateDeviceRGB() backColor:NULL premultied:premultied];
            info.transformController = transformController;
            [transformController release];
            
            free(selectedData);
            [m_transformedLayerInfoArray addObject:info];
        }
        
    }else{
        int minx = 50000;
        int maxx = -50000;
        int miny = 50000;
        int maxy = -50000;
        for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
        {
            id tempLayer = [contents layer:whichLayer];
            if ([tempLayer linked])
            {
                int xoffset = [(PSAbstractLayer*)tempLayer xoff];
                int yoffset = [(PSAbstractLayer*)tempLayer yoff];
                int width = [(PSAbstractLayer*)tempLayer width];
                int height = [(PSAbstractLayer*)tempLayer height];
                int spp = [(PSLayer*)tempLayer spp];
                unsigned char* rawData = [(PSLayer*)tempLayer getRawData];
                BOOL premultied = (((PSAbstractLayer*)tempLayer).layerFormat == PS_TEXT_LAYER);
                if (m_hasBeginTransform)
                {
                    PSLayerTransformInfo *info = [[PSLayerTransformInfo alloc] init];
                    info.transformedLayer = tempLayer;
                    
                    PSAffinePerspectiveTransform *transformController = [[PSAffinePerspectiveTransform alloc] init];
                    [transformController initWithSrcData:rawData FromRect:IntMakeRect(xoffset, yoffset, width, height) spp:spp opaque:NO colorSpace:CGColorSpaceCreateDeviceRGB() backColor:NULL premultied:premultied];
                    info.transformController = transformController;
                    [transformController release];
                    
                    [m_transformedLayerInfoArray addObject:info];
                }
                [(PSLayer*)tempLayer unLockRawData];
                
                if (xoffset < minx) {
                    minx = xoffset;
                }
                if (xoffset + width > maxx) {
                    maxx = xoffset + width;
                }
                if (yoffset < miny) {
                    miny = yoffset;
                }
                if (yoffset + height > maxy) {
                    maxy = yoffset + height;
                }
            }
        }
        if (minx == 50000) {
            return;
        }
        m_topLeftPoint = NSMakePoint(minx, miny);
        m_topRightPoint = NSMakePoint(maxx, miny);
        m_bottumRightPoint = NSMakePoint(maxx, maxy);
        m_bottumLeftPoint = NSMakePoint(minx, maxy);
        m_centerPoint = NSMakePoint(minx + (maxx - minx) / 2.0, miny + (maxy - miny) / 2.0);
        
    }
    m_topLeftPointOriginal = m_topLeftPoint;
    m_topRightPointOriginal = m_topRightPoint;
    m_bottumRightPointOriginal = m_bottumRightPoint;
    m_bottumLeftPointOriginal = m_bottumLeftPoint;
    
}

void CGDataProviderReleaseData(void * __nullable info, const void *  data, size_t size)
{
    free((void *)data);
}

-(NSPoint)getAffineDesPointAtIndex:(int)index
{
    switch (index) {
        case 0:
            return m_topLeftPoint;
            break;
        case 1:
            return m_topRightPoint;
            break;
        case 2:
            return m_bottumRightPoint;
            break;
        case 3:
            return m_bottumLeftPoint;
            break;
        case 4:
            return m_centerPoint;
            break;
            
        default:
            break;
    }
    return NSMakePoint(0, 0);
}

-(NSPoint)getAffineOriginalPointAtIndex:(int)index
{
    switch (index) {
        case 0:
            return m_topLeftPointOriginal;
            break;
        case 1:
            return m_topRightPointOriginal;
            break;
        case 2:
            return m_bottumRightPointOriginal;
            break;
        case 3:
            return m_bottumLeftPointOriginal;
            break;
        case 4:
            return m_centerPoint;
            break;
            
        default:
            break;
    }
    return NSMakePoint(0, 0);
}

-(CGSize)getAffineOriginalSize
{
    return CGSizeMake(m_topRightPointOriginal.x - m_topLeftPointOriginal.x, m_bottumLeftPointOriginal.y - m_topLeftPointOriginal.y);
}

-(void)setAffineDesPoint:(NSPoint)point AtIndex:(int)index
{
    if (m_hasBeginTransform) {
        if (index == 4) {
            m_needUpdateCenterPoint = NO;
            m_centerPoint = point;
        }else{            
            switch (index) {
                case 0:
                    m_topLeftPoint = point;
                    break;
                case 1:
                    m_topRightPoint = point;
                    break;
                case 2:
                    m_bottumRightPoint = point;
                    break;
                case 3:
                    m_bottumLeftPoint = point;
                    break;
                    
                default:
                    break;
            }
            if (m_needUpdateCenterPoint) {
                NSPoint point0 = m_topLeftPoint;
                NSPoint point1 = m_topRightPoint;
                NSPoint point2 = m_bottumRightPoint;
                NSPoint point3 = m_bottumLeftPoint;
                float minx = point0.x;
                minx = MIN(minx, point1.x);
                minx = MIN(minx, point2.x);
                minx = MIN(minx, point3.x);
                float miny = point0.y;
                miny = MIN(miny, point1.y);
                miny = MIN(miny, point2.y);
                miny = MIN(miny, point3.y);
                float maxx = point0.x;
                maxx = MAX(maxx, point1.x);
                maxx = MAX(maxx, point2.x);
                maxx = MAX(maxx, point3.x);
                float maxy = point0.y;
                maxy = MAX(maxy, point1.y);
                maxy = MAX(maxy, point2.y);
                maxy = MAX(maxy, point3.y);
                m_centerPoint = NSMakePoint(minx + (maxx - minx) / 2.0, miny + (maxy - miny) / 2.0);
            }
        }

    }else{
        if (index == 4) {
            m_needUpdateCenterPoint = NO;
            m_centerPoint = point;
        }else{
            m_hasBeginTransform = YES;
            [self initialAffineInfo];
            [self setAffineDesPoint:point AtIndex:index];
        }
        
    }
}



- (NSMutableArray*)getTransformedLayerInfoArray
{
    return m_transformedLayerInfoArray;
}

- (BOOL)getIfHasBeginTransform
{
    return m_hasBeginTransform;
}

- (void)setIfHasBeginTransform:(BOOL)hasBegin
{
    m_hasBeginTransform = hasBegin;
}


- (la_object_t)computePerspectiveMatrixWithsrcPoint1:(NSPoint)srcPoint1 srcPoint2:(NSPoint)srcPoint2 srcPoint3:(NSPoint)srcPoint3 srcPoint4:(NSPoint)srcPoint4 desPoint1:(NSPoint)desPoint1 desPoint2:(NSPoint)desPoint2 desPoint3:(NSPoint)desPoint3 desPoint4:(NSPoint)desPoint4
{
    NSPoint src[4];
    src[0] = srcPoint1;
    src[1] = srcPoint2;
    src[2] = srcPoint3;
    src[3] = srcPoint4;
    NSPoint dst[4];
    dst[0] = desPoint1;
    dst[1] = desPoint2;
    dst[2] = desPoint3;
    dst[3] = desPoint4;
    
    float *bufferA = malloc(64 * sizeof(float));
    float *bufferB = malloc(8 * sizeof(float));
    for( int i = 0; i < 4; ++i )
    {
        bufferA[i * 8 + 0] = bufferA[(i + 4) * 8 + 3] = src[i].x;
        bufferA[i * 8 + 1] = bufferA[(i + 4) * 8 + 4] = src[i].y;
        bufferA[i * 8 + 2] = bufferA[(i + 4) * 8 + 5] = 1.0;
        bufferA[i * 8 + 3] = bufferA[i * 8 + 4] = bufferA[i * 8 + 5] = 0.0;
        bufferA[(i + 4) * 8 + 0] = bufferA[(i + 4) * 8 + 1] = bufferA[(i + 4) * 8 + 2] = 0.0;
        bufferA[i * 8 + 6] = -src[i].x * dst[i].x;
        bufferA[i * 8 + 7] = -src[i].y * dst[i].x;
        bufferA[(i + 4) * 8 + 6] = -src[i].x * dst[i].y;
        bufferA[(i + 4) * 8 + 7] = -src[i].y * dst[i].y;
        bufferB[i] = dst[i].x;
        bufferB[i + 4] = dst[i].y;
    }
    
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            if (i > j) {
                float tt=bufferA[i*8+j];
                bufferA[i*8+j]=bufferA[j*8+i];
                bufferA[j*8+i]=tt;
            }
        }
    }
    
    __CLPK_integer n = 8;
    __CLPK_integer nrhs = 1;
    __CLPK_integer lda = 8;
    __CLPK_integer ldb = 8;
    __CLPK_integer *ipiv = malloc(sizeof(__CLPK_integer)*n);
    __CLPK_integer info;
    sgesv_(&n, &nrhs, bufferA, &lda, ipiv, bufferB, &ldb, &info);
    free(ipiv);
    
    float *bufferX = malloc(9 * sizeof(float));
    for (int i = 0; i < 8; i++) {
        bufferX[i] = bufferB[i];
    }
    bufferX[8] = 1.0;
    free(bufferA);
    free(bufferB);
    la_object_t matrixS = la_matrix_from_float_buffer(bufferX, 3, 3, 3, LA_NO_HINT, LA_DEFAULT_ATTRIBUTES);
    
    free(bufferX);
    return matrixS;
    
}


//- (la_object_t)computePerspectiveMatrixWithsrcPoint1:(NSPoint)srcPoint1 srcPoint2:(NSPoint)srcPoint2 srcPoint3:(NSPoint)srcPoint3 srcPoint4:(NSPoint)srcPoint4 desPoint1:(NSPoint)desPoint1 desPoint2:(NSPoint)desPoint2 desPoint3:(NSPoint)desPoint3 desPoint4:(NSPoint)desPoint4
//{
//    NSPoint src[4];
//    src[0] = srcPoint1;
//    src[1] = srcPoint2;
//    src[2] = srcPoint3;
//    src[3] = srcPoint4;
//    NSPoint dst[4];
//    dst[0] = desPoint1;
//    dst[1] = desPoint2;
//    dst[2] = desPoint3;
//    dst[3] = desPoint4;
//    
//    float *bufferA = malloc(64 * sizeof(float));
//    float *bufferB = malloc(8 * sizeof(float));
//    for( int i = 0; i < 4; ++i )
//    {
//        bufferA[i * 8 + 0] = bufferA[(i + 4) * 8 + 3] = src[i].x;
//        bufferA[i * 8 + 1] = bufferA[(i + 4) * 8 + 4] = src[i].y;
//        bufferA[i * 8 + 2] = bufferA[(i + 4) * 8 + 5] = 1.0;
//        bufferA[i * 8 + 3] = bufferA[i * 8 + 4] = bufferA[i * 8 + 5] = 0.0;
//        bufferA[(i + 4) * 8 + 0] = bufferA[(i + 4) * 8 + 1] = bufferA[(i + 4) * 8 + 2] = 0.0;
//        bufferA[i * 8 + 6] = -src[i].x * dst[i].x;
//        bufferA[i * 8 + 7] = -src[i].y * dst[i].x;
//        bufferA[(i + 4) * 8 + 6] = -src[i].x * dst[i].y;
//        bufferA[(i + 4) * 8 + 7] = -src[i].y * dst[i].y;
//        bufferB[i] = dst[i].x;
//        bufferB[i + 4] = dst[i].y;
//    }
//    
////    for (int i = 0; i < 8; i++) {
////        for (int j = 0; j < 8; j++) {
////            if (i > j) {
////                float tt=bufferA[i*8+j];
////                bufferA[i*8+j]=bufferA[j*8+i];
////                bufferA[j*8+i]=tt;
////            }
////        }
////    }
//
//    
//    la_object_t matrixA = la_matrix_from_float_buffer(bufferA, 8, 8, 8, LA_NO_HINT, LA_DEFAULT_ATTRIBUTES);
//    //matrixA = la_transpose(matrixA);
//    la_object_t vectorB = la_vector_from_float_buffer(bufferB, 8, 1, LA_DEFAULT_ATTRIBUTES);
//    la_object_t matrixX = la_solve(matrixA, vectorB);
//    float *bufferX = malloc(9 * sizeof(float));
//    la_vector_to_float_buffer(bufferX, 1, matrixX);
//    bufferX[8] = 1.0;
//    
//    la_object_t matrixS = la_matrix_from_float_buffer(bufferX, 3, 3, 3, LA_NO_HINT, LA_DEFAULT_ATTRIBUTES);
//    return matrixS;
// 
//}

- (la_object_t)getVector3FromPoints:(NSPoint)point
{
    float *buffer = malloc(3 * sizeof(float));
    buffer[0] = point.x;
    buffer[1] = point.y;
    buffer[2] = 1.0;
    la_object_t vector = la_vector_from_float_buffer(buffer, 3, 1, LA_DEFAULT_ATTRIBUTES);
    free(buffer);
    return vector;
}

- (NSPoint)getPointFromVector3:(la_object_t)vector
{
    float *buffer = malloc(3 * sizeof(float));
    la_vector_to_float_buffer(buffer, 1, vector);
    NSPoint point = NSMakePoint(buffer[0], buffer[1]);
    free(buffer);
    return point;
}

- (NSPoint)getTranformedPointFromSrcPoint:(NSPoint)srcPoint transformMatrix:(la_object_t)matrix
{
    la_object_t src = [self getVector3FromPoints:srcPoint];
    la_object_t des = la_matrix_product(matrix, src);
    return [self getPointFromVector3:des];
}


-(void)makeAffineTransform
{
    if (isnan(m_topLeftPoint.x) || isnan(m_topLeftPoint.y)) {
        return;
    }
    //NSLog(@"makeAffineTransform");
    SEL sel = @selector(makeAffineTransformInThread);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
     sel object: nil];
    [self performSelector: sel withObject: nil afterDelay: 0.05];
    
}


-(void)makeAffineTransformInThread
{
    //NSLog(@"makeAffineTransformInThread");
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    la_object_t matrixS;
    if (m_useSelection) {
        
    }else{
        if ([m_transformedLayerInfoArray count] > 1) {
            matrixS = [self computePerspectiveMatrixWithsrcPoint1:m_topLeftPointOriginal srcPoint2:m_topRightPointOriginal srcPoint3:m_bottumRightPointOriginal srcPoint4:m_bottumLeftPointOriginal desPoint1:m_topLeftPoint desPoint2:m_topRightPoint desPoint3:m_bottumRightPoint desPoint4:m_bottumLeftPoint];
        }
        
    }
    for (int i = 0; i < [m_transformedLayerInfoArray count]; i++) {
        PSLayerTransformInfo *info = [m_transformedLayerInfoArray objectAtIndex:i];
        PSAffinePerspectiveTransform *controller = info.transformController;
        PSAbstractLayer* tempLayer = info.transformedLayer;
        int spp = [(PSLayer*)tempLayer spp];
        int xoff = [tempLayer xoff];
        int yoff = [tempLayer yoff];
        int width = [tempLayer width];
        int height = [tempLayer height];
        if (width == 0 || height == 0) {
            continue;
        }
        
        NSPoint tl = m_topLeftPoint;
        NSPoint tr = m_topRightPoint;
        NSPoint br = m_bottumRightPoint;
        NSPoint bl = m_bottumLeftPoint;
        
        int newWidth, newHeight;
        int newXOffset, newYOffset;
        
        if (m_useSelection) {
            IntPoint tlp = NSPointMakeIntPoint(tl);
            IntPoint trp = NSPointMakeIntPoint(tr);
            IntPoint brp = NSPointMakeIntPoint(br);
            IntPoint blp = NSPointMakeIntPoint(bl);
            
            
            tlp.x = tlp.x - info.selectedRect.origin.x - xoff;
            tlp.y = tlp.y - info.selectedRect.origin.y - yoff;
            trp.x = trp.x - info.selectedRect.origin.x - xoff;
            trp.y = trp.y - info.selectedRect.origin.y - yoff;
            brp.x = brp.x - info.selectedRect.origin.x - xoff;
            brp.y = brp.y - info.selectedRect.origin.y - yoff;
            blp.x = blp.x - info.selectedRect.origin.x - xoff;
            blp.y = blp.y - info.selectedRect.origin.y - yoff;
            
            CGImageRef imageRef = [controller makePerspectiveTransformImageRefWithPoint_tl:tlp Point_tr:trp Point_br:brp Point_bl:blp newWidth:&newWidth newHeight:&newHeight newXOff:&newXOffset newYOff:&newYOffset];
            
            
            newXOffset = newXOffset + info.selectedRect.origin.x + xoff;
            newYOffset = newYOffset + info.selectedRect.origin.y + yoff;
            
            
            int minx = MIN(xoff, newXOffset);
            int maxx = MAX(xoff + width, newXOffset + newWidth);
            int newXOffsetBig = minx;
            int newWidthBig = maxx- minx;
            int miny = MIN(yoff, newYOffset);
            int maxy = MAX(yoff + height, newYOffset + newHeight);
            int newYOffsetBig = miny;
            int newHeightBig = maxy- miny;
            
            CGLayerRef resultLayerRef = NULL;
            CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
            CGContextRef bitmapContext = CGBitmapContextCreate(NULL, newWidthBig, newHeightBig, 8, spp * newWidthBig, defaultColorSpace, kCGImageAlphaPremultipliedLast);
            assert(bitmapContext);
            resultLayerRef = CGLayerCreateWithContext(bitmapContext, CGSizeMake(newWidthBig, newHeightBig), nil);
            assert(resultLayerRef);
            CGContextRelease(bitmapContext);
            CGContextRef layerContext= CGLayerGetContext(resultLayerRef);
            CGContextClearRect(layerContext, CGRectMake(0, 0, newWidthBig, newHeightBig));
            customDrawImage(layerContext, info.stayedImageRef, CGRectMake(xoff - newXOffsetBig, (yoff - newYOffsetBig), width, height));
            customDrawImage(layerContext, imageRef, CGRectMake(newXOffset - newXOffsetBig, newYOffset - newYOffsetBig, newWidth, newHeight));
            
            CGColorSpaceRelease(defaultColorSpace);
            
            [self lockNewCGLayer:YES];
            CGImageRelease(imageRef);
            if (info.newCGLayerRef) {
                CGLayerRelease(info.newCGLayerRef);
                info.newCGLayerRef = NULL;
            }
            info.newCGLayerRef = resultLayerRef;
            [self lockNewCGLayer:NO];
            
            info.newWidth = newWidthBig;
            info.newHeight = newHeightBig;
            info.newXOffset = newXOffsetBig;
            info.newYOffset = newYOffsetBig;
        }else{
            
            if ([m_transformedLayerInfoArray count] > 1) {
                tl = NSMakePoint(xoff, yoff);
                tr = NSMakePoint(xoff + width, yoff);
                br = NSMakePoint(xoff + width, yoff + height);
                bl = NSMakePoint(xoff, yoff + height);
                
//                tl = [self getTranformedPointFromSrcPoint:tl transformMatrix:matrixS];
//                tr = [self getTranformedPointFromSrcPoint:tr transformMatrix:matrixS];
//                br = [self getTranformedPointFromSrcPoint:br transformMatrix:matrixS];
//                bl = [self getTranformedPointFromSrcPoint:bl transformMatrix:matrixS];
                
                CGPoint source[4];
                source[0] = m_topLeftPointOriginal;
                source[1] = m_topRightPointOriginal;
                source[2] = m_bottumRightPointOriginal;
                source[3] = m_bottumLeftPointOriginal;
                CGPoint destination[4];
                destination[0] = m_topLeftPoint;
                destination[1] = m_topRightPoint;
                destination[2] = m_bottumRightPoint;
                destination[3] = m_bottumLeftPoint;
                
//                tl = [self transferPoint:tl refS:source refD:destination];
//                tr = [self transferPoint:tr refS:source refD:destination];
//                br = [self transferPoint:br refS:source refD:destination];
//                bl = [self transferPoint:bl refS:source refD:destination];
                
//                CGPoint source1[4];
//                source1[0] = CGPointMake(-1000, -1000);
//                source1[1] = CGPointMake(1000, -1000);
//                source1[2] = CGPointMake(1000, 1000);
//                source1[3] = CGPointMake(-1000, 1000);
//                
//                CGPoint destination1[4];
//                destination1[0] = [self transferPoint:source1[0] refS:source refD:destination];
//                destination1[1] = [self transferPoint:source1[1] refS:source refD:destination];
//                destination1[2] = [self transferPoint:source1[2] refS:source refD:destination];
//                destination1[3] = [self transferPoint:source1[3] refS:source refD:destination];
//                
//                tl = [self transferPoint:tl refS:source1 refD:destination1];
//                tr = [self transferPoint:tr refS:source1 refD:destination1];
//                br = [self transferPoint:br refS:source1 refD:destination1];
//                bl = [self transferPoint:bl refS:source1 refD:destination1];
                
                
                PSPerspectiveTransform transform = quadrilateralToQuadrilateral(source[0].x, source[0].y, source[1].x, source[1].y, source[2].x, source[2].y, source[3].x, source[3].y, destination[0].x, destination[0].y, destination[1].x, destination[1].y, destination[2].x, destination[2].y, destination[3].x, destination[3].y);
                tl = perspectiveTransfromPoint(tl, transform);
                tr = perspectiveTransfromPoint(tr, transform);
                br = perspectiveTransfromPoint(br, transform);
                bl = perspectiveTransfromPoint(bl, transform);
                
                
            }
            
            IntPoint tlp = NSPointMakeIntPoint(tl);
            IntPoint trp = NSPointMakeIntPoint(tr);
            IntPoint brp = NSPointMakeIntPoint(br);
            IntPoint blp = NSPointMakeIntPoint(bl);
            
            CGImageRef imageRef = [controller makePerspectiveTransformImageRefWithPoint_tl:tlp Point_tr:trp Point_br:brp Point_bl:blp newWidth:&newWidth newHeight:&newHeight newXOff:&newXOffset newYOff:&newYOffset];
            newWidth = MAX(newWidth, 1);
            newHeight = MAX(newHeight, 1);
            CGLayerRef resultLayerRef = NULL;
            CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
            CGContextRef bitmapContext = CGBitmapContextCreate(NULL, newWidth, newHeight, 8, spp * newWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
            assert(bitmapContext);
            resultLayerRef = CGLayerCreateWithContext(bitmapContext, CGSizeMake(newWidth, newHeight), nil);
            assert(resultLayerRef);
            CGContextRelease(bitmapContext);
            
            CGContextRef layerContext= CGLayerGetContext(resultLayerRef);
            CGContextClearRect(layerContext, CGRectMake(0, 0, newWidth, newHeight));
            customDrawImage(layerContext, imageRef, CGRectMake(0, 0, newWidth, newHeight));
            CGColorSpaceRelease(defaultColorSpace);
            
            [self lockNewCGLayer:YES];
            CGImageRelease(imageRef);
            if (info.newCGLayerRef) {
                CGLayerRelease(info.newCGLayerRef);
                info.newCGLayerRef = NULL;
            }
            info.newCGLayerRef = resultLayerRef;
            [self lockNewCGLayer:NO];
            
            info.newWidth = newWidth;
            info.newHeight = newHeight;
            info.newXOffset = newXOffset;
            info.newYOffset = newYOffset;
        }
        
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    //NSLog(@"time for transform %f", [NSDate timeIntervalSinceReferenceDate] - begin);
    
}

void customDrawImage(CGContextRef context, CGImageRef image , CGRect rect)
{
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);//4
    CGContextTranslateCTM(context, 0, rect.size.height);//3
    CGContextScaleCTM(context, 1.0, -1.0);//2
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);//1
    CGContextDrawImage(context, rect, image);
    CGContextRestoreGState(context);
    
}

- (void)doNotApplyAffineTransform
{
    for (int i = 0; i < [m_transformedLayerInfoArray count]; i++)
    {
        PSLayerTransformInfo *info = [m_transformedLayerInfoArray objectAtIndex:i];
        
        [self lockNewCGLayer:YES];
        
        if (info.newCGLayerRef)
        {
            CGLayerRelease(info.newCGLayerRef);
      //      info.newCGLayerRef = NULL;
        }
        
        [self lockNewCGLayer:NO];
        
        if (m_useSelection)
        {
            if (info.selectedData)
            {
                free(info.selectedData);
        //        info.selectedData = NULL;
            }
            if (info.stayedData)
            {
                free(info.selectedData);
          //      info.selectedData = NULL;
            }
            if (info.stayedImageRef)
            {
                CGImageRelease(info.stayedImageRef);
            //    info.stayedImageRef = NULL;
            }
        }
        
        if (info.transformController)
        {
            [info.transformController release];
         //   info.transformController = nil;
        }
    }
    
    m_hasBeginTransform = NO;
    m_needUpdateCenterPoint = YES;
    m_topLeftPoint = NSMakePoint(-50000.0, 0);
    
    [m_transformedLayerInfoArray removeAllObjects];
    [[m_idDocument docView] setNeedsDisplay:YES];
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (unsigned char *)getBufferFromCGLayerRef:(CGLayerRef)layerRef width:(int)width height:(int)height spp:(int)spp
{
    unsigned char *data = malloc(make_128(width * height * spp));
    memset(data, 0, width * height * spp);
    
    CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(data, width, height, 8, spp * width, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    CGRect destRect = CGRectMake(0, 0, width, height);
    CGContextDrawLayerInRect(bitmapContext, destRect, layerRef);
    //CGContextRestoreGState(bitmapContext);
    
    unsigned char temp[spp * width];
    int j;
    for (j = 0; j < height / 2; j++) {
        memcpy(temp, data + (j * width) * spp, spp * width);
        memcpy(data + (j * width) * spp, data + ((height - j - 1) * width) * spp, spp * width);
        memcpy(data + ((height - j - 1) * width) * spp, temp, spp * width);
    }
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(defaultColorSpace);

    return data;

}

- (CGPoint) transferPoint:(CGPoint)sPoint refS:(CGPoint[4])source refD:(CGPoint[4])destination
{
    float ADDING = 0.001; // to avoid dividing by zero
    CGPoint dPoint;
    float xI = sPoint.x;
    float yI = sPoint.y;
    float xA = source[0].x;
    float yA = source[0].y;
    
    float xC = source[2].x;
    float yC = source[2].y;
    
    float xAu = destination[0].x;
    float yAu = destination[0].y;
    
    float xBu = destination[1].x;
    float yBu = destination[1].y;
    
    float xCu = destination[2].x;
    float yCu = destination[2].y;
    
    float xDu = destination[3].x;
    float yDu = destination[3].y;
    
    // Calcultations
    // if points are the same, have to add a ADDING to avoid dividing by zero
    if (xBu==xCu) xCu+=ADDING;
    if (xAu==xDu) xDu+=ADDING;
    if (xAu==xBu) xBu+=ADDING;
    if (xDu==xCu) xCu+=ADDING;
    float kBC = (yBu-yCu)/(xBu-xCu);
    float kAD = (yAu-yDu)/(xAu-xDu);
    float kAB = (yAu-yBu)/(xAu-xBu);
    float kDC = (yDu-yCu)/(xDu-xCu);
    
    if (kBC==kAD) kAD+=ADDING;
    float xE = (kBC*xBu - kAD*xAu + yAu - yBu) / (kBC-kAD);
    float yE = kBC*(xE - xBu) + yBu;
    
    if (kAB==kDC) kDC+=ADDING;
    float xF = (kAB*xBu - kDC*xCu + yCu - yBu) / (kAB-kDC);
    float yF = kAB*(xF - xBu) + yBu;
    
    if (xE==xF) xF+=ADDING;
    float kEF = (yE-yF) / (xE-xF);
    
    if (kEF==kAB) kAB+=ADDING;
    float xG = (kEF*xDu - kAB*xAu + yAu - yDu) / (kEF-kAB);
    float yG = kEF*(xG - xDu) + yDu;
    
    if (kEF==kBC) kBC+=ADDING;
    float xH = (kEF*xDu - kBC*xBu + yBu - yDu) / (kEF-kBC);
    float yH = kEF*(xH - xDu) + yDu;
    
    float rG = (yC-yI)/(yC-yA);
    float rH = (xI-xA)/(xC-xA);
    
    float xJ = (xG-xDu)*rG + xDu;
    float yJ = (yG-yDu)*rG + yDu;
    
    float xK = (xH-xDu)*rH + xDu;
    float yK = (yH-yDu)*rH + yDu;
    
    if (xF==xJ) xJ+=ADDING;
    if (xE==xK) xK+=ADDING;
    float kJF = (yF-yJ) / (xF-xJ); //23
    float kKE = (yE-yK) / (xE-xK); //12
    
    float xKE;
    if (kJF==kKE) kKE+=ADDING;
    float xIu = (kJF*xF - kKE*xE + yE - yF) / (kJF-kKE);
    float yIu = kJF * (xIu - xJ) + yJ;
    
//    var b={x:xIu,y:yIu};
//    b.x=Math.round(b.x);
//    b.y=Math.round(b.y);
    
    dPoint.x = xIu;
    dPoint.y = yIu;
    return dPoint;
}

- (void)applyAffineTransform
{
    for (int i = 0; i < [m_transformedLayerInfoArray count]; i++)
    {
        PSLayerTransformInfo *info = [m_transformedLayerInfoArray objectAtIndex:i];
        PSLayer *layer = info.transformedLayer;
        if(layer.layerFormat == PS_TEXT_LAYER  || (layer.layerFormat == PS_VECTOR_LAYER))
        {
            CGPoint source[4];
            source[0] = m_topLeftPointOriginal;
            source[1] = m_topRightPointOriginal;
            source[2] = m_bottumRightPointOriginal;
            source[3] = m_bottumLeftPointOriginal;
            CGPoint destination[4];
            destination[0] = m_topLeftPoint;
            destination[1] = m_topRightPoint;
            destination[2] = m_bottumRightPoint;
            destination[3] = m_bottumLeftPoint;
            
            CGAffineTransform transformInvert = CGAffineTransformInvert([(PSVecLayer *)layer transform]);
            source[0] = CGPointApplyAffineTransform(source[0], transformInvert);
            source[1] = CGPointApplyAffineTransform(source[1], transformInvert);
            source[2] = CGPointApplyAffineTransform(source[2], transformInvert);
            source[3] = CGPointApplyAffineTransform(source[3], transformInvert);
            
            destination[0] = CGPointApplyAffineTransform(destination[0], transformInvert);
            destination[1] = CGPointApplyAffineTransform(destination[1], transformInvert);
            destination[2] = CGPointApplyAffineTransform(destination[2], transformInvert);
            destination[3] = CGPointApplyAffineTransform(destination[3], transformInvert);
            
            PSPerspectiveTransform transform = quadrilateralToQuadrilateral(source[0].x, source[0].y, source[1].x, source[1].y, source[2].x, source[2].y, source[3].x, source[3].y, destination[0].x, destination[0].y, destination[1].x, destination[1].y, destination[2].x, destination[2].y, destination[3].x, destination[3].y);
            
            PSPerspectiveTransform reverseTransform = quadrilateralToQuadrilateral(destination[0].x, destination[0].y, destination[1].x, destination[1].y, destination[2].x, destination[2].y, destination[3].x, destination[3].y, source[0].x, source[0].y, source[1].x, source[1].y, source[2].x, source[2].y, source[3].x, source[3].y);
            
            [(PSVecLayer *)layer concatPerspectiveTransform:transform withReverseTransform:reverseTransform];
        }
        else
        {
            int newWidth = info.newWidth;
            int newHight = info.newHeight;
            int newXOff = info.newXOffset;
            int newYOff = info.newYOffset;
            int spp = [layer spp];
            unsigned char *newData = [self getBufferFromCGLayerRef:info.newCGLayerRef width:newWidth height:newHight spp:spp];
            unpremultiplyBitmap(spp, newData, newData, newWidth * newHight);
            
            // unsigned char *oldData = [layer getRawData];
            int  width= [layer width];
            int  height= [layer height];
            int  xoff= [layer xoff];
            int  yoff= [layer yoff];
            int index = [layer index];
            
            int undoIndex = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, width, height) automatic:NO];
            
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoApplyTransfromForLayer:index  width:width height:height xoffset:xoff yoffset:yoff undoIndex:undoIndex];
            [layer updateData:newData width:newWidth height:newHight xoffset:newXOff yoffset:newYOff];
        }
    
        
    }
    [self doNotApplyAffineTransform];
}

- (void)undoApplyTransfromForLayer:(int)layerIndex  width:(int)width height:(int)height xoffset:(int)xoff yoffset:(int)yoff undoIndex:(int)undoIndex
{
    PSLayer* layer = [[m_idDocument contents] layer:layerIndex];
    
  //  unsigned char *data1 = [layer getRawData];
    int  width1= [layer width];
    int  height1= [layer height];
    int  xoff1= [layer xoff];
    int  yoff1= [layer yoff];
    
    int undoIndex1 = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, width1, height1) automatic:NO];
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] redoApplyTransfromForLayer:layerIndex  width:width1 height:height1 xoffset:xoff1 yoffset:yoff1 undoIndex:undoIndex1 redoIndex:undoIndex];
    [layer resetLayerInfoAndDataWithWidth:width height:height xoffset:xoff yoffset:yoff];
    [[layer seaLayerUndo] restoreSnapshot:undoIndex automatic:NO];
    [layer refreshTotalToRender];
    
  //  [[[m_idDocument tools] currentTool] redoUndoEventDidEndForLayer:layer];
    [[[m_idDocument tools] getTool:kTransformTool] redoUndoEventDidEndForLayer:layer];  //wzq

}

- (void)redoApplyTransfromForLayer:(int)layerIndex  width:(int)width height:(int)height xoffset:(int)xoff yoffset:(int)yoff undoIndex:(int)undoIndex redoIndex:(int)redoIndex
{
    PSLayer* layer = [[m_idDocument contents] layer:layerIndex];
    
  //  unsigned char *data1 = [layer getRawData];
    int  width1= [layer width];
    int  height1= [layer height];
    int  xoff1= [layer xoff];
    int  yoff1= [layer yoff];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] redoApplyTransfromForLayer:layerIndex  width:width1 height:height1 xoffset:xoff1 yoffset:yoff1 undoIndex:redoIndex redoIndex:undoIndex];
    [layer resetLayerInfoAndDataWithWidth:width height:height xoffset:xoff yoffset:yoff];
    [[layer seaLayerUndo] restoreSnapshot:undoIndex automatic:NO];
    [layer refreshTotalToRender];
    
    [[[m_idDocument tools] getTool:kTransformTool] redoUndoEventDidEndForLayer:layer];
    
}


@end
