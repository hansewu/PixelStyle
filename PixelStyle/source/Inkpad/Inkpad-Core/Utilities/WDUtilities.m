//
//  WDUtilities.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#if TARGET_OS_MAC
#import <UIKit/UIKit.h>
#endif

#import "WDBezierNode.h"
#import "WDBezierSegment.h"
#import "WDPath.h"
#import "WDUtilities.h"
#include <CommonCrypto/CommonHMAC.h>

#define kMiterLimit 10

#pragma mark Color Conversion

void HSVtoRGB(float h, float s, float v, float *r, float *g, float *b)
{
    if (s == 0) {
        *r = *g = *b = v;
    } else {
        float   f,p,q,t;
        int     i;
        
        h *= 360;
        
        if (h == 360.0f) {
            h = 0.0f;
        }
        
        h /= 60;
        i = floor(h);
        
        f = h - i;
        p = v * (1.0 - s);
        q = v * (1.0 - (s*f));
        t = v * (1.0 - (s * (1.0 - f)));
        
        switch (i) {
            case 0: *r = v; *g = t; *b = p; break;
            case 1: *r = q; *g = v; *b = p; break;
            case 2: *r = p; *g = v; *b = t; break;
            case 3: *r = p; *g = q; *b = v; break;
            case 4: *r = t; *g = p; *b = v; break;
            case 5: *r = v; *g = p; *b = q; break;
        }
    }
}   

void RGBtoHSV(float r, float g, float b, float *h, float *s, float *v)
{
    float max = MAX(r, MAX(g, b));
    float min = MIN(r, MIN(g, b));
    float delta = max - min;
    
    *v = max;
    *s = (max != 0.0f) ? (delta / max) : 0.0f;
    
    if (*s == 0.0f) {
        *h = 0.0f;
    } else {
        if (r == max) {
            *h = (g - b) / delta;
        } else if (g == max) {
            *h = 2.0f + (b - r) / delta;
        } else if (b == max) {
            *h = 4.0f + (r - g) / delta;
        }
        
        *h *= 60.0f;
        
        if (*h < 0.0f) {
            *h += 360.0f;
        }
    }
    
    *h /= 360.0f;
}

#pragma mark -
#pragma mark Drawing Functions

void WDDrawCheckersInRect(CGContextRef ctx, CGRect dest, int size)
{
    CGRect  square = CGRectMake(0, 0, size, size);
    float   startx = CGRectGetMinX(dest);
    float   starty = CGRectGetMinY(dest);
    
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, dest);
    
    CGContextSetGrayFillColor(ctx, 0.9f, 1.0f);
    CGContextFillRect(ctx, dest);
    
    CGContextSetGrayFillColor(ctx, 0.78f, 1.0f);
    for (int y = 0; y * size < CGRectGetHeight(dest); y++) {
        for (int x = 0; x * size < CGRectGetWidth(dest); x++) {
            if ((y + x) % 2) {
                square.origin.x = startx + x * size;
                square.origin.y = starty + y * size;
                CGContextFillRect(ctx, square);
            }
        }
    }
    
    CGContextRestoreGState(ctx);
}

void WDDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest)
{
    float   minX = CGRectGetMinX(dest);
    float   maxX = CGRectGetMaxX(dest);
    float   minY = CGRectGetMinY(dest);
    float   maxY = CGRectGetMaxY(dest);
    
    // preserve the existing color
    CGContextSaveGState(ctx);
    [[UIColor whiteColor] set];
    CGContextFillRect(ctx, dest);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, minX, minY);
    CGPathAddLineToPoint(path, NULL, maxX, minY);
    CGPathAddLineToPoint(path, NULL, minX, maxY);
    CGPathCloseSubpath(path);
    
    [[UIColor blackColor] set];
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
    
    CGPathRelease(path);
}

void WDContextDrawImageToFill(CGContextRef ctx, CGRect bounds, CGImageRef imageRef)
{
    size_t  width = CGImageGetWidth(imageRef);
    size_t  height = CGImageGetHeight(imageRef);
    float   wScale = CGRectGetWidth(bounds) / width;
    float   hScale = CGRectGetHeight(bounds) / height;
    float   scale = MAX(wScale, hScale);
    float   hOffset = 0.0f, vOffset = 0.0f;
    
    CGRect  rect = CGRectMake(0, 0, width * scale, height * scale);
    
    if (CGRectGetWidth(rect) > CGRectGetWidth(bounds)) {
        hOffset = CGRectGetWidth(rect) - CGRectGetWidth(bounds);
        hOffset /= -2;
    }
    
    if (CGRectGetHeight(rect) > CGRectGetHeight(bounds)) {
        vOffset = CGRectGetHeight(rect) - CGRectGetHeight(bounds);
        vOffset /= -2;
    }
    
    rect = CGRectOffset(rect, hOffset, vOffset);
    
    CGContextDrawImage(ctx, rect, imageRef);
}

#pragma mark -
#pragma mark Mathy Stuff

float WDSineCurve(float input)
{
    float result;
    
    input *= M_PI; // move from [0.0, 1.0] tp [0.0, Pi]
    input -= M_PI_2; // shift back onto a trough
    
    result = sin(input) + 1; // add 1 to put in range [0.0,2.0]
    result /= 2; // back to [0.0, 1.0];
    
    return result;
}

float WDRandomFloat()
{
    float r = random() % 10000;
    return r / 10000.0f;
}

NSData * WDSHA1DigestForData(NSData *data)
{
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, NULL, 0, [data bytes], [data length], cHMAC);
    
    return [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
}

#pragma mark -
#pragma mark Geometry

