//
//  main.m
//  oslo
//
//  Created by Ethan Arbuckle on 01/05/25.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import "output.h"
#import "grouping.h"
#import "highlight.h"

#define VERSION "1.0.0"

@implementation _OSLogEventCopy : NSObject
- (id)initWithProxyEvent:(OSLogEventProxy *)event {
    if (self = [super init]) {
        
        // Include {private} fields in the composed message
        [event _setIncludeSensitive:YES];
        _composedMessage = event.composedMessage;
        _processImagePath = event.processImagePath;
        _senderImagePath = event.senderImagePath;
        _date = event.date;
        _processIdentifier = event.processIdentifier;
        _logType = event.logType;
        _isError = event.logType == 16;
    }
    return self;
}
@end

static void (^streamEventHandler)(OSLogEventProxy *) = ^void(OSLogEventProxy *logProxyEvent) {
    if (!logProxyEvent) {
        return;
    }
    printLogEvent([[_OSLogEventCopy alloc] initWithProxyEvent:logProxyEvent]);
};

static void (^streamInvalidationHandler)(OSLogEventStream *, NSUInteger, id) = ^void(OSLogEventStream *stream, NSUInteger code, id info) {
    printf("Stream invalidated with code %lu\n", (unsigned long)code);
    exit(0);
};

static void startLiveStreamWithPredicate(NSPredicate *predicate) {
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
        return;
    }
    
    [stream setFilterPredicate:predicate];
    [stream setEventHandler:streamEventHandler];
    [stream setInvalidationHandler:streamInvalidationHandler];
    [stream activate];
}

static void startStoredStreamWithPredicate(NSPredicate *predicate, BOOL group) {
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
        return;
    }
    
    [stream setFilterPredicate:predicate];
    if (!group) {
        [stream setEventHandler:streamEventHandler];
    }
    else {
        // Grouping requires a different event handler
        [stream setEventHandler:^(OSLogEventProxy *event) {
            if (event) {
                handleLogEventWithGrouping(event);
            }
        }];
    }
    [stream activateStreamFromDate:[NSDate distantPast]];
}
                                  
static void printUsage(void) {
    printf("oslo %s\n", VERSION);
    printf("Usage: oslo [-s] [-g] [ProcessName]\n");
    printf("Options:\n");
    printf("  -l: Stream live logs\n");
    printf("  -s: Stream past logs\n");
    printf("      -g: Group by PID\n");
    printf("  ProcessName: Filter by process name\n");
    printf("\n");
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        dlopen("/System/Library/PrivateFrameworks/LoggingSupport.framework/LoggingSupport", RTLD_NOW);
        termDumper = [[objc_getClass("OSLogTermDumper") alloc] initWithFd:STDOUT_FILENO colorMode:2];
        if (!termDumper || highlight_init(NULL) != KERN_SUCCESS) {
            printf("Failed to initialize highlight\n");
            return 1;
        }
        
        bool live = true;
        bool group = false;
        char *process = NULL;
        
        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-l") == 0) {
                live = true;
            }
            else if (strcmp(argv[i], "-s") == 0) {
                live = false;
            }
            else if (strcmp(argv[i], "-g") == 0) {
                group = true;
            }
            else if (argv[i][0] != '-' && !process) {
                process = argv[i];
            }
            else {
                printUsage();
                return 1;
            }
        }
        
        if (group) {
            if (live || !process) {
                printf("Grouping only works with stored logs and requires a process name\n");
                return 1;
            }
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
        if (process) {
            printf("Filtering process image path with: %s\n", process);
            predicate = [NSPredicate predicateWithFormat:@"processImagePath contains %@", [NSString stringWithUTF8String:process]];
        }
        
        if (live) {
            startLiveStreamWithPredicate(predicate);
        }
        else {
            startStoredStreamWithPredicate(predicate, group);
        }

        dispatch_main();
    }
    
    return 0;
}
