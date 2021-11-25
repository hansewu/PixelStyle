//
//  EmailController.m
//  eMail Test
//
//  Created by apple on 3/12/14.
//  Copyright (c) 2014 apple. All rights reserved.
//

#import "EmailController.h"
#import <ScriptingBridge/SBApplication.h>
#import "Mail.h"

#define DEFAULT_ACCEPT_MAIL_COUNT   @"market@effectmatrix.com"


@interface EmailController (delegate) <SBApplicationDelegate>
@end

@implementation EmailController


#pragma mark -
#pragma mark Init

- (id) init {
	if ((self = [super initWithWindowNibName:@"EMail"]))
	{
        m_pAttachments = [[NSMutableArray alloc] init];
        m_selectedLikeType = 9999;
        m_selectedFadebackType = 9999;
        m_isModelWindow = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [m_pAttachments release];
    
    [super dealloc];
}

- (void)awakeFromNib{
    [self initWindowStatus];
    
    [m_pToField setStringValue:DEFAULT_ACCEPT_MAIL_COUNT];
    
    [m_pMessageContent setFont:[NSFont fontWithName:@"Helvetica" size:15]];
    
    [self.window setTitle:NSLocalizedString(@"Mail", nil)];
    
    [m_pFadebackType setLabel:NSLocalizedString(@"Bravo", nil) forSegment:0];
    [m_pFadebackType setLabel:NSLocalizedString(@"Bug", nil) forSegment:1];
    [m_pFadebackType setLabel:NSLocalizedString(@"Idea", nil) forSegment:2];
    
    [m_pLikeTheApp setStringValue:NSLocalizedString(@"Like this app ?", nil)];
    [m_pFadebackLabel setStringValue:NSLocalizedString(@"Feedback Type ?", nil)];
    
    [m_pToLabel setStringValue:NSLocalizedString(@"To :", nil)];
    [m_pSubjectLable setStringValue:NSLocalizedString(@"Subject :", nil)];
    
    [m_pCancel setTitle:NSLocalizedString(@"Remind me later", nil)];
    [m_pSend setTitle:NSLocalizedString(@"Send", nil)];
    
    [m_pSupportFormat setStringValue:NSLocalizedString(@"Supported formats :", nil)];
    [m_pMaxFileNumbers setStringValue:NSLocalizedString(@"The maximum number of attachments :", nil)];
    [m_pMaxSignalFileSize setStringValue:NSLocalizedString(@"The maximum size of single file :", nil)];
    
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[m_pCancel attributedTitle]];
    
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    
    [colorTitle addAttribute:NSForegroundColorAttributeName
                       value:[NSColor whiteColor]
                       range:titleRange];
    
    [m_pCancel setAttributedTitle:colorTitle];
    [colorTitle release];
    
    colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[m_pSend attributedTitle]];
    
    titleRange = NSMakeRange(0, [colorTitle length]);
    
    [colorTitle addAttribute:NSForegroundColorAttributeName
                       value:[NSColor whiteColor]
                       range:titleRange];
    
    [m_pSend setAttributedTitle:colorTitle];
    [colorTitle release];
}

- (void)initWindowStatus
{
    [m_pFileAttachmentAddBtn setEnabled:YES];
    
    [m_pFileAttachmentLabel1 setHidden:YES];
    [m_pFileAttachmentLabel1 setStringValue:@""];
    [m_pFileAttachmentDeleteBtn1 setHidden:YES];
    
    [m_pFileAttachmentLabel2 setHidden:YES];
    [m_pFileAttachmentLabel2 setStringValue:@""];
    [m_pFileAttachmentDeleteBtn2 setHidden:YES];
    
    [m_pFileAttachmentLabel3 setHidden:YES];
    [m_pFileAttachmentLabel3 setStringValue:@""];
    [m_pFileAttachmentDeleteBtn3 setHidden:YES];
    
    [m_pFileAttachmentLabel4 setHidden:YES];
    [m_pFileAttachmentLabel4 setStringValue:@""];
    [m_pFileAttachmentDeleteBtn4 setHidden:YES];
    
    [m_pFileAttachmentLabel5 setHidden:YES];
    [m_pFileAttachmentLabel5 setStringValue:@""];
    [m_pFileAttachmentDeleteBtn5 setHidden:YES];
    
    [m_pLikeTheAppType setSelectedSegment:0];
    [m_pFadebackType setSelectedSegment:0];
    
    [m_pAttachments removeAllObjects];
    
    [m_pMessageContent setString:@""];
    
    NSRect frame = m_pMessageScrollView.frame;
    frame.size.height = 376.0;
    m_pMessageScrollView.frame = frame;
    
    NSString *fadeback = NSLocalizedString(@" Fadeback", nil);
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    fadeback = [sProductName stringByAppendingString:fadeback];
    [m_pSubjectField setStringValue:fadeback];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self initWindowStatus];
}


