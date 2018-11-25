package com.regula.documentreader;

import android.graphics.Bitmap;
import android.net.Uri;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.regula.documentreader.api.DocumentReader;
import com.regula.documentreader.api.enums.DocReaderAction;
import com.regula.documentreader.api.enums.eGraphicFieldType;
import com.regula.documentreader.api.results.DocumentReaderJsonResultGroup;
import com.regula.documentreader.api.results.DocumentReaderResults;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import io.tradle.reactimagestore.ImageStoreModule;

public class RNRegulaDocumentReaderModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  //constructor
  public RNRegulaDocumentReaderModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  //Mandatory function getName that specifies the module name
  @Override
  public String getName() {
    return "RNRegulaDocumentReader";
  }

  @ReactMethod
  public void initialize(final Callback cb) {
    try {
      byte[] license = readLicense();
      DocumentReader.Instance().initializeReader(reactContext.getApplicationContext(), license, new DocumentReader.DocumentReaderInitCompletion() {
        @Override
        public void onInitCompleted(boolean b, String s) {
          if (b) {
            cb.invoke(null, null);
          } else {
            cb.invoke(s == null ? "initilization failed" : s);
          }
        }
      });
    } catch (IOException e) {
      e.printStackTrace();
      cb.invoke(e.toString(), null);
    }
  }

  @ReactMethod
  public void scan(ReadableMap opts, final Callback cb) {
    final DocumentReader reader = DocumentReader.Instance();
    RegulaConfig.setCustomization(reader.customization, opts.getMap("customization"));
    RegulaConfig.setFunctionality(reader.functionality, opts.getMap("functionality"));
    RegulaConfig.setProcessParams(reader.processParams, opts.getMap("processParams"));
    DocumentReader.Instance().showScanner(new DocumentReader.DocumentReaderCompletion() {
      @Override
      public void onCompleted(int action, DocumentReaderResults documentReaderResults, String s) {
        switch (action) {
          case DocReaderAction.COMPLETE:
            if (documentReaderResults != null && documentReaderResults.jsonResult != null) {
              JSONObject resultObj = new JSONObject();
              JSONArray jsonArray = new JSONArray();
              int index = 0;
              try {
                for (DocumentReaderJsonResultGroup group : documentReaderResults.jsonResult.results) {
                  jsonArray.put(index, new JSONObject(group.jsonResult));
                  index++;
                }

                resultObj.put("jsonResult", jsonArray);
                Bitmap bitmap = documentReaderResults.getGraphicFieldImageByType(eGraphicFieldType.GT_DOCUMENT_FRONT);
                if (bitmap != null) {
                  ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                  bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
//                  bitmap.compress(Bitmap.CompressFormat.JPEG, 80, byteArrayOutputStream);
                  byte[] imageBytes = byteArrayOutputStream.toByteArray();
                  Uri fileUri = ImageStoreModule.storeImageBytes(reactContext, imageBytes);
                  resultObj.put("image", fileUri.toString());

                  String resultString = resultObj.toString();

                  cb.invoke(null, resultString);
                }
              } catch (Exception ex) {
                cb.invoke(resultObj.toString(), null);
              }


            }
            break;
          case DocReaderAction.CANCEL:
            cb.invoke("Cancelled by user", null);
            break;
          case DocReaderAction.ERROR:
            cb.invoke(s, null);
            break;
          default:
            return;
        }

        reader.stopScanner();;
      }

    });
  }

//  @ReactMethod
//  public void setScenario(String identifier) {
//    DocumentReader.Instance().processParams.scenario = identifier;
//  }

  private byte[] readLicense() throws IOException {
    InputStream licInput = null;
    int resId = reactContext
            .getResources()
            .getIdentifier("regula", "raw", reactContext.getPackageName());

    if (resId != 0) {
      licInput = reactContext.getResources().openRawResource(resId);
    }

    if (licInput == null) {
      throw new RuntimeException("missing license!");
    }

    int available = licInput.available();
    byte[] license = new byte[available];
    licInput.read(license);

    return license;
  }
}