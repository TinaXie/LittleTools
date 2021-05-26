//
//  Tools.m
//  LittleTools
//
//  Created by xiejc on 2021/5/26.
//

#import "Tools.h"

@implementation Tools

+(NSString *)objectToJson:(id)obj {
    if (obj == nil) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:0
                                                         error:&error];

    if ([jsonData length] && error == nil){
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

+ (id)jsonToObject:(NSString *)json {
    NSData * jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    return obj;
}


+ (NSString *)notNullString:(NSString *)str {
    if (str == nil) {
        return @"";
    }
    return str;
}

@end
