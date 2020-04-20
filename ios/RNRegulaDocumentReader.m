@import UIKit;
#import "RNRegulaDocumentReader.h"
@import DocumentReader;

@implementation RNRegulaDocumentReader

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSDictionary*) options callback:(RCTResponseSenderBlock)callback)
{
    NSString *dbResource = options[@"dbResource"];
    NSString *licenseResource = options[@"licenseResource"];
    NSString *licenseKey = options[@"licenseKey"];
    NSData *licenseData;
    if (licenseKey == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:licenseResource ofType:nil];
        licenseData = [NSData dataWithContentsOfFile:path];
    } else {
        licenseData = [[NSData alloc] initWithBase64EncodedString:licenseKey options:0];
    }
    
    if (dbResource == nil) {
        [RGLDocReader.shared initializeReader:licenseData completion:^(BOOL successful, NSString * _Nullable error ) {
            if (successful) {
                callback(@[[NSNull null], [NSNull null]]);
            } else {
                callback(@[error, [NSNull null]]);
            }
        }];
        
        return;
    }

    NSString *path = [[NSBundle mainBundle] pathForResource:dbResource ofType:nil];
    [RGLDocReader.shared initializeReader:licenseData databasePath:path completion:^(BOOL successful, NSString * _Nullable error ) {
        if (successful) {
            callback(@[[NSNull null], [NSNull null]]);
        } else {
            callback(@[error, [NSNull null]]);
        }
    }];
}

RCT_EXPORT_METHOD(prepareDatabase:(NSDictionary*) options callback:(RCTResponseSenderBlock)callback)
{
    NSString *dbID = options[@"dbID"];
   [RGLDocReader.shared prepareDatabase:dbID completion:^(BOOL successful, NSString * _Nullable error) {
        if (successful) {
            callback(@[[NSNull null], [NSNull null]]);
        } else {
            callback(@[error, [NSNull null]]);
        }
    }];
}

//RCT_EXPORT_METHOD(initialize:(RCTResponseSenderBlock)callback)
//{
//    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"regula.license" ofType:nil];
//    NSData *licenseData = [NSData dataWithContentsOfFile:dataPath];
//
//    ProcessParams *params = [[ProcessParams alloc] init];
//    self.docReader = [[DocReader alloc] initWithProcessParams:params];
//
//    [self.docReader initilizeReaderWithLicense:licenseData completion:^(BOOL successful, NSString * _Nullable error ) {
//        if (successful) {
//            callback(@[[NSNull null], [NSNull null]]);
//        } else {
//            callback(@[error, [NSNull null]]);
//        }
//    }];
//}

RCT_EXPORT_METHOD(scan:(NSDictionary*)opts callback:(RCTResponseSenderBlock)cb)
{
    __block RCTResponseSenderBlock callback = cb;
    // prevent multiple invocations of cb
    void __block (^callbackWith)(id results) = ^(id results)
    {
      if (callback == nil) return;

      callback(results);
      callback = nil;
      // [self.docReader stopScanner];
    };

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *currentViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        [RGLDocReader.shared.processParams setValuesForKeysWithDictionary:opts[@"processParams"]];
        [RGLDocReader.shared.customization setValuesForKeysWithDictionary:opts[@"customization"]];
        [RGLDocReader.shared.functionality setValuesForKeysWithDictionary:opts[@"functionality"]];

        [RGLDocReader.shared showScanner:currentViewController completion:^(enum RGLDocReaderAction action, RGLDocumentReaderResults * _Nullable result, NSString * _Nullable error) {
            NSLog(@"DocumentReaderAction %ld", (long)action);
            switch (action) {
                case RGLDocReaderActionCancel: {
                    callbackWith(@[@"Cancelled by user", [NSNull null]]);
                    break;
                }

                case RGLDocReaderActionComplete: {
                    if (result != nil) {
                        __block NSMutableDictionary *totalResults = [NSMutableDictionary new];
                        __block int togo = 0;
                        void __block (^setField)(id field, id value) = ^(id field, id value)
                        {

                            totalResults[field] = value;
                            togo--;
                            if (togo == 0) {
                                callbackWith(@[[NSNull null], totalResults]);
                            }
                        };

                        NSMutableArray *jsonResults = [NSMutableArray array];
                        for (RGLDocumentReaderJsonResultGroup *resultObject in result.jsonResult.results) {
                            [jsonResults addObject:resultObject.jsonResult];
                        }

                        [totalResults setObject:jsonResults forKey:@"jsonResult"];
                        UIImage *front = [result getGraphicFieldImageByType:RGLGraphicFieldTypeGf_DocumentImage source:RGLResultTypeRawImage];

                        UIImage *back = [result getGraphicFieldImageByType:RGLGraphicFieldTypeGf_DocumentImage source:RGLResultTypeRawImage];

                        if (opts[@"returnBase64Images"]) {
                            NSData *frontImageData = UIImageJPEGRepresentation(front, 1.0);
                            NSData *backImageData = UIImageJPEGRepresentation(back, 1.0);
                            setField(@"imageFront", [frontImageData base64EncodedStringWithOptions:0]);
                            setField(@"imageBack", [backImageData base64EncodedStringWithOptions:0]);
                            callbackWith(@[[NSNull null], totalResults]);
                            return;
                        }
                        
                        NSData *frontData;
                        NSData *backData;
                        if (front != nil) {
                            togo++;
                            frontData = UIImagePNGRepresentation(front);
                            [self->_bridge.imageStoreManager storeImageData:frontData withBlock:^(NSString *imageTag) {
                                setField(@"imageFront", imageTag);
                            }];
                        }

                        if (back != nil) {
                            togo++;
                            backData = UIImagePNGRepresentation(back);
                            [self->_bridge.imageStoreManager storeImageData:backData withBlock:^(NSString *imageTag) {
                                setField(@"imageBack", imageTag);
                            }];
                        }
                    }
                    break;
                }

                case RGLDocReaderActionError: {
                    callbackWith(@[error, [NSNull null]]);
                    break;
                }

                case RGLDocReaderActionProcess: {
                    break;
                }

                case RGLDocReaderActionMorePagesAvailable: {
                    break;
                }

                default: {
                    callbackWith(@[@"unknown scanning status"]);
                    break;
                }
            }
        }];
    });
}

@end
