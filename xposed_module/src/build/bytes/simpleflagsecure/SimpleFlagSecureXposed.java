package build.bytes.simpleflagsecure;

import android.app.Activity;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.Build;
import android.view.Display;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager.LayoutParams;

import java.util.concurrent.Executor;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XC_MethodReplacement;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage.LoadPackageParam;

public class SimpleFlagSecureXposed implements IXposedHookLoadPackage {

    private static final String TAG = "SimpleFlagSecure";

    @Override
    public void handleLoadPackage(final LoadPackageParam lpparam) {
        if (lpparam == null || lpparam.packageName == null) return;

        // 1. Strip FLAG_SECURE from Window
        hookWindowFlags(lpparam.classLoader);

        // 2. Strip FLAG_SECURE from WindowManagerGlobal LayoutParams
        hookWindowManagerGlobal(lpparam.classLoader);

        // 3. Strip secure flag from SurfaceView & SurfaceControl
        hookSurface(lpparam.classLoader);

        // 4. Neutralize Android 14+ Screenshot Detection Callback
        hookScreenshotDetection(lpparam.classLoader);

        // 5. Force Recents Screenshot Enabled (Android 13/14+)
        hookRecentsScreenshot(lpparam.classLoader);

        // 6. Neutralize Android 15+ Screen Recording Callback
        hookScreenRecordingDetection(lpparam.classLoader);

        // 7. Suppress MediaStore Screenshot Probing (Fallback Detection)
        hookMediaStoreQuery(lpparam.classLoader);
    }

    private void hookWindowFlags(ClassLoader classLoader) {
        try {
            // Window.setFlags(int flags, int mask)
            XposedHelpers.findAndHookMethod(
                Window.class,
                "setFlags",
                int.class,
                int.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        int flags = (int) param.args[0];
                        int mask = (int) param.args[1];
                        flags &= ~LayoutParams.FLAG_SECURE;
                        mask &= ~LayoutParams.FLAG_SECURE;
                        param.args[0] = flags;
                        param.args[1] = mask;
                    }
                }
            );

