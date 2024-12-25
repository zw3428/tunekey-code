package com.spelist.tunekey.ui.teacher.profile.fragments;

import android.app.Dialog;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.appsflyer.AFInAppEventParameterName;
import com.appsflyer.AFInAppEventType;
import com.appsflyer.AFPurchaseDetails;
import com.appsflyer.AFPurchaseType;
import com.appsflyer.AppsFlyerInAppPurchaseValidationCallback;
import com.appsflyer.AppsFlyerInAppPurchaseValidatorListener;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.attribution.AppsFlyerRequestListener;
import com.google.firebase.functions.FirebaseFunctions;
import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.dialog.FollowUsDialog;
import com.spelist.tunekey.customView.dialog.ProInfoDialog;
import com.spelist.tunekey.customView.dialog.ReferralCodeDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.studioEvent.StudioEventListAc;
import com.spelist.tunekey.databinding.ActivityProfileTeacherBinding;
import com.spelist.tunekey.entity.StudioInfoEntity;
import com.spelist.tunekey.notification.TKNotificationUtils;
import com.spelist.tunekey.ui.loginAndOnboard.selectStudioSize.SelectStudioSizeAc;
import com.spelist.tunekey.ui.studio.profile.myAccount.MyAccountAc;
import com.spelist.tunekey.databinding.ItemStudioEventListByProfileBinding;
import com.spelist.tunekey.entity.TKStudioEvent;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonTypeActivity;
import com.spelist.tunekey.ui.teacher.profileTeacher.EditProfileActivity;
import com.spelist.tunekey.ui.teacher.profileTeacher.ProfileTeacherViewModel;
import com.spelist.tunekey.ui.toolsView.FaqActivity;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerAdapter;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerHolder;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.utils.DeviceInfoUtils;
import me.jessyan.autosize.utils.AutoSizeUtils;
import retrofit2.http.HEAD;

/**
 * Author WHT
 * Description:
 * Date :2019-10-07
 */
public class ProfileFragment extends BaseFragment<ActivityProfileTeacherBinding, ProfileTeacherViewModel> {

    public Map<String, Object> map = new HashMap<>();
    public FragmentManager fragmentManager;
    private BillingClient billingClient;
    private BaseViewBindingRecyclerAdapter<TKStudioEvent> studioEventAdapter;
    private String LOG_TAG = "ProfileFragment";

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.activity_profile_teacher;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        try {
            if (!TKNotificationUtils.areNotificationsEnabled(getContext())) {
                // 创建一个 Handler 对象
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    // 这里放置你想要在 5 秒后执行的代码
                    // 例如：检查通知权限并引导用户去设置
                    Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "Notification permission", "We need notification access to provide you with timely updates and alerts. Would you like to enable notifications now?", "To setting", "Not now");
                    TextView leftButton1 = dialog.findViewById(R.id.left_button);
                    leftButton1.setOnClickListener(v -> {
                        dialog.dismiss();
                        TKNotificationUtils.openNotificationSettingsForApp(getContext());
                    });
                }, 1500); // 延时时间设置为 5000 毫秒（即 5 秒）
            }
        }catch (Exception e){
            Logger.e("检查订阅失败==>%s",e.getMessage());
        }


        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getContext());
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvLessonType.setLayoutManager(linearLayoutManager);

//        binding.swCancellation.setToggleOn();
//        binding.swCancellation.setOnToggleChanged(new SwitchButton.OnToggleChanged() {
//            @Override
//            public void onToggle(boolean on) {
//                if (on) {
//                    map.put("cancelLessonNotificationOpened", false);
//                } else {
//                    map.put("cancelLessonNotificationOpened", false);
//                }
//                viewModel.updateNotification(map);
//            }
//        });

        binding.swMakeup.setToggleOn();
        binding.swMakeup.setOnToggleChanged(on -> {
            if (on) {
                map.put("rescheduleConfirmedNotificationOpened", true);
            } else {
                map.put("rescheduleConfirmedNotificationOpened", false);
            }
            viewModel.updateNotification(map);
        });

