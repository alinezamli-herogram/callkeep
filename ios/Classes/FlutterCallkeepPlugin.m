//
//  FlutterCallkeepPlugin.m
//

#import "FlutterCallkeepPlugin.h"
#import "CallKeep.h"

@implementation FlutterCallkeepPlugin
{
    CallKeep *_callKeep;
}

// Singleton reference
static id _instance;

// Expose a sharedInstance for other parts of Objective-C to call if needed
+ (FlutterCallkeepPlugin *)sharedInstance {
    return _instance;
}

/**
 * Called automatically when Flutter registers the plugin.
 * Sets up a method channel "FlutterCallKeep.Method"
 * and delegates method calls to this plugin instance.
 */
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (_instance == nil) {
        // Create the method channel for calls from Dart to iOS
        FlutterMethodChannel* channel = [FlutterMethodChannel
                                         methodChannelWithName:@"FlutterCallKeep.Method"
                                         binaryMessenger:[registrar messenger]];
        
        // Create a plugin instance
        UIViewController *viewController = (UIViewController *)registrar.messenger;
        _instance = [[FlutterCallkeepPlugin alloc] initWithChannel:channel
                                                         registrar:registrar
                                                         messenger:[registrar messenger]
                                                    viewController:viewController
                                                      withTextures:[registrar textures]];
        
        // Register this instance to handle the method calls
        [registrar addMethodCallDelegate:_instance channel:channel];
    }
}

/**
 * Custom initializer sets up a CallKeep instance and its event channel.
 */
- (instancetype)initWithChannel:(FlutterMethodChannel *)channel
                      registrar:(NSObject<FlutterPluginRegistrar>*)registrar
                      messenger:(NSObject<FlutterBinaryMessenger>*)messenger
                 viewController:(UIViewController *)viewController
                   withTextures:(NSObject<FlutterTextureRegistry> *)textures {
#ifdef DEBUG
    NSLog(@"[FlutterCallkeepPlugin][init]");
#endif
    self = [super init];
    if (self) {
        // Initialize CallKeep singleton
        _callKeep = [CallKeep allocWithZone:nil];
        
        // Create an event channel for iOS => Flutter events
        _callKeep.eventChannel = [FlutterMethodChannel
                                  methodChannelWithName:@"FlutterCallKeep.Event"
                                  binaryMessenger:[registrar messenger]];
    }
    return self;
}

/**
 * Clean up when plugin is deallocated
 */
- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"[FlutterCallkeepPlugin][dealloc]");
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _callKeep = nil;
}

/**
 * This is where we intercept calls from Dart via the "FlutterCallKeep.Method" channel.
 * If the call is recognized, we handle it here; otherwise we forward it to CallKeep.
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    NSDictionary *argsMap = call.arguments;

    // Check if we want to handle a specific method ourselves
    if ([method isEqualToString:@"setAudioRouteToSpeaker"]) {
        BOOL toSpeaker = [argsMap[@"toSpeaker"] boolValue];
        [self setAudioRouteToSpeaker:toSpeaker];
        result(nil);
    } else {
        // If not recognized here, let CallKeep handle it
        if (![_callKeep handleMethodCall:call result:result]) {
            result(FlutterMethodNotImplemented);
        }
    }
}

/**
 * Toggle speaker or earpiece on iOS by calling the method in CallKeep.m
 */
- (void)setAudioRouteToSpeaker:(BOOL)toSpeaker {
    [_callKeep setAudioRouteToSpeaker:toSpeaker];
}

/**
 * Handle iOS 9+ openURL scenario if you need it.
 * Currently returns NO as you indicated in your snippet.
 */
+ (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    return NO;
}

/**
 * Handle iOS user activities for incoming calls, SiriKit, etc.
 * Passes to CallKeep’s application:continueUserActivity:restorationHandler:
 */
- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler {
    return [CallKeep application:application
          continueUserActivity:userActivity
          restorationHandler:restorationHandler];
}

@end
