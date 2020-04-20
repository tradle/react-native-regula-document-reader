
#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTImageStoreManager.h>
#else
#import "RCTBridgeModule.h"
#import "RCTImageStoreManager.h"
#endif

#import <DocumentReader/DocumentReader.h>

@interface RNRegulaDocumentReader : NSObject <RCTBridgeModule>

@end
