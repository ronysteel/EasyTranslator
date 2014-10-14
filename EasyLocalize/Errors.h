//
//  Errors.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#ifndef EasyLocalize_Errors_h
#define EasyLocalize_Errors_h

@import Foundation;

typedef NS_ENUM(NSUInteger, EasyLocalizeError) {
    EasyLocalizeFileNotReadError = -1,
    EasyLocalizeFileInvalidError = -2,
    EasyLocalizeStorageNoMOMDError = -3,
    EasyLocalizeStorageInternalError = -4,
    EasyLocalizeFileFormatMissingTargetLanguageError = -5,
    EasyLocalizeUnknownError = -99
};


static NSError *errorWithCode(EasyLocalizeError errorCode, BOOL logError) {

    NSError *error = nil;
    NSString *domain = @"Easy XLIFF Error";
    
    switch (errorCode) {
        case EasyLocalizeFileNotReadError:
            error = [NSError errorWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey : @"Could not read file."}];
            break;
        case EasyLocalizeFileInvalidError:
            error = [NSError errorWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey : @"File is not a valid XLIFF file."}];
            break;
        case EasyLocalizeStorageNoMOMDError:
            error = [NSError errorWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey : @"Could not create persistent object model."}];
            break;
        case EasyLocalizeStorageInternalError:
            error = [NSError errorWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey : @"An internal storage error occured."}];
            break;
        case EasyLocalizeFileFormatMissingTargetLanguageError:
            error = [NSError errorWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey : @"File format error: missing target language."}];
            break;
        default:
            error = [NSError errorWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey : @"Unknown error."}];
    }
    
    if (logError) {
        NSLog(@"%@", error.localizedDescription);
    }
    
    return error;
}


#endif
