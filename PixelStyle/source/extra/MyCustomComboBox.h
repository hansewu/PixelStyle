//
//  MyCustomComboBox.h
//  PixelStyle
//
//  Created by wyl on 15/11/21.
//
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class MyCustomComboBox;
@protocol MyCustomComboBoxDelegate <NSTextFieldDelegate>

-(void)valueDidChange:(nullable MyCustomComboBox *)customComboBox value:(nullable NSString *)sValue;

@end


@interface MyCustomComboBox : NSView
{
    id<MyCustomComboBoxDelegate> m_delegate;
}

- (void)setDelegate:(nullable id <MyCustomComboBoxDelegate>)delegate;

-(void)setSliderMaxValue:(float)fValue;
-(void)setSliderMinValue:(float)fValue;

-(void)setStringValue:(nullable NSString *)sValue;

-(NSString *)getStringValue;


-(void)setEnabled:(BOOL)bEnable;

-(float)getSliderMaxValue;
-(float)getSliderMinValue;

@end
