
// http://lists.apple.com/archives/Cocoa-dev/2006/Dec/msg00871.html

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (RoundRect)

+ (NSBezierPath*)bezierPathWithRoundRect:(NSRect)inRect xRadius:(float)inRadiusX yRadius:(float)inRadiusY;

@end
