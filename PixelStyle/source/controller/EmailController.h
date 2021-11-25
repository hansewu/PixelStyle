//
//  EmailController.h
//  eMail Test
//
//  Created by apple on 3/12/14.
//  Copyright (c) 2014 apple. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface EmailController : NSWindowController
{
    IBOutlet NSTextField *m_pLikeTheApp;
    IBOutlet NSSegmentedControl *m_pLikeTheAppType;
    
    IBOutlet NSTextField *m_pFadebackLabel;
    IBOutlet NSSegmentedControl *m_pFadebackType;
    
    IBOutlet NSTextField *m_pToLabel;
	IBOutlet NSTextField *m_pToField;
    
	IBOutlet NSTextField *m_pSubjectLable;
	IBOutlet NSTextField *m_pSubjectField;

    IBOutlet NSButton *m_pFileAttachmentAddBtn;
	IBOutlet NSTextField *m_pFileAttachmentLabel1;
    IBOutlet NSButton *m_pFileAttachmentDeleteBtn1;
	IBOutlet NSTextField *m_pFileAttachmentLabel2;
    IBOutlet NSButton *m_pFileAttachmentDeleteBtn2;
	IBOutlet NSTextField *m_pFileAttachmentLabel3;
    IBOutlet NSButton *m_pFileAttachmentDeleteBtn3;
	IBOutlet NSTextField *m_pFileAttachmentLabel4;
    IBOutlet NSButton *m_pFileAttachmentDeleteBtn4;
	IBOutlet NSTextField *m_pFileAttachmentLabel5;
    IBOutlet NSButton *m_pFileAttachmentDeleteBtn5;

	IBOutlet NSTextView *m_pMessageContent;
    IBOutlet NSScrollView *m_pMessageScrollView;
    
    IBOutlet NSButton *m_pCancel;
    IBOutlet NSButton *m_pSend;
    
    IBOutlet NSView *m_pLimtView;
    IBOutlet NSTextField *m_pSupportFormat;
    IBOutlet NSTextField *m_pMaxFileNumbers;
    IBOutlet NSTextField *m_pMaxSignalFileSize;
    
    NSMutableArray *m_pAttachments;
    NSInteger m_selectedLikeType;
    NSInteger m_selectedFadebackType;
    BOOL m_isModelWindow;
}

- (void)showEMailWindow;
- (void)showEMailWindowWithModel:(NSWindow*)fatherWindow;

@end
