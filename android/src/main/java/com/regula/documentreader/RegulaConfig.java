package com.regula.documentreader;

import com.facebook.react.bridge.ReadableMap;
import com.regula.documentreader.api.params.Customization;
import com.regula.documentreader.api.params.Functionality;
import com.regula.documentreader.api.params.ProcessParam;

public class RegulaConfig {
  public static void setFunctionality(Functionality functionality, ReadableMap opts) {
    if (opts.hasKey("pictureOnBoundsReady")) {
      functionality.pictureOnBoundsReady = opts.getBoolean("pictureOnBoundsReady");
    }

    if (opts.hasKey("showTorchButton")) {
      functionality.showTorchButton = opts.getBoolean("showTorchButton");
    }

    if (opts.hasKey("showCloseButton")) {
      functionality.showCloseButton = opts.getBoolean("showCloseButton");
    }

    if (opts.hasKey("showCaptureButton")) {
      functionality.showCaptureButton = opts.getBoolean("showCaptureButton");
    }

    if (opts.hasKey("showChangeFrameButton")) {
      functionality.showChangeFrameButton = opts.getBoolean("showChangeFrameButton");
    }

    if (opts.hasKey("showCaptureButtonAfterDelay")) {
      functionality.showCaptureButtonAfterDelay = opts.getBoolean("showCaptureButtonAfterDelay");
    }

    if (opts.hasKey("isOnlineMode")) {
      functionality.isOnlineMode = opts.getBoolean("isOnlineMode");
    }

    if (opts.hasKey("showSkipNextPageButton")) {
      functionality.showSkipNextPageButton = opts.getBoolean("showSkipNextPageButton");
    }

    if (opts.hasKey("videoCaptureMotionControl")) {
      functionality.videoCaptureMotionControl = opts.getBoolean("videoCaptureMotionControl");
    }
    if (opts.hasKey("orientation")) {
      functionality.orientation = opts.getInt("orientation");
    }
  }

  public static void setCustomization(Customization customization, ReadableMap opts) {
    if (opts.hasKey("showStatusMessages")) {
      customization.showStatusMessages = opts.getBoolean("showStatusMessages");
    }

    if (opts.hasKey("showHelpAnimation")) {
      customization.showHelpAnimation = opts.getBoolean("showHelpAnimation");
    }

    if (opts.hasKey("cameraFrameDefaultColor")) {
      customization.cameraFrameDefaultColor = opts.getString("cameraFrameDefaultColor");
    }

    if (opts.hasKey("cameraFrameActiveColor")) {
      customization.cameraFrameActiveColor = opts.getString("cameraFrameActiveColor");
    }
  }

  public static void setProcessParams(ProcessParam processParams, ReadableMap opts) {
    if (opts.hasKey("scenario")) {
      processParams.scenario = opts.getString("scenario");
    }

    if (opts.hasKey("multipageProcessing")) {
      processParams.multipageProcessing = opts.getBoolean("multipageProcessing");
    }

    if (opts.hasKey("debugSaveImages")) {
      processParams.debugSaveImages = opts.getBoolean("debugSaveImages");
    }

    if (opts.hasKey("debugSaveLogs")) {
      processParams.debugSaveLogs = opts.getBoolean("debugSaveLogs");
    }

    if (opts.hasKey("dateFormat")) {
      processParams.dateFormat = opts.getString("dateFormat");
    }

    if (opts.hasKey("debugSaveCroppedImages")) {
      processParams.debugSaveCroppedImages = opts.getBoolean("debugSaveCroppedImages");
    }
  }
}
