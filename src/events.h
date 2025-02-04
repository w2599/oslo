//
//  events.h
//  oslo
//
//  Created by Ethan Arbuckle on 1/23/25.
//

#import "config.h"

typedef void (^OSEventHandler)(OSLogEventProxy *);

@interface OSEventProcessor : NSObject
@property (nonatomic, copy) OSEventHandler handler;
@property (nonatomic, strong) OSLogEventStream *currentStream;

+ (id)sharedProcessor;
- (OSEventHandler)handlerWithOptions:(OSloLogOptions *)opts;

@end
