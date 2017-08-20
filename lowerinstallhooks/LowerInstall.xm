#import <objc/runtime.h>
#import <notify.h>
#import <dlfcn.h>
#import <substrate.h>
#import <sys/utsname.h>

extern const char *__progname;

#define NSLog(...)

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.lowerinstall.plist"


static BOOL Enabled;
static __strong NSString* kCurrentiOSVersion = nil;
static __strong NSString* kCurrentDeviceType = nil;
const char * kCurrentiOSVersionSpoof;
const char * kCurrentDeviceTypeSpoof;
static __strong NSString* kUserAgent = @"User-Agent";
static __strong NSString* kFormatHeader = @"/%@ ";

%group itunesstoredHooks
%hook NSMutableURLRequest
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
	if(Enabled && field && value && kUserAgent && [field isEqualToString:kUserAgent] && kCurrentiOSVersion && kCurrentiOSVersionSpoof) {
		if([value rangeOfString:kCurrentiOSVersion].location != NSNotFound) {
			value = [value stringByReplacingOccurrencesOfString:[NSString stringWithFormat:kFormatHeader, kCurrentiOSVersion] withString:[NSString stringWithFormat:kFormatHeader, [NSString stringWithUTF8String:kCurrentiOSVersionSpoof]]];
			value = [value stringByReplacingOccurrencesOfString:[NSString stringWithFormat:kFormatHeader, kCurrentDeviceType] withString:[NSString stringWithFormat:kFormatHeader, [NSString stringWithUTF8String:kCurrentDeviceTypeSpoof]]];
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
- (NSArray *)supportedDevices
{
	NSArray* ret = %orig?:@[];
	if(kCurrentDeviceType && ![ret containsObject:kCurrentDeviceType]) {
		NSMutableArray* retMut = [ret mutableCopy];
		[retMut addObject:[kCurrentDeviceType copy]];
		ret = [retMut copy];
	}
	return ret;
}
%end
%end

static void settingsChangedLowerInstall()
{	
	@autoreleasepool {
		NSDictionary *LowerInstallPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] copy];
		Enabled = (BOOL)[[LowerInstallPrefs objectForKey:@"Enabled"]?:@YES boolValue];
		NSString* CurrentiOSVersionSpoof = [LowerInstallPrefs objectForKey:@"SpoofVersion"]?:@"10.3";
		kCurrentiOSVersionSpoof = (const char*)(malloc([CurrentiOSVersionSpoof length]));
		memcpy((void*)kCurrentiOSVersionSpoof,(const void*)CurrentiOSVersionSpoof.UTF8String, [CurrentiOSVersionSpoof length]);
		((char*)kCurrentiOSVersionSpoof)[[CurrentiOSVersionSpoof length]] = '\0';
		NSString* CurrentDeviceTypeSpoof = [LowerInstallPrefs objectForKey:@"SpoofDevice"]?:@"iPhone6,1";
		kCurrentDeviceTypeSpoof = (const char*)(malloc([CurrentDeviceTypeSpoof length]));
		memcpy((void*)kCurrentDeviceTypeSpoof,(const void*)CurrentDeviceTypeSpoof.UTF8String, [CurrentDeviceTypeSpoof length]);
		((char*)kCurrentDeviceTypeSpoof)[[CurrentDeviceTypeSpoof length]] = '\0';
	}
}

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)settingsChangedLowerInstall, CFSTR("com.julioverne.lowerinstall/SettingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	settingsChangedLowerInstall();
	struct utsname systemInfo;
	uname(&systemInfo);
	kCurrentDeviceType = [NSString stringWithFormat:@"%s", systemInfo.machine];
	kCurrentiOSVersion = [NSString stringWithFormat:@"%@", [[UIDevice currentDevice] systemVersion]];
	if(strcmp(__progname, "itunesstored") == 0) {
		%init(itunesstoredHooks);
	} else {
		%init(installdHooks);
	}
}