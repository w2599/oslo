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
#import "highlight.h"
#import "config.h"
#import "stream.h"

#define VERSION "1.0.0"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        dlopen("/System/Library/PrivateFrameworks/LoggingSupport.framework/LoggingSupport", RTLD_NOW);
        
        termDumper = [[objc_getClass("OSLogTermDumper") alloc] initWithFd:STDOUT_FILENO colorMode:2];
        if (!termDumper || highlight_init(NULL) != KERN_SUCCESS) {
            printf("Failed to initialize highlight\n");
            return 1;
        }
        
        OSLogConfig *config = [OSLogConfig parseWithArgc:argc argv:argv];
        OSEventProcessor *processor = [OSEventProcessor sharedProcessor];
        OSEventHandler handler = [processor handlerWithOptions:config.options];
        NSPredicate *predicate = [config buildPredicate];
        
        processor.currentStream = config.options.live ? CreateLiveStream() : CreateStoredStream();
        ConfigureStream(processor.currentStream, predicate, handler);
        
        if (config.options.live) {
            [(OSLogEventLiveStream *)processor.currentStream activate];
        }
        else {
            [processor.currentStream activateStreamFromDate:config.filter.after ?: [NSDate distantPast]];
        }
        
        dispatch_main();
    }
    return 0;
}
