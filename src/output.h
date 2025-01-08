//
//  output.h
//  oslo
//
//  Created by Ethan Arbuckle on 1/5/25.
//

#ifndef output_h
#define output_h

#import <Foundation/Foundation.h>
#import "LoggingSupport.h"

extern OSLogTermDumper *termDumper;

void printLogEvent(_OSLogEventCopy *logProxyEvent);

#endif /* output_h */
