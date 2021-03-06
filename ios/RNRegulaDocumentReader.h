
#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTImageStoreManager.h>
#else
#import "RCTBridgeModule.h"
#import "RCTImageStoreManager.h"
#endif

#import <DocumentReader/DocumentReader-Swift.h>

@interface RNRegulaDocumentReader : NSObject <RCTBridgeModule>

@property (strong, nonatomic) DocReader *docReader;

@end