CGSize WDSizeOfRectWithAngle(CGRect rect, float angle, CGPoint *upperLeft, CGPoint *upperRight)
{
    CGPoint center, corners[4];
    
    center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle * M_PI / 180.0f);
    
    corners[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    corners[1] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    corners[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    corners[3] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    
    for (int i = 0; i < 4; i++) {
        corners[i] = CGPointApplyAffineTransform(corners[i], transform);
    }
    center = CGPointApplyAffineTransform(center, transform);
    
    float minx = corners[0].x;
    float maxx = corners[0].x;
    float miny = corners[0].y;
    float maxy = corners[0].y;
    
    for (int i = 1; i < 4; i++) {
        minx = MIN(minx, corners[i].x);
        maxx = MAX(maxx, corners[i].x);
        miny = MIN(miny, corners[i].y);
        maxy = MAX(maxy, corners[i].y);
    }
    
    if (upperLeft) {
        *upperLeft = WDSubtractPoints(corners[0], center);
    }
    
    if (upperRight) {
        *upperRight = WDSubtractPoints(corners[3], center);
    }
    
    return CGSizeMake(maxx - minx, maxy - miny);
}

CGPoint WDNormalizePoint(CGPoint vector)
{
    float distance = WDDistance(CGPointZero, vector);
    
    if (distance == 0.0f) {
        return vector;
    }
    
    return WDMultiplyPointScalar(vector, 1.0f / distance);
}

CGRect WDGrowRectToPoint(CGRect rect, CGPoint pt)
{
    double minX, minY, maxX, maxY;
    
    minX = MIN(CGRectGetMinX(rect), pt.x);
    minY = MIN(CGRectGetMinY(rect), pt.y);
    maxX = MAX(CGRectGetMaxX(rect), pt.x);
    maxY = MAX(CGRectGetMaxY(rect), pt.y);
    
    return CGRectUnion(rect, CGRectMake(minX, minY, maxX - minX, maxY - minY));
}

CGPoint WDSharpPointInContext(CGPoint pt, CGContextRef ctx)
{
    pt = CGContextConvertPointToDeviceSpace(ctx, pt);
    pt = WDFloorPoint(pt);
    pt = WDAddPoints(pt, CGPointMake(0.5f, 0.5f));
    pt = CGContextConvertPointToUserSpace(ctx, pt);
    
    return pt;
}

CGPoint WDConstrainPoint(CGPoint delta)
{
    float   angle = atan2(delta.y, delta.x);
    float   magnitude = WDDistance(delta, CGPointZero);
    
    angle = roundf(angle / M_PI_4) * M_PI_4;
    delta.x = cos(angle) * magnitude;
    delta.y = sin(angle) * magnitude;
    
    return delta;
}

CGRect WDRectFromPoint(CGPoint a, float width, float height)
{
    return CGRectMake(a.x - (width / 2), a.y - (height / 2), width, height);
}

BOOL WDCollinear(CGPoint a, CGPoint b, CGPoint c)
{
    float temp, distances[3];
    
    distances[0] = WDDistance(a, b);
    distances[1] = WDDistance(b, c);
    distances[2] = WDDistance(a, c);

    // sort the array...
    if (distances[0] > distances[1]) {
        temp = distances[1];
        distances[1] = distances[0];
        distances[0] = temp;
    }
    
    if (distances[1] > distances[2]) {
        temp = distances[2];
        distances[2] = distances[1];
        distances[1] = temp;
    }
    
    // if the points are collinear, the sum of the shortest 2 distances is equal to the longest distance
    float shortestSum = distances[0] + distances[1];
    float difference = fabs(shortestSum - distances[2]);
    
    return (difference < 1.0e-4);
}

BOOL WDLineSegmentsIntersectWithValues(CGPoint A, CGPoint B, CGPoint C, CGPoint D, float *rV, float *sV)
{
    float denom = (B.x - A.x) * (D.y - C.y) - (B.y - A.y) * (D.x - C.x);
    
    if (denom == 0) {
        return NO;
    }
    
    float r = (A.y - C.y) * (D.x - C.x) - (A.x - C.x) * (D.y - C.y);
    r /= denom;
    
    float s = (A.y - C.y) * (B.x - A.x) - (A.x - C.x) * (B.y - A.y);
    s /= denom;
    
    if (rV) {
        *rV = r;
    }
    
    if (sV) {
        *sV = s;
    }
    
    return (r < 0 || r > 1 || s < 0 || s > 1) ? NO : YES;;
}

BOOL WDLineSegmentsIntersect(CGPoint A, CGPoint B, CGPoint C, CGPoint D)
{
    return WDLineSegmentsIntersectWithValues(A, B, C, D, NULL, NULL);
}

CGRect WDShrinkRect(CGRect rect, float percentage)
{
    float   widthInset = CGRectGetWidth(rect) * percentage;
    float   heightInset = CGRectGetHeight(rect) * percentage;
    
    return CGRectInset(rect, widthInset, heightInset);
}

CGSize WDClampSize(CGSize size, float maxDimension)
{
    if (size.width > maxDimension || size.height > maxDimension) {
        if (size.width > size.height) {
            size.height = (size.height / size.width) * maxDimension;
            size.width = maxDimension;
        } else {
            size.width = (size.width / size.height) * maxDimension;
            size.height = maxDimension;
        }
    }
    
    return size;
}

#pragma mark -
#pragma mark Paths

void convertQuadraticPathElement(void *info, const CGPathElement *element)
{
    CGMutablePathRef    converted = (CGMutablePathRef) info;
    CGPoint             prev;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            CGPathMoveToPoint(converted, NULL, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddLineToPoint:
            CGPathAddLineToPoint(converted, NULL, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddQuadCurveToPoint:
            prev = CGPathGetCurrentPoint(converted);
            
            // convert quadratic to cubic: http://fontforge.sourceforge.net/bezier.html
            CGPoint outPoint = WDAddPoints(prev, WDMultiplyPointScalar(WDSubtractPoints(element->points[0], prev), 2.0f / 3));
            CGPoint inPoint = WDAddPoints(element->points[1], WDMultiplyPointScalar(WDSubtractPoints(element->points[0], element->points[1]), 2.0f / 3));
            
            CGPathAddCurveToPoint(converted, NULL, outPoint.x, outPoint.y, inPoint.x, inPoint.y, element->points[1].x, element->points[1].y);
            break;
        case kCGPathElementAddCurveToPoint:
            CGPathAddCurveToPoint(converted, NULL, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
            break;
        case kCGPathElementCloseSubpath:
            CGPathCloseSubpath(converted);
            break;
    }
}

CGPathRef WDCreateCubicPathFromQuadraticPath(CGPathRef pathRef)
{
    CGMutablePathRef converted = CGPathCreateMutable();
        
    CGPathApply(pathRef, converted, &convertQuadraticPathElement);
    
    return converted;
}

void WDPathApplyAccumulateElement(void *info, const CGPathElement *element)
{
    NSMutableArray  *subpaths = (__bridge NSMutableArray *)info;
    WDPath          *path = [subpaths lastObject];
    WDBezierNode    *prev, *node;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            path = [[WDPath alloc] init];
            
            node = [[WDBezierNode alloc] initWithAnchorPoint:element->points[0]];
            [path.nodes addObject:node];
            
            [subpaths addObject:path];
            break;
        case kCGPathElementAddLineToPoint:
            node = [[WDBezierNode alloc] initWithAnchorPoint:element->points[0]];
            [path.nodes addObject:node];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            prev = [path lastNode];
            
            // convert quadratic to cubic: http://fontforge.sourceforge.net/bezier.html
            CGPoint outPoint = WDAddPoints(prev.anchorPoint, WDMultiplyPointScalar(WDSubtractPoints(element->points[0], prev.anchorPoint), 2.0f / 3));
            CGPoint inPoint = WDAddPoints(element->points[1], WDMultiplyPointScalar(WDSubtractPoints(element->points[0], element->points[1]), 2.0f / 3));
            
            // update and replace previous node
            node = [[WDBezierNode alloc] initWithInPoint:prev.inPoint anchorPoint:prev.anchorPoint outPoint:outPoint];
            [path.nodes removeLastObject];
            [path.nodes addObject:node];
            
            node = [[WDBezierNode alloc] initWithInPoint:inPoint anchorPoint:element->points[1] outPoint:element->points[1]];
            [path.nodes addObject:node];
            break;
        case kCGPathElementAddCurveToPoint:
            prev = [path lastNode];
            
            // update and replace previous node
            node = [[WDBezierNode alloc] initWithInPoint:prev.inPoint anchorPoint:prev.anchorPoint outPoint:element->points[0]];
            [path.nodes removeLastObject];
            [path.nodes addObject:node];
            
            node = [[WDBezierNode alloc] initWithInPoint:element->points[1] anchorPoint:element->points[2] outPoint:element->points[2]];
            [path.nodes addObject:node];
            break;
        case kCGPathElementCloseSubpath:
            [path setClosedQuiet:YES];
            break;
    }
}

CGRect WDStrokeBoundsForPath(CGPathRef pathRef, WDStrokeStyle *strokeStyle) 
{
    CGRect basicBounds = CGPathGetPathBoundingBox(pathRef);
    
    if (!strokeStyle || ![strokeStyle willRender]) {
        return basicBounds;
    }
    
    float halfWidth = strokeStyle.width / 2.0f;
    float outset = sqrt((halfWidth * halfWidth) * 2);
    
    // expand by half the stroke width to find the basic bounding box
    CGRect styleBounds = CGRectInset(basicBounds, -outset, -outset);
    
    // include miter joins on corners
    if (strokeStyle.join == kCGLineJoinMiter) {
        NSMutableArray *subpaths = [NSMutableArray array];
        CGPathApply(pathRef, (__bridge void *)(subpaths), &WDPathApplyAccumulateElement);
        
        for (WDPath *subpath in subpaths) {
            NSArray         *nodes = subpath.nodes;
            NSInteger       nodeCount = subpath.closed ? nodes.count + 1 : nodes.count;
            
            if (nodeCount < 3) {
                continue;
            }
            
            WDBezierNode    *prev = nodes[0];
            WDBezierNode    *curr = nodes[1];
            WDBezierNode    *next;
            CGPoint         inPoint, outPoint, inVec, outVec;
            float           miterLength, angle;
            
            for (int i = 1; i < nodeCount; i++) {
                next = nodes[(i+1) % nodes.count];
                
                inPoint = [curr hasInPoint] ? curr.inPoint : prev.outPoint;
                outPoint = [curr hasOutPoint] ? curr.outPoint : next.inPoint;
                
                inVec = WDSubtractPoints(inPoint, curr.anchorPoint);
                outVec = WDSubtractPoints(outPoint, curr.anchorPoint);
                
                inVec = WDNormalizePoint(inVec);
                outVec = WDNormalizePoint(outVec);
                
                angle = acos(inVec.x * outVec.x + inVec.y * outVec.y);
                miterLength = strokeStyle.width / sin(angle / 2.0f);
                
                if ((miterLength / strokeStyle.width) < kMiterLimit) {
                    CGPoint avg = WDAveragePoints(inVec, outVec);
                    CGPoint directed = WDMultiplyPointScalar(WDNormalizePoint(avg), -miterLength / 2.0f);
                    
                    styleBounds = WDGrowRectToPoint(styleBounds, WDAddPoints(curr.anchorPoint, directed));
                }
                
                prev = curr;
                curr = next;
            }
        }
    }
    
    return styleBounds;
}

typedef struct {
    CGMutablePathRef mutablePath;
    CGAffineTransform transform;
} WDPathAndTransform;

void transformPathElement(void *info, const CGPathElement *element)
{
    WDPathAndTransform  pathAndTransform = *((WDPathAndTransform *) info);
    CGAffineTransform   transform = pathAndTransform.transform;
    CGMutablePathRef    pathRef = pathAndTransform.mutablePath;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            CGPathMoveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddLineToPoint:
            CGPathAddLineToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddQuadCurveToPoint:
            CGPathAddQuadCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y);
            break;
        case kCGPathElementAddCurveToPoint:
            CGPathAddCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
            break;
        case kCGPathElementCloseSubpath:
            CGPathCloseSubpath(pathRef);
            break;
            
    }
}



