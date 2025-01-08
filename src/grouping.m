//
//  grouping.m
//  oslo
//
//  Created by Ethan Arbuckle on 1/5/25.
//

#import "grouping.h"
#import "output.h"

@interface _OSLogEventGroup : NSObject
@property (nonatomic, strong) NSMutableArray <_OSLogEventCopy *> *events;
@property (nonatomic, assign) int processId;
@property (nonatomic, assign) NSDate *lastEventDate;
@end

@implementation _OSLogEventGroup

- (id)init {
    if (self = [super init]) {
        _events = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

static NSMutableDictionary<NSNumber *, _OSLogEventGroup *> *logGroups = nil;

static void printAllGroups(void) {
    // Sort groups by date of the last event they contain
    NSArray *sortedPIDs = [logGroups.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *pid1, NSNumber *pid2) {
        _OSLogEventGroup *group1 = logGroups[pid1];
        _OSLogEventGroup *group2 = logGroups[pid2];
        return [group1.lastEventDate compare:group2.lastEventDate];
    }];
    
    for (NSNumber *pid in sortedPIDs) {
        // Skip empty groups
        _OSLogEventGroup *group = logGroups[pid];
        if (group.events.count == 0) {
            continue;
        }
        
        // Write a header with PID and timestamp of the group's last event
        [termDumper setBold:YES];
        [termDumper setFgColor:7];
        [termDumper puts:[NSString stringWithFormat:@"\nPID %d ", group.processId].UTF8String];
        [termDumper pad:'-' count:10];
        [termDumper puts:" "];
        [termDumper puts:[group.lastEventDate descriptionWithLocale:[NSLocale currentLocale]].UTF8String];
        [termDumper writeln];
        [termDumper resetStyle];
        
        // Print all events in the group
        for (_OSLogEventCopy *event in group.events) {
            printLogEvent(event);
        }
        [termDumper writeln];
    }
}

void handleLogEventWithGrouping(OSLogEventProxy *logProxyEvent) {
    // Ignore logs from stuff in the dyld cache
    NSString *senderImagePath = logProxyEvent.senderImagePath;
    BOOL shouldIgnore = !senderImagePath || ![[NSFileManager defaultManager] fileExistsAtPath:senderImagePath];
    // Unless the log is an error
    shouldIgnore = shouldIgnore && logProxyEvent.logType != 16;
    if (shouldIgnore) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!logGroups) {
            logGroups = [[NSMutableDictionary alloc] init];
        }
    });

    NSNumber *pidKey = @(logProxyEvent.processIdentifier);
    _OSLogEventGroup *group = logGroups[pidKey];
    if (!group) {
        group = [[_OSLogEventGroup alloc] init];
        group.processId = logProxyEvent.processIdentifier;
        group.lastEventDate = logProxyEvent.date;
        logGroups[pidKey] = group;
        printAllGroups();
    }
    
    [group.events addObject:[[_OSLogEventCopy alloc] initWithProxyEvent:logProxyEvent]];
}

