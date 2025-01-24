//
//  stream.h
//  oslo
//
//  Created by Ethan Arbuckle on 1/23/25.
//

#import "LoggingSupport.h"
#import "events.h"


OSLogEventStream *CreateLiveStream(void);
OSLogEventStream *CreateStoredStream(void);
void ConfigureStream(OSLogEventStream *stream, NSPredicate *pred, OSEventHandler handler);
