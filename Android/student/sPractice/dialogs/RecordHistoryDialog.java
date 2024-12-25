package com.spelist.tunekey.ui.student.sPractice.dialogs;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.text.Spannable;
import android.text.SpannableString;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;
import androidx.databinding.DataBindingUtil;
import androidx.fragment.app.FragmentActivity;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.functions.FirebaseFunctions;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;
import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BottomPopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.SLCircularProgressView;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.CenterAlignImageSpan;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.ThreeButtonDialog;
import com.spelist.tunekey.databinding.DialogRecordHistoryBinding;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.ui.teacher.materials.dialog.PlayAudioDialog;
import com.spelist.tunekey.ui.toolsView.videoPlayer.VideoPlayerActivity;
import com.spelist.tunekey.utils.BaseRecyclerAdapter;
import com.spelist.tunekey.utils.BaseRecyclerHolder;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTools;
import com.spelist.tunekey.utils.TimeUtils;
import com.tbruyelle.rxpermissions2.RxPermissions;

import java.io.File;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.goldze.mvvmhabit.bus.Messenger;
import me.jessyan.autosize.utils.AutoSizeUtils;

/**
 * com.spelist.tunekey.ui.student.sPractice.dialogs
 * 2022/1/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RecordHistoryDialog extends BottomPopupView {
    private DialogRecordHistoryBinding binding;
    private TKPractice practice;
    private FragmentActivity activity;
    //0历史,1音频,2视频
    private int type;
    private boolean isLook;
    private BaseRecyclerAdapter<TKPractice.PracticeRecord> adapter;
    private DecimalFormat dec = new DecimalFormat("##");
    private BaseFragment baseFragment;


    public RecordHistoryDialog(@NonNull Context context, TKPractice practice, FragmentActivity activity, int type, boolean isLook) {
        super(context);
        this.type = type;
        this.activity = activity;
        this.practice = practice;
        this.isLook = isLook;
    }

    public RecordHistoryDialog(@NonNull Context context, BaseFragment baseFragment, TKPractice practice, FragmentActivity activity, int type, boolean isLook) {
        super(context);
        this.type = type;
        this.activity = activity;
        this.practice = practice;
        this.isLook = isLook;
        this.baseFragment = baseFragment;
    }

    private OnClickListener mOnClickListener;
    private List<TKPractice.PracticeRecord> deleteId = new ArrayList<>();
    private List<String> cancelUploadId = new ArrayList<>();

    public interface OnClickListener {
        void onClickClose(List<TKPractice.PracticeRecord> deleteId);
    }

    protected int getImplLayoutId() {
        return R.layout.dialog_record_history;
    }


    public void setClickListener(OnClickListener mOnClickListener) {
        this.mOnClickListener = mOnClickListener;
    }



    @SuppressLint("CheckResult")
    public void showDialog() {
        List<String> permissionsList = new ArrayList<>();
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
            permissionsList.add("android.permission.READ_MEDIA_AUDIO");
        } else {
            permissionsList.add(Manifest.permission.READ_EXTERNAL_STORAGE);
            permissionsList.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
        }
        String[] permissions = permissionsList.toArray(new String[0]);
        new RxPermissions(activity)
                .request(permissions)
                .subscribe(aBoolean -> {
                    if (aBoolean) {
                        new XPopup.Builder(getContext())
                                .isDestroyOnDismiss(true)
                                .enableDrag(false)
                                .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                                .dismissOnTouchOutside(false)
                                .asCustom(this)
                                .show();
                    } else {
                        SLToast.warning("Please allow the permission request and try again.");
                    }
                });

    }

    @SuppressLint("CheckResult")
    @Override
    protected void onCreate() {
        super.onCreate();
        binding = DataBindingUtil.bind(getPopupImplView());
        if (binding == null) {
            return;
        }
        binding.infoTv.setVisibility(VISIBLE);
        if (type == 0) {
            binding.infoTv.setVisibility(GONE);
            binding.centerButton.setText("CANCEL");
            binding.title.setText("Record History");
        } else if (type == 1) {
            binding.title.setText("Audio Recording");
        } else if (type == 2) {
            binding.title.setText("Video Recording");
        }
        initInfo();
        Logger.e("practicie==>%s", SLJsonUtils.toJsonString(practice));


        binding.centerButton.setClickListener(tkButton -> {
            if (mOnClickListener != null) {
                mOnClickListener.onClickClose(deleteId);
            }
            dismiss();
        });
        List<String> notUploadPracticeFileId = SLCacheUtil.getNotUploadPracticeFileId(UserService.getInstance().getCurrentUserId());
        Logger.e("notUploadPracticeFileId==>%s", SLJsonUtils.toJsonString(notUploadPracticeFileId));
        Logger.e("practic==>%s", SLJsonUtils.toJsonString(practice));

        practice.getRecordData().removeIf(record -> {
            if (record.isUpload()) {
                return false;
            } else {
                return !(notUploadPracticeFileId.contains(record.getId()));
            }
        });
        Logger.e("practic==>%s", SLJsonUtils.toJsonString(practice));



//        if (isLook) {
//            practice.getRecordData().removeIf(practiceRecord -> !practiceRecord.isUpload());
//        }

        if (practice.getRecordData().size() > 0) {

            practice.getRecordData().sort((o1, o2) -> o2.getStartTime() - o1.getStartTime());
            practice.getRecordData().get(0).setOpen(true);
        }

        //设置高度
        LinearLayout.LayoutParams lp = (LinearLayout.LayoutParams) binding.recyclerView.getLayoutParams();
        if (practice.getRecordData().size() * 290 > AutoSizeUtils.pt2px(getContext(), 380)) {
            lp.height = AutoSizeUtils.pt2px(getContext(), 380);
        } else {
            lp.height = practice.getRecordData().size() * 290;
        }

        binding.recyclerView.setLayoutParams(lp);

        binding.recyclerView.setItemAnimator(null);
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.nameTv.setText(practice.getName());
        Logger.e("practicie==>%s", SLJsonUtils.toJsonString(practice));
        adapter = new BaseRecyclerAdapter<TKPractice.PracticeRecord>(getContext(), practice.getRecordData(), R.layout.item_record_history) {
            @SuppressLint("NotifyDataSetChanged")
            @Override
            public void convert(BaseRecyclerHolder holder, TKPractice.PracticeRecord item, int position, boolean isScrolling) {
                ImageView arrowView = holder.getView(R.id.arrowImg);
                LinearLayout operationView = holder.getView(R.id.operationView);
                LinearLayout mainLayout = holder.getView(R.id.mainLayout);
                View div = holder.getView(R.id.div);
                ImageView play = holder.getView(R.id.play);
                ImageView share = holder.getView(R.id.share);
                ImageView upload = holder.getView(R.id.upload);
                ImageView delete = holder.getView(R.id.delete);
                SLCircularProgressView progress = holder.getView(R.id.progress);
                if (position == practice.getRecordData().size() - 1) {
                    div.setVisibility(GONE);
                } else {
                    div.setVisibility(VISIBLE);
                }


                if (item.isOpen()) {
                    arrowView.setRotation(180);
                    operationView.setVisibility(VISIBLE);
                } else {
                    arrowView.setRotation(0);
                    operationView.setVisibility(GONE);
                }
                String text = TimeUtils.timeFormat(item.getStartTime(), "hh:mm:ssa, MM/dd/yyyy");
                holder.setText(R.id.uploadTime, text);
                double time = item.getDuration() * 1000L;
                String s = "0" + (int) Math.floor(time / 60000) + ":";
                if (dec.format((time % 60000) / 1000).length() == 1) {
                    s = s + "0" + dec.format((time % 60000) / 1000);
                } else {
                    s = s + dec.format((time % 60000) / 1000);
                }

                if (item.isUpload()) {
                    upload.setImageResource(R.mipmap.ic_upload_true_primary);
                } else {
                    upload.setImageResource(R.mipmap.ic_upload_primary);
                }
                if (isLook) {
                    upload.setVisibility(GONE);
                    delete.setVisibility(GONE);
                } else {
                    upload.setVisibility(VISIBLE);
                    delete.setVisibility(VISIBLE);
                }
                if (item.isShowProgress()) {

                    progress.setProgress(item.getProgress());
                    if (isLook) {
                        upload.setVisibility(GONE);
                        delete.setVisibility(GONE);
                    } else {
                        upload.setVisibility(GONE);
                        progress.setVisibility(VISIBLE);
                    }
                    holder.setText(R.id.time, SLStringUtils.getNetFileSizeDescription(item.getProgressSize()) + " / " + SLStringUtils.getNetFileSizeDescription(item.getFileSize()));
                } else {
                    holder.setText(R.id.time, s);
                    if (isLook) {
                        upload.setVisibility(GONE);
                        delete.setVisibility(GONE);
                    } else {
                        upload.setVisibility(VISIBLE);
                        progress.setVisibility(GONE);
                    }

                }

                if (item.getFormat().equals(".mp4")) {
                    play.setImageResource(R.mipmap.ic_video_play_primary);
                } else {
                    play.setImageResource(R.mipmap.ic_play_primary);
                }


                String url = "https://firebasestorage.googleapis.com/v0/b/tunekey-2019.appspot.com/o/practice%2F" + item.getId() + item.getFormat() + "?alt=media&token=b2ed7c5d-136a-4c39-838e-954153295500";

                share.setOnClickListener(v -> {
                    Intent intent = new Intent();
                    intent.setAction(Intent.ACTION_SEND);
                    boolean isHave = false;
                    File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
                    File localFile = new File(storagePath, item.getId() + item.getFormat());
                    if (storagePath.exists()) {
                        if (localFile.exists()) {
                            isHave = true;
                        }
                    }
                    if (!isHave && !item.isUpload()) {
                        SLToast.error("Oops! the media files is missing accidentally. UPLOADING your next  recordings will avoid this happening again. ");
                        return;
                    }
                    if (isHave) {
                        if (item.getFormat().equals(".mp4")) {
                            intent.setType("video/*");
                        } else {
                            intent.setType("audio/*");
                        }
                        ApplicationInfo applicationInfo = getContext().getApplicationInfo();
                        Uri uri;
                        int targetSDK = applicationInfo.targetSdkVersion;
                        if (targetSDK >= Build.VERSION_CODES.N) {
                            uri = FileProvider.getUriForFile(getContext(), getContext().getApplicationContext().getPackageName() + ".fileprovider", localFile);
                        } else {
                            uri = Uri.fromFile(localFile);
                        }

                        intent.putExtra(Intent.EXTRA_STREAM, uri);
                        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                    } else {
                        intent.putExtra(Intent.EXTRA_TEXT, url);
                        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        intent.setType("text/plain");
                    }

                    activity.startActivity(intent);

                });

                String finalS = text;
                play.setOnClickListener(v -> {
                    boolean isHave = false;
                    File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
                    File localFile = new File(storagePath, item.getId() + item.getFormat());
                    if (storagePath.exists()) {
                        if (localFile.exists()) {
                            isHave = true;
                        }
                    }
                    if (!isHave && !item.isUpload()) {
                        SLToast.error("Oops! the media files is missing accidentally. UPLOADING your next  recordings will avoid this happening again. ");
                        return;
                    }
                    if (item.getFormat().equals(".mp4")) {

                        Class<?> AimActivityVideo = VideoPlayerActivity.class;
                        if (isHave) {
                            FuncUtils.goToVideoPlayer(activity, v, AimActivityVideo, localFile.getPath(), practice.getName(), "");

                        } else {
                            if (item.isUpload()) {
                                FuncUtils.goToVideoPlayer(activity, v, AimActivityVideo, url, practice.getName(), "");

                            } else {
                                SLToast.error("Oops! the media files is missing accidentally. UPLOADING your next  recordings will avoid this happening again. ");
                            }
                        }


                    } else {
                        List<String> permissionsList = new ArrayList<>();
                        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
                            permissionsList.add("android.permission.READ_MEDIA_AUDIO");
                        } else {
                            permissionsList.add(Manifest.permission.READ_EXTERNAL_STORAGE);
                            permissionsList.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
                        }
                        String[] permissions = permissionsList.toArray(new String[0]);
                        new RxPermissions(activity)
                                .request(permissions)
                                .subscribe(aBoolean -> {
                                    if (aBoolean) {
                                        MaterialEntity data = new MaterialEntity();
                                        data.setStoragePatch("/practice/" + item.getId() + item.getFormat());
                                        data.setId(item.getId());
                                        data.setName(finalS);
                                        String suffix = item.getFormat();
                                        suffix = suffix.replace(".", "");
                                        data.setSuffixName(suffix);
                                        PlayAudioDialog playPracticeDialog = new PlayAudioDialog(activity,activity, data);
                                        new XPopup.Builder(activity)
                                                .isDestroyOnDismiss(true)
                                                .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                                                .dismissOnTouchOutside(false)
                                                .enableDrag(false)
                                                .asCustom(playPracticeDialog)
                                                .show();

                                    } else {
                                        SLToast.warning("Please allow the permission request and try again.");
                                    }
                                });
                    }

                });
                progress.setOnClickListener(v -> {
                    upload.setVisibility(VISIBLE);
                    progress.setVisibility(GONE);
                    practice.getRecordData().get(position).setShowProgress(false);
                    practice.getRecordData().get(position).setProgress(0);
                    practice.getRecordData().get(position).setUpload(false);
                    practice.getRecordData().get(position).setProgressSize(0);
                    practice.getRecordData().get(position).getUploadTask().cancel();
                    notifyDataSetChanged();
                    SLToast.success("Your uploading has been removed!");
                });
                upload.setOnClickListener(v -> {

                    if (item.isUpload()) {
//                        upload.setVisibility(VISIBLE);
//                        progress.setVisibility(GONE);
//                        practice.getRecordData().get(position).setShowProgress(false);
//                        practice.getRecordData().get(position).setProgress(0);
//                        practice.getRecordData().get(position).setUpload(false);
//                        practice.getRecordData().get(position).setProgressSize(0);
//                        notifyDataSetChanged();
//                        SLToast.success("Your uploading has been removed!");
//                        cancelUpload(item);
                    } else {
                        if (item.isShowProgress()) {
                            upload.setVisibility(VISIBLE);
                            progress.setVisibility(GONE);
                            practice.getRecordData().get(position).setShowProgress(false);
                            practice.getRecordData().get(position).setProgress(0);
                            practice.getRecordData().get(position).setUpload(false);
                            practice.getRecordData().get(position).setProgressSize(0);
                            practice.getRecordData().get(position).getUploadTask().cancel();
                            notifyDataSetChanged();
                        } else {

                            upload.setVisibility(GONE);
                            progress.setVisibility(VISIBLE);
                            practice.getRecordData().get(position).setShowProgress(true);
                            item.setShowProgress(true);
                            upload(item);
                        }
                    }

                });
                delete.setOnClickListener(v1 -> {
                    if (item.isShowProgress()) {
                        return;
                    }
                    if (item.isUpload()) {
                        ThreeButtonDialog dialog = new ThreeButtonDialog(getContext(), "Remove recording?", "Tap on 'Cloud Only', your recording will be removed from the cloud, not local file.  You still can access it on your device.", "Cloud Only", "Cloud & Local", "Cancel", true);
                        dialog.showDialog();
                        dialog.setClickListener(new ThreeButtonDialog.OnClickListener() {
                            @Override
                            public void onClickOne() {
                                upload.setVisibility(VISIBLE);
                                progress.setVisibility(GONE);
                                practice.getRecordData().get(position).setShowProgress(false);
                                practice.getRecordData().get(position).setProgress(0);
                                practice.getRecordData().get(position).setUpload(false);
                                practice.getRecordData().get(position).setProgressSize(0);
                                notifyDataSetChanged();
                                SLToast.success("Remove successfully");
                                cancelUpload(item);
                                dialog.dismiss();
                            }

                            @Override
                            public void onClickTwo() {
                                deleteData(practice.getRecordData().get(position));
                                dialog.dismiss();
                            }

                            @Override
                            public void onClickThree() {
                                dialog.dismiss();
                            }
                        });


                    } else {
                        Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "Delete recording?", "Your recording will be deleted permanently, are you sure to continue?", "Delete", "Go back");
                        TextView leftButton = dialog.findViewById(R.id.left_button);
                        leftButton.setTextColor(ContextCompat.getColor(getContext(), R.color.red));
                        leftButton.setOnClickListener(v2 -> {
//                        deleteId.add(item);

                            deleteData(practice.getRecordData().get(position));
                            dialog.dismiss();
                        });
                    }

                });


            }
        };
        binding.recyclerView.setAdapter(adapter);
        binding.recyclerView.setAnimation(null);
        adapter.setOnItemClickListener((parent, view, position) -> {
            practice.getRecordData().get(position).setOpen(!practice.getRecordData().get(position).isOpen());
            ImageView arrow = view.findViewById(R.id.arrowImg);
            if (practice.getRecordData().get(position).isOpen()) {
                arrow.animate().rotation(180);
            } else {
                arrow.animate().rotation(0);
            }
            adapter.notifyItemChanged(position);
        });
    }

    private void initInfo() {
        double totalTime = 0;
        for (TKPractice.PracticeRecord recordDatum : practice.getRecordData()) {
            totalTime += recordDatum.getDuration();
        }
        totalTime = totalTime / 60;
        if (totalTime < 0.1 && totalTime > 0) {
            totalTime = 0.1;
        }
        String start = "You just completed " + String.format("%.1f", totalTime) + " mins practice.\nTap on ";
        String text = start + "[upload] to upload the recordings for instructor's review.";

        String icon = "[upload]";
        SpannableString spannable = new SpannableString(text);//用于可变字符串
        Drawable drawable = ContextCompat.getDrawable(TApplication.getInstance().getBaseContext(), R.mipmap.ic_upload_primary);
        drawable.setBounds(0, 0, drawable.getMinimumWidth(), drawable.getMinimumHeight());
        CenterAlignImageSpan span = new CenterAlignImageSpan(drawable, CenterAlignImageSpan.CENTRE);
        spannable.setSpan(span, start.length(), start.length() + icon.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        binding.infoTv.setText(spannable);
    }

    @SuppressLint("NotifyDataSetChanged")
    private void upload(TKPractice.PracticeRecord record) {
        String filePath = "";
        File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
        File localFile = new File(storagePath, record.getId() + record.getFormat());
        if (storagePath.exists()) {
            if (localFile.exists()) {
                filePath = localFile.getPath();
            }
        }
        if (filePath.equals("")) {
            SLToast.error("Oops! the media files is missing accidentally. UPLOADING your next  recordings will avoid this happening again. ");
            record.setUpload(false);
            record.setShowProgress(false);
            for (TKPractice.PracticeRecord item : practice.getRecordData()) {
                if (item.getId().equals(record.getId())) {
                    item.setUpload(false);
                    item.setShowProgress(false);
                }
            }
            adapter.notifyDataSetChanged();
            return;
        }

        record.setFileSize(localFile.length());


        FirebaseStorage storage = FirebaseStorage.getInstance();
        StorageReference storageRef = storage.getReference();
        StorageReference spaceRef = storageRef.child("practice/" + record.getId() + record.getFormat());
        Uri file = Uri.fromFile(localFile);
        UploadTask uploadTask = spaceRef.putFile(file);
        for (TKPractice.PracticeRecord item : practice.getRecordData()) {
            if (item.getId().equals(record.getId())) {
                item.setFileSize(localFile.length());
                item.setUploadTask(uploadTask);
            }
        }
        adapter.notifyDataSetChanged();
        uploadTask.addOnProgressListener(snapshot -> {
            int progress = (int) ((double) snapshot.getBytesTransferred() / (double) snapshot.getTotalByteCount() * 100D);
            if (progress >= 90) {
                progress = 90;
            }
            for (TKPractice.PracticeRecord item : practice.getRecordData()) {
                if (item.getId().equals(record.getId())) {
                    item.setProgress(progress);
                }
            }
            record.setFileSize(snapshot.getTotalByteCount());

            record.setProgressSize(snapshot.getBytesTransferred());
            record.setProgress(progress);
            adapter.notifyDataSetChanged();
        }).addOnCompleteListener(task -> {
            if (task.getException() == null) {
                Logger.e("上传成功==>开始更新数据");
                FirebaseFirestore.getInstance().runTransaction(transaction -> {
                    try {
                        TKPractice tkPractice = transaction.get(DatabaseService.Collections.practice().document(record.getPraicticeId())).toObject(TKPractice.class);
                        if (tkPractice != null) {
                            for (TKPractice.PracticeRecord item : tkPractice.getRecordData()) {
                                if (item.getId().equals(record.getId())) {
                                    item.setUpload(true);
                                    item.setShowProgress(false);
                                }
                            }
//                            Logger.e("????==>%s", SLJsonUtils.toJsonString(tkPractice.getRecordData()));
                            transaction.update(DatabaseService.Collections.practice().document(record.getPraicticeId()), "recordData", tkPractice.getRecordData());
                        } else {
                            throw new FirebaseFirestoreException("get practice failed",
                                    FirebaseFirestoreException.Code.UNKNOWN);
                        }


                    } catch (Throwable throwable) {
                        throw new FirebaseFirestoreException("get practice failed",
                                FirebaseFirestoreException.Code.UNKNOWN);
                    }


                    return null;
                }).addOnCompleteListener(btask -> {
                    Logger.e("更新数据完成 是否成功==>%s", btask.getException() == null);
                    if (btask.getException() == null) {
                        SLToast.success("Upload Successfully!");
                        record.setProgress(100);
                        adapter.notifyDataSetChanged();
                        record.setUpload(true);
                        record.setShowProgress(false);
                        for (TKPractice.PracticeRecord item : practice.getRecordData()) {
                            if (item.getId().equals(record.getId())) {
                                item.setUpload(true);
                                item.setShowProgress(false);
                            }
                        }
                        Messenger.getDefault().sendNoMsg(MessengerUtils.STUDENT_PRACTICE_CHANGED);

                        sendPracticeMessage(practice.getId());

                    } else {
                        SLToast.showError();
                        record.setProgress(100);
                        adapter.notifyDataSetChanged();
                        record.setUpload(false);
                        record.setShowProgress(false);
                        for (TKPractice.PracticeRecord item : practice.getRecordData()) {
                            if (item.getId().equals(record.getId())) {
                                item.setUpload(false);
                                item.setShowProgress(false);
                            }
                        }
                    }
                    adapter.notifyDataSetChanged();

                });


            } else {
//                upload(record);
                Logger.e("上传失败==>%s", task.getException().getMessage());
            }
        });


    }

    private void sendPracticeMessage(String id) {
        Logger.e("????==>%s", id);
        Map<String, Object> map = new HashMap<>();
        map.put("practiceId", id);
        FirebaseFunctions
                .getInstance()
                .getHttpsCallable("sendNotificationForStudentUploadedPracticeFile")
                .call(map)
                .addOnCompleteListener(task -> {
                    if (task.getException() == null) {
                        Logger.e("发送通知成功==>%s");
                    } else {
                        Logger.e("发送通知失败==>%s", task.getException().getMessage());
                    }
                });


    }

    public void cancelUpload(TKPractice.PracticeRecord record) {
        FirebaseFirestore.getInstance().runTransaction(transaction -> {
            try {
                TKPractice tkPractice = transaction.get(DatabaseService.Collections.practice().document(record.getPraicticeId())).toObject(TKPractice.class);
                if (tkPractice != null) {
                    for (TKPractice.PracticeRecord item : tkPractice.getRecordData()) {
                        if (item.getId().equals(record.getId())) {
                            item.setUpload(false);
                        }
                    }
//                    Logger.e("????==>%s", SLJsonUtils.toJsonString(tkPractice.getRecordData()));

                    transaction.update(DatabaseService.Collections.practice().document(record.getPraicticeId()), "recordData", tkPractice.getRecordData());
                } else {
                    throw new FirebaseFirestoreException("get practice failed",
                            FirebaseFirestoreException.Code.UNKNOWN);
                }


            } catch (Throwable throwable) {
                throw new FirebaseFirestoreException("get practice failed",
                        FirebaseFirestoreException.Code.UNKNOWN);
            }


            return null;
        }).addOnCompleteListener(btask -> {
            Logger.e("更新数据完成 是否成功==>%s", btask.getException() == null);
            if (btask.getException() != null) {
                Logger.e("错误==>%s", btask.getException());
            }

        });
    }


    public void deleteData(TKPractice.PracticeRecord record) {
        if (baseFragment != null) {
            baseFragment.showDialog("");
        }
        FirebaseFirestore.getInstance().runTransaction(transaction -> {
            try {
                TKPractice tkPractice = transaction.get(DatabaseService.Collections.practice().document(record.getPraicticeId())).toObject(TKPractice.class);
                if (tkPractice != null) {
                    tkPractice.getRecordData().removeIf(t -> t.getId().equals(record.getId()));


                    transaction.update(DatabaseService.Collections.practice().document(record.getPraicticeId()), "recordData", tkPractice.getRecordData());
                } else {
                    throw new FirebaseFirestoreException("get practice failed",
                            FirebaseFirestoreException.Code.UNKNOWN);
                }


            } catch (Throwable throwable) {
                throw new FirebaseFirestoreException("get practice failed",
                        FirebaseFirestoreException.Code.UNKNOWN);
            }


            return null;
        }).addOnCompleteListener(btask -> {
            if (baseFragment != null) {
                baseFragment.dismissDialog();
            }
            Logger.e("更新数据完成 是否成功==>%s", btask.getException() == null);
            if (btask.getException() != null) {
                SLToast.showError();
            } else {
                SLToast.success("Remove successfully");
                practice.getRecordData().removeIf(t -> t.getId().equals(record.getId()));
                adapter.notifyDataSetChanged();
                if (practice.getRecordData().size() == 0) {
                    dismiss();
                }
            }
        });
    }


}
