@import UIKit;
#import "RNRegulaDocumentReader.h"

@implementation RNRegulaDocumentReader

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSDictionary*) options callback:(RCTResponseSenderBlock)callback)
{
    NSString *licenseKey = options[@"licenseKey"];
    NSData *licenseData = [[NSData alloc] initWithBase64EncodedString:licenseKey options:0];
    ProcessParams *params = [[ProcessParams alloc] init];
    self.docReader = [[DocReader alloc] initWithProcessParams:params];

    [self.docReader initilizeReaderWithLicense:licenseData completion:^(BOOL successful, NSString * _Nullable error ) {
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
    ProcessParams *params = [[ProcessParams alloc] init];
    self.docReader = [[DocReader alloc] initWithProcessParams:params];

   [self.docReader prepareDatabaseWithDatabaseID:dbID progressHandler:^(NSProgress * _Nonnull progress) {
            // self.initializationLabel.text = [NSString stringWithFormat:@"%.1f", progress.fractionCompleted * 100];
        } completion:^(BOOL successful, NSString * _Nullable error) {
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

        [self.docReader.processParams setValuesForKeysWithDictionary:opts[@"processParams"]];
        [self.docReader.customization setValuesForKeysWithDictionary:opts[@"customization"]];
        [self.docReader.functionality setValuesForKeysWithDictionary:opts[@"functionality"]];

        [self.docReader showScanner:currentViewController completion:^(enum DocReaderAction action, DocumentReaderResults * _Nullable result, NSString * _Nullable error) {
            NSLog(@"DocumentReaderAction %ld", (long)action);
            switch (action) {
                case DocReaderActionCancel: {
                    callbackWith(@[@"Cancelled by user", [NSNull null]]);
                    break;
                }

                case DocReaderActionComplete: {
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
                        for (DocumentReaderJsonResultGroup *resultObject in result.jsonResult.results) {
                            [jsonResults addObject:resultObject.jsonResult];
                        }

                        [totalResults setObject:jsonResults forKey:@"jsonResult"];
                        UIImage *front = [result getGraphicFieldImageByTypeWithFieldType:GraphicFieldTypeGf_DocumentFront source:ResultTypeRawImage];

                        UIImage *back = [result getGraphicFieldImageByTypeWithFieldType:GraphicFieldTypeGf_DocumentRear source:ResultTypeRawImage];

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

                case DocReaderActionError: {
                    callbackWith(@[error, [NSNull null]]);
                    break;
                }

                case DocReaderActionProcess: {
                    break;
                }

                case DocReaderActionMorePagesAvailable: {
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
