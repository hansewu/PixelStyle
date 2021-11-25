//
//  PSGradientWindow.m
//  PixelStyle
//
//  Created by lchzh on 5/18/16.
//
//

#import "PSGradientWindow.h"

@implementation PSGradientWindow

#define N_COLORS 6

- (void)setGradientDelegate:(id)delegate
{
    m_idGradientDelegate = delegate;
}


- (void)setGradientColor:(GRADIENT_COLOR)gradientColor
{
    m_structGradientColor = gradientColor;
    [m_btnGradient setGradientColor:gradientColor];
    
    NSGradient *gradient = [self makeGradientFromGradientColor:gradientColor];
    [self setGradient:gradient];
}


- (void)awakeFromNib {
    [m_btnReverse setTitle:NSLocalizedString(@"Reverse", nil)];
    [m_btnOK setTitle:NSLocalizedString(@"OK", nil)];
    self.checkBoxes = [NSMutableArray array];
    self.colorWells = [NSMutableArray array];
    self.sliders = [NSMutableArray array];
    
    NSView *view = self.contentView;
    for (NSObject *child in view.subviews) {
        if (![child isKindOfClass:[NSControl class]]) {
            continue;
        }
        NSControl *control = (NSControl *)child;
        if (!control.tag) {
            continue;
        }
        control.target = self;
        control.action = @selector(onChange:);
        NSInteger index = control.tag - 1;
        if ([control isKindOfClass:[NSButton class]]) {
            if (index > [self.checkBoxes count]) {
                index = [self.checkBoxes count];
            }
            [self.checkBoxes insertObject:child atIndex:index];
        }
        if ([control isKindOfClass:[NSColorWell class]]) {
            if (index > [self.colorWells count]) {
                index = [self.colorWells count];
            }
            [self.colorWells insertObject:child atIndex:index];
        }
        if ([control isKindOfClass:[NSSlider class]]) {
            if (index > [self.sliders count]) {
                index = [self.sliders count];
            }
            [self.sliders insertObject:child atIndex:index];
        }
    }
//    [self loadPresets];
//    [self onPreset:nil];
}

- (void)dealloc {
    self.checkBoxes = nil;
    self.colorWells = nil;
    self.sliders = nil;
    self.names = nil;
    self.gradients = nil;
    
    [super dealloc];
    
}



- (NSColor *)color:(unsigned int)value {
    double r = ((value >> 16) & 0xff) / 255.0;
    double g = ((value >> 8) & 0xff) / 255.0;
    double b = ((value >> 0) & 0xff) / 255.0;
    double a = 1.0;
    return [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
}


- (NSGradient *)createGradient {
    NSMutableArray *colors = [NSMutableArray array];
    CGFloat *locations = malloc(sizeof(CGFloat) * N_COLORS);
    for (int i = 0; i < N_COLORS; i++) {
        NSButton *checkBox = [self.checkBoxes objectAtIndex:i];
        NSColorWell *colorWell = [self.colorWells objectAtIndex:i];
        NSSlider *slider = [self.sliders objectAtIndex:i];
        if (checkBox.state == NSOffState) {
            continue;
        }
        locations[colors.count] = slider.doubleValue;
        [colors addObject:colorWell.color];
    }
    NSGradient *gradient = [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace deviceRGBColorSpace]];
    free(locations);
    return gradient;
}

- (void)setGradient:(NSGradient *)gradient {
    for (int i = 0; i < N_COLORS; i++) {
        NSButton *checkBox = [self.checkBoxes objectAtIndex:i];
        NSColorWell *colorWell = [self.colorWells objectAtIndex:i];
        NSSlider *slider = [self.sliders objectAtIndex:i];
        checkBox.state = NSOffState;
        colorWell.color = [NSColor whiteColor];
        slider.doubleValue = 0.5;
    }
    for (int i = 0; i < gradient.numberOfColorStops; i++) {
        NSButton *checkBox = [self.checkBoxes objectAtIndex:i];
        NSColorWell *colorWell = [self.colorWells objectAtIndex:i];
        NSSlider *slider = [self.sliders objectAtIndex:i];
        NSColor *color;
        CGFloat location;
        [gradient getColor:&color location:&location atIndex:i];
        checkBox.state = NSOnState;
        colorWell.color = color;
        slider.doubleValue = location;
    }
}

- (void)onChange:(id)sender
{
    GRADIENT_COLOR gradientColor = [self makeGradientColorFromGradient:[self createGradient]];
    [m_btnGradient setGradientColor:gradientColor];
    [m_idGradientDelegate gradientColorChanged:gradientColor];
    
}

- (IBAction)reverseColor:(id)sender
{
    for (int i = 0; i < N_COLORS; i++) {
        NSButton *checkBox = [self.checkBoxes objectAtIndex:i];
        NSSlider *slider = [self.sliders objectAtIndex:i];
        if (checkBox.state == NSOnState) {
            [slider setFloatValue:1.0 - [slider floatValue]];
        }
    }
    [self onChange:nil];
}


