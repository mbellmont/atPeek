
// http://lists.apple.com/archives/Cocoa-dev/2006/Dec/msg00871.html

#import "RoundRect.h"
	
@implementation NSBezierPath (RoundRect)

+ (NSBezierPath*)bezierPathWithRoundRect:(NSRect)inRect
								 xRadius:(float)inRadiusX
								 yRadius:(float)inRadiusY
{
	const float kEllipseFactor = 0.55228474983079;
	
	float theMaxRadiusX = NSWidth(inRect) / 2.0;
	float theMaxRadiusY = NSHeight(inRect) / 2.0;
	float theRadiusX = (inRadiusX < theMaxRadiusX) ? inRadiusX :
	theMaxRadiusX;
	float theRadiusY = (inRadiusY < theMaxRadiusY) ? inRadiusY :
	theMaxRadiusY;
	float theControlX = theRadiusX * kEllipseFactor;
	float theControlY = theRadiusY * kEllipseFactor;
	NSRect theEdges = NSInsetRect(inRect, theRadiusX, theRadiusY);
	NSBezierPath* theResult = [NSBezierPath bezierPath];
	
	//	Lower edge and lower-right corner
	[theResult moveToPoint:NSMakePoint(theEdges.origin.x,
									   inRect.origin.y)];
	[theResult lineToPoint:NSMakePoint(NSMaxX(theEdges),
									   inRect.origin.y)];
	[theResult curveToPoint:NSMakePoint(NSMaxX(inRect),
										theEdges.origin.y)
			  controlPoint1:NSMakePoint(NSMaxX(theEdges) +
										theControlX, inRect.origin.y)
			  controlPoint2:NSMakePoint(NSMaxX(inRect),
										theEdges.origin.y - theControlY)];
	
	//	Right edge and upper-right corner
	[theResult lineToPoint:NSMakePoint(NSMaxX(inRect), NSMaxY
									   (theEdges))];
	[theResult curveToPoint:NSMakePoint(NSMaxX(theEdges), NSMaxY
										(inRect))
			  controlPoint1:NSMakePoint(NSMaxX(inRect), NSMaxY
										(theEdges) + theControlY)
			  controlPoint2:NSMakePoint(NSMaxX(theEdges) +
										theControlX, NSMaxY(inRect))];
	
	//	Top edge and upper-left corner
	[theResult lineToPoint:NSMakePoint(theEdges.origin.x, NSMaxY
									   (inRect))];
	[theResult curveToPoint:NSMakePoint(inRect.origin.x, NSMaxY
										(theEdges))
			  controlPoint1:NSMakePoint(theEdges.origin.x -
										theControlX, NSMaxY(inRect))
			  controlPoint2:NSMakePoint(inRect.origin.x, NSMaxY
										(theEdges) + theControlY)];
	
	//	Left edge and lower-left corner
	[theResult lineToPoint:NSMakePoint(inRect.origin.x,
									   theEdges.origin.y)];
	[theResult curveToPoint:NSMakePoint(theEdges.origin.x,
										inRect.origin.y)
			  controlPoint1:NSMakePoint(inRect.origin.x,
										theEdges.origin.y - theControlY)
			  controlPoint2:NSMakePoint(theEdges.origin.x -
										theControlX, inRect.origin.y)];
	
	
	//	Finish up and return
	[theResult closePath];
	return theResult;
}

@end