CGPathRef WDCreateTransformedCGPathRef(CGPathRef pathRef, CGAffineTransform transform)
{
    CGMutablePathRef    transformedPath = CGPathCreateMutable();
    WDPathAndTransform  pathAndTransform = {transformedPath, transform};
    
    CGPathApply(pathRef, &pathAndTransform, &transformPathElement);
    
    return transformedPath;
}


typedef struct {
    CGMutablePathRef mutablePath;
//    CGAffineTransform transform;
    CUSTOM_TRANSFORM *transformCustom;
    CGRect rect;
} CUSTOMTransPathAndTransform;

typedef struct {
    CGMutablePathRef mutablePath;
    PSPerspectiveTransform transformPers;
    CGRect rect;
} CUSTOMTransPathAndPerspective;

static CGPoint arctransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform)
{
    CGPoint pointOut;
    
    if(pCustTransform->transformCustom->nBendPercent == 0) return point;
    double dBendPercent = fabs((double)pCustTransform->transformCustom->nBendPercent);
    
    double dHalfWidth = (double)(pCustTransform->rect.size.width/2.0);
    double dBlend  = dBendPercent * dHalfWidth/100.0;
    
    double dRadius = (dBlend*dBlend + dHalfWidth*dHalfWidth)/(2.0 * dBlend);
    double dAngle  = asin(dHalfWidth/dRadius);
    
    if(pCustTransform->transformCustom->nBendPercent >  0)
        point.y = pCustTransform->rect.size.height - point.y;
    
    pointOut.x = (point.y + dRadius) * sin((point.x-dHalfWidth) * dAngle/dHalfWidth);
    pointOut.y = sqrt((point.y + dRadius) * (point.y + dRadius) - pointOut.x * pointOut.x) + (dBlend - dRadius);
    pointOut.x += dHalfWidth;
    
    if(pCustTransform->transformCustom->nBendPercent >  0)
        pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    return pointOut;
}

