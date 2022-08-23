#include <stdio.h>
#import <mach-o/ldsyms.h>
#import <Network/Network.h>
#include <dlfcn.h>
#include "fishhook.h"

struct os_system_version_s {
    unsigned int major;
    unsigned int minor;
    unsigned int patch;
};

static const char SystemVersion_plist[] = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
"<plist version=\"1.0\">\n"
"<dict>\n"
"	<key>ProductBuildVersion</key>\n"
"	<string>19A346</string>\n"
"	<key>ProductCopyright</key>\n"
"	<string>1983-2021 Apple Inc.</string>\n"
"	<key>ProductName</key>\n"
"	<string>iPhone OS</string>\n"
"	<key>ProductVersion</key>\n"
"	<string>15.0</string>\n"
"</dict>\n"
"</plist>";

// This is in libSystem, so it's OK to refer to it directly here
extern int os_system_version_get_current_version(struct os_system_version_s * _Nonnull);
%group Availability

%hookf(int, os_system_version_get_current_version, struct os_system_version_s * _Nonnull v) {
	v->major = 15;
	v->minor = 0;
	v->patch = 0;
	return 0;
}

%hookf(FILE *, fopen, const char * restrict path, const char * restrict mode) {
	if (path != NULL && strcmp(mode, "r") == 0 && strcmp(path, "/System/Library/CoreServices/SystemVersion.plist") == 0) {
		return fmemopen((void*)SystemVersion_plist, sizeof(SystemVersion_plist), mode);
	}
	return %orig;
}

%end

%group iOS14

%hook UITableView

%new
-(bool)isPrefetchingEnabled {
	return false;
}
%new
-(void)setPrefetchingEnabled:(bool)enabled {
	return;
}

%end

%end

%group iOS14_5

%hook NSMutableURLRequest

%property BOOL assumesHTTP3Capable;

%end

%end

%group iOS13

%hook NSProcessInfo

%new
-(BOOL)isiOSAppOnMac {
	return false;
}

%end
%hook UIBarButtonItem

%property(nonatomic, copy) id menu;

%end

%hook UIButton

%property(nonatomic, assign) BOOL showsMenuAsPrimaryAction;
%property(nonatomic, copy) id menu;

%end

%end

extern void nw_parameters_create_quic_connection();

extern sec_protocol_options_t _Nullable nw_quic_connection_copy_sec_protocol_options(void *conn);

static void nw_quic_add_tls_application_protocol(void *conn, const char *application_protocol) {
	sec_protocol_options_t _Nullable sec_protocol_options = nw_quic_connection_copy_sec_protocol_options(conn);
	sec_protocol_options_add_tls_application_protocol(sec_protocol_options, application_protocol);
}

%ctor {
	
	if (@available(iOS 15, macOS 12, *)) {
		return;
	}
	void *main_start = dlsym(RTLD_MAIN_ONLY, MH_EXECUTE_SYM);
	if (main_start) {
		rebind_symbols_image(main_start, 
			(uint64_t)main_start - 0x100000000, 
			(struct rebinding[2]){
				{"nw_parameters_create_quic", (void *) nw_parameters_create_quic_connection, NULL}, 
				{"nw_quic_add_tls_application_protocol", nw_quic_add_tls_application_protocol, NULL}
			}, 2);
	}
	
	if (@available(iOS 13, *)) {
		if (@available(iOS 14, *)) {
		} else {
			%init(iOS13);
		}
		if (@available(iOS 14.5, *)) {
		} else {
			%init(iOS14_5);
		}
		%init(iOS14);
	}
	%init(Availability);
}
