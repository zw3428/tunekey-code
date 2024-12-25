package com.spelist.tunekey.ui.student.sPractice.activity.recordVideo;

import android.content.res.Resources;
import android.graphics.PointF;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.githang.statusbar.StatusBarCompat;
import com.jakewharton.rxbinding2.view.RxView;
import com.orhanobut.logger.Logger;
import com.otaliastudios.cameraview.CameraException;
import com.otaliastudios.cameraview.CameraListener;
import com.otaliastudios.cameraview.CameraOptions;
import com.otaliastudios.cameraview.CameraView;
import com.otaliastudios.cameraview.PictureResult;
import com.otaliastudios.cameraview.VideoResult;
import com.otaliastudios.cameraview.controls.Facing;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.SLTools;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.File;
import java.text.DecimalFormat;
import java.util.concurrent.TimeUnit;

import io.reactivex.functions.Consumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.jessyan.autosize.AutoSizeCompat;

/**
 * com.spelist.tunekey.ui.student.sPractice.activity.recordVideo
 * 2022/1/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RecordVideoAc extends AppCompatActivity {
    private ImageView back;
    private TextView title;
    private CameraView cameraView;
    private ImageView centerButton;
    private TextView timerView;
    private String id = IDUtils.getId();
    private boolean isStart;
    private LinearLayout titleLayout;
    private TKPractice practice;
    private TKPractice.PracticeRecord recordData = new TKPractice.PracticeRecord();
    private long time = 0;
    public static String RECORD_MESSAGE = "RecordMessage";
    private boolean isAutoStop = false;
    private ImageView rotateView;
    private LinearLayout topLayout;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StatusBarCompat.setTranslucent(getWindow(), true);

        setContentView(R.layout.activity_record_video);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        initView();
        initData();
    }

    private void initData() {
        practice = (TKPractice) getIntent().getSerializableExtra("data");
        title.setText(practice.getName());

    }

    private void initView() {
        back = (ImageView) findViewById(R.id.back);
        back.setOnClickListener(v -> {
            finish();

        });
        title = (TextView) findViewById(R.id.title);
        cameraView = (CameraView) findViewById(R.id.cameraView);
        centerButton = (ImageView) findViewById(R.id.centerButton);
        timerView = (TextView) findViewById(R.id.timerView);
//        centerButton.setOnClickListener(v -> {
//            if (isStart) {
////                Dialog stop_recording = SLDialogUtils.showTwoButton(this, "Stop Recording", "Are you sure stop recording?", "Stop", "Go back");
////                stop_recording.findViewById(R.id.left_button).setOnClickListener(v1 -> {
////
////                });
////                stop_recording.dismiss();
//                stopRecord();
//            } else {
//                startRecord();
//            }
//        });
        RxView.clicks(centerButton)
                .throttleFirst(1000, TimeUnit.MILLISECONDS)//1秒钟内只允许点击1次
                .subscribe(object -> {
                    if (isStart) {
                        stopRecord();
                    } else {
                        startRecord();
                    }
                });
        cameraView.setLifecycleOwner(this);
        cameraView.addCameraListener(new CameraListener() {
            @Override
            public void onCameraOpened(@NonNull CameraOptions options) {
                super.onCameraOpened(options);
            }

            @Override
            public void onCameraClosed() {
                super.onCameraClosed();
            }

            @Override
            public void onCameraError(@NonNull CameraException exception) {
                super.onCameraError(exception);
            }

            @Override
            public void onPictureTaken(@NonNull PictureResult result) {
                super.onPictureTaken(result);
            }

            @Override
            public void onVideoTaken(@NonNull VideoResult result) {
                super.onVideoTaken(result);

                recordData.setFileSize(result.getFile().length());
                recordData.setUpload(false);
                recordData.setOld(false);
                practice.getRecordData().add(recordData);
                practice.setTotalTimeLength(practice.getTotalTimeLength() + recordData.getDuration());
                finish();
                Messenger.getDefault().send(practice, RECORD_MESSAGE);

            }

            @Override
            public void onOrientationChanged(int orientation) {
                super.onOrientationChanged(orientation);
            }

            @Override
            public void onAutoFocusStart(@NonNull PointF point) {
                super.onAutoFocusStart(point);
            }

            @Override
            public void onAutoFocusEnd(boolean successful, @NonNull PointF point) {
                super.onAutoFocusEnd(successful, point);

            }

            @Override
            public void onZoomChanged(float newValue, @NonNull float[] bounds, @Nullable PointF[] fingers) {
                super.onZoomChanged(newValue, bounds, fingers);
            }

            @Override
            public void onExposureCorrectionChanged(float newValue, @NonNull float[] bounds, @Nullable PointF[] fingers) {
                super.onExposureCorrectionChanged(newValue, bounds, fingers);
            }

            @Override
            public void onVideoRecordingStart() {
                super.onVideoRecordingStart();
                Log.e("TAG", ": 录像开始");
            }

            @Override
            public void onVideoRecordingEnd() {
                super.onVideoRecordingEnd();
                Log.e("TAG", ": 录像结束");
            }

            @Override
            public void onPictureShutter() {
                super.onPictureShutter();
            }

            @Override
            public int hashCode() {
                return super.hashCode();
            }

            @Override
            public boolean equals(@Nullable Object obj) {
                return super.equals(obj);
            }

            @NonNull
            @Override
            protected Object clone() throws CloneNotSupportedException {
                return super.clone();
            }

            @NonNull
            @Override
            public String toString() {
                return super.toString();
            }

            @Override
            protected void finalize() throws Throwable {
                super.finalize();
            }
        });

        titleLayout = (LinearLayout) findViewById(R.id.titleLayout);
        LinearLayout topLayout = findViewById(R.id.topLayout);
        int statusBarHeight = getStatusBarHeight();
        ConstraintLayout.LayoutParams layoutParams = (ConstraintLayout.LayoutParams) topLayout.getLayoutParams();
        layoutParams.height = statusBarHeight;
        topLayout.setLayoutParams(layoutParams);


        rotateView = (ImageView) findViewById(R.id.rotateView);
        topLayout = (LinearLayout) findViewById(R.id.topLayout);
        rotateView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (cameraView.getFacing() == Facing.FRONT) {
                    cameraView.setFacing(Facing.BACK);
                } else {
                    cameraView.setFacing(Facing.FRONT);
                }
            }
        });
    }

    private void stopRecord() {
        isStart = false;
        cameraView.stopVideo();
        centerButton.setImageResource(R.mipmap.video_start);
        recordData.setDuration(((time) / 1000L));
        time = 0;
        handler.removeCallbacksAndMessages(null);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        handler.removeCallbacksAndMessages(null);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    private Handler handler = new Handler(Looper.getMainLooper(), new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            time = time + 1000;

            if (time <= 0) {
//                title.setText("00 : 00");
//                stopRecord();
            } else {
                String s = "0" + (int) Math.floor(time / 60000) + ":";
                if (dec.format((time % 60000) / 1000).length() == 1) {
                    s = s + "0" + dec.format((time % 60000) / 1000);
                } else {
                    s = s + dec.format((time % 60000) / 1000);
                }
                title.setText(s + " / 10:00");
                if (time == 10 * 60 * 1000) {
                    stopRecord();
                } else {
                    postDelayed();
                }

            }


            return false;
        }
    });

    private void postDelayed() {
        handler.postDelayed(() -> handler.sendEmptyMessage(1), 1000);
    }

    private DecimalFormat dec = new DecimalFormat("##.##");

    private void startRecord() {
        File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
        File localFile = new File(storagePath, id + ".mp4");
        if (!storagePath.exists()) {
            storagePath.mkdirs();
        }
        if (localFile.exists()) {
            localFile.delete();
        }
        rotateView.setVisibility(View.GONE);
        cameraView.takeVideo(localFile);
        centerButton.setImageResource(R.mipmap.video_stop);
        isStart = true;
        recordData.setStartTime(TimeUtils.getCurrentTime());
        recordData.setId(id);
        recordData.setFormat(".mp4");
        title.setText("10 : 00");
        postDelayed();
    }

    public int getStatusBarHeight() {
        int result = 0;
        //获取状态栏高度的资源id
        int resourceId = getResources().getIdentifier("status_bar_height", "dimen", "android");
        if (resourceId > 0) {
            result = getResources().getDimensionPixelSize(resourceId);
        }
        return result;
    }

    @Override
    public Resources getResources() {

        try {
            runOnUiThread(() -> {
                if (super.getResources() != null) {
                    AutoSizeCompat.autoConvertDensityOfGlobal(super.getResources());//如果没有自定义需求用这个方法
//                AutoSizeCompat.autoConvertDensity(super.getResources(), 375, true);//如果有自定义需求就用这个方法
                }
            });

        } catch (Throwable e) {
            Log.e("TAG", "getResources重置Density 失败: " + e.getMessage());
        }
        return super.getResources();
    }
}