- (void)loadPresets {
    NSString *name;
    NSArray *colors;
    NSGradient *gradient;
    
    self.names = [NSMutableArray array];
    self.gradients = [NSMutableArray array];
    
    name = @"Preset 1";
    colors = [NSArray arrayWithObjects:[self color:0x580022], [self color:0xAA2C30], [self color:0xFFBE8D], [self color:0x487B7F], [self color:0x011D24], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 2";
    colors = [NSArray arrayWithObjects:[self color:0xF6F9F4], [self color:0xBCB293], [self color:0x776B5C], [self color:0x4C393D], [self color:0x1C1A24], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 3";
    colors = [NSArray arrayWithObjects:[self color:0x736C48], [self color:0xF2E3B3], [self color:0xF2A950], [self color:0xD98032], [self color:0xD95D30], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 4";
    colors = [NSArray arrayWithObjects:[self color:0xFF2C38], [self color:0xFFFFED], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 5";
    colors = [NSArray arrayWithObjects:[self color:0x8BA5C4], [self color:0x25303D], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 6";
    colors = [NSArray arrayWithObjects:[self color:0xEBD096], [self color:0xD1B882], [self color:0x5D8A66], [self color:0x1A6566], [self color:0x21445B], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 7";
    colors = [NSArray arrayWithObjects:[self color:0xBF9F63], [self color:0x261F1D], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 8";
    colors = [NSArray arrayWithObjects:[self color:0xD9961A], [self color:0x261B11], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 9";
    colors = [NSArray arrayWithObjects:[self color:0x21487F], [self color:0x001C3D], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    name = @"Preset 10";
    colors = [NSArray arrayWithObjects:[self color:0xF2F2F2], [self color:0x038C3E], nil];
    gradient = [[NSGradient alloc] initWithColors:colors];
    [self.names addObject:name];
    [self.gradients addObject:gradient];
    
    for (NSString *name in self.names) {
        [self.presetsButton addItemWithTitle:name];
    }
    [self.presetsButton selectItemAtIndex:0];

    
}

- (IBAction)onPreset:(id)sender {
    NSInteger index = self.presetsButton.indexOfSelectedItem;
    if (index < 0) {
        index = 0;
        [self.presetsButton selectItemAtIndex:0];
    }
    NSGradient *gradient = [self.gradients objectAtIndex:index];
    [self setGradient:gradient];
    
    GRADIENT_COLOR gradientColor = [self makeGradientColorFromGradient:gradient];
    [m_btnGradient setGradientColor:gradientColor];
    [m_idGradientDelegate gradientColorChanged:gradientColor];
}

- (NSGradient *)makeGradientFromGradientColor:(GRADIENT_COLOR)gradientColor
{
    NSGradient *gradient = nil;
    
    int colorCount = gradientColor.colorInfo[0];
    int alphaCount = gradientColor.colorAlphaInfo[0];
    
    NSMutableArray *colors = [NSMutableArray array];
    CGFloat *locations = malloc(sizeof(CGFloat) * colorCount);
    for (int i = 0; i < colorCount; i++) {
        float red = gradientColor.colorInfo[i * 4 + 1];
        float green = gradientColor.colorInfo[i * 4 + 2];
        float blue = gradientColor.colorInfo[i * 4 + 3];
        float alpha = 1.0;
        if (alphaCount == colorCount) {
            alpha = gradientColor.colorAlphaInfo[i * 2 + 1];
        }
        locations[colors.count] = gradientColor.colorInfo[i * 4 + 4];
        [colors addObject:[NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha]];
    }
    gradient = [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace deviceRGBColorSpace]];
    free(locations);
    
    return gradient;
}

- (GRADIENT_COLOR)makeGradientColorFromGradient:(NSGradient *)gradient
{
    int count = [gradient numberOfColorStops];
    GRADIENT_COLOR gradientColor;
    gradientColor.colorInfo[0] = count;
    gradientColor.colorAlphaInfo[0] = count;
    
    for (int i = 0; i < count; i++) {
        NSColor *color;
        CGFloat location = 0.0;
        [gradient getColor:&color location:&location atIndex:i];
        gradientColor.colorInfo[i * 4 + 1] = [color redComponent];
        gradientColor.colorInfo[i * 4 + 2] = [color greenComponent];
        gradientColor.colorInfo[i * 4 + 3] = [color blueComponent];
        gradientColor.colorInfo[i * 4 + 4] = location;
        gradientColor.colorAlphaInfo[i * 2 + 1] = [color alphaComponent];
        gradientColor.colorAlphaInfo[i * 2 + 2] = location;
    }
    
    
    gradientColor = [self repairGradientColor:gradientColor];
    
    return gradientColor;
}


- (GRADIENT_COLOR)repairGradientColor:(GRADIENT_COLOR)srcGradient
{
    GRADIENT_COLOR gradientColor = srcGradient;
    
//    int colorCount = srcGradient.colorInfo[0];
//    int alphaCount = srcGradient.colorAlphaInfo[0];
    
    return gradientColor;
}

@end
