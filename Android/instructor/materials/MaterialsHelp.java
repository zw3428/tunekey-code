package com.spelist.tunekey.ui.teacher.materials;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.view.View;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;

import com.lxj.xpopup.XPopup;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.teacher.materials.activity.PreviewPdfActivity;
import com.spelist.tunekey.ui.teacher.materials.dialog.PlayAudioDialog;
import com.spelist.tunekey.ui.toolsView.TKWebViewAc;
import com.spelist.tunekey.ui.toolsView.videoPlayer.VideoPlayerActivity;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLImageUtils;
import com.tbruyelle.rxpermissions2.RxPermissions;
import com.wanglu.photoviewerlibrary.PhotoViewer;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.utils.ToastUtils;

/**
 * com.spelist.tunekey.ui.materials
 * 2020/12/29
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MaterialsHelp {
    public static void clickMaterial(Map<String, Object> map, FragmentActivity activity, Fragment context) {
        MaterialEntity entity = (MaterialEntity) map.get("data");
        View view = (View) map.get("view");
        String url = entity.getUrl();
        String minPicUrl = entity.getMinPictureUrl();
        String name = entity.getName();
        if (entity.getStatus() == -1) {
            activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(url))));
            return;
        }
        switch (entity.getType()) {
            case -2:
                break;
            case -1:
                break;
            case 0:
                break;
            case 1:
                ImageView imageView = (ImageView) map.get("view");
                assert imageView != null;
                if (url != null) {
                    PhotoViewer.INSTANCE
                            .setClickSingleImg(url, imageView, ContextCompat.getDrawable(activity, R.mipmap.image_share))
                            .setShowImageViewInterface(SLImageUtils::loadImage)
                            .setOnClickShareListener(iamge -> {
                                //点击到了分享
                                Logger.e("点击到了分享==>");
                                try {
                                    Bitmap bitmap = ((BitmapDrawable) iamge.getDrawable()).getBitmap();
                                    Uri uri = Uri.parse(MediaStore.Images.Media.insertImage(activity.getContentResolver(), bitmap, null, null));
                                    shareImage(uri, activity);
                                } catch (Throwable e) {
                                    Logger.e("分享图片失败==>%s", e.getMessage());
                                }


                            })
                            .start(context);
                } else {
                    ToastUtils.showShort("Image's url is empty!");
                }
                break;
            case 2:
            case 14:
            case 13:
            case 15:
            case 12:
            case 16:
            case 11:
            case 17:
            case 10:
            case 18:
            case 8:
            case 3:


                activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(url))));
                break;
            case 4:
                Logger.e("======我是录音");
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
                                PlayAudioDialog playPracticeDialog = new PlayAudioDialog(activity,activity, entity);
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

                break;
            case 5:

                Class<?> AimActivityVideo = VideoPlayerActivity.class;
                FuncUtils.goToVideoPlayer(activity, view, AimActivityVideo, url, name, minPicUrl);
                break;
            case 6:
//                Class<?> AimActivityYouTube = YouTubeVideoPlayerActivity.class;
//                FuncUtils.goToVideoPlayer(activity, view, AimActivityYouTube, url, name, minPicUrl);
                //根据url 跳转到系统浏览器
                activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(url))));

                break;
            case 7:
//                Uri uri = Uri.parse(url);
//                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
//                activity.startActivity(intent);

//                activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(url))));

                Intent intent = new Intent(activity, TKWebViewAc.class);
                intent.putExtra("url", url);
                intent.putExtra("title", entity.getName());
                activity.startActivity(intent);

                break;
            case 9:
                Intent intent1 = new Intent(activity, PreviewPdfActivity.class);
                intent1.putExtra("url", url);
                activity.startActivity(intent1);
                break;

        }
    }

    public static void clickMaterial(Map<String, Object> map, AppCompatActivity activity) {
        MaterialEntity entity = (MaterialEntity) map.get("data");
        View view = (View) map.get("view");
//        Logger.e("======%s", SLJsonUtils.toJsonString(entity));

        String url = entity.getUrl();
        Logger.e("======%s", url);
        String minPicUrl = entity.getMinPictureUrl();
        String name = entity.getName();
        switch (entity.getType()) {
            case -2:
                break;
            case -1:
                break;
            case 0:
                break;
            case 1:
                ImageView imageView = (ImageView) map.get("view");
                assert imageView != null;
                if (url != null) {
                    PhotoViewer.INSTANCE
                            .setClickSingleImg(url, imageView, ContextCompat.getDrawable(activity, R.mipmap.share))
                            .setShowImageViewInterface((view2, url1) -> SLImageUtils.loadImage(view2, url1))
                            .setOnClickShareListener(iamge -> {
                                //点击到了分享
                                Logger.e("点击到了分享1==>");
                                try {
                                    Bitmap bitmap = ((BitmapDrawable) iamge.getDrawable()).getBitmap();
                                    Uri uri = Uri.parse(MediaStore.Images.Media.insertImage(activity.getContentResolver(), bitmap, null, null));
                                    shareImage(uri, activity);
                                } catch (Throwable e) {
                                    Logger.e("分享图片失败==>%s", e.getMessage());
                                }

                            })
                            .start(activity);
                } else {
                    ToastUtils.showShort("Image's url is empty!");
                }
                break;
            case 2:
            case 14:
            case 13:
            case 15:
            case 12:
            case 16:
            case 11:
            case 17:
            case 10:
            case 18:
            case 8:
            case 3:
                activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(url))));
                break;
            case 4:
                Logger.e("======我是录音");
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
                                PlayAudioDialog playPracticeDialog = new PlayAudioDialog(activity,activity, entity);
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
                break;
            case 5:

                Class<?> AimActivityVideo = VideoPlayerActivity.class;
                FuncUtils.goToVideoPlayer(activity, view, AimActivityVideo, url, name, minPicUrl);
                break;
            case 6:
//                Class<?> AimActivityYouTube = YouTubeVideoPlayerActivity.class;
//                FuncUtils.goToVideoPlayer(activity, view, AimActivityYouTube, url, name, minPicUrl);
                activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(url))));

                break;
            case 7:
//                Uri uri = Uri.parse(url);
//                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
//                activity.startActivity(intent);
//                activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(url))));
                Intent intent = new Intent(activity, TKWebViewAc.class);
                intent.putExtra("url", url);
                intent.putExtra("title", entity.getName());
                activity.startActivity(intent);
                break;
            case 9:
                Intent intent1 = new Intent(activity, PreviewPdfActivity.class);
                intent1.putExtra("url", url);
                activity.startActivity(intent1);
                break;

        }
    }

    public static void shareImage(Uri uri, Activity activity) {
        Intent intent = new Intent();
        intent.setAction(Intent.ACTION_SEND);
        intent.setType("image/*");
        intent.putExtra(Intent.EXTRA_STREAM, uri);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        activity.startActivity(intent);
    }

    public static String checkUrl(String url) {
        String checkUrl = "";
        if (url.contains("http")) {
            checkUrl = url;
        } else {
            checkUrl = "http://" + url;
        }
        return checkUrl;
    }

    public static enum UploadType {
        NONE, GOOGLE_PHOTO, GOOGLE_DRIVE, AUDIO
    }

    public static class MaterialsCatalogueIndex {
        public int start = 0;
        public int end = 0;

        public int getStart() {
            return start;
        }

        public MaterialsCatalogueIndex setStart(int start) {
            this.start = start;
            return this;
        }

        public int getEnd() {
            return end;
        }

        public MaterialsCatalogueIndex setEnd(int end) {
            this.end = end;
            return this;
        }
    }
}
