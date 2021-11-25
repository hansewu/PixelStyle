//
//  PSExporter.m
//  PixelStyle
//
//  Created by wyl on 15/9/18.
//
//

#import "PSExporter.h"
#import "PSContent.h"

@implementation PSExporter

- (BOOL)hasOptions
{
    return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
    return @"PixelStyle image (PSDB)";
}

- (NSString *)extension
{
    return @"psdb";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver =[[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
    
    [archiver encodeObject:[document contents] forKey:@"content"];
    
    [archiver finishEncoding];
    
    [data writeToFile:path atomically:YES];
    
    
//    [NSKeyedArchiver archiveRootObject:[document contents] toFile:path];
    
    return YES;
}


@end
