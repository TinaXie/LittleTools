//
//  Tools.h
//  LittleTools
//
//  Created by xiejc on 2021/5/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tools : NSObject

+(NSString *)objectToJson:(id)obj;

+(id)jsonToObject:(NSString *)json;

+ (NSString *)notNullString:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