static CGPoint lowerarctransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform)
{
    CGPoint pointOut;
    
    if(pCustTransform->transformCustom->nBendPercent == 0) return point;
    double dBendPercent = fabs((double)pCustTransform->transformCustom->nBendPercent);
    
    double dHalfWidth = (double)(pCustTransform->rect.size.width/2.0);
    double dBlend  = dBendPercent * dHalfWidth/100.0;
    dBlend *= point.y/pCustTransform->rect.size.height;
    if(dBlend < 0.001)  return point;
    
    double dRadius = (dBlend*dBlend + dHalfWidth*dHalfWidth)/(2.0 * dBlend);
    double dAngle  = asin(dHalfWidth/dRadius);
    
    if(pCustTransform->transformCustom->nBendPercent <  0)
        point.y = pCustTransform->rect.size.height - point.y;
    double pointyold = point.y;
    point.y = 0;
    pointOut.x = (point.y + dRadius) * sin((point.x-dHalfWidth) * dAngle/dHalfWidth);
    pointOut.y = sqrt((point.y + dRadius) * (point.y + dRadius) - pointOut.x * pointOut.x) + (dBlend - dRadius);
    pointOut.x += dHalfWidth;
    
    pointOut.y += pointyold;
    if(pCustTransform->transformCustom->nBendPercent <  0)
        pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    return pointOut;
}

static CGPoint upperarctransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform)
{
    CGPoint pointOut = point;
    
    if(pCustTransform->transformCustom->nBendPercent == 0) return point;
    double dBendPercent = fabs((double)pCustTransform->transformCustom->nBendPercent);
    
    double dHalfWidth = (double)(pCustTransform->rect.size.width/2.0);
    double dBlend  = dBendPercent * dHalfWidth/100.0;
    
    if(point.y > pCustTransform->rect.size.height) return point;
    point.y = pCustTransform->rect.size.height - point.y;

    dBlend *= point.y/pCustTransform->rect.size.height;
    if(dBlend < 0.00000001)  return pointOut;
    
    double dRadius = (dBlend*dBlend + dHalfWidth*dHalfWidth)/(2.0 * dBlend);
    double dAngle  = asin(dHalfWidth/dRadius);
    
    if(pCustTransform->transformCustom->nBendPercent <  0)
        point.y = pCustTransform->rect.size.height - point.y;
    double pointyold = point.y;
    point.y = 0;
    pointOut.x = (point.y + dRadius) * sin((point.x-dHalfWidth) * dAngle/dHalfWidth);
    pointOut.y = sqrt((point.y + dRadius) * (point.y + dRadius) - pointOut.x * pointOut.x) + (dBlend - dRadius);
    pointOut.x += dHalfWidth;
    
    pointOut.y += pointyold;
    if(pCustTransform->transformCustom->nBendPercent <  0)
        pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    return pointOut;
}


