//
//  LanguageValueTransformer.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 06.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LanguageValueTransformer.h"

@implementation LanguageValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

-(id)transformedValue:(id)value {
    NSString *language = [[NSLocale currentLocale] displayNameForKey:NSLocaleLanguageCode value:value];
    NSString *result = [NSString stringWithFormat:@"%@", language];
    return result;
}

@end
