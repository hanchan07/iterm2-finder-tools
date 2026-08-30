#import "FinderScriptingBridge.h"
#import <CoreServices/CoreServices.h>

NSURL *OpenITermCopyFrontFinderWindowURL(NSError **error) {
    NSAppleEventDescriptor *targetDescriptor =
        [NSAppleEventDescriptor descriptorWithBundleIdentifier:@"com.apple.finder"];
    OSStatus permissionStatus = AEDeterminePermissionToAutomateTarget(
        targetDescriptor.aeDesc,
        typeWildCard,
        typeWildCard,
        true
    );
    if (permissionStatus != noErr) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:permissionStatus userInfo:nil];
        }
        return nil;
    }

    // The cast is intentional: ScriptingBridge returns a runtime proxy that forwards the
    // generated Finder selectors. It must not be initialized as a concrete subclass.
    FinderScriptingBridgeApplication *finder =
        (FinderScriptingBridgeApplication *)[SBApplication applicationWithBundleIdentifier:@"com.apple.finder"];
    SBElementArray *windows = [finder FinderWindows];
    if (windows == nil || windows.count == 0) {
        if (error != NULL) {
            *error = finder.lastError;
        }
        return nil;
    }

    FinderScriptingBridgeFinderWindow *frontWindow = [windows objectAtIndex:0];
    FinderScriptingBridgeItem *target = frontWindow.target;
    NSString *rawURL = target.URL;
    NSURL *url = rawURL == nil ? nil : [NSURL URLWithString:rawURL];
    if (url == nil && error != NULL) {
        *error = finder.lastError;
    }
    return url;
}
