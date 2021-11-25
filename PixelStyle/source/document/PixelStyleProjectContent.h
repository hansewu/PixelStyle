//
//  PixelStyleProjectContent.h
//  PixelStyle
//
//  Created by wyl on 15/9/18.
//
//

#import "PSContent.h"

@interface PixelStyleProjectContent : PSContent

/*!
	@method		typeIsEditable:
	@discussion	Whether or not the type is PixelStyleProjectContent
	@param		type
 A string type, could be an PSDB File Type or psdb
	@result		A boolean indicating acceptance.
 
 */
+ (BOOL)typeIsEditable:(NSString *)type;

/*!
	@method		initWithDocument:contentsOfFile:
	@discussion	Initializes an instance of this class with the given PSDB file.
	@param		doc
 The document with which to initialize the instance.
	@param		path
 The path of the PSDB file with which to initalize this class.
	@result		Returns instance upon success (or NULL otherwise).
 */
- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path;

/*!
	@method		initWithDocumentAfterCoder:content:
	@discussion	Initializes an instance of this class with the given PSDB file.
	@param		doc
 The document with which to initialize the instance.
	@param		path
 The path of the PSDB file with which to initalize this class.
	@result		Returns instance upon success (or NULL otherwise).
 */
-(id)initWithDocumentAfterCoder:doc content:(PSContent *)idContents;

@end
