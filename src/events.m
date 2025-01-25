//
//  events.m
//  oslo
//
//  Created by Ethan Arbuckle on 1/23/25.
//

#import <Foundation/Foundation.h>
#import "LoggingSupport.h"
#import "events.h"
#import "output.h"
#import "grouping.h"

@implementation _OSLogEventCopy

- (id)initWithProxyEvent:(OSLogEventProxy *)event {
    if ((self = [super init])) {
        
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

- (NSDictionary *)asJSONDictionary {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    });
    
    return @{
        @"timestamp": [formatter stringFromDate:self.date],
        @"message": self.composedMessage ?: @"",
        @"process": self.processImagePath.lastPathComponent ?: @"",
        @"sender": self.senderImagePath.lastPathComponent ?: @"",
        @"pid": @(self.processIdentifier),
        @"type": @(self.logType),
        @"isError": @(self.isError)
    };
}

@end

@interface OSEventProcessor ()
@property (nonatomic, strong) NSFileHandle *outputFile;
@property (nonatomic, assign) BOOL jsonOutput;
@end

@implementation OSEventProcessor {
    _OSLogEventCopy *_lastEvent;
    int _lastEventRepeatCount;
}

+ (id)sharedProcessor {
    static OSEventProcessor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init {
    if ((self = [super init])) {
        _lastEventRepeatCount = 0;
        _outputFile = nil;
    }
    return self;
}

- (void)dealloc {
    if (_outputFile) {
        [_outputFile closeFile];
    }
}

- (OSEventHandler)handlerWithOptions:(OSLogOptions *)opts {
    if (opts.outputFile) {
        if (![[NSFileManager defaultManager] createFileAtPath:opts.outputFile contents:nil attributes:nil]) {
            printf("Failed to create output file: %s\n", [opts.outputFile UTF8String]);
            exit(1);
        }
        
       self.outputFile = [NSFileHandle fileHandleForWritingAtPath:opts.outputFile];
        if (!self.outputFile) {
            printf("Failed to open output file: %s\n", [opts.outputFile UTF8String]);
            exit(1);
        }
    }
    
    self->_jsonOutput = opts.json;
    if (opts.group) {
        return ^(OSLogEventProxy *event) {
            if (event) {
                handleLogEventWithGrouping(event);
            }
        };
    }

    return ^(OSLogEventProxy *event) {
        if (!event) {
            return;
        }
        
        if (opts.dropRepeatedMessages && self->_lastEvent && self->_lastEvent.processIdentifier == event.processIdentifier) {
            
            NSTimeInterval timeDiff = [event.date timeIntervalSinceDate:self->_lastEvent.date];
            BOOL sameMessage = [self->_lastEvent.composedMessage isEqualToString:event.composedMessage];
            if (sameMessage && timeDiff <= 1) {
                self->_lastEventRepeatCount++;
                return;
            }
            
            if (!sameMessage && self->_lastEventRepeatCount > 0) {
                if (timeDiff > 1) {
                    NSString *repeatedMsg = [NSString stringWithFormat:@"Last message repeated %d times\n", self->_lastEventRepeatCount];
                    [self writeOutput:repeatedMsg];
                }
                self->_lastEventRepeatCount = 0;
            }
        }
        
        _OSLogEventCopy *eventCopy = [[_OSLogEventCopy alloc] initWithProxyEvent:event];

        if (self->_jsonOutput) {
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[eventCopy asJSONDictionary] options:0 error:&error];
            if (jsonData) {
                [self writeOutput:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
                [self writeOutput:@"\n"];
            }
        }
        else if (self.outputFile) {
            NSString *output = [NSString stringWithFormat:@"%@ %s\n", [eventCopy.date description], [eventCopy.composedMessage UTF8String]];
            [self writeOutput:output];
        }
        else {
            printLogEvent(eventCopy);
        }
        
        if (opts.dropRepeatedMessages) {
            self->_lastEvent = eventCopy;
        }
    };
}

- (void)writeOutput:(NSString *)text {
    if (self.outputFile) {
        [self.outputFile writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else {
        printf("%s", [text UTF8String]);
    }
}

@end