//        binding.swReminder.setToggleOn();
        binding.swReminder.setOnToggleChanged(on -> {
            if (on) {
                binding.linReminder.setVisibility(View.VISIBLE);
                map.put("reminderOpened", true);
            } else {
                binding.linReminder.setVisibility(View.GONE);
                map.put("reminderOpened", false);
            }
            viewModel.updateNotification(map);
        });

        binding.checkMin15.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityMin15.set(isChecked);
                viewModel.getReminderTime(5);
            }

        });
        binding.checkMin30.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityMin30.set(isChecked);
                viewModel.getReminderTime(10);
            }
        });
        binding.checkHour1.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour1.set(isChecked);
                viewModel.getReminderTime(15);
            }
        });
        binding.checkHours2.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour2.set(isChecked);
                viewModel.getReminderTime(30);
            }
        });
        binding.checkHour3.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour3.set(isChecked);
                viewModel.getReminderTime(60);
            }
        });
        binding.checkHour4.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour4.set(isChecked);
                viewModel.getReminderTime(120);
            }
        });
        binding.checkHour5.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour5.set(isChecked);
                viewModel.getReminderTime(180);
            }
        });
        binding.checkDay1.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityDay1.set(isChecked);
                viewModel.getReminderTime(1440);
            }
        });
        binding.studioType.setOnClickListener(view -> {
            int oldSelect = -1;
            if (SLCacheUtil.getStudioInfo() != null) {
                String studioType = SLCacheUtil.getStudioInfo().getStudioType();
                if (studioType.equals(StudioInfoEntity.StudioType.singleInstructor)) {
                    oldSelect = 0;
                } else if (studioType.equals(StudioInfoEntity.StudioType.multipleInstructors)) {
                    oldSelect = 1;
                } else if (studioType.equals(StudioInfoEntity.StudioType.multipleStudios)) {
                    oldSelect = 2;
                }
            }
            Bundle bundle = new  Bundle();
            bundle.putBoolean("isFromProfile", true);
            bundle.putInt("oldType", oldSelect);
            startActivity(SelectStudioSizeAc.class, bundle);
        });
        initBilling();
    }

    @Override
    public void initView() {
        binding.versionTv.setOnClickListener(v -> {
           if (!viewModel.isLatestVersion){
               DeviceInfoUtils.openGooglePlay(getContext());
           }
        });
        binding.myProfile.setOnClickListener(view -> {
            Bundle bundle = new Bundle();
            bundle.putBoolean("isStudioTeacher", true);
            startActivity(MyAccountAc.class, bundle);
        });
        binding.studioEventsRecyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        studioEventAdapter = new BaseViewBindingRecyclerAdapter<TKStudioEvent>(getActivity(), viewModel.studioEventData, R.layout.item_studio_event_list_by_profile) {
            @Override
            public void convert(BaseViewBindingRecyclerHolder holder, TKStudioEvent item, int position, boolean isScrolling) {
                if (holder.getBinding() instanceof ItemStudioEventListByProfileBinding) {
                    ItemStudioEventListByProfileBinding binding = (ItemStudioEventListByProfileBinding) holder.getBinding();
                    binding.dayTv.setText(TimeUtils.timeFormat((long) item.getStartTime(), "dd"));
                    binding.monthTv.setText(TimeUtils.timeFormat((long) item.getStartTime(), "MMM"));

                    binding.titleTv.setText(item.getTitle());
                    if (item.getDescription().length() == 0) {
                        binding.descriptionTv.setVisibility(View.GONE);
                    } else {
                        binding.descriptionTv.setVisibility(View.VISIBLE);
                    }
                    binding.descriptionTv.setText(item.getDescription());

                    binding.timeTv.setText(item.getTimeString());
                    binding.lineView.setVisibility(position == viewModel.studioEventData.size() - 1 ? View.GONE : View.VISIBLE);
                    binding.mainLayout.setOnClickListener(view -> startActivity(StudioEventListAc.class));
                }
            }
        };
        binding.studioEventsRecyclerView.setAdapter(studioEventAdapter);

    }

    @Override
    public void initViewObservable() {
        viewModel.uc.refreshStudioData.observe(this, unused -> {
            if (viewModel.studioData!=null){
                binding.totalLayout.setBackground(viewModel.studioData.getStudioProfileFrame());
            }
        });

        viewModel.uc.refreshStudioEventsData.observe(this, aVoid -> studioEventAdapter.refreshData(viewModel.studioEventData));
        viewModel.uc.eventChange.observe(this, event -> {
            binding.eventButtonText.setTextColor(Color.parseColor(event.getButtonTitleColor()));
            binding.eventButton.setBackgroundColor(Color.parseColor(event.getButtonBackgroundColor()));
            ViewGroup.LayoutParams layoutParams = binding.eventImage.getLayoutParams();
            layoutParams.width = AutoSizeUtils.pt2px(getContext(), (float) event.getImageSize().getWidth());
            layoutParams.height = AutoSizeUtils.pt2px(getContext(), (float) event.getImageSize().getHeight());
            binding.eventImage.setLayoutParams(layoutParams);
        });
        viewModel.uc.clickContact.observe(this, unused -> {
            Dialog dialog = new Dialog(getActivity(), R.style.BottomDialog);

            View contentView = LayoutInflater.from(getActivity()).inflate(R.layout.dialog_contact, null);
            contentView.findViewById(R.id.messageLayout).setOnClickListener(v -> {
                viewModel.getSupportGroupConversation();
                dialog.dismiss();
            });
            contentView.findViewById(R.id.textLayout).setOnClickListener(v -> {
                try {
                    Intent intent = new Intent(Intent.ACTION_SENDTO);
                    intent.setData(Uri.parse("smsto:14088688371"));           //设置发送的号码
                    intent.putExtra("sms_body", "");
                    startActivity(intent);
                    dialog.dismiss();
                } catch (Throwable e) {
                    SLToast.error("Failed to open SMS, please try again!");
                }
            });
            contentView.findViewById(R.id.emailLayout).setOnClickListener(v -> {
                String[] TO = {"support@tunekey.app"};
                Intent emailIntent = new Intent(Intent.ACTION_SEND);
                emailIntent.setData(Uri.parse("mailto:"));
                emailIntent.setType("text/plain");
                emailIntent.putExtra(Intent.EXTRA_EMAIL, TO);

                try {
                    startActivity(emailIntent);
                } catch (android.content.ActivityNotFoundException ex) {
                    SLToast.error("Failed to open email, please try again!");
                }
                dialog.dismiss();
            });
            contentView.findViewById(R.id.followLayout).setOnClickListener(v -> {

                viewModel.getFollowUsData();
                //youtube
//                toApp("https://www.youtube.com/channel/UCxpG0ByYyvLadNKrukECAgw","https://www.youtube.com/channel/UCxpG0ByYyvLadNKrukECAgw","com.google.android.youtube");
                //instagram
//                toApp("https://www.instagram.com/tunekeyapp/","https://www.instagram.com/tunekeyapp/","com.instagram.android");
                //facebook
//                toApp("fb://page/105654964705036","com.facebook.katana");
                //Twitter
//                toApp("https://twitter.com/TunekeyA","twitter://user?screen_name=TunekeyA","com.twitter.android");
                // Tik tok
//                toApp("https://www.tiktok.com/@tunekeyapp","https://www.tiktok.com/@tunekeyapp","com.zhiliaoapp.musically");
//               toApp("https://tunekey.app","https://tunekey.app","");

                dialog.dismiss();
            });

            contentView.findViewById(R.id.cancel).setOnClickListener(v -> {
                dialog.dismiss();
            });
            dialog.setContentView(contentView);
            ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
            layoutParams.width = getResources().getDisplayMetrics().widthPixels;
            contentView.setLayoutParams(layoutParams);
            dialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
            dialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
            dialog.show();//显示弹窗
        });
        viewModel.uc.showFollow.observe(this, followUs -> {
            FollowUsDialog dialog = new FollowUsDialog(getActivity(), followUs.getResources());
            BasePopupView popupView = new XPopup.Builder(getActivity())
                    .isDestroyOnDismiss(true)
                    .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                    .dismissOnTouchOutside(false)
                    .asCustom(dialog)
                    .show();
            dialog.setClickListener(data -> {
                popupView.dismiss();
                toApp(data.getFailedUrl(), data.getAndroidIntentUrl(), data.getAndroidPackageName());
            });

        });
        viewModel.uc.refreshAvatar.observe(this, time -> {
            getActivity().runOnUiThread(() -> binding.avatarView.refreshAvatar(time));
        });
        viewModel.uc.clickReferral.observe(this, data -> {
            ReferralCodeDialog dialog = new ReferralCodeDialog(getContext(), data);
            BasePopupView popupView = new XPopup.Builder(getContext())
                    .isDestroyOnDismiss(true)
                    .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                    .dismissOnTouchOutside(true)
                    .asCustom(dialog)
                    .show();
            dialog.onClick = () -> {
                popupView.dismiss();
                Intent sendIntent = new Intent();
                sendIntent.setAction(Intent.ACTION_SEND);
                sendIntent.putExtra(Intent.EXTRA_TEXT, "TuneKey, a music education artifact, tap link to start.\n\n" + data.getDeepLink());
                sendIntent.setType("text/plain");
                Intent shareIntent = Intent.createChooser(sendIntent, null);
                startActivity(shareIntent);
            };
        });

        viewModel.isReminderOpened.observe(this, isReminderOpened -> {
            binding.swReminder.setToggle(isReminderOpened);
            binding.linReminder.setVisibility(isReminderOpened ? View.VISIBLE : View.GONE);
        });

        viewModel.uc.clickAddLessonType.observe(this, aVoid -> {
            Intent intent = new Intent(getActivity(), LessonTypeActivity.class);
            intent.putExtra("type",1);
            startActivity(intent);
        });

        viewModel.uc.linEditProfile.observe(this, aVoid -> {
            Bundle bundle = new Bundle();
            bundle.putSerializable("studioData", viewModel.studioData);
            startActivity(EditProfileActivity.class, bundle);
        });

        viewModel.uc.linPro.observe(this, aVoid -> showProDialog());
        viewModel.uc.clickFAQ.observe(this, unused -> startActivity(FaqActivity.class));
    }

    public void toApp(String url, String intentUrl, String packageName) {
        Intent intent = null;
        if (!packageName.equals("")) {
            try {
                intent = new Intent(Intent.ACTION_VIEW);
                intent.setPackage(packageName);
                intent.setData(Uri.parse(intentUrl));
                startActivity(intent);

            } catch (Throwable e) {
                intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse(url));
                startActivity(intent);
            }
        } else {
            try {
                intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse(url));
                startActivity(intent);
            } catch (Throwable e) {
                SLToast.error("Failed to open app, please try again!");
            }
        }

    }


    public void showProDialog() {
        Logger.e("????==>%s","????");
        ProInfoDialog dialog = new ProInfoDialog(getContext(), viewModel.teacherInfoEntity);
        BasePopupView popupView = new XPopup.Builder(getContext())
                .isDestroyOnDismiss(true)
                .autoFocusEditText(false)
                .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(false)
                .asCustom(dialog)
                .show();
        dialog.listener = new ProInfoDialog.Listener() {
            @Override
            public void isShowLoading(boolean isShow) {
                if (isShow) {
                    showDialog("Loading...");
                } else {

                    dismissDialog();
                }
            }

            @Override
            public void upgradePro() {
                dialog.dismiss();
                showDialog("Loading");
                startConnection();
            }

            @Override
            public void cancelPro() {
                Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "PRO subscription ended", "PRO will stop and you won\\'t be charged on next renewal day.\n\nAs a non-PRO user, you still can enjoy free Tunekey app with 5 student accounts and limited access.\n\nYour subscription is our motivation to improve!", "Back", "Confirm");
                dialog.findViewById(R.id.right_button).setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        dialog.dismiss();
                        showDialog("Loading...");
                        FirebaseFunctions
                                .getInstance()
                                .getHttpsCallable("subscriptionCancel")
                                .call()
                                .addOnCompleteListener(task -> {
                                    dismissDialog();
                                    if (task.isSuccessful()) {
                                        Logger.e("Cancel成功");
                                        SLToast.success("Cancel successfully!");
                                    } else {
                                        Logger.e("Cancel失败" + task.getException().getMessage());
                                        SLToast.showError();
                                    }
                                });
                    }
                });
            }
        };
    }

    private void initBilling() {
        billingClient = BillingClient.newBuilder(getActivity())
                .setListener((billingResult, list) -> {
                    Logger.e("billingResult:%s", SLJsonUtils.toJsonString(billingResult));
                    Logger.e("Purchase:%s", SLJsonUtils.toJsonString(list));
                    if (list != null && list.size() > 0) {
                        handleConsumedPurchases(list.get(0));
                    } else {
                        dismissDialog();
                    }
                })
                .enablePendingPurchases()
                .build();
    }

    private void handleConsumedPurchases(Purchase purchase) {
        Logger.e("%s", purchase.getPurchaseToken());
        AcknowledgePurchaseParams build = AcknowledgePurchaseParams
                .newBuilder()
                .setPurchaseToken(purchase.getPurchaseToken())
                .build();
        billingClient.acknowledgePurchase(build, billingResult -> {
            Logger.e("billingResult:%s", SLJsonUtils.toJsonString(billingResult));
            billingClient.queryPurchasesAsync(BillingClient.SkuType.SUBS, (billingResult1, list) -> {
                Logger.e("billingResult1:%s", SLJsonUtils.toJsonString(billingResult1.getDebugMessage()));
                Logger.e("list:%s", SLJsonUtils.toJsonString(list.get(0)));
                if (list.size() > 0) {
                    Purchase data = list.get(0);
                    String purchaseToken = data.getPurchaseToken();
                    long purchaseTime = data.getPurchaseTime() / 1000L;
                    Map<String, Object> map = new HashMap<>();
                    map.put("memberLevelId", 2);
                    map.put("autoSubscribeType", 1);
                    map.put("firstPaymentTime", purchaseTime + "");
                    map.put("nextPaymentTime", purchaseTime + (30L * 86400L));
                    map.put("thisPaymentTime", purchaseTime + "");
                    map.put("purchaseToken", purchaseToken);
                    DatabaseService.Collections.teacher()
                            .document(UserService.getInstance().getCurrentUserId())
                            .update(map)
                            .addOnCompleteListener(task -> {
                                dismissDialog();
                                Messenger.getDefault().send(2, MessengerUtils.CHANGE_MEMBER_LEVEL_ID);

                                Logger.e("修改是否成功: %s", task.getException() == null);
                            });

//                    AFPurchaseDetails purchaseDetails = new AFPurchaseDetails(
//                            AFPurchaseType.SUBSCRIPTION, //Purchase type
//                            data.getPurchaseToken(), // Purchase token
//                            "subscriptions", // Product ID
//                            "9.99", // Price
//                            "USD"); // Currency
//                    Map<String, String> purchaseAdditionalDetails = new HashMap<>();
//
//// Adding some key-value pairs to the map
//                    purchaseAdditionalDetails.put("firstDetail", "something");
//                    purchaseAdditionalDetails.put("secondDetail", "nice");
//                    AppsFlyerLib.getInstance().validateAndLogInAppPurchase(
//                            purchaseDetails,
//                            purchaseAdditionalDetails, //optional
//                            new AppsFlyerInAppPurchaseValidationCallback() {
//                                @Override
//                                public void onInAppPurchaseValidationFinished(@NonNull Map<String, ?> validationFinishedResult) {
//                                    Log.e(LOG_TAG, "Purchase validation response arrived");
//                                    Boolean validationResult = (Boolean) validationFinishedResult.get("result");
//
//                                    if (validationResult == true) {
//                                        Log.e(LOG_TAG, "Purchase validated successfully");
//                                        // Add here code following successful purchase validation
//                                    } else {
//                                        @NonNull Map<String, ?> error_data = (Map<String, ?>) validationFinishedResult.get("error_data");
//                                        Log.e(LOG_TAG, "Purchase validated was not validated due to " + error_data.get("message"));
//                                        // Add here code when validation was not successful
//                                    }
//                                }
//
//                                @Override
//                                public void onInAppPurchaseValidationError(@NonNull Map<String, ?> validationErrorResult) {
//                                    Log.e(LOG_TAG, "Purchase validation returned error: " + validationErrorResult.get("error_message"));
//                                }
//                            }
//                    );

//                    Log.d(LOG_TAG, "Purchase successful!");

                    Map<String, Object> eventValues1 = new HashMap<String, Object>();
                    eventValues1.put(AFInAppEventParameterName.CURRENCY, "USD");
                    eventValues1.put(AFInAppEventParameterName.REVENUE, 9.9);
                    AppsFlyerLib.getInstance().logEvent(getContext(),
                            AFInAppEventType.PURCHASE, eventValues1, new AppsFlyerRequestListener() {
                                @Override
                                public void onSuccess() {
                                    Log.e(LOG_TAG, "Event sent successfully");
                                }
                                @Override
                                public void onError(int i, @NonNull String s) {
                                    Log.e(LOG_TAG, "Event failed to be sent:\n" +
                                            "Error code: " + i + "\n"
                                            + "Error description: " + s);
                                }
                            });
                    AppsFlyerLib.getInstance().registerValidatorListener(getContext(),new
                            AppsFlyerInAppPurchaseValidatorListener() {
                                public void onValidateInApp() {
                                    Log.e(LOG_TAG, "Purchase validated successfully " );
                                }
                                public void onValidateInAppFailure(String error) {
                                    Log.e(LOG_TAG, "Purchase validated called " +error);

                                }
                            });
                    Map<String, String> eventValues = new HashMap<>();
                    eventValues.put("some_parameter", "some_value");
                    AppsFlyerLib.getInstance().validateAndLogInAppPurchase(getActivity(),
                            "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvYL7vWONxKXP42szNducSiiQJVickA+2cjlD2JXMs5oZjux8UGuGPw3HvnlEUiheqniuzSBi27bhh9KU/gvLLbOSD5Dm9BmAjC4uNH19ybm3AVIBBRJi//Bv1+u6oqxL92VtsWsHMVn8GaKMq4Xkp3D8kqUWKoX2baVk26k8ojpUSsfJZXKJrqga3ZQTFqf9oSGve0nYs+d8t8DXAacQLUgiUIKxG4WW+c7zhCl2lT6Yu1Hjp5UfI31MI3NZSzKkqoSwAaX6RNIzpmUftiZmlUj2JP0cOLFg9vKiYBO+6w7VYPfrw04qKZT7RgnuTrbnG985quB1Wto3HfZo7LBVQwIDAQAB",
                            purchase.getSignature(),
                            purchase.getOriginalJson(),
                            "9.99",
                            "USD",
                            eventValues);
                }
            });

        });
    }

    /**
     * 链接商店 购买商品
     */
    private void startConnection() {
        billingClient.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingServiceDisconnected() {
                Logger.e("%s", "onBillingServiceDisconnected");
            }

            @Override
            public void onBillingSetupFinished(@NonNull @NotNull BillingResult billingResult) {
                Logger.e("onBillingSetupFinished:%s", SLJsonUtils.toJsonString(billingResult.getDebugMessage()));
                queryAvailableProducts();
            }
        });
    }
    private ProductDetails skuDetails;
    private void queryAvailableProducts() {
        List<String> skuList = new ArrayList<>();
        skuList.add("subscriptions");
        List<QueryProductDetailsParams.Product> productList = new ArrayList<>();
        for (String sku : skuList) {
            productList.add(QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(sku)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build());
        }
        QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
                .setProductList(productList)
                .build();
        billingClient.queryProductDetailsAsync(params, (billingResult, productDetailsList) -> {
            Logger.e("BillingResult%s", SLJsonUtils.toJsonString(billingResult));
            if (productDetailsList == null || productDetailsList.isEmpty()) {
                dismissDialog();
                return;
            }

            Logger.e("ProductDetails:%s", SLJsonUtils.toJsonString(productDetailsList.get(0)));
//            ProductDetails productDetails1 = productDetailsList.get(0);
            skuDetails = productDetailsList.get(0);
            Logger.e("1==>%s",1);
            ProductDetails productDetails = productDetailsList.get(0);
            Logger.e("2==>%s",2);
            Logger.e("ProductDetails: %s", SLJsonUtils.toJsonString(productDetails));
            String obfuscatedAccountId = UserService.getInstance().getCurrentUserId();
            if (obfuscatedAccountId == null || obfuscatedAccountId.isEmpty()) {
                Logger.e("ObfuscatedAccountId is null or empty");
                dismissDialog();
                return;
            }
            Logger.e("ObfuscatedAccountId: %s", obfuscatedAccountId);

            BillingFlowParams.ProductDetailsParams build = BillingFlowParams.ProductDetailsParams.newBuilder()
                    .setProductDetails(productDetails)
                    .setOfferToken(productDetails.getSubscriptionOfferDetails().get(0).getOfferToken())
                    .build();
            Logger.e("ProductDetailsParamsList: %s",build);
            List<BillingFlowParams.ProductDetailsParams> productDetailsParamsList = Collections.singletonList(build);

            BillingFlowParams billingFlowParams = BillingFlowParams.newBuilder()
                    .setObfuscatedAccountId(UserService.getInstance().getCurrentUserId())
                    .setProductDetailsParamsList(productDetailsParamsList)
                    .build();
            Logger.e("3==>%s",3);

            BillingResult launchBillingResult = billingClient.launchBillingFlow(getActivity(), billingFlowParams);
            Logger.e("responseCode:%s", launchBillingResult.getResponseCode(), BillingClient.BillingResponseCode.OK);
        });


//        SkuDetailsParams.Builder params = SkuDetailsParams.newBuilder();
//
//        params.setSkusList(skuList).setType(BillingClient.SkuType.SUBS);
//        billingClient.querySkuDetailsAsync(params.build(),
//                (billingResult, skuDetailsList) -> {
//                    // Process the result.
//                    Logger.e("BillingResult%s", SLJsonUtils.toJsonString(billingResult));
//                    if (skuDetailsList == null) {
//                        dismissDialog();
//                        return;
//                    }
//                    if (skuDetailsList.size() > 0) {
//                        Logger.e("SkuDetails:%s", SLJsonUtils.toJsonString(skuDetailsList.get(0)));
//                        skuDetails = skuDetailsList.get(0);
//                        BillingFlowParams billingFlowParams = BillingFlowParams.newBuilder()
//                                .setObfuscatedAccountId(UserService.getInstance().getCurrentUserId())
//                                .setSkuDetails(skuDetails)
//                                .build();
//                        int responseCode = billingClient.launchBillingFlow(getActivity(), billingFlowParams).getResponseCode();
//                        Logger.e("responseCode:%s", responseCode, BillingClient.BillingResponseCode.OK);
//
//
//                    } else {
//                        dismissDialog();
//                    }
//
//                });

    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (billingClient.isReady()) {
            billingClient.endConnection();
        }
    }
}