#pragma mark -
#pragma mark Public function

- (void)showEMailWindow
{
    m_isModelWindow = NO;
    [self.window makeKeyAndOrderFront:nil];
}

- (void)showEMailWindowWithModel:(NSWindow*)fatherWindow
{
    if (fatherWindow) {
        m_isModelWindow = YES;
        [NSApp beginSheet:self.window modalForWindow:fatherWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    else
    {
        m_isModelWindow = NO;
        [self.window makeKeyAndOrderFront:nil];
    }
}


#pragma mark -
#pragma mark UI action

- (IBAction)likeThisAppTypeAction:(id)sender {
    m_selectedLikeType = [m_pLikeTheAppType selectedSegment];
    [self updateSubjectText];
}

- (IBAction)fadebackTypeAction:(id)sender {
    m_selectedFadebackType = [m_pFadebackType selectedSegment];
    [self updateSubjectText];
}

- (void)updateSubjectText
{
    NSString *fadeback = NSLocalizedString(@" Fadeback", nil);
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    fadeback = [sProductName stringByAppendingString:fadeback];
    
    // Like this app
    if (m_selectedLikeType == 0) {   // Like
        fadeback = [fadeback stringByAppendingString:@" : "];
        fadeback = [fadeback stringByAppendingString:NSLocalizedString(@"Like", nil)];
    }
    else if (m_selectedLikeType == 1) // Do not like
    {
        fadeback = [fadeback stringByAppendingString:@" : "];
        fadeback = [fadeback stringByAppendingString:NSLocalizedString(@"Do not like", nil)];
    }
    
    // Fadeback type
    if (m_selectedFadebackType == 0) {   // Bravo
        fadeback = [fadeback stringByAppendingString:@";  "];
        fadeback = [fadeback stringByAppendingString:NSLocalizedString(@"Bravo", nil)];
    }
    else if (m_selectedFadebackType == 1) // Bug
    {
        fadeback = [fadeback stringByAppendingString:@";  "];
        fadeback = [fadeback stringByAppendingString:NSLocalizedString(@"Bug", nil)];
    }
    else if (m_selectedFadebackType == 2) // Idea
    {
        fadeback = [fadeback stringByAppendingString:@";  "];
        fadeback = [fadeback stringByAppendingString:NSLocalizedString(@"Idea", nil)];
    }
    
    [m_pSubjectField setStringValue:fadeback];
}

- (IBAction)addFileAttachment:(id)sender {
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	[op setCanChooseDirectories:NO];
	[op setAllowsMultipleSelection:YES];
	[op setCanChooseFiles:YES];
    
    [op setAllowedFileTypes:[NSArray arrayWithObjects: @"gif", @"jpg", @"pdf", @"png", @"rtf", @"txt", nil]];
    
    [m_pLimtView retain];
    [op setAccessoryView:m_pLimtView];
	
	NSInteger openResult = [op runModal];
	if ( NSOKButton == openResult ) {
        NSInteger remainCount = 5 - [m_pAttachments count];
        NSInteger maxCount = MIN([[op URLs] count], remainCount);
        for (NSInteger i = 0; i < maxCount; i++) {
            NSString *filePath = [[[op URLs] objectAtIndex:i] path];
            BOOL canAdd = [self judgeFileSize:filePath];
            if ( (! [m_pAttachments containsObject:filePath]) && canAdd ) {
                [m_pAttachments addObject:filePath];
            }
            
            [self updateAttachmentsViewArea];
        }
        
	}
}

- (BOOL)judgeFileSize:(NSString*)filePath
{
    BOOL isFit = NO;
    
    if (filePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *theFileAttr = [fileManager attributesOfItemAtPath:filePath error:nil];
        NSNumber *theFileSize = [theFileAttr objectForKey:NSFileSize];
        unsigned long long fileSize = [theFileSize longLongValue];
        if (fileSize < 1024 * 1024 * 5) {
            isFit = YES;
        }
    }
    
    return isFit;
}

- (void)calcAttachmentsLabelAndButtonFrame:(NSString*)fileName fileLabel:(NSTextField*)fileLabel deleteBtn:(NSButton*)deleteBtn
{
    if (fileName && fileLabel && deleteBtn) {
        NSSize textSize = [fileName sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[fileLabel font], NSFontAttributeName, nil]];
        
        NSRect labelFrame = fileLabel.frame;
        labelFrame.size.width = MIN(390.0, textSize.width) + 10;
        fileLabel.frame = labelFrame;
        
        NSRect deleteBtnFrame = deleteBtn.frame;
        deleteBtnFrame.origin.x = labelFrame.origin.x + labelFrame.size.width + 20;
        deleteBtn.frame = deleteBtnFrame;
    }
}

- (IBAction)deleteFileAttachmentFir:(id)sender {
    if ([m_pAttachments count] > 0) {
        [m_pAttachments removeObjectAtIndex:0];
    }
    
    [self updateAttachmentsViewArea];
}

- (IBAction)deleteFileAttachmentSec:(id)sender {
    if ([m_pAttachments count] > 1) {
        [m_pAttachments removeObjectAtIndex:1];
    }
    
    [self updateAttachmentsViewArea];
}

- (IBAction)deleteFileAttachmentThi:(id)sender {
    if ([m_pAttachments count] > 2) {
        [m_pAttachments removeObjectAtIndex:2];
    }
    
    [self updateAttachmentsViewArea];
}

- (IBAction)deleteFileAttachmentFor:(id)sender {
    if ([m_pAttachments count] > 3) {
        [m_pAttachments removeObjectAtIndex:3];
    }
    
    [self updateAttachmentsViewArea];
}

- (IBAction)deleteFileAttachmentFiv:(id)sender {
    if ([m_pAttachments count] > 4) {
        [m_pAttachments removeObjectAtIndex:4];
    }
    
    [self updateAttachmentsViewArea];
}

- (void)updateAttachmentsViewArea
{
    NSRect frame = m_pMessageScrollView.frame;
    
    NSString *fileName = @"";
    NSInteger fileCount = [m_pAttachments count];
    switch (fileCount) {
        case 1:
        {
            [m_pFileAttachmentAddBtn setEnabled:YES];
            [m_pFileAttachmentLabel1 setHidden:NO];
            [m_pFileAttachmentDeleteBtn1 setHidden:NO];
            [m_pFileAttachmentLabel2 setHidden:YES];
            [m_pFileAttachmentDeleteBtn2 setHidden:YES];
            [m_pFileAttachmentLabel3 setHidden:YES];
            [m_pFileAttachmentDeleteBtn3 setHidden:YES];
            [m_pFileAttachmentLabel4 setHidden:YES];
            [m_pFileAttachmentDeleteBtn4 setHidden:YES];
            [m_pFileAttachmentLabel5 setHidden:YES];
            [m_pFileAttachmentDeleteBtn5 setHidden:YES];
            [m_pFileAttachmentLabel2 setStringValue:@""];
            [m_pFileAttachmentLabel3 setStringValue:@""];
            [m_pFileAttachmentLabel4 setStringValue:@""];
            [m_pFileAttachmentLabel5 setStringValue:@""];
            
            fileName = [[m_pAttachments objectAtIndex:0] lastPathComponent];
            [m_pFileAttachmentLabel1 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel1 deleteBtn:m_pFileAttachmentDeleteBtn1];
            
            frame.size.height = m_pFileAttachmentDeleteBtn1.frame.origin.y - 8 - frame.origin.y;
            m_pMessageScrollView.frame = frame;
            
            break;
        }
            
        case 2:
        {
            [m_pFileAttachmentAddBtn setEnabled:YES];
            [m_pFileAttachmentLabel1 setHidden:NO];
            [m_pFileAttachmentDeleteBtn1 setHidden:NO];
            [m_pFileAttachmentLabel2 setHidden:NO];
            [m_pFileAttachmentDeleteBtn2 setHidden:NO];
            [m_pFileAttachmentLabel3 setHidden:YES];
            [m_pFileAttachmentDeleteBtn3 setHidden:YES];
            [m_pFileAttachmentLabel4 setHidden:YES];
            [m_pFileAttachmentDeleteBtn4 setHidden:YES];
            [m_pFileAttachmentLabel5 setHidden:YES];
            [m_pFileAttachmentDeleteBtn5 setHidden:YES];
            [m_pFileAttachmentLabel3 setStringValue:@""];
            [m_pFileAttachmentLabel4 setStringValue:@""];
            [m_pFileAttachmentLabel5 setStringValue:@""];
            
            fileName = [[m_pAttachments objectAtIndex:0] lastPathComponent];
            [m_pFileAttachmentLabel1 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel1 deleteBtn:m_pFileAttachmentDeleteBtn1];
            
            fileName = [[m_pAttachments objectAtIndex:1] lastPathComponent];
            [m_pFileAttachmentLabel2 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel2 deleteBtn:m_pFileAttachmentDeleteBtn2];
            
            frame.size.height = m_pFileAttachmentDeleteBtn2.frame.origin.y - 8 - frame.origin.y;
            m_pMessageScrollView.frame = frame;
            
            break;
        }
            
        case 3:
        {
            [m_pFileAttachmentAddBtn setEnabled:YES];
            [m_pFileAttachmentLabel1 setHidden:NO];
            [m_pFileAttachmentDeleteBtn1 setHidden:NO];
            [m_pFileAttachmentLabel2 setHidden:NO];
            [m_pFileAttachmentDeleteBtn2 setHidden:NO];
            [m_pFileAttachmentLabel3 setHidden:NO];
            [m_pFileAttachmentDeleteBtn3 setHidden:NO];
            [m_pFileAttachmentLabel4 setHidden:YES];
            [m_pFileAttachmentDeleteBtn4 setHidden:YES];
            [m_pFileAttachmentLabel5 setHidden:YES];
            [m_pFileAttachmentDeleteBtn5 setHidden:YES];
            [m_pFileAttachmentLabel4 setStringValue:@""];
            [m_pFileAttachmentLabel5 setStringValue:@""];
           
            fileName = [[m_pAttachments objectAtIndex:0] lastPathComponent];
            [m_pFileAttachmentLabel1 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel1 deleteBtn:m_pFileAttachmentDeleteBtn1];
            
            fileName = [[m_pAttachments objectAtIndex:1] lastPathComponent];
            [m_pFileAttachmentLabel2 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel2 deleteBtn:m_pFileAttachmentDeleteBtn2];
            
            fileName = [[m_pAttachments objectAtIndex:2] lastPathComponent];
            [m_pFileAttachmentLabel3 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel3 deleteBtn:m_pFileAttachmentDeleteBtn3];
            
            frame.size.height = m_pFileAttachmentDeleteBtn3.frame.origin.y - 8 - frame.origin.y;
            m_pMessageScrollView.frame = frame;
            
            break;
        }
            
        case 4:
        {
            [m_pFileAttachmentAddBtn setEnabled:YES];
            [m_pFileAttachmentLabel1 setHidden:NO];
            [m_pFileAttachmentDeleteBtn1 setHidden:NO];
            [m_pFileAttachmentLabel2 setHidden:NO];
            [m_pFileAttachmentDeleteBtn2 setHidden:NO];
            [m_pFileAttachmentLabel3 setHidden:NO];
            [m_pFileAttachmentDeleteBtn3 setHidden:NO];
            [m_pFileAttachmentLabel4 setHidden:NO];
            [m_pFileAttachmentDeleteBtn4 setHidden:NO];
            [m_pFileAttachmentLabel5 setHidden:YES];
            [m_pFileAttachmentDeleteBtn5 setHidden:YES];
            [m_pFileAttachmentLabel5 setStringValue:@""];
            
            fileName = [[m_pAttachments objectAtIndex:0] lastPathComponent];
            [m_pFileAttachmentLabel1 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel1 deleteBtn:m_pFileAttachmentDeleteBtn1];
            
            fileName = [[m_pAttachments objectAtIndex:1] lastPathComponent];
            [m_pFileAttachmentLabel2 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel2 deleteBtn:m_pFileAttachmentDeleteBtn2];
            
            fileName = [[m_pAttachments objectAtIndex:2] lastPathComponent];
            [m_pFileAttachmentLabel3 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel3 deleteBtn:m_pFileAttachmentDeleteBtn3];
            
            fileName = [[m_pAttachments objectAtIndex:3] lastPathComponent];
            [m_pFileAttachmentLabel4 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel4 deleteBtn:m_pFileAttachmentDeleteBtn4];
            
            frame.size.height = m_pFileAttachmentDeleteBtn4.frame.origin.y - 8 - frame.origin.y;
            m_pMessageScrollView.frame = frame;
            
            break;
        }
            
        case 5:
        {
            [m_pFileAttachmentAddBtn setEnabled:NO];
            [m_pFileAttachmentLabel1 setHidden:NO];
            [m_pFileAttachmentDeleteBtn1 setHidden:NO];
            [m_pFileAttachmentLabel2 setHidden:NO];
            [m_pFileAttachmentDeleteBtn2 setHidden:NO];
            [m_pFileAttachmentLabel3 setHidden:NO];
            [m_pFileAttachmentDeleteBtn3 setHidden:NO];
            [m_pFileAttachmentLabel4 setHidden:NO];
            [m_pFileAttachmentDeleteBtn4 setHidden:NO];
            [m_pFileAttachmentLabel5 setHidden:NO];
            [m_pFileAttachmentDeleteBtn5 setHidden:NO];
            
            fileName = [[m_pAttachments objectAtIndex:0] lastPathComponent];
            [m_pFileAttachmentLabel1 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel1 deleteBtn:m_pFileAttachmentDeleteBtn1];
            
            fileName = [[m_pAttachments objectAtIndex:1] lastPathComponent];
            [m_pFileAttachmentLabel2 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel2 deleteBtn:m_pFileAttachmentDeleteBtn2];
            
            fileName = [[m_pAttachments objectAtIndex:2] lastPathComponent];
            [m_pFileAttachmentLabel3 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel3 deleteBtn:m_pFileAttachmentDeleteBtn3];
            
            fileName = [[m_pAttachments objectAtIndex:3] lastPathComponent];
            [m_pFileAttachmentLabel4 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel4 deleteBtn:m_pFileAttachmentDeleteBtn4];
            
            fileName = [[m_pAttachments objectAtIndex:4] lastPathComponent];
            [m_pFileAttachmentLabel5 setStringValue:fileName];
            
            [self calcAttachmentsLabelAndButtonFrame:fileName fileLabel:m_pFileAttachmentLabel5 deleteBtn:m_pFileAttachmentDeleteBtn5];
            
            frame.size.height = m_pFileAttachmentDeleteBtn5.frame.origin.y - 8 - frame.origin.y;
            m_pMessageScrollView.frame = frame;
            
            break;
        }
            
        default:
        {
            [m_pFileAttachmentAddBtn setEnabled:YES];
            [m_pFileAttachmentLabel1 setHidden:YES];
            [m_pFileAttachmentDeleteBtn1 setHidden:YES];
            [m_pFileAttachmentLabel2 setHidden:YES];
            [m_pFileAttachmentDeleteBtn2 setHidden:YES];
            [m_pFileAttachmentLabel3 setHidden:YES];
            [m_pFileAttachmentDeleteBtn3 setHidden:YES];
            [m_pFileAttachmentLabel4 setHidden:YES];
            [m_pFileAttachmentDeleteBtn4 setHidden:YES];
            [m_pFileAttachmentLabel5 setHidden:YES];
            [m_pFileAttachmentDeleteBtn5 setHidden:YES];
            [m_pFileAttachmentLabel1 setStringValue:@""];
            [m_pFileAttachmentLabel2 setStringValue:@""];
            [m_pFileAttachmentLabel3 setStringValue:@""];
            [m_pFileAttachmentLabel4 setStringValue:@""];
            [m_pFileAttachmentLabel5 setStringValue:@""];
            
            frame.size.height = 376.0;
            m_pMessageScrollView.frame = frame;

            break;
        }
    }
}

- (IBAction)cancelAction:(id)sender {
    [self closeMailWindow];
}

- (IBAction)sendAction:(id)sender {
    NSString *text = [[m_pMessageContent textStorage] string];
    if (text && ![text isEqualToString:@""]) {
        BOOL bSuccessed = [self sendEmailMessage];
        
        [self closeMailWindow];
        
        if(bSuccessed)
        {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *sAppName = [infoDictionary objectForKey:(NSString*)kCFBundleNameKey];
            NSString *sVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
            NSString *sFeedBackApp = [[@"feedBack" stringByAppendingString:sAppName] stringByAppendingString:sVersion];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:sFeedBackApp];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"defaultValueKeyUserRateDate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)closeMailWindow
{
    if (m_isModelWindow) {
        [NSApp endSheet:self.window];
        [self.window orderOut:nil];
    } else {
        [self.window orderOut:nil];
    }
    
    [self initWindowStatus];
}

#pragma mark -
#pragma mark Send action

- (BOOL)sendEmailMessage {
    
    /* create a Scripting Bridge object for talking to the Mail application */
	MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
    
    /* set ourself as the delegate to receive any errors */
    mail.delegate = self;
	
    /* create a new outgoing message object */
    NSString *myContent = [[m_pMessageContent textStorage] string];
    if (myContent && ![myContent isEqualToString:@""]) {
        myContent = [myContent stringByAppendingString:@"\n\n\n"];
    }
    else
    {
        NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
        myContent = [NSString stringWithFormat:@"%@\n\n\n",sProductName];
    }
    
	MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
                                         [NSDictionary dictionaryWithObjectsAndKeys:
                                          [m_pSubjectField stringValue], @"subject",
                                          myContent, @"content",
                                          nil]];
    
    /* add the object to the mail app  */
	[[mail outgoingMessages] addObject: emailMessage];
    
    /* set the sender, show the message */
//	emailMessage.sender = [fromField stringValue];
	emailMessage.visible = YES;
    
    /* Test for errors */
    if ( [mail lastError] != nil ) {
        return NO;
    }
    
    /* create a new recipient and add it to the recipients list */
	MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
                                     [NSDictionary dictionaryWithObjectsAndKeys:
                                      [m_pToField stringValue], @"address",
                                      nil]];
	[emailMessage.toRecipients addObject: theRecipient];
    [theRecipient release];
    
    /* Test for errors */
    if ( [mail lastError] != nil ) {
        return NO;
    }
    
    SInt32 osxMinorVersion;
    Gestalt(gestaltSystemVersionMinor, &osxMinorVersion);
    
    for (NSInteger i = 0; i < [m_pAttachments count]; i++) {
        /* add attachments */
        NSString *attachmentFilePath = [m_pAttachments objectAtIndex:i];
        if ( [attachmentFilePath length] > 0 ) {
            MailAttachment *theAttachment;
            
            /* In Snow Leopard, the fileName property requires an NSString representing the path to the
             * attachment.  In Lion, the property has been changed to require an NSURL.   */
            /* create an attachment object */
            if ( osxMinorVersion >= 7 )
            {
                theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                                 [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSURL fileURLWithPath:attachmentFilePath], @"fileName",
                                  nil]];
            }
            else
            {
                theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                                 [NSDictionary dictionaryWithObjectsAndKeys:
                                  attachmentFilePath, @"fileName",
                                  nil]];
            }
            
            /* add it to the list of attachments */
            [[emailMessage.content attachments] addObject: theAttachment];
            
            [theAttachment release];
            
            /* Test for errors */
            if ( [mail lastError] != nil )
            {
                return NO;
            }
        }
    }

    /* send the message */
	BOOL success = [emailMessage send];
    
    [emailMessage release];
    
    NSLog(@"eMail send finished. stas = %d", success);
    
    return success;
}

/* Part of the SBApplicationDelegate protocol.  Called when an error occurs in
 Scripting Bridge method. */
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
//    [[NSAlert alertWithMessageText:NSLocalizedString(@"Error", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil
//         informativeTextWithFormat: @"%@", [error localizedDescription]] runModal];
    return nil;
}

@end
