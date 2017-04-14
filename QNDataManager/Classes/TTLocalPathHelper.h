//
//  TTLocalPathHelper.h
//  TTFoundation
//
//  Created by Xiaoxuan Tang on 14-7-2.
//  Copyright (c) 2014年 tietie tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTLocalPathHelper : NSObject

+ (NSString*) documentsPath;
+ (NSString*) libraryPath;
+ (NSString*) tempPath;
+ (NSString*) mimeTypeWithFilePath:(NSString*) filePath;
@end
