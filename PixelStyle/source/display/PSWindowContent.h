#import "Globals.h"

/*!
	@class		PSWindowContent
	@abstract	Provides a view manages all of the various subviews in the document window.
	@discussion	Ideally this is the only class that sets the frames, sizes and locations of
				each of the views in the main document view. The major caveat is that this 
				relies strongly on the window being configured properly in the IB NIB file.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

enum
{
	kOptionsBar,
	kSidebar,
	kPointInformation,
	kStatusBar,
	kWarningsBar,
    kMyToolsBar
};


@class PSDocument;
@class PSOptionsView;
@class LayerControlView;
@class BannerView;
@class MyToolBarView;

@interface PSWindowContent : NSView {
	IBOutlet PSDocument *m_idDocument;

	IBOutlet PSOptionsView* m_ovOptionsBar;
	IBOutlet NSView *m_vNonOptionsBar;
	
	IBOutlet NSView* m_vSidebar;
	IBOutlet NSView* m_svLayers;
	IBOutlet NSView* m_vPointInformation;
	IBOutlet LayerControlView* m_cvSidebarStatusbar;
	
	IBOutlet NSView *m_vNonSidebar;
	IBOutlet BannerView *m_bvWarningsBar;
	IBOutlet NSView *m_vMainDocumentView;
	IBOutlet LayerControlView *m_cvStatusBar;
    
    IBOutlet MyToolBarView *m_tbvMyToolBar;
    IBOutlet NSScrollView  *m_scrollViewToolBar;
	// Dictionary for all properties
	NSDictionary *m_dict;
    
    
    id              m_idEventLocalMonitor;
}

- (BOOL)visibilityForRegion:(int)region;
- (void)setVisibility:(BOOL)visibility forRegion:(int)region;
- (float)sizeForRegion:(int)region;
- (BOOL)windowWillResizeTo:(NSSize)frameSize;
@end