            // Window.addFlags(int flags)
            XposedHelpers.findAndHookMethod(
                Window.class,
                "addFlags",
                int.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        int flags = (int) param.args[0];
                        flags &= ~LayoutParams.FLAG_SECURE;
                        param.args[0] = flags;
                    }
                }
            );
        } catch (Throwable t) {
            XposedBridge.log(TAG + " - Window flag hook error: " + t.getMessage());
        }
    }

    private void hookWindowManagerGlobal(ClassLoader classLoader) {
        XC_MethodHook layoutParamsHook = new XC_MethodHook() {
            @Override
            protected void beforeHookedMethod(MethodHookParam param) {
                if (param.args != null && param.args.length > 1 && param.args[1] instanceof LayoutParams) {
                    LayoutParams lp = (LayoutParams) param.args[1];
                    lp.flags &= ~LayoutParams.FLAG_SECURE;
                }
            }
        };

        // Hook exact addView and updateViewLayout overloads
        try {
            XposedHelpers.findAndHookMethod(
                "android.view.WindowManagerGlobal",
                classLoader,
                "addView",
                View.class,
                ViewGroup.LayoutParams.class,
                Display.class,
                Window.class,
                layoutParamsHook
            );
        } catch (Throwable ignored) {}

        try {
            XposedHelpers.findAndHookMethod(
                "android.view.WindowManagerGlobal",
                classLoader,
                "addView",
                View.class,
                ViewGroup.LayoutParams.class,
                Display.class,
                Window.class,
                int.class,
                layoutParamsHook
            );
        } catch (Throwable ignored) {}

        try {
            XposedHelpers.findAndHookMethod(
                "android.view.WindowManagerGlobal",
                classLoader,
                "updateViewLayout",
                View.class,
                ViewGroup.LayoutParams.class,
                layoutParamsHook
            );
        } catch (Throwable ignored) {}
    }

    private void hookSurface(ClassLoader classLoader) {
        try {
            // SurfaceView.setSecure(boolean)
            XposedHelpers.findAndHookMethod(
                SurfaceView.class,
                "setSecure",
                boolean.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        param.args[0] = false;
                    }
                }
            );

            // SurfaceControl.Builder.setSecure(boolean)
            try {
                Class<?> scBuilder = XposedHelpers.findClass("android.view.SurfaceControl$Builder", classLoader);
                XposedHelpers.findAndHookMethod(
                    scBuilder,
                    "setSecure",
                    boolean.class,
                    new XC_MethodHook() {
                        @Override
                        protected void beforeHookedMethod(MethodHookParam param) {
                            param.args[0] = false;
                        }
                    }
                );
            } catch (Throwable ignored) {}
        } catch (Throwable t) {
            XposedBridge.log(TAG + " - Surface hook error: " + t.getMessage());
        }
    }

    private void hookScreenshotDetection(ClassLoader classLoader) {
        if (Build.VERSION.SDK_INT < 34) return; // Android 14+ (UPSIDE_DOWN_CAKE)

        try {
            Class<?> callbackClass = XposedHelpers.findClass("android.app.Activity$ScreenCaptureCallback", classLoader);

            // Neutralize Activity.registerScreenCaptureCallback
            XposedHelpers.findAndHookMethod(
                Activity.class,
                "registerScreenCaptureCallback",
                Executor.class,
                callbackClass,
                XC_MethodReplacement.DO_NOTHING
            );

            // Neutralize Activity.unregisterScreenCaptureCallback
            XposedHelpers.findAndHookMethod(
                Activity.class,
                "unregisterScreenCaptureCallback",
                callbackClass,
                XC_MethodReplacement.DO_NOTHING
            );
        } catch (Throwable t) {
            XposedBridge.log(TAG + " - Screenshot detection hook error: " + t.getMessage());
        }
    }

    private void hookRecentsScreenshot(ClassLoader classLoader) {
        if (Build.VERSION.SDK_INT < 33) return;

        try {
            XposedHelpers.findAndHookMethod(
                Activity.class,
                "setRecentsScreenshotEnabled",
                boolean.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        param.args[0] = true;
                    }
                }
            );
        } catch (Throwable ignored) {}
    }

    private void hookScreenRecordingDetection(ClassLoader classLoader) {
        if (Build.VERSION.SDK_INT < 35) return; // Android 15+ (VANILLA_ICE_CREAM)

        try {
            Class<?> wmImpl = XposedHelpers.findClass("android.view.WindowManagerImpl", classLoader);
            for (java.lang.reflect.Method m : wmImpl.getDeclaredMethods()) {
                if ("addScreenRecordingCallback".equals(m.getName()) || "removeScreenRecordingCallback".equals(m.getName())) {
                    XposedBridge.hookMethod(m, XC_MethodReplacement.DO_NOTHING);
                }
            }
        } catch (Throwable ignored) {}
    }

    private void hookMediaStoreQuery(ClassLoader classLoader) {
        try {
            Class<?> resolverClass = XposedHelpers.findClass("android.content.ContentResolver", classLoader);
            XposedHelpers.findAndHookMethod(
                resolverClass,
                "query",
                Uri.class,
                String[].class,
                String.class,
                String[].class,
                String.class,
                new XC_MethodHook() {
                    @Override
                    protected void afterHookedMethod(MethodHookParam param) {
                        String selection = (String) param.args[2];
                        String[] selectionArgs = (String[]) param.args[3];

                        boolean looksLikeScreenshotQuery = false;
                        if (selection != null && (selection.contains("screenshot") || selection.contains("Screenshots"))) {
                            looksLikeScreenshotQuery = true;
                        }
                        if (selectionArgs != null) {
                            for (String arg : selectionArgs) {
                                if (arg != null && (arg.toLowerCase().contains("screenshot"))) {
                                    looksLikeScreenshotQuery = true;
                                    break;
                                }
                            }
                        }

                        if (looksLikeScreenshotQuery) {
                            param.setResult(new MatrixCursor(new String[]{"_id"}));
                        }
                    }
                }
            );
        } catch (Throwable ignored) {}
    }
}
