package com.regula;

import android.content.Context;
import android.graphics.Bitmap;
import android.util.Base64;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.regula.documentreader.api.DocumentReader;
import com.regula.documentreader.api.enums.DocReaderAction;
import com.regula.documentreader.api.enums.eGraphicFieldType;
import com.regula.documentreader.api.results.DocumentReaderJsonResultGroup;
import com.regula.documentreader.api.results.DocumentReaderResults;
import com.regulatest.R;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class RNRegulaDocumentReaderModule extends ReactContextBaseJavaModule {

    //constructor
   public RNRegulaDocumentReaderModule(ReactApplicationContext reactContext) {
       super(reactContext);
   }

   //Mandatory function getName that specifies the module name
   @Override
   public String getName() {
       return "RNRegulaDocumentReader";
   }

   @ReactMethod
   public void initialize(final Callback cb) {
       try {
           byte[] license = readLicense(getReactApplicationContext().getApplicationContext());
           DocumentReader.Instance().initializeReader(getReactApplicationContext().getApplicationContext(), license, new DocumentReader.DocumentReaderInitCompletion() {
               @Override
               public void onInitCompleted(boolean b, String s) {
                   cb.invoke(null, null);
               }
           });
       } catch (IOException e) {
           e.printStackTrace();
           cb.invoke(e.toString(), null);
       }
   }

    @ReactMethod
    public void showScanner(final Callback cb) {
        DocumentReader.Instance().customization.showHintMessages = true;
        DocumentReader.Instance().functionality.videoCaptureMotionControl = true;
        DocumentReader.Instance().showScanner(new DocumentReader.DocumentReaderCompletion() {
            @Override
            public void onCompleted(int action, DocumentReaderResults documentReaderResults, String s) {
                switch (action){
                    case DocReaderAction.COMPLETE:
                        if(documentReaderResults!=null && documentReaderResults.jsonResult!=null) {
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
                                if(bitmap!=null) {
                                    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                                    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, byteArrayOutputStream);
                                    byte[] byteArray = byteArrayOutputStream.toByteArray();
                                    String encoded = Base64.encodeToString(byteArray, Base64.DEFAULT);
                                    resultObj.put("image", encoded);

                                    String resultString = resultObj.toString();

                                    cb.invoke(null, resultString);
                                }
                            } catch (Exception ex){
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
                }
            }
        });
    }

    @ReactMethod
    public void setScenario(String identifier) {
        DocumentReader.Instance().processParams.scenario = identifier;
    }

   private byte[] readLicense(Context context) throws IOException {
       InputStream licInput = context.getResources().openRawResource(R.raw.regula);
       int available = licInput.available();
       byte[] license = new byte[available];
       licInput.read(license);

       return license;
   }
}