static CGPoint archtransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform)
{
    CGPoint pointOut = point;
    
    if(pCustTransform->transformCustom->nBendPercent == 0) return point;
    double dBendPercent = fabs((double)pCustTransform->transformCustom->nBendPercent);
    
    double dHalfWidth = (double)(pCustTransform->rect.size.width/2.0);
    double dBlend  = dBendPercent * dHalfWidth/100.0;
    
    if(point.y > pCustTransform->rect.size.height) return point;
    point.y = pCustTransform->rect.size.height - point.y;
    
    double dRadius = (dBlend*dBlend + dHalfWidth*dHalfWidth)/(2.0 * dBlend);
    double dAngle  = asin(dHalfWidth/dRadius);
    
    if(pCustTransform->transformCustom->nBendPercent <  0)
        point.y = pCustTransform->rect.size.height - point.y;
    double pointyold = point.y;
    point.y = 0;
    pointOut.x = (point.y + dRadius) * sin((point.x-dHalfWidth) * dAngle/dHalfWidth);
    pointOut.y = sqrt((point.y + dRadius) * (point.y + dRadius) - pointOut.x * pointOut.x) + (dBlend - dRadius);
    pointOut.x += dHalfWidth;
    
    pointOut.y += pointyold;
    if(pCustTransform->transformCustom->nBendPercent <  0)
        pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    return pointOut;
}

static CGPoint buldgetransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform, CGPoint *pointRefercence)
{
    CUSTOMTransPathAndTransform CustomTransform = *pCustTransform;
    CGPoint pointOut = point;
    CGPoint pointRef = point;
    if(pointRefercence) pointRef = *pointRefercence;
    
    if(pointRef.y > CustomTransform.rect.size.height/2)
    {
        point.y -= CustomTransform.rect.size.height/2;
   //     CustomTransform.rect.origin.y -= CustomTransform.rect.size.height/2;
        CustomTransform.rect.size.height /= 2;

        
        pointOut = lowerarctransformPoint(point, &CustomTransform);
        pointOut.y += CustomTransform.rect.size.height/2;
    }
    else
    {
        CustomTransform.rect.size.height /= 2;
        pointOut = upperarctransformPoint(point, &CustomTransform);
    }
    
    return pointOut;
}

static CGPoint shelllowertransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform)
{
    CGPoint pointOut = point;
    
    if(pCustTransform->transformCustom->nBendPercent == 0) return point;
    double dBendPercent = fabs((double)pCustTransform->transformCustom->nBendPercent);
    
    double dHalfWidth = (double)(pCustTransform->rect.size.width/2.0);
    double dBlend  = dBendPercent * dHalfWidth/100.0;
    dBlend *= point.y/pCustTransform->rect.size.height;
    if(dBlend < 0.00000001)  return pointOut;
    
    double dRadius = (dBlend*dBlend + dHalfWidth*dHalfWidth)/(2.0 * dBlend);
    double dAngle  = asin(dHalfWidth/dRadius);
    
    if(pCustTransform->transformCustom->nBendPercent <  0)
        point.y = pCustTransform->rect.size.height - point.y;
    
    pointOut.x = (point.y + dRadius) * sin((point.x-dHalfWidth) * dAngle/dHalfWidth);
    pointOut.y = sqrt((point.y + dRadius) * (point.y + dRadius) - pointOut.x * pointOut.x) + (dBlend - dRadius);
    pointOut.x += dHalfWidth;
    
    if(pCustTransform->transformCustom->nBendPercent <  0)
        pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    return pointOut;
}


static CGPoint shelluppertransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform)
{
    CGPoint pointOut = point;
    
    if(pCustTransform->transformCustom->nBendPercent == 0) return point;
    double dBendPercent = fabs((double)pCustTransform->transformCustom->nBendPercent);
    
    double dHalfWidth = (double)(pCustTransform->rect.size.width/2.0);
    double dBlend  = dBendPercent * dHalfWidth/100.0;
    
    if(point.y > pCustTransform->rect.size.height) return point;
    point.y = pCustTransform->rect.size.height - point.y;
    
    dBlend *= point.y/pCustTransform->rect.size.height;
    if(dBlend < 0.00000001)  return pointOut;
    
    double dRadius = (dBlend*dBlend + dHalfWidth*dHalfWidth)/(2.0 * dBlend);
    double dAngle  = asin(dHalfWidth/dRadius);
    
    if(pCustTransform->transformCustom->nBendPercent <  0)
        point.y = pCustTransform->rect.size.height - point.y;
    
    pointOut.x = (point.y + dRadius) * sin((point.x-dHalfWidth) * dAngle/dHalfWidth);
    pointOut.y = sqrt((point.y + dRadius) * (point.y + dRadius) - pointOut.x * pointOut.x) + (dBlend - dRadius);
    pointOut.x += dHalfWidth;
    
    if(pCustTransform->transformCustom->nBendPercent <  0)
        pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    pointOut.y = pCustTransform->rect.size.height - pointOut.y;
    
    return pointOut;
}

static CGPoint customtransformPoint(CGPoint point, CUSTOMTransPathAndTransform *pCustTransform, CGPoint *pointReference)
{
    CGPoint pointOut = point;
 //   pointOut = CGPointApplyAffineTransform(point, pCustTransform->transform);
    
    switch(pCustTransform->transformCustom->nTransformStyleID)
    {
        case ARC_WARP_METHOD:
            return arctransformPoint(pointOut, pCustTransform);
            break;
        case ARCLOWER_WARP_METHOD:
            return lowerarctransformPoint(pointOut, pCustTransform);
            break;
        case ARCUPPER_WARP_METHOD:
            return upperarctransformPoint(pointOut, pCustTransform);
            break;
        case ARCH_WARP_METHOD:
            return archtransformPoint(pointOut, pCustTransform);
            break;
        case BULDGE_WARP_METHOD:
            return buldgetransformPoint(pointOut, pCustTransform, pointReference);
            break;
        case SHELLLOWER_WARP_METHOD:
            return shelllowertransformPoint(pointOut, pCustTransform);
            break;
        case SHELLUPPER_WARP_METHOD:
            return shelluppertransformPoint(pointOut, pCustTransform);
            break;
        case FLAG_WARP_METHOD: break;
        case WAVE_WARP_METHOD: break;
        case FISH_WARP_METHOD: break;
        case RISE_WARP_METHOD: break;
        case FISHEYE_WARP_METHOD: break;
        case INFLATE_WARP_METHOD: break;
        case SQUEEZE_WARP_METHOD: break;
        case TWIST_WARP_METHOD: break;
        default: assert(false); break;
    }
    
    return pointOut;
}

