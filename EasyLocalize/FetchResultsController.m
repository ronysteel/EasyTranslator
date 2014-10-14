//
//  FetchResultsController.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 07.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "FetchResultsController.h"

@interface FetchResultsController ()
@end

@implementation FetchResultsController

- (instancetype)initWithContent:(id)content {
    self = [super initWithContent:content];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self addObserver:self forKeyPath:@"arrangedObjects" options:0 context:NULL];
    self.automaticallyPreparesContent = NO;
    self.automaticallyRearrangesObjects = NO;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"arrangedObjects" context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (object == self && [keyPath isEqualToString:@"arrangedObjects"]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resultsDidChange) object:nil];
        [self performSelector:@selector(resultsDidChange) withObject:nil afterDelay:0];
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (BOOL)fetchWithRequest:(NSFetchRequest *)fetchRequest merge:(BOOL)merge error:(NSError *__autoreleasing *)error {
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:nil];
    }
    
    NSUInteger batchSize = 20;
    if ([self.delegate respondsToSelector:@selector(numberOfVisibleRecordsForController:)]) {
        batchSize = [self.delegate numberOfVisibleRecordsForController:self];
    }
    fetchRequest.fetchBatchSize = batchSize;
    return [super fetchWithRequest:fetchRequest merge:merge error:error];
}

- (void)resultsDidChange {
    if ([self.delegate respondsToSelector:@selector(controllerDidChangeContents:)]) {
        [self.delegate controllerDidChangeContents:self];
    }
}

@end
