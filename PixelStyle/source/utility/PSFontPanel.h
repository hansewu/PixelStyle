//
//  PSFontPanel.h
//  PixelStyle
//
//  Created by wzq on 15/11/5.
//
//

#import <Cocoa/Cocoa.h>

@protocol FontFamilyNotifyProtocol
@required
-(void)fontFramilySelected:(NSString *)strFamilyName fontName:(NSString *)strFontName;
@end

@interface PSFontPanel : NSWindow<NSTableViewDelegate, NSTableViewDataSource>
{
    NSTableView    *m_faceTable;
    NSTableView    *m_familyTable;
    
    id              m_idEventLocalMonitor;
    id              m_idEventGlobalMonitor;
    
    NSMutableIndexSet      *m_indexSelectedLast;
    
    BOOL             m_bInitScroll;
    NSString        *m_strFamilyName;
    
    id<FontFamilyNotifyProtocol> m_delegateFontFamilyNotify;
}

- (instancetype)initWithRect:(NSRect)contentRect selectedFont:(NSString *)fontFamilyyName;
- (void)showPanel:(NSRect)contentRect selectedFont:(NSString *)fontFamilyyName;
- (void)setDelegateFontFamilyNotify:(id)delegateFontFamilyNotify;

@end
