//
//  config.h
//  oslo
//
//  Created by Ethan Arbuckle on 1/23/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OSLogLevel) {
    OSLogLevelNotice = 0x00,
    OSLogLevelInfo = 0x01,
    OSLogLevelDebug = 0x02,
    OSLogLevelError = 0x10,
    OSLogLevelFault = 0x11
};

@interface OSLogFilter : NSObject
@property (nonatomic, copy) NSString *processPattern;
@property (nonatomic, assign) pid_t pid;
@property (nonatomic, assign) OSLogLevel level;
@property (nonatomic, strong) NSDate *after;
@property (nonatomic, strong) NSDate *before;
@property (nonatomic, strong) NSArray<NSString *> *containsPatterns;
@property (nonatomic, strong) NSArray<NSString *> *excludePatterns;
@property (nonatomic, strong) NSString *imagePath;

@end

@interface OSLogOptions : NSObject
@property (nonatomic, assign) BOOL live;
@property (nonatomic, assign) BOOL group;
@property (nonatomic, assign) BOOL json;
@property (nonatomic, assign) BOOL dropRepeatedMessages;
@property (nonatomic, assign) BOOL noColor;
@property (nonatomic, copy) NSString *outputFile;
@end

@interface OSLogConfig : NSObject
@property (nonatomic, strong) OSLogFilter *filter;
@property (nonatomic, strong) OSLogOptions *options;

+ (instancetype)parseWithArgc:(int)argc argv:(char **)argv;
- (NSPredicate *)buildPredicate;

@end
