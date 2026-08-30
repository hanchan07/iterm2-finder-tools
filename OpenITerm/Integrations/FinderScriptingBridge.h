/*
 * Generated from Finder's scripting definition with:
 * sdef /System/Library/CoreServices/Finder.app | sdp -fh --basename FinderScriptingBridge
 *
 * This checked-in subset retains only declarations used to read the front Finder window target.
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>

@class FinderScriptingBridgeFinderWindow;
@class FinderScriptingBridgeItem;

@interface FinderScriptingBridgeApplication : SBApplication
@property(copy, readonly, nullable) SBElementArray<FinderScriptingBridgeFinderWindow *> *FinderWindows;
@end

@interface FinderScriptingBridgeFinderWindow : SBObject
@property(copy, nullable) FinderScriptingBridgeItem *target;
@end

@interface FinderScriptingBridgeItem : SBObject
@property(copy, readonly, nullable) NSString *URL;
@end

FOUNDATION_EXPORT NSURL * _Nullable OpenITermCopyFrontFinderWindowURL(NSError * _Nullable * _Nullable error);
