#import "Rects.h"

/*!
	@enum		Overlay behaviours
	@constant	kNormalBehaviour
				Indicates the overlay is to be composited on to the underlying layer.
	@constant	kErasingBehaviour
				Indicates the overlay is to erase the underlying layer.
	@constant	kReplacingBehaviour
				Indicates the overlay is to replace the underling layer where specified.
*/
enum {
	kNormalBehaviour,
	kErasingBehaviour,
	kReplacingBehaviour
};

/*!
	@enum		Channel specifications
	@constant	kAllChannels
				Specifies all channels.
	@constant	kPrimaryChannels
				Specifies the primary RGB channels in a colour image or the
				primary white channel in a greyscale image.
	@constant	kAlphaChannel
				Specifies the alpha channel.
*/
enum {
	kAllChannels,
	kPrimaryChannels,
	kAlphaChannel
};

/*!
	@class		PluginData
	@abstract	The object shared between PhotoArt and most plug-ins.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

@interface PluginData : NSObject {

	// The document associated with this object
    IBOutlet id document;

}

/*!
	@method		selection
	@discussion	Returns the rectange bounding the active selection in the
				layer's co-ordinates.
    @discussion 显示激活的选择区
	@result		Returns a IntRect indicating the active selection.
*/
- (IntRect)selection;

/*!
	@method		data
	@discussion	Returns the bitmap data of the layer.
    @discussion 返回这个图层的位图的数据
	@result		Returns a pointer to the bitmap data of the layer.
*/
- (unsigned char *)data;

/*!
	@method		whiteboardData
	@discussion	Returns the bitmap data of the document.
    @discussion 返回文件的位图的数据
	@result		Returns a pointer to the bitmap data of the document.
*/
- (unsigned char *)whiteboardData;

/*!
	@method		replace
	@discussion	Returns the replace mask of the overlay.
    @discussion 返回覆盖图的replace mask 8位字节每像素
	@result		Returns a pointer to the 8 bits per pixel replace mask of the
				overlay.
*/
- (unsigned char *)replace;

/*!
	@method		overlay
	@discussion	Returns the bitmap data of the overlay.
    @discussion 返回覆盖图的位图数据
	@result		Returns a pointer to the bitmap data of the overlay.
*/
- (unsigned char *)overlay;

/*!
	@method		spp
	@discussion	Returns the document's samples per pixel (either 2 or 4).
	@result		Returns an integer indicating the document's sample per pixel.
    @discussion 返回文件的每个像素的样本
*/
- (int)spp;

/*!
	@method		channel
	@discussion	Returns the currently selected channel.
    @discussion 返回一个目前选择的通道
	@result		Returns an integer representing the currently selected channel.
*/
- (int)channel;

/*!
	@method		width
	@discussion	Returns the layer's width in pixels.
    @discussion 返回一个图层的像素宽度
	@result		Returns an integer indicating the layer's width in pixels.
*/
- (int)width;

/*!
	@method		height
	@discussion	Returns the layer's height in pixels.
    @discussion 返回一个图层的像素高度
	@result		Returns an integer indicating the layer's height in pixels.
*/
- (int)height;

/*!
	@method		hasAlpha
	@discussion	Returns if the layer's alpha channel is enabled.
    @discussion 返回是否这个图层的alpha通道激活
	@result		Returns YES if the layer's alpha channel is enabled, NO
				otherwise.
*/
- (BOOL)hasAlpha;

/*!
	@method		point:
	@discussion	Returns the given point from the effect tool. Only valid
				for plug-ins with type one.
	@param		index
				An integer from zero to less than the plug-in's specified
				value.
	@result		The corresponding point from the effect tool.
*/
- (IntPoint)point:(int)index;

/*!
	@method		foreColor
	@discussion	Return the active foreground colour.
    @discussion 返回有效的前景色
	@param		calibrated
				YES if the colour is to be calibrated (usually bad), NO otherwise.
	@result		Returns an NSColor representing the active foreground
				colour.
*/
- (NSColor *)foreColor:(BOOL)calibrated;

/*!
	@method		backColor
	@discussion	Return the active background colour.
    @discussion 返回有效的背景色
	@param		calibrated
				YES if the colour is to be calibrated (usually bad), NO otherwise.
	@result		Returns an NSColor representing the active background
				colour.
*/
- (NSColor *)backColor:(BOOL)calibrated;

/*!
	@method		displayProf
	@discussion	Returns the current display profile.
    @discussion 返回现在显示的轮廓
	@result		Returns a CGColorSpaceRef representing the ColorSync display profile
				PhotoArt is using.
*/
- (CGColorSpaceRef)displayProf;
- (CGColorSpaceRef)dataColorSpace;
/*!
	@method		window
	@discussion	Returns the window to use for the plug-in's panel.
    @discussion 返回窗口的仪表板
	@result		Returns the window to use for the plug-in's panel.
*/
- (id)window;

/*!
	@method		setOverlayBehaviour:
	@discussion	Sets the overlay behaviour.
    @discussion 设置覆盖图的行为
	@param		value
				The new overlay behaviour (see PSWhiteboard).
*/
- (void)setOverlayBehaviour:(int)value;

/*!
	@method		setOverlayOpacity:
	@discussion	Sets the opacity of the overlay.
    @discussion 设置覆盖图的容量
	@param		value
				An integer from 0 to 255 representing the revised opacity of the
				overlay.
*/
- (void)setOverlayOpacity:(int)value;

/*!
	@method		applyWithNewDocumentData:spp:width:height:
	@discussion	Creates a new document with the given data.
    @discussion 用给定的数据创建一个新的文件
 
	@param		data
				The data of the new document (must be a multiple of 128-bits in
				length).
	@param		spp
				The samples per pixel of the new document.
	@param		width
				The width of the new document.
	@param		height
				The height of the new document.
*/
- (void)applyWithNewDocumentData:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height;

/*!
	@method		apply
	@discussion	Apply the plug-in changes.
    @discussion 应用插件的变化
*/
- (void)apply;

/*!
	@method		preview
	@discussion	Preview the plug-in changes.
    @discussion 预览插件的变化
*/
- (void)preview;

/*!
	@method		cancel
	@discussion	Cancel the plug-in changes.
    @discussion 取消插件的变化
*/
- (void)cancel;

@end