static CGPoint PointDeOffset(CGPoint point, CGPoint offset)
{
    return CGPointMake(point.x - offset.x, point.y - offset.y);
}

static CGPoint PointOffset(CGPoint point, CGPoint offset)
{
    return CGPointMake(point.x + offset.x, point.y + offset.y);
}

static NSMutableArray *GetMoreInterPoints(CGPoint pointStart, CGPoint pointEnd)
{
    NSMutableArray *points = [NSMutableArray array];
    CGPoint pointOffset = PointDeOffset(pointStart, pointEnd);
    CGFloat distance = pointOffset.x;
    
    if(fabs(pointOffset.x) < fabs(pointOffset.y))
        distance = pointOffset.y;
    
    int num = fabs(distance) / 5 + 1;
    
    for(int i = 0; i < num; i++)
    {
        CGFloat fx = pointStart.x - (CGFloat)(i+1)*pointOffset.x/(CGFloat)num;
        CGFloat fy = pointStart.y - (CGFloat)(i+1)*pointOffset.y/(CGFloat)num;
        
        [points addObject: [NSValue valueWithPoint: CGPointMake(fx, fy)]];
    }
    
    return points;
}


la_object_t getVector3FromPoints(CGPoint point)
{
    float *buffer = malloc(3 * sizeof(float));
    buffer[0] = point.x;
    buffer[1] = point.y;
    buffer[2] = 1.0;
    la_object_t vector = la_vector_from_float_buffer(buffer, 3, 1, LA_DEFAULT_ATTRIBUTES);
    free(buffer);
    return vector;
}

CGPoint getPointFromVector3(la_object_t vector)
{
    float *buffer = malloc(3 * sizeof(float));
    la_vector_to_float_buffer(buffer, 1, vector);
    NSPoint point = NSMakePoint(buffer[0], buffer[1]);
    free(buffer);
    return point;
}


CGPoint getTranformedPointFromSrcPoint(CGPoint srcPoint, PSPerspectiveTransform matrix)
{
    //la_object_t src = getVector3FromPoints(srcPoint);
    //la_object_t des = la_matrix_product(matrix, src);
    return perspectiveTransfromPoint(srcPoint, matrix);
}


void perspectiveTransformPathElement(void *info, const CGPathElement *element)
{
    CUSTOMTransPathAndPerspective  pathAndTransform = *((CUSTOMTransPathAndPerspective *) info);
    //   CGAffineTransform   transform = pathAndTransform.transform;
    CGMutablePathRef    pathRef = pathAndTransform.mutablePath;
    CGPoint point[3];
    CGPoint pointOffset = pathAndTransform.rect.origin;
    static CGPoint pointLast;
    static CGPoint pointStart;
    PSPerspectiveTransform perTransform = pathAndTransform.transformPers;
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            pointStart = element->points[0];
            pointLast = element->points[0];
            //point[0] = customtransformPoint(PointDeOffset(element->points[0], pointOffset), &pathAndTransform, NULL);
            //point[0] = getTranformedPointFromSrcPoint(PointDeOffset(element->points[0], pointOffset), perTransform);
            //point[0] = PointOffset(point[0], pointOffset);
            
            point[0] = getTranformedPointFromSrcPoint(element->points[0], perTransform);
            
            CGPathMoveToPoint(pathRef, NULL, point[0].x, point[0].y);
            break;
        case kCGPathElementAddLineToPoint:
        {
            NSMutableArray *points = GetMoreInterPoints(pointLast, element->points[0]);
            pointLast = element->points[0];
            
            for(int i= 0; i< [points count]; i++)
            {
                point[0] = [[points objectAtIndex:i] pointValue];// CGPointValue];
                //point[0] = customtransformPoint(PointDeOffset(point[0], pointOffset), &pathAndTransform, NULL);
//                point[0] = getTranformedPointFromSrcPoint(PointDeOffset(point[0], pointOffset), perTransform);
//                point[0] = PointOffset(point[0], pointOffset);
                point[0] = getTranformedPointFromSrcPoint(point[0], perTransform);
                CGPathAddLineToPoint(pathRef, NULL, point[0].x, point[0].y);
            }
        }
            break;
        case kCGPathElementAddQuadCurveToPoint:
        {
            CGPoint pointRef = PointDeOffset(element->points[1], pointOffset);
            pointLast = element->points[1];
//            point[0] = customtransformPoint(PointDeOffset(element->points[0], pointOffset), &pathAndTransform, &pointRef);
//            point[1] = customtransformPoint(PointDeOffset(element->points[1], pointOffset), &pathAndTransform, NULL);
            
//            point[0] = getTranformedPointFromSrcPoint(PointDeOffset(element->points[0], pointOffset), perTransform);
//            point[1] = getTranformedPointFromSrcPoint(PointDeOffset(element->points[1], pointOffset), perTransform);
//            point[0] = PointOffset(point[0], pointOffset);
//            point[1] = PointOffset(point[1], pointOffset);
            
            point[0] = getTranformedPointFromSrcPoint(element->points[0], perTransform);
            point[1] = getTranformedPointFromSrcPoint(element->points[1], perTransform);
            
            CGPathAddQuadCurveToPoint(pathRef, NULL, point[0].x, point[0].y, point[1].x, point[1].y);
        }
            break;
        case kCGPathElementAddCurveToPoint:
        {
            CGPoint pointRef = PointDeOffset(element->points[2], pointOffset);
            pointLast = element->points[2];
//            point[0] = customtransformPoint(PointDeOffset(element->points[0], pointOffset), &pathAndTransform, &pointRef);
//            point[1] = customtransformPoint(PointDeOffset(element->points[1], pointOffset), &pathAndTransform, &pointRef);
//            point[2] = customtransformPoint(PointDeOffset(element->points[2], pointOffset), &pathAndTransform, NULL);
            
//            point[0] = getTranformedPointFromSrcPoint(PointDeOffset(element->points[0], pointOffset), perTransform);
//            point[1] = getTranformedPointFromSrcPoint(PointDeOffset(element->points[1], pointOffset), perTransform);
//            point[2] = getTranformedPointFromSrcPoint(PointDeOffset(element->points[2], pointOffset), perTransform);
//            point[0] = PointOffset(point[0], pointOffset);
//            point[1] = PointOffset(point[1], pointOffset);
//            point[2] = PointOffset(point[2], pointOffset);
            
            point[0] = getTranformedPointFromSrcPoint(element->points[0], perTransform);
            point[1] = getTranformedPointFromSrcPoint(element->points[1], perTransform);
            point[2] = getTranformedPointFromSrcPoint(element->points[2], perTransform);
            
            CGPathAddCurveToPoint(pathRef, NULL, point[0].x, point[0].y, point[1].x, point[1].y, point[2].x, point[2].y);
        }
            break;
        case kCGPathElementCloseSubpath:
        {
            NSMutableArray *points = GetMoreInterPoints(pointLast, pointStart);
            for(int i= 0; i< [points count]-1; i++)
            {
                point[0] = [[points objectAtIndex:i] pointValue];// CGPointValue];
//                point[0] = customtransformPoint(PointDeOffset(point[0], pointOffset), &pathAndTransform, NULL);
                
//                point[0] = getTranformedPointFromSrcPoint(PointDeOffset(point[0], pointOffset), perTransform);
//                point[0] = PointOffset(point[0], pointOffset);
                
                point[0] = getTranformedPointFromSrcPoint(point[0], perTransform);
                
                CGPathAddLineToPoint(pathRef, NULL, point[0].x, point[0].y);
            }
            CGPathCloseSubpath(pathRef);
        }
            break;
            
    }
}

