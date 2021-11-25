//
//  PSArrowController.h
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "PSAbstractPanel.h"
@class WDrawingController;

@interface PSArrowController : PSAbstractPanel <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView *m_tableViewArrow;
}

@property (nonatomic, retain) WDDrawingController *drawingController;

@end
