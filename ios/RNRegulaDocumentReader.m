@import UIKit;
#import "RNRegulaDocumentReader.h"

@implementation RNRegulaDocumentReader

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(RCTResponseSenderBlock)callback)
{
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"regula.license" ofType:nil];
    NSData *licenseData = [NSData dataWithContentsOfFile:dataPath];

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

RCT_EXPORT_METHOD(scan:(NSDictionary*)opts callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *currentViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];

        [self.docReader.processParams setValuesForKeysWithDictionary:opts[@"processParams"]];
        [self.docReader.customization setValuesForKeysWithDictionary:opts[@"customization"]];
        [self.docReader.functionality setValuesForKeysWithDictionary:opts[@"functionality"]];

        [self.docReader showScanner:currentViewController completion:^(enum DocReaderAction action, DocumentReaderResults * _Nullable result, NSString * _Nullable error) {
            switch (action) {
                case DocReaderActionCancel: {
                    callback(@[@"Cancelled by user", [NSNull null]]);
                }
                    break;

                case DocReaderActionComplete: {
                    if (result != nil) {
                        __block NSMutableDictionary *totalResults = [NSMutableDictionary new];
                        __block int togo = 0;
                        void __block (^setField)(id field, id value) = ^(id field, id value)
                        {

                            totalResults[field] = value;
                            togo--;
                            if (togo == 0) {
                                callback(@[[NSNull null], totalResults]);
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
                }
                    break;

                case DocReaderActionError: {
                  callback(@[error, [NSNull null]]);
                }
                    break;

                default:
                    break;
            }
        }];
    });
}

@end
