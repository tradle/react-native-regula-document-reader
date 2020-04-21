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

                        NSDictionary* whatToReturn = opts[@"return"] ?: [[NSDictionary alloc] init];
                        if (whatToReturn[@"barcodeResult"]) {
                            NSMutableArray *results = [NSMutableArray array];
                            for (RGLDocumentReaderBarcodeField *field in result.barcodeResult.fields) {
                                NSDictionary* fieldInfo = [[NSMutableDictionary alloc] init];
                                RGLBarcodeType type = [field barcodeType];
                                NSString* typeString = [RNRegulaDocumentReader barcodeTypeToString:type];
                                [fieldInfo setValue:typeString forKey:@"type"];
                                NSString *base64 = [[field data] base64EncodedStringWithOptions:0];
                                [fieldInfo setValue:base64 forKey:@"data"];
                                [results addObject:fieldInfo];
                            }

                            [totalResults setObject:results forKey:@"barcodeResult"];
                        }

                        if (whatToReturn[@"jsonResult"]) {
                            NSMutableArray *results = [NSMutableArray array];
                            for (RGLDocumentReaderJsonResultGroup *resultObject in result.jsonResult.results) {
                                [results addObject:resultObject.jsonResult];
                            }

                            [totalResults setObject:results forKey:@"jsonResult"];
                        }

                        // Get document image from the first page
                        UIImage *front;
                        UIImage *back;
                        NSMutableArray *results = [NSMutableArray array];
                        for (RGLDocumentReaderGraphicField *field in result.graphicResult.fields) {
                            switch ([field fieldType]) {
                                case RGLGraphicFieldTypeGf_DocumentImage:
                                    if ([field pageIndex] == 0) {
                                        front = [field value];
                                    } else if ([field pageIndex] == 1) {
                                        back = [field value];
                                    }

                                    break;
                                default:
                                    break;
                            }
                        }

                        [totalResults setObject:results forKey:@"jsonResult"];

                        // this didn't work for getting the front image for some reason
//                        UIImage *front = [result getGraphicFieldImageByType:RGLGraphicFieldTypeGf_DocumentImage source:RGLResultTypeGraphics pageIndex:0];
//
//                        // Get document image from the second page
//                        UIImage *back = [result getGraphicFieldImageByType:RGLGraphicFieldTypeGf_DocumentImage source:RGLResultTypeRawImage pageIndex:1];

                        if (whatToReturn[@"base64Images"]) {
                            setField(@"imageFront", [RNRegulaDocumentReader uiimageToNSDictionary:front]);
                            setField(@"imageBack", [RNRegulaDocumentReader uiimageToNSDictionary:back]);
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

+ (NSString*)barcodeTypeToString:(RGLBarcodeType)barcodeType {
    switch(barcodeType) {
        case RGLBarcodeTypeCode128:
            return @"Code128";
        case RGLBarcodeTypeCode39:
            return @"Code39";
        case RGLBarcodeTypeEAN8:
            return @"EAN8";
        case RGLBarcodeTypeITF:
            return @"ITF";
        case RGLBarcodeTypePDF417:
            return @"PDF417";
        case RGLBarcodeTypeSTF:
            return @"STF";
        case RGLBarcodeTypeMTF:
            return @"MTF";
        case RGLBarcodeTypeIATA:
            return @"IATA";
        case RGLBarcodeTypeCODABAR:
            return @"CODABAR";
        case RGLBarcodeTypeUPCA:
            return @"UPCA";
        case RGLBarcodeTypeCODE93:
            return @"CODE93";
        case RGLBarcodeTypeUPCE:
            return @"UPCE";
        case RGLBarcodeTypeEAN13:
            return @"EAN13";
        case RGLBarcodeTypeQRCODE:
            return @"QRCODE";
        case RGLBarcodeTypeAZTEC:
            return @"AZTEC";
        case RGLBarcodeTypeDATAMATRIX:
            return @"DATAMATRIX";
        case RGLBarcodeTypeALL_1D:
            return @"ALL_1D";
        default:
            return @"Unknown";
    }
}

+ (NSDictionary*) uiimageToNSDictionary:(UIImage*) image {
    double widthInPoints = image.size.width;
    double widthInPixels = widthInPoints * image.scale;
    double heightInPoints = image.size.height;
    double heightInPixels = heightInPoints * image.scale;
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    NSString* base64 = [imageData base64EncodedStringWithOptions:0];
    return @{
        @"width": [NSNumber numberWithDouble:widthInPixels],
        @"height": [NSNumber numberWithDouble:heightInPixels],
        @"dataUri": [@"data:image/jpeg;base64," stringByAppendingString:base64]
    };
}

@end
