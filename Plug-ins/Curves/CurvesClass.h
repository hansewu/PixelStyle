//
//  CurvesClass.h
//  Curves
//
//  Created by lchzh on 22/9/15.
//  Copyright (c) 2015 lchzh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Cocoa/Cocoa.h>
#import "PSPlugins.h"

#include "Lagrange.hpp"
#import "PSCurveView.h"

@class PSColorSelectView;


@interface CurvesClass : NSObject
{
    
    // The plug-in's manager
    id seaPlugins;
    
    
    // The panel for the plug-in
    IBOutlet id panel;
    IBOutlet PSCurveView *m_curveView;
    IBOutlet NSSegmentedControl *m_colorChannelSegment;
    IBOutlet NSButton *m_previewButton;
    
    IBOutlet NSButton *m_blackFieldButton;
    IBOutlet NSButton *m_grayFieldButton;
    IBOutlet NSButton *m_whiteFieldButton;
    int m_selectedFieldIndex;
    
    // YES if the effect must be refreshed
    BOOL refresh;
    // YES if the application succeeded
    BOOL success;
    
    
    NSMutableArray * m_pointValueArray;
    Lagrange *m_curveInterpolationObject;
    NSMutableArray * m_pointValueArrayForRed;
    Lagrange *m_curveInterpolationObjectForRed;
    NSMutableArray * m_pointValueArrayForGreen;
    Lagrange *m_curveInterpolationObjectForGreen;
    NSMutableArray * m_pointValueArrayForBlue;
    Lagrange *m_curveInterpolationObjectForBlue;
    BOOL m_redEnable;
    BOOL m_greenEnable;
    BOOL m_blueEnable;
    unsigned char m_grayHistogramInfo[256];
    
    unsigned char m_blackFieldFrom[4];
    unsigned char m_blackFieldTo[4];
    unsigned char m_grayFieldFrom[4];
    unsigned char m_grayFieldTo[4];
    unsigned char m_whiteFieldFrom[4];
    unsigned char m_whiteFieldTo[4];
    
    IBOutlet PSColorSelectView *m_blackFieldToColorView;
    IBOutlet PSColorSelectView *m_grayFieldToColorView;
    IBOutlet PSColorSelectView *m_whiteFieldToColorView;
        
}


/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		manager
 The PSPlugins instance responsible for managing the plug-ins.
	@result		Returns instance upon success (or NULL otherwise).
 */
- (id)initWithManager:(PSPlugins *)manager;

/*!
	@method		type
	@discussion	Returns the type of plug-in so PixelStyle can correctly interact
 with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
 */
- (int)type;

/*!
	@method		name
	@discussion	Returns the plug-in's name.
	@result		Returns an NSString indicating the plug-in's name.
 */
- (NSString *)name;

/*!
	@method		groupName
	@discussion	Returns the plug-in's group name.
	@result		Returns an NSString indicating the plug-in's group name.
 */
- (NSString *)groupName;

/*!
	@method		sanity
	@discussion	Returns a string to indicate this is a PixelStyle plug-in.
	@result		Returns the NSString "PixelStyle Approved (Bobo)".
 */
- (NSString *)sanity;

/*!
	@method		run
	@discussion	Runs the plug-in.
	@result		YES if the plug-in was run successfully, NO otherwise.
 */
- (void)run;

/*!
	@method		apply:
	@discussion	Applies the plug-in's changes.
	@param		sender
 Ignored.
 */
- (IBAction)apply:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)resetLine:(id)sender;
- (IBAction)segmentSelectionChanged:(id)sender;



/*!
	@method		reapply
	@discussion	Applies the plug-in with previous settings.
 */
- (void)reapply;

/*!
	@method		canReapply
	@discussion Returns whether or not the plug-in can be applied again.
	@result		Returns YES if the plug-in can be applied again, NO otherwise.
 */
- (BOOL)canReapply;


- (BOOL)validateMenuItem:(id)menuItem;

- (IBAction)previewButtonClicked:(id)sender;
- (IBAction)autoButtonClicked:(id)sender;
- (IBAction)blackFieldButtonClicked:(id)sender;
- (IBAction)grayFieldButtonClicked:(id)sender;
- (IBAction)whiteFieldButtonClicked:(id)sender;
- (IBAction)blackFieldToButtonClicked:(id)sender;
- (IBAction)grayFieldToButtonClicked:(id)sender;
- (IBAction)whiteFieldToButtonClicked:(id)sender;





@end
