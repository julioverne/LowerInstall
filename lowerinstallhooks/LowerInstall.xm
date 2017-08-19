#import <objc/runtime.h>
#import <notify.h>
#import <dlfcn.h>
#import <substrate.h>

extern const char *__progname;
extern "C" CFPropertyListRef MGCopyAnswer(CFStringRef property);

#define NSLog(...)

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.lowerinstall.plist"


static BOOL Enabled;
static __strong NSString* kCurrentiOSVersion = nil;
static __strong NSString* kCurrentiOSVersionSpoof = nil;
static __strong NSString* kUserAgent = @"User-Agent";



%group itunesstoredHooks
%hook NSMutableURLRequest
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
	if(Enabled && field && value && [field isEqualToString:kUserAgent]) {
		if([value rangeOfString:kCurrentiOSVersion].location != NSNotFound) {
			value = [value stringByReplacingOccurrencesOfString:kCurrentiOSVersion withString:kCurrentiOSVersionSpoof];
		}
	}
	%orig(value, field);
}
%end
%end

%group installdHooks
%hook MIBundle
- (NSString*)minimumOSVersion
{
	NSString* ret = %orig;
	ret = @"2.0";
	return ret;
}
%end
%end

static void settingsChangedLowerInstall()
{	
	@autoreleasepool {
		NSDictionary *EdgeAlertPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] copy];
		Enabled = (BOOL)[[EdgeAlertPrefs objectForKey:@"Enabled"]?:@YES boolValue];
		kCurrentiOSVersionSpoof = [NSString stringWithFormat:@"/%@ ", [EdgeAlertPrefs objectForKey:@"SpoofVersion"]?:@"10.3"];
	}
}

%ctor
{
	if(strcmp(__progname, "itunesstored") == 0) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)settingsChangedLowerInstall, CFSTR("com.julioverne.lowerinstall/SettingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		settingsChangedLowerInstall();
		kCurrentiOSVersion = [NSString stringWithFormat:@"/%@ ", (NSString *)MGCopyAnswer(CFSTR("ProductVersion"))];
		%init(itunesstoredHooks);
	} else {
		%init(installdHooks);
	}
}