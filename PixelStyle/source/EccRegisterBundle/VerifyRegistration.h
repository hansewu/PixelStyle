//
//  VerifyRegistration.h
//  PixelStyle
//
//  Created by wyl on 16/1/21.
//
//

#import <Cocoa/Cocoa.h>

@interface VerifyRegistration : NSWindowController
{
    IBOutlet id m_idVerifyRegistrationPanel;
    IBOutlet id m_idShowInfoTitle;
    IBOutlet id m_idShowInfo;
    IBOutlet id m_idBuy;
    IBOutlet id m_labelInputRegistrationInfo;
    IBOutlet id m_labelUserName;
    IBOutlet id m_labelLicense;
    IBOutlet id m_textFieldUserName;
    IBOutlet id m_textFieldLicense;
    IBOutlet id m_idTry;
    IBOutlet id m_idRegister;
    
    IBOutlet id m_idTipsView;
    
    NSString *m_buyPath;
    NSString *m_productName;
    int m_nMode;
}

+(nonnull VerifyRegistration*)sharedVerifyRegistration;

-(void)verifyRegistration;
-(BOOL)isRegisted;

-(int)setPublicKey:(nonnull unsigned char*)pubKey;
-(void)setBuyPath:(nonnull NSString*)buyPath;
-(void)setProductName:(nonnull NSString*)name;
-(void)addTips:(nonnull NSAttributedString*)tips;

-(void)setRegisterMode:(int)mode;


@end
