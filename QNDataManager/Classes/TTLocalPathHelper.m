//
//  TTLocalPathHelper.m
//  TTFoundation
//
//  Created by Xiaoxuan Tang on 14-7-2.
//  Copyright (c) 2014年 tietie tech. All rights reserved.
//

#import "TTLocalPathHelper.h"
@import MobileCoreServices;

@implementation TTLocalPathHelper

+ (NSString*) documentsPath
{
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/"];
}

+ (NSString*) libraryPath
{
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/"];
}

+ (NSString*) tempPath
{
    return NSTemporaryDirectory();
}

+ (NSString*) mimeTypeWithFilePath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return (__bridge NSString *)mimeType;
}
@end