void customtransformPathElement(void *info, const CGPathElement *element)
{
    CUSTOMTransPathAndTransform  pathAndTransform = *((CUSTOMTransPathAndTransform *) info);
 //   CGAffineTransform   transform = pathAndTransform.transform;
    CGMutablePathRef    pathRef = pathAndTransform.mutablePath;
    CGPoint point[3];
    CGPoint pointOffset = pathAndTransform.rect.origin;
    static CGPoint pointLast;
    static CGPoint pointStart;
    //NSLog(@"thred %@",[NSThread currentThread]);
    switch (element->type) {
        case kCGPathElementMoveToPoint:
        {
            pointStart = element->points[0];
            pointLast = element->points[0];
            point[0] = customtransformPoint(PointDeOffset(element->points[0], pointOffset), &pathAndTransform, NULL);
            point[0] = PointOffset(point[0], pointOffset);
            CGPathMoveToPoint(pathRef, NULL, point[0].x, point[0].y);
            
        }
            break;
            
        case kCGPathElementAddLineToPoint:
        {
            NSMutableArray *points = GetMoreInterPoints(pointLast, element->points[0]);
            pointLast = element->points[0];
            for(int i= 0; i< [points count]; i++)
            {
                point[0] = [[points objectAtIndex:i] pointValue];// CGPointValue];
                point[0] = customtransformPoint(PointDeOffset(point[0], pointOffset), &pathAndTransform, NULL);
                point[0] = PointOffset(point[0], pointOffset);
                CGPathAddLineToPoint(pathRef, NULL, point[0].x, point[0].y);
            }
            
        }
            break;
        
        case kCGPathElementAddQuadCurveToPoint:
        {
            CGPoint pointRef = PointDeOffset(element->points[1], pointOffset);
            pointLast = element->points[1];
            point[0] = customtransformPoint(PointDeOffset(element->points[0], pointOffset), &pathAndTransform, &pointRef);
            point[1] = customtransformPoint(PointDeOffset(element->points[1], pointOffset), &pathAndTransform, NULL);
            point[0] = PointOffset(point[0], pointOffset);
            point[1] = PointOffset(point[1], pointOffset);
            CGPathAddQuadCurveToPoint(pathRef, NULL, point[0].x, point[0].y, point[1].x, point[1].y);
        }
            break;
        case kCGPathElementAddCurveToPoint:
        {
            CGPoint pointRef = PointDeOffset(element->points[2], pointOffset);
            pointLast = element->points[2];
            point[0] = customtransformPoint(PointDeOffset(element->points[0], pointOffset), &pathAndTransform, &pointRef);
            point[1] = customtransformPoint(PointDeOffset(element->points[1], pointOffset), &pathAndTransform, &pointRef);
            point[2] = customtransformPoint(PointDeOffset(element->points[2], pointOffset), &pathAndTransform, NULL);
            point[0] = PointOffset(point[0], pointOffset);
            point[1] = PointOffset(point[1], pointOffset);
            point[2] = PointOffset(point[2], pointOffset);
            CGPathAddCurveToPoint(pathRef, NULL, point[0].x, point[0].y, point[1].x, point[1].y, point[2].x, point[2].y);
        }
            break;
        case kCGPathElementCloseSubpath:
        {
            NSMutableArray *points = GetMoreInterPoints(pointLast, pointStart);
            for(int i= 0; i< [points count]-1; i++)
            {
                point[0] = [[points objectAtIndex:i] pointValue];// CGPointValue];
                point[0] = customtransformPoint(PointDeOffset(point[0], pointOffset), &pathAndTransform, NULL);
                point[0] = PointOffset(point[0], pointOffset);
                CGPathAddLineToPoint(pathRef, NULL, point[0].x, point[0].y);
            }
            CGPathCloseSubpath(pathRef);
        }
            break;
            
        default:
            break;
            
    }
}

