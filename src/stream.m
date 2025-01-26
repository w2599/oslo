//
//  stream.m
//  oslo
//
//  Created by Ethan Arbuckle on 1/23/25.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "stream.h"
#import "events.h"

OSLogEventStream *CreateLiveStream(void) {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block OSLogEventLiveStream *stream = nil;
    
    OSLogEventLiveStore *store = [objc_getClass("OSLogEventLiveStore") liveLocalStore];
    [store prepareWithCompletionHandler:^(OSLogEventLiveSource *liveEventSource) {
        if (liveEventSource) {
            stream = [[objc_getClass("OSLogEventLiveStream") alloc] initWithLiveSource:liveEventSource];
            if (stream) {
                [stream setFlags:OSLogStreamFlagLogMessages];
            }
        }
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    
    if (!stream) {
        printf("Failed to create live stream\n");
        return nil;
    }

    return stream;
}

OSLogEventStream *CreateStoredStream(void) {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block OSLogEventStream *stream;
    
    OSLogEventLocalStore *store = [objc_getClass("OSLogEventLocalStore") localStore];
    [store prepareWithCompletionHandler:^(OSLogEventSource *eventSource, NSError *error) {
        if (eventSource) {
            stream = [[objc_getClass("OSLogEventStream") alloc] initWithSource:eventSource];
            [stream setFlags:OSLogStreamFlagLogMessages];
        }
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    if (!stream) {
        printf("Failed to create stored stream\n");
        return nil;
    }

    return stream;
}

void ConfigureStream(OSLogEventStream *stream, NSPredicate *pred, OSEventHandler handler) {
    [stream setFilterPredicate:pred];
    [stream setEventHandler:handler];
    [stream setInvalidationHandler:^(void) {
        printf("End of stream\n");
        exit(0);
    }];
}
