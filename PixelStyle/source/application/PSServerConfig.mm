//
//  PSServerConfig.m
//  PixelStyle
//
//  Created by wyl on 16/2/25.
//
//

#import "PSServerConfig.h"
#import "ConfigureInfo.h"
#import "tinyxml.h"
@interface PSReadXml : NSObject

- (NSMutableDictionary *)getResponseInfo:(NSString *)xmlInfo;
- (NSMutableArray *)read_CategoriesGetList_Xml:(NSString*)aString;
- (NSMutableArray *)read_CategoriesGetImages_Xml:(NSString*)aString;
- (NSMutableDictionary *)read_ImagesGetInfo_Xml:(NSString*)aString;

- (NSMutableDictionary *)getConfig:(NSString *)aString;

@end


@implementation PSReadXml

- (NSMutableDictionary *)getResponseInfo:(NSString *)xmlInfo
{
    if (!xmlInfo) return nil;
    
    
    NSRange range = [xmlInfo rangeOfString:@"<?xml"];
    
    if (range.location == NSNotFound) return nil;
    
    NSString *sub = [xmlInfo substringFromIndex:range.location];
    
    TiXmlDocument* myDocument = new TiXmlDocument();
    
    myDocument->Parse([sub UTF8String]);
    
    TiXmlElement* rootElement = myDocument->RootElement();
    
    if (!rootElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    TiXmlAttribute* attributeOfRootElement = rootElement->FirstAttribute();
    
    if (!attributeOfRootElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    NSMutableDictionary *dicRoot = [[[NSMutableDictionary alloc] init] autorelease];
    
    
    while (attributeOfRootElement) {
        
        if (attributeOfRootElement->Name() && attributeOfRootElement->Value()) {
            
            NSString *name = [NSString stringWithUTF8String:attributeOfRootElement->Name()];
            NSString *valueOfName = [NSString stringWithUTF8String:attributeOfRootElement->Value()];
            
            [dicRoot setObject:valueOfName forKey:name];
        }
        
        attributeOfRootElement = attributeOfRootElement->Next();
        
    }
    
    delete myDocument;
    
    return dicRoot;
}

- (NSMutableArray *)getCategoryInfo:(NSString *)xmlCategoryInfo
{
    if (!xmlCategoryInfo) {
        return nil;
    }
    
    NSRange range = [xmlCategoryInfo rangeOfString:@"<?xml"];
    
    if (range.location == NSNotFound) {
        return nil;
    }
    
    
    NSString *sub = [xmlCategoryInfo substringFromIndex:range.location];
    
    
    TiXmlDocument* myDocument = new TiXmlDocument();
    
    myDocument->Parse([sub UTF8String]);
    
    TiXmlElement* rootElement = myDocument->RootElement();
    
    if (!rootElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    TiXmlElement* categoriesElement = rootElement->FirstChildElement();
    
    if (!categoriesElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    TiXmlElement* categoryElement = categoriesElement->FirstChildElement();
    
    if (!categoryElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    
    
    while (categoryElement) {
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        
        TiXmlAttribute* attributeOfCategoryElement = categoryElement->FirstAttribute();
        
        while (attributeOfCategoryElement) {
            
            if (attributeOfCategoryElement->Name() && attributeOfCategoryElement->Value()) {
                
                NSString *name = [NSString stringWithUTF8String:attributeOfCategoryElement->Name()];
                NSString *valueOfName = [NSString stringWithUTF8String:attributeOfCategoryElement->Value()];
                
                [dic setObject:valueOfName forKey:name];
            }
            
            attributeOfCategoryElement = attributeOfCategoryElement->Next();
            
        }
        
        TiXmlElement* temp = categoryElement->FirstChildElement();
        while (temp) {
            
            if (temp->Value() && temp->GetText()) {
                
                NSString *tempName = [NSString stringWithUTF8String:temp->Value()];
                NSString *tempText = [NSString stringWithUTF8String:temp->GetText()];
                
                [dic setObject:tempText forKey:tempName];
            }
            
            temp = temp->NextSiblingElement();
        }
        
        [array addObject:dic];
        [dic release];
        
        categoryElement = categoryElement->NextSiblingElement();
        
    }
    
    delete myDocument;
    
    return array;
}



- (NSMutableArray *)read_CategoriesGetList_Xml:(NSString*)aString
{
    if (!aString) {
        return nil;
    }
    
    NSRange range = [aString rangeOfString:@"<?xml"];
    
    if (range.location == NSNotFound) {
        return nil;
    }
    
    
    NSString *sub = [aString substringFromIndex:range.location];
    
    
    
    TiXmlDocument* myDocument = new TiXmlDocument();
    
    myDocument->Parse([sub UTF8String]);
    
    TiXmlElement* rootElement = myDocument->RootElement();
    
    if (!rootElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    TiXmlElement* categoriesElement = rootElement->FirstChildElement();
    
    if (!categoriesElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    TiXmlElement* categoryElement = categoriesElement->FirstChildElement();
    
    if (!categoryElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    
    
    while (categoryElement) {
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        
        TiXmlAttribute* attributeOfCategoryElement = categoryElement->FirstAttribute();
        
        while (attributeOfCategoryElement) {
            
            if (attributeOfCategoryElement->Name() && attributeOfCategoryElement->Value()) {
                
                NSString *name = [NSString stringWithUTF8String:attributeOfCategoryElement->Name()];
                NSString *valueOfName = [NSString stringWithUTF8String:attributeOfCategoryElement->Value()];
                
                [dic setObject:valueOfName forKey:name];
            }
            
            attributeOfCategoryElement = attributeOfCategoryElement->Next();
            
        }
        
        TiXmlElement* temp = categoryElement->FirstChildElement();
        while (temp) {
            
            if (temp->Value() && temp->GetText()) {
                
                NSString *tempName = [NSString stringWithUTF8String:temp->Value()];
                NSString *tempText = [NSString stringWithUTF8String:temp->GetText()];
                
                [dic setObject:tempText forKey:tempName];
            }
            
            temp = temp->NextSiblingElement();
        }
        
        [array addObject:dic];
        [dic release];
        
        categoryElement = categoryElement->NextSiblingElement();
        
    }
    
    delete myDocument;
    
    return array;
    
}


- (NSMutableArray *)read_CategoriesGetImages_Xml:(NSString*)aString
{
    
    if (!aString) {
        return nil;
    }
    
    NSRange range = [aString rangeOfString:@"<?xml"];
    
    if (range.location == NSNotFound) {
        return nil;
    }
    
    
    NSString *sub = [aString substringFromIndex:range.location];
    
    
    
    TiXmlDocument* myDocument = new TiXmlDocument();
    
    myDocument->Parse([sub UTF8String]);
    
    TiXmlElement* rootElement = myDocument->RootElement();
    
    if (!rootElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    TiXmlElement* imagesElement = rootElement->FirstChildElement();
    
    if (!imagesElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    TiXmlElement* imageElement = imagesElement->FirstChildElement();
    
    if (!imageElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    
    
    
    while (imageElement) {
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        
        TiXmlAttribute* attributeOfImage = imageElement->FirstAttribute();
        
        while ( attributeOfImage ) {
            
            if (attributeOfImage->Name() && attributeOfImage->Value()) {
                
                NSString *name = [NSString stringWithUTF8String:attributeOfImage->Name()];
                NSString *valueOfName = [NSString stringWithUTF8String:attributeOfImage->Value()];
                
                [dic setObject:valueOfName forKey:name];
            }
            
            attributeOfImage = attributeOfImage->Next();
            
        }
        
        
        TiXmlElement* temp = imageElement->FirstChildElement();
        while (temp) {
            
            
            if (temp->Value()) {
                
                NSString *tempName = [NSString stringWithUTF8String:temp->Value()];
                
                if ([tempName isEqualToString:@"name"] || [tempName isEqualToString:@"comment"]) {
                    
                    if (temp->GetText()) {
                        NSString *tempText = [NSString stringWithUTF8String:temp->GetText()];
                        [dic setObject:tempText forKey:tempName];
                    }
                }
                
                if ([tempName isEqualToString:@"derivatives"]) {
                    
                    TiXmlElement* element = temp->FirstChildElement();
                    
                    while (element) {
                        
                        if (element->Value()) {
                            
                            NSString *elementName = [NSString stringWithUTF8String:element->Value()];
                            
                            if ([elementName isEqualToString:@"thumb"]) {
                                
                                
                                TiXmlElement* subElement = element->FirstChildElement();
                                
                                while (subElement) {
                                    
                                    if (subElement->Value()) {
                                        
                                        NSString *subelementName = [NSString stringWithUTF8String:subElement->Value()];
                                        
                                        if ([subelementName isEqualToString:@"url"]) {
                                            
                                            
                                            NSString *tempText = [NSString stringWithUTF8String:subElement->GetText()];
                                            
                                            [dic setObject:tempText forKey:@"tn_url"];
                                            
                                        }
                                    }
                                    
                                    subElement = subElement->NextSiblingElement();
                                    
                                }
                                
                                
                            }
                            
                        }
                        
                        element = element->NextSiblingElement();
                    }
                    
                }
                
            }
            
            temp = temp->NextSiblingElement();
            
        }
        
        [array addObject:dic];
        [dic release];
        
        imageElement = imageElement->NextSiblingElement();
    }
    delete 	myDocument;
    
    return array;
    
}

- (NSMutableDictionary *)read_ImagesGetInfo_Xml:(NSString*)aString;
{
    if (!aString) {
        return nil;
    }
    
    NSRange range = [aString rangeOfString:@"<?xml"];
    
    if (range.location == NSNotFound) {
        return nil;
    }
    
    
    NSString *sub = [aString substringFromIndex:range.location];
    
    TiXmlDocument* myDocument = new TiXmlDocument();
    
    myDocument->Parse([sub UTF8String]);
    
    TiXmlElement* rootElement = myDocument->RootElement();
    
    if (!rootElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    TiXmlElement* imageElement = rootElement->FirstChildElement();
    
    if (!imageElement) {
        
        delete myDocument;
        return nil;
        
    }
    
    
    NSMutableDictionary *dicImageInfo = [[[NSMutableDictionary alloc] init] autorelease];
    
    TiXmlAttribute* attributeOfImage = imageElement->FirstAttribute();
    
    while ( attributeOfImage ) {
        
        if (attributeOfImage->Name() && attributeOfImage->Value()) {
            
            NSString *name = [NSString stringWithUTF8String:attributeOfImage->Name()];
            NSString *valueOfName = [NSString stringWithUTF8String:attributeOfImage->Value()];
            
            [dicImageInfo setObject:valueOfName forKey:name];
        }
        
        attributeOfImage = attributeOfImage->Next();
        
    }
    
    
    
    TiXmlElement* imageChildElement = imageElement->FirstChildElement();
    
    
    while (imageChildElement) {
        
        
        if (imageChildElement->Value()) {
            
            NSString *tempName = [NSString stringWithUTF8String:imageChildElement->Value()];
            
            if ([tempName isEqualToString:@"name"]) {
                
                if (imageChildElement->GetText()) {
                    NSString *tempText = [NSString stringWithUTF8String:imageChildElement->GetText()];
                    [dicImageInfo setObject:tempText forKey:tempName];
                }
            }
            
            
            else if ([tempName isEqualToString:@"rates"])
            {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                
                TiXmlAttribute* attribute = imageChildElement->FirstAttribute();
                
                while ( attribute ) {
                    
                    if (attribute->Name() && attribute->Value()) {
                        
                        NSString *name = [NSString stringWithUTF8String:attribute->Name()];
                        NSString *valueOfName = [NSString stringWithUTF8String:attribute->Value()];
                        
                        [dic setObject:valueOfName forKey:name];
                    }
                    
                    attribute = attribute->Next();
                    
                }
                
                [dicImageInfo setObject:dic forKey:tempName];
                
                
                [dic release];
            }
            
            
            else if ([tempName isEqualToString:@"comment_post"])
            {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                
                TiXmlAttribute* attribute = imageChildElement->FirstAttribute();
                
                while ( attribute ) {
                    
                    if (attribute->Name() && attribute->Value()) {
                        
                        NSString *name = [NSString stringWithUTF8String:attribute->Name()];
                        NSString *valueOfName = [NSString stringWithUTF8String:attribute->Value()];
                        
                        [dic setObject:valueOfName forKey:name];
                    }
                    
                    attribute = attribute->Next();
                    
                }
                
                [dicImageInfo setObject:dic forKey:tempName];
                
                
                [dic release];
            }
            
            
            else if ([tempName isEqualToString:@"comments"])
            {
                
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                
                TiXmlAttribute* attribute = imageChildElement->FirstAttribute();
                
                while ( attribute ) {
                    
                    if (attribute->Name() && attribute->Value()) {
                        
                        NSString *name = [NSString stringWithUTF8String:attribute->Name()];
                        NSString *valueOfName = [NSString stringWithUTF8String:attribute->Value()];
                        
                        [dic setObject:valueOfName forKey:name];
                    }
                    
                    attribute = attribute->Next();
                    
                }
                
                NSMutableArray *arrayID = [[NSMutableArray alloc] init];
                NSMutableArray *arrayDate = [[NSMutableArray alloc] init];
                NSMutableArray *arrayAuthor = [[NSMutableArray alloc] init];
                NSMutableArray *arrayContent = [[NSMutableArray alloc] init];
                
                TiXmlElement* subElement = imageChildElement->FirstChildElement();
                
                while (subElement) {
                    
                    TiXmlAttribute* attribute = subElement->FirstAttribute();
                    
                    while ( attribute ) {
                        
                        if (attribute->Name() && attribute->Value()) {
                            
                            NSString *name = [NSString stringWithUTF8String:attribute->Name()];
                            NSString *valueOfName = [NSString stringWithUTF8String:attribute->Value()];
                            
                            if ([name isEqualToString:@"id"]) {
                                [arrayID addObject:valueOfName];
                            }
                            
                            else if ([name isEqualToString:@"date"])
                            {
                                [arrayDate addObject:valueOfName];
                            }
                            
                        }
                        
                        attribute = attribute->Next();
                        
                    }
                    
                    TiXmlElement* childElement = subElement->FirstChildElement();
                    
                    
                    while (childElement) {
                        
                        
                        if (childElement->Value() && childElement->GetText()) {
                            
                            NSString *tempName = [NSString stringWithUTF8String:childElement->Value()];
                            
                            NSString *tempText = [NSString stringWithUTF8String:childElement->GetText()];
                            
                            if ([tempName isEqualToString:@"author"]) {
                                [arrayAuthor addObject:tempText];
                            }
                            
                            else if ([tempName isEqualToString:@"content"])
                            {
                                [arrayContent addObject:tempText];
                            }
                            
                        }
                        
                        childElement = childElement->NextSiblingElement();
                    }
                    
                    
                    subElement = subElement->NextSiblingElement();
                    
                }
                
                [dic setObject:arrayID forKey:@"id"];
                [dic setObject:arrayDate forKey:@"date"];
                [dic setObject:arrayAuthor forKey:@"author"];
                [dic setObject:arrayContent forKey:@"content"];
                
                [arrayID release];
                [arrayDate release];
                [arrayAuthor release];
                [arrayContent release];
                
                [dicImageInfo setObject:dic forKey:tempName];
                
                [dic release];
                
            }
            
        }
        
        imageChildElement = imageChildElement->NextSiblingElement();
        
    }
    
    
    return dicImageInfo;
    
    
}

- (NSMutableDictionary *)getConfig:(NSString *)aString
{
    NSRange range = [aString rangeOfString:@"<?xml"];
    
    if (range.location == NSNotFound) {
        return nil;
    }
    
    NSString *sub = [aString substringFromIndex:range.location];
    
    
    TiXmlDocument *pXmlDoc = NULL;
    
    pXmlDoc = new TiXmlDocument();
    
    if( !pXmlDoc )
    {
        return nil;
    }
    
    //加载目标XML文件
    
    //pXmlDoc->LoadFile( [path UTF8String] );
    
    pXmlDoc->Parse([sub UTF8String]);
    
    
    TiXmlElement *pRootElement;
    
    pRootElement = pXmlDoc->RootElement();
    
    if ( !pRootElement )
    {
        if( pXmlDoc )
        {
            delete pXmlDoc;
        }
        return nil;
    }
    
    
    TiXmlElement *pRootChild;
    
    pRootChild = pRootElement->FirstChildElement();
    
    if( ! pRootChild )
    {
        if( pXmlDoc )
        {
            delete pXmlDoc;
        }
        return nil;
    }
    
    NSMutableDictionary * dic = [[[NSMutableDictionary alloc] init] autorelease];
    
    while (pRootChild) {
        
        if (pRootChild->Value() && pRootChild->GetText()) {
            
            NSString *name = [NSString stringWithUTF8String:pRootChild->Value()];
            NSString *text = [NSString stringWithUTF8String:pRootChild->GetText()];
            
            //NSLog(@"name: %@,text: %@", name, text);
            
            [dic setObject:text forKey:name];
            
        }
        
        pRootChild = pRootChild-> NextSiblingElement();
        
    }
    
    
    if( pXmlDoc )
    {
        delete pXmlDoc;
    }
    
    return dic;
    
}


@end



@implementation PSServerConfig

static PSServerConfig *shareInstance = nil;

+ (PSServerConfig *)ShareInstance
{
    if(shareInstance == nil)
    {
        shareInstance = [[PSServerConfig alloc] init];
    }
    
    return shareInstance;
}


- (void)checkClientVersion
{
    NSURL *url = [NSURL URLWithString:URL_WEB_CONFIG_INFO];
    
    NSData *xmlData = [NSData dataWithContentsOfURL:url];
    NSString *xmlString = [[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease];
    
    if (xmlData == nil) return;
    else
    {
        //NSLog(@"File read succeed!:%@",xmlString);
        [self readXml:xmlString];
    }
}


-(void)readXml:(NSString *)sXmlString
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    
    PSReadXml *read=[[[PSReadXml alloc] init] autorelease];
    NSDictionary *dic = [read getConfig:sXmlString];
    
    if (dic)
    {
        NSString *requireVersion = [dic objectForKey:@"require_client_version"];
        NSString *recommendVersion = [dic objectForKey:@"recommend_client_version"];
        
        if (requireVersion && recommendVersion)
        {
            BOOL bNeedUpdate = NO;
            BOOL bNeedRecommend = NO;
            
            if ([app_Version floatValue] < [requireVersion floatValue])
                bNeedUpdate = YES;
            
            if ([app_Version floatValue] < [recommendVersion floatValue])
                bNeedRecommend = YES;

            
            NSString *message = [dic objectForKey:@"update_message_english"];
            message = [message stringByReplacingOccurrencesOfString:@"XXX" withString:app_Name];
            message = [message stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            
            NSString *informative = [dic objectForKey:@"update_informative_english"];
            informative = [informative stringByReplacingOccurrencesOfString:@"XXX" withString:app_Name];
            informative = [informative stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            
            if (bNeedUpdate)
            {
                [self alertUpdateView:message informative:informative];
            }
            else if (bNeedRecommend)
            {
                [self alertCanUpdateView:message informative:informative];
            }
        }
    }
}

-(void)alertUpdateView:(NSString *)sMessage informative:(NSString *)sInformative
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *userLibraryPath = [paths objectAtIndex:0];
    NSString *sIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
    NSString *supportFile = [NSString stringWithFormat:@"%@/Containers/%@", userLibraryPath,sIdentifier];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL bAppStoreUser = NO;
//    if ([fm fileExistsAtPath:supportFile isDirectory:nil])
//    {
//        bAppStoreUser = YES;
//    }
//    else
//    {
//        bAppStoreUser = NO;
//    }
    
    //是AppStore用户的时候
    if (bAppStoreUser)
    {
        [self appStoreAlertUpdateView:sMessage informative:sInformative];
    }
    else
    {
        [self webAlertUpdateView:sMessage informative:sInformative];
    }
}

-(void)appStoreAlertUpdateView:(NSString *)sMessage informative:(NSString *)sInformative
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:NSLocalizedString(sMessage, nil) ];
    [alert setInformativeText:NSLocalizedString(sInformative, nil)];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSModalResponse reCode = [alert runModal];
    [NSApp terminate:nil];
}

-(void)webAlertUpdateView:(NSString *)sMessage informative:(NSString *)sInformative
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Update Now"];
    [alert addButtonWithTitle:@"No"];
    [alert setMessageText:NSLocalizedString(sMessage, nil) ];
    [alert setInformativeText:NSLocalizedString(sInformative, nil)];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSModalResponse reCode = [alert runModal];
    if(reCode == NSAlertFirstButtonReturn) //Update Now
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URL_PRODUCT]];
        [NSApp terminate:nil];
    }
    else                  //No
    {
        [NSApp terminate:nil];
    }
}


-(void)alertCanUpdateView:(NSString *)sMessage informative:(NSString *)sInformative
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *userLibraryPath = [paths objectAtIndex:0];
    NSString *sIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
    NSString *supportFile = [NSString stringWithFormat:@"%@/Containers/%@", userLibraryPath,sIdentifier];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL bAppStoreUser = NO;
//    if ([fm fileExistsAtPath:supportFile isDirectory:nil])
//    {
//        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//        [alert addButtonWithTitle:@"OK"];
//        [alert setMessageText:NSLocalizedString(sMessage, nil) ];
//        [alert setInformativeText:NSLocalizedString(sInformative, nil)];
//        [alert setAlertStyle:NSWarningAlertStyle];
//        
//        NSModalResponse reCode = [alert runModal];
//    }
//    else
//    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"Update Now"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:NSLocalizedString(sMessage, nil) ];
        [alert setInformativeText:NSLocalizedString(sInformative, nil)];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        NSModalResponse reCode = [alert runModal];
        if(reCode == NSAlertFirstButtonReturn)
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URL_PRODUCT]];
            [NSApp terminate:nil];
        }
        else  //No
        {
            
        }
//    }
}

@end
