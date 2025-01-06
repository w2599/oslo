//
//  LoggingSupport.h
//  oslo
//
//  Created by Ethan Arbuckle on 1/5/25.
//

#ifndef LoggingSupport_h
#define LoggingSupport_h

@class OSLogEventProxy;

@interface OSLogEventSource : NSObject
@end

@interface OSLogEventStore : NSObject
- (void)setProgressHandler:(void (^)(id, id))handler;
- (void)prepareWithCompletionHandler:(void (^)(OSLogEventSource *, NSError *))handler;
@end

@interface OSLogEventLocalStore : OSLogEventStore
+ (id)localStore;
@end

@interface OSLogEventStream : NSObject
- (id)initWithSource:(id)source;
- (id)initWithLiveSource:(id)source;
- (void)setFilterPredicate:(NSPredicate *)predicate;
- (void)setEventHandler:(void (^)(OSLogEventProxy *))handler;
- (void)setInvalidationHandler:(void (^)(OSLogEventStream *, NSUInteger code, id info))handler;
- (void)invalidate;
- (void)setFlags:(NSUInteger)flags;
- (void)activateStreamFromDate:(NSDate *)date;
@end

@interface OSLogEventProxy : NSObject
@property (readonly) NSString *processImagePath;
@property (readonly) NSString *senderImagePath;
- (NSString *)composedMessage;
- (NSDate *)date;
- (void)_setIncludeSensitive:(BOOL)a3;
- (int)processIdentifier;
- (int)logType;
@end

@interface OSLogEventLiveSource : OSLogEventSource
@end

@interface OSLogEventLiveStore : OSLogEventStore
+ (id)liveLocalStore;
- (void)prepareWithCompletionHandler:(void (^)(OSLogEventLiveSource *))handler;
@end

@interface OSLogEventLiveStream : OSLogEventStream
- (void)activate;
@end

@interface OSLogTermDumper : NSObject
- (id)initWithFd:(int)fd colorMode:(int)colorMode;
- (void)setBold:(BOOL)bold;
- (void)dump:(NSString *)string;
- (void)setFgColor:(int)fgColor;
- (void)setBgColor:(int)bgColor;
- (void)puts:(const char *)string;
- (void)resetStyle;
- (void)writeln;
- (BOOL)flush:(BOOL)force;
- (void)_resetAttrsForNewline;
- (void)pad:(int)a3 count:(uint64_t)a4;
@end

typedef NS_OPTIONS(NSUInteger, OSLogStreamFlags) {
    OSLogStreamFlagActivityTracing = 1 << 0,
    OSLogStreamFlagTraceMessages = 1 << 1,
    OSLogStreamFlagLogMessages = 1 << 2,
    OSLogStreamFlagSignpostMessages = 1 << 5,
    OSLogStreamFlagLossMessages = 1 << 6
};

// Wrapper for OSLogEventProxy, because the type cannot be safely retained
@interface _OSLogEventCopy : NSObject
@property NSString *processImagePath;
@property NSString *senderImagePath;
@property NSString *composedMessage;
@property NSDate *date;
@property int logType;
@property int processIdentifier;
@property BOOL isError;
- (id)initWithProxyEvent:(OSLogEventProxy *)event;
@end

#endif /* LoggingSupport_h */
