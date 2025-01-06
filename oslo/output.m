//
//  output.m
//  oslo
//
//  Created by Ethan Arbuckle on 1/5/25.
//

#import <sys/ioctl.h>
#import "kat/highlight.h"
#import "output.h"

OSLogTermDumper *termDumper = nil;

static int termWidth(void) {
    static dispatch_once_t onceToken;
    static int width = 0;
    dispatch_once(&onceToken, ^{
        struct winsize ws;
        ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws);
        width = ws.ws_col;
    });
    return width;
}

static void removeNewlines(char *str) {
    char *pos = str;
    while (*str) {
        if (*str != '\n' && *str != '\t') {
            *pos++ = *str;
        }
        str++;
    }
    *pos = '\0';
}

static char *padLineBreaks(const char *str, int padding, int termWidth) {
    if (!str || !*str || padding < 0 || termWidth <= 0) {
        return NULL;
    }
    
    int effectiveWidth = termWidth - padding;
    if (effectiveWidth <= 0) {
        return NULL;
    }
    
    size_t len = strlen(str);
    size_t maxSize = len + ((len / effectiveWidth) + 1) * (padding + 1) + 1;
    if (maxSize < len) {
        return NULL;
    }
    
    char *result = calloc(1, maxSize);
    if (!result) {
        return NULL;
    }
    
    size_t pos = 0;
    size_t outPos = 0;
    size_t lineStart = 0;
    int column = 0;
    while (pos < len) {
        if (outPos >= maxSize - 1) {
            free(result);
            return NULL;
        }
        
        if (str[pos] == '\n' || (column >= effectiveWidth - 3 && column > 0)) {
            size_t segLen = pos - lineStart;
            if (outPos + segLen >= maxSize - 1) {
                free(result);
                return NULL;
            }
            
            memcpy(&result[outPos], &str[lineStart], segLen);
            outPos += segLen;
            result[outPos++] = '\n';
            
            if (pos + 1 < len) {
                if (outPos + padding >= maxSize - 1) {
                    free(result);
                    return NULL;
                }
                memset(&result[outPos], ' ', padding);
                outPos += padding;
            }
            lineStart = pos + (str[pos] == '\n' ? 1 : 0);
            column = 0;
        }
        else {
            if (str[pos] == '\033') {
                while (pos < len && str[pos] != 'm') {
                    pos++;
                }
            }
            else {
                column++;
            }
        }
        pos++;
    }
    
    if (lineStart < len) {
        size_t remaining = len - lineStart;
        if (outPos + remaining >= maxSize) {
            free(result);
            return NULL;
        }
        memcpy(&result[outPos], &str[lineStart], remaining);
        outPos += remaining;
    }
    
    result[outPos] = '\0';
    return result;
}

void printLogEvent(_OSLogEventCopy *logProxyEvent) {
    // The composed message is the fully formatted log
    const char *composed_message = [logProxyEvent.composedMessage UTF8String];
    if (composed_message == NULL || strlen(composed_message) == 0) {
        return;
    }
    
    NSString *processName = logProxyEvent.processImagePath.lastPathComponent;
    NSString *imageName = logProxyEvent.senderImagePath.lastPathComponent;
    if (!processName || !imageName) {
        return;
    }

    // If the date is >=24 hours ago, show the full date
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm:ss"];
    }
    
    if (fabs([logProxyEvent.date timeIntervalSinceNow]) >= 86400) {
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    BOOL processAndSenderMatch = [processName isEqualToString:imageName];
    if (!processAndSenderMatch && [imageName length] > 20) {
        // Truncate it by snipping the middle and adding ellipsis
        imageName = [NSString stringWithFormat:@"%@...%@", [imageName substringToIndex:10], [imageName substringFromIndex:[imageName length] - 10]];
    }
    
    // If process and image names are the same, only show it once
    NSString *processAndImage = processAndSenderMatch ? processName : [NSString stringWithFormat:@"%@(%@)", processName, imageName];
    
    NSString *timestamp = [formatter stringFromDate:logProxyEvent.date];
    NSString *prefix = [NSString stringWithFormat:@"%@ %@:%d ", timestamp, processAndImage, logProxyEvent.processIdentifier];
    int prefixLen = (int)[prefix lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    // Log line prefix --  `12:15:01 Process(Image):PID <message>`
    [termDumper setBold:YES];
    [termDumper setFgColor:6];
    [termDumper puts:timestamp.UTF8String];
    [termDumper puts:" "];
    // Process name
    [termDumper setFgColor:2];
    [termDumper setBold:NO];
    [termDumper puts:processName.UTF8String];
    // image name in brackets
    if (!processAndSenderMatch) {
        [termDumper setFgColor:7];
        [termDumper puts:"("];
        [termDumper setFgColor:3];
        [termDumper puts:imageName.UTF8String];
        [termDumper setFgColor:7];
        [termDumper puts:")"];
    }
    [termDumper setFgColor:7];
    [termDumper puts:":"];
    [termDumper setFgColor:5];
    [termDumper puts:[NSString stringWithFormat:@"%d", logProxyEvent.processIdentifier].UTF8String];
    [termDumper setFgColor:7];
    [termDumper puts:" "];
    [termDumper resetStyle];
    [termDumper flush:YES];
    
    char *message_copy = strdup(composed_message);
    if (message_copy == NULL) {
        return;
    }
    
    removeNewlines((char *)message_copy);
    
    if (logProxyEvent.isError) {
        [termDumper setFgColor:1];
        char *padded = padLineBreaks(message_copy, prefixLen, termWidth());
        if (padded) {
            [termDumper puts:padded];
            free(padded);
            [termDumper writeln];
        }
    }
    else {
        char *highlighted_log = highlight_line(message_copy, NULL, 0);
        if (!highlighted_log) {
            [termDumper resetStyle];
            [termDumper puts:message_copy];
            [termDumper writeln];
        }
        else {
            char *padded = padLineBreaks(highlighted_log, prefixLen, termWidth());
            if (padded) {
                puts(padded);
                free(padded);
            }
            highlight_free(highlighted_log);
        }
    }
    
    free(message_copy);
    [termDumper _resetAttrsForNewline];
}