CGPathRef WDCreateCustomTransformedCGPathRef(CGPathRef pathRef, CUSTOM_TRANSFORM *transformCustom, CGRect rect)
{
    CGMutablePathRef    transformedPath = CGPathCreateMutable();
    CUSTOMTransPathAndTransform  pathAndTransform = {transformedPath, transformCustom, rect};
    
    CGPathApply(pathRef, &pathAndTransform, &customtransformPathElement);
    
    return transformedPath;
}

CGPathRef WDCreateCustomPerspectiveTransformedCGPathRef(CGPathRef pathRef, PSPerspectiveTransform transformPerspective, CGRect rect)
{
    CGMutablePathRef    transformedPath = CGPathCreateMutable();
    CUSTOMTransPathAndPerspective  pathAndTransform = {transformedPath, transformPerspective, rect};
    CGPathApply(pathRef, &pathAndTransform, &perspectiveTransformPathElement);
    
    return transformedPath;
}


#pragma mark -
#pragma mark Misc

NSString * WDSVGStringForCGAffineTransform(CGAffineTransform t)
{
    return [NSString stringWithFormat:@"matrix(%g %g %g %g %g %g)", t.a, t.b, t.c, t.d, t.tx, t.ty];
}

WDPickResult * WDSnapToRectangle(CGRect rect, CGAffineTransform *transform, CGPoint pt, float viewScale, int snapFlags)
{
    WDPickResult    *pickResult = [WDPickResult pickResult];
    CGPoint         corner[4];
    
    corner[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    corner[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    corner[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    corner[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    if (transform) {
        for (int i = 0; i < 4; i++) {
            corner[i] = CGPointApplyAffineTransform(corner[i], *transform);
        }
    }
    
    if (snapFlags & kWDSnapNodes) {
        for (int i = 0; i < 4; i++) {
            if (WDDistance(corner[i], pt) < (kNodeSelectionTolerance / viewScale)) {
                pickResult.snappedPoint = corner[i];
                pickResult.type = kWDRectCorner;
                return pickResult;
            }
        }
    }
    
    if (snapFlags & kWDSnapEdges) {
        WDBezierSegment     segment;
        CGPoint             nearest;
        
        for (int i = 0; i < 4; i++) {
            segment.a_ = segment.out_ = corner[i];
            segment.b_ = segment.in_ = corner[(i+1) % 4];
            
            if (WDBezierSegmentFindPointOnSegment(segment, pt, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
                pickResult.snappedPoint = nearest;
                pickResult.type = kWDRectEdge;
                return pickResult;
            }
        }
    }

    return pickResult;
}

#pragma mark -
#pragma mark WDQuad

WDQuad WDQuadNull()
{
    CGPoint bogusPoint = CGPointMake(INFINITY, INFINITY);
    return WDQuadMake(bogusPoint, bogusPoint, bogusPoint, bogusPoint);
}

WDQuad WDQuadMake(CGPoint a, CGPoint b, CGPoint c, CGPoint d)
{
    WDQuad quad;
    
    quad.corners[0] = a;
    quad.corners[1] = b;
    quad.corners[2] = c;
    quad.corners[3] = d;
    
    return quad;
}

WDQuad WDQuadWithRect(CGRect rect, CGAffineTransform transform)
{
    WDQuad quad;
    
    quad.corners[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    quad.corners[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    quad.corners[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    quad.corners[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    for (int i = 0; i < 4; i++) {
        quad.corners[i] = CGPointApplyAffineTransform(quad.corners[i], transform);
    }
    
    return quad;
}

BOOL WDQuadEqualToQuad(WDQuad a, WDQuad b)
{
    for (int i = 0; i < 4; i++) {
        if (!CGPointEqualToPoint(a.corners[i], b.corners[i])) {
            return NO;
        }
    }
    
    return YES;
}

BOOL WDQuadIntersectsQuad(WDQuad a, WDQuad b)
{
    WDQuad nullQuad = WDQuadNull();
    if (WDQuadEqualToQuad(a, nullQuad) || WDQuadEqualToQuad(b, nullQuad)) {
        return NO;
    }
    
    for (int i = 0; i < 4; i++) {
        for (int n = 0; n < 4; n++) {
            if (WDLineSegmentsIntersect(a.corners[i], a.corners[(i+1)%4], b.corners[n], b.corners[(n+1)%4])) {
                return YES;
            }
        }
    }
    
    return NO;
}

NSString * NSStringFromWDQuad(WDQuad quad)
{
    return [NSString stringWithFormat:@"{{%@}, {%@}, {%@}, {%@}}", NSStringFromCGPoint(quad.corners[0]), NSStringFromCGPoint(quad.corners[1]),
            NSStringFromCGPoint(quad.corners[2]), NSStringFromCGPoint(quad.corners[3])];
}

CGPathRef WDCreateQuadPathRef(WDQuad q)
{
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    CGPathMoveToPoint(pathRef, NULL, q.corners[0].x, q.corners[0].y);
    for (int i = 1; i < 4; i++) {
        CGPathAddLineToPoint(pathRef, NULL, q.corners[i].x, q.corners[i].y);
    }
    CGPathCloseSubpath(pathRef);
    
    return pathRef;
}
