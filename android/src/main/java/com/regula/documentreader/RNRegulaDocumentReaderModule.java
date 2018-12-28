package com.regula.documentreader;

import android.graphics.Bitmap;
import android.net.Uri;
import android.util.Base64;

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
  public void prepareDatabase(ReadableMap opts, final Callback cb) {
    String dbID = opts.getString("dbID");
    if (dbID == null)
      dbID = "Full";
    try {
      DocumentReader.Instance().prepareDatabase(reactContext.getApplicationContext(), dbID, new
        DocumentReader.DocumentReaderPrepareCompletion() {
          @Override
          public void onPrepareProgressChanged(int progress) {
            // System.out.println("prepareDatabase: ");
          //get progress update
          }

          @Override
          public void onPrepareCompleted(boolean status, String error) {
            System.out.println("prepareDatabase: completed status = " + status + "; error = " + error);
            if (status) {
              // initialize(opts, cb);
              cb.invoke(null, null);
            } else {
              cb.invoke(error == null ? "preparation failed" : error);
            }
            //database downloaded
          }
      });
    } catch (Exception e) {
      e.printStackTrace();
      cb.invoke(e.toString(), null);
    }
  }

  @ReactMethod
  public void initialize(ReadableMap opts, final Callback cb) {
    try {
      byte[] license = Base64.decode(opts.getString("licenseKey"), Base64.NO_WRAP);
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
    } catch (Exception e) {
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
            JSONObject resultObj = new JSONObject();
            if (documentReaderResults != null) {
              try {
                // TODO: do these in parallel, async
                Uri front = maybeGetImage(documentReaderResults.getGraphicFieldImageByType(eGraphicFieldType.GT_DOCUMENT_FRONT));
                Uri back = maybeGetImage(documentReaderResults.getGraphicFieldImageByType(eGraphicFieldType.GT_DOCUMENT_REAR));

                if (front != null) {
                  resultObj.put("imageFront", front.toString());
                }

                if (back != null) {
                  resultObj.put("imageBack", back.toString());
                }
              } catch (Exception ex) {
                cb.invoke(resultObj.toString(), null);
                return;
              }

              if (documentReaderResults.jsonResult != null) {
                JSONArray jsonArray = new JSONArray();
                int index = 0;
                try {
                  for (DocumentReaderJsonResultGroup group : documentReaderResults.jsonResult.results) {
                    jsonArray.put(index, new JSONObject(group.jsonResult));
                    index++;
                  }

                  resultObj.put("jsonResult", jsonArray);
                } catch (Exception ex) {
                  cb.invoke(resultObj.toString(), null);
                  return;
                }
              }
            }

            String resultString = resultObj.toString();
            cb.invoke(null, resultString);

            break;
          case DocReaderAction.CANCEL:
            cb.invoke("Cancelled by user", null);
            break;
          case DocReaderAction.ERROR:
            cb.invoke(s, null);
            break;
          default:
            break;
        }
      }

    });
  }

//  @ReactMethod
//  public void setScenario(String identifier) {
//    DocumentReader.Instance().processParams.scenario = identifier;
//  }

  private Uri maybeGetImage(Bitmap bitmap) throws IOException {
    if (bitmap == null) return null;

    return ImageStoreModule.storeImageBitmap(reactContext, bitmap, "image/png", 100);
  }

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
