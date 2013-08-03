/*
 
 atPeek - iPhone app browsing tool
 Copyright (C) 2008  atPurpose
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>
 
 */

#import "Foundation/Foundation.h"
#import "Utilities.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

static char string[1024];

static inline void custom_sprintf(const char* postfix, double number, int precision)
{
    if (precision == ZERO_DIGIT)
    {
        sprintf(string, "%.0f %s", rint(number+0.5), postfix);
    }
    else if (precision == ONE_DIGIT)
    {
        sprintf(string, "%.1f %s", number, postfix);
    }
    else if (precision == TWO_DIGIT)
    {
        sprintf(string, "%.2f %s", number, postfix);
    }
    else
    {
        sprintf(string, "%f %s", number, postfix);
    }
}

char *utf8StringFor(double number, double base, int precision)
{
    if (number < base)
    {
        custom_sprintf("B", number, ZERO_DIGIT);
    }
    else
    {
        number = number/base;
        if (number < base)
        {
            custom_sprintf("KB", number, precision);
        }
        else
        {
            number = number/base;
            if (number < base)
            {
                custom_sprintf("MB", number, precision);
            }
            else
            {
                number = number/base;
                if (number < base)
                {
                    custom_sprintf("GB", number, precision);
                }
                else
                {
                    number = number/base;
                    if (number < base)
                    {
                        custom_sprintf("TB", number, precision);
                    }
                    else
                    {
                        number = number/base;
                        if (number < base)
                        {
                            custom_sprintf("PB", number, precision);
                        }
                        else
                        {
                            number = number/base;
                            custom_sprintf("EB", number, precision);
                        }
                    }
                }
            }
        }
    }
    
    return &string[0];
}

NSString *runCommandUsingNSTask(NSString *arguments)
{
	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/sh"];
	[task setArguments:[NSArray arrayWithObjects:@"-c", arguments, nil]];
	[task setStandardInput:[NSPipe pipe]];
	[task setStandardOutput:pipe];
	[task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
	[task launch];
	
	NSString *results = [[[NSString alloc] initWithData:[file readDataToEndOfFile] encoding: NSUTF8StringEncoding] autorelease];
	
	[task waitUntilExit];
	[task release];
	
	return results;
}

NSString *runCommandUsingPopen(NSString *arguments)
{
    static char *buffer = NULL;
    int bufferSize = 0;
    
    fflush(NULL);
    FILE *file = popen([arguments UTF8String], "r");
    if (file != NULL)
    {
        char chunk[1024];
        int chunkIndex = 0;
        int chunkSize = sizeof(chunk);
        while (fgets(chunk, chunkSize, file) != NULL)
        {
            int chunkLength = strlen(chunk);
            buffer = (char*)realloc(buffer, bufferSize+chunkLength);
            memcpy((char*)(buffer+bufferSize), chunk, chunkLength);
            bufferSize += chunkLength;
            
            chunkIndex++;
        }
        
        buffer = (char*)realloc(buffer, bufferSize+1);
        buffer[bufferSize] = '\0';
        
        pclose(file);
    }
	
    if (bufferSize > 0)
    {
        return [NSString stringWithFormat:@"%s", buffer];
    }
    else
    {
        return nil;
    }
}
