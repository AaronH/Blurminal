#import "Blurminal.h"
#import "JRSwizzle.h"

typedef void* CGSConnectionID;
extern OSStatus CGSNewConnection (const void** attr, CGSConnectionID* id);

uint32_t _myFilter;
CGSConnectionID _myConnection;

@implementation NSWindow (TTWindow)
// Found here:
// http://www.aeroxp.org/board/index.php?s=d18e98cabed9ce5ad27f9449b4e2298f&showtopic=8984&pid=116022&st=0&#entry116022
- (void)enableBlur
{	
	if (!_myConnection) CGSNewConnection(NULL , &_myConnection);

	if (!_myFilter){
		CGSNewCIFilterByName (_myConnection, (CFStringRef)@"CIGaussianBlur", &_myFilter);
		
		NSDictionary* optionsDict = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"Blurminal Radius"] forKey:@"inputRadius"];
		CGSSetCIFilterValuesFromDictionary(_myConnection, _myFilter, (CFDictionaryRef)optionsDict);		
	}
	
	CGSAddWindowFilter(_myConnection, [self windowNumber], _myFilter, 1);
	
}

- (void)disableBlur
{
	if (_myFilter && _myConnection) {
		CGSRemoveWindowFilter(_myConnection, [self windowNumber], _myFilter);
		CGSReleaseCIFilter(_myConnection, _myFilter);
	}
}

- (void)enableBlurIfCorrectWindow:(BOOL)delay
{
	if([self isKindOfClass:NSClassFromString(@"TTWindow")] || [self isKindOfClass:NSClassFromString(@"VisorWindow")])
	{
		
		if (delay == TRUE) {
			[self performSelector:@selector(enableBlur) withObject:nil afterDelay:0]; // FIXME
		} else {
			[self enableBlur];
		}
	}
}

- (id)Blurred_initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if(self = [self Blurred_initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation])
	{
		// The window has to be onscreen to get a windowNumber, so we run the enableBlur after the event loop
		[self enableBlurIfCorrectWindow:TRUE];
	}
	return self;
}

- (void)Blurred_miniaturize:(id)sender;
{
	[self Blurred_miniaturize:sender];
	[self disableBlur];
}
- (void)Blurred_deminiaturize:(id)sender;
{
	[self Blurred_deminiaturize:sender];
	[self enableBlur];
}
@end


@implementation Blurminal
+ (void)load
{
	for (id window in [NSApp orderedWindows]) {
		[window enableBlurIfCorrectWindow:FALSE];
	}
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:1.0],@"Blurminal Radius",
		nil]];
	[[NSWindow class] jr_swizzleMethod:@selector(initWithContentRect:styleMask:backing:defer:) withMethod:@selector(Blurred_initWithContentRect:styleMask:backing:defer:) error:NULL];
//	[[NSWindow class] jr_swizzleMethod:@selector(miniaturize:) withMethod:@selector(Blurred_miniaturize:) error:NULL];
//	[[NSWindow class] jr_swizzleMethod:@selector(deminiaturize:) withMethod:@selector(Blurred_deminiaturize:) error:NULL];
							
}
@end
