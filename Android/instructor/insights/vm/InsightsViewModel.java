package com.spelist.tunekey.ui.teacher.insights.vm;

import android.annotation.SuppressLint;
import android.app.Application;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.HashMap;
import java.util.Map;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

public class InsightsViewModel extends ToolbarViewModel {

    public ObservableField<Boolean> isShowUploadPro = new ObservableField<>(false);
    //    public ViewPagerBindingAdapter adapter;
    public long rangeStartTime = TimeUtils.addDay(TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis(), -7);
    public long rangeEndTime = TimeUtils.getTwelveTimeOfDay(System.currentTimeMillis());
    public boolean isPro = false;
    public int insightsCount = 0;
    public int insightsLimitCount = 10;
    public boolean isAdd = false;

    public InsightsViewModel(@NonNull Application application) {
        super(application);
        initData();
    }

    private void initData() {
        getTeacherInfo();
    }


    private void getTeacherInfo() {
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_INFO_CHANGED, () -> {
            isPro = ListenerService.shared.teacherData.getTeacherInfoEntity().getMemberLevelId() == 2;
            initIsShowUploadPro();
        });
        if (ListenerService.shared.teacherData!=null){
            isPro = ListenerService.shared.teacherData.getTeacherInfoEntity().getMemberLevelId() == 2;
        }
        getInsightsCount();
    }

    private void getInsightsCount() {
        addSubscribe(
                UserService
                        .getInstance()
                        .getInsightsCount()
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            insightsCount = data;
                            initIsShowUploadPro();
                            addInsightsCount();
                        }, throwable -> {
                            insightsCount = 0;
                            initIsShowUploadPro();
                            Logger.e("==count====失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    private void addInsightsCount() {
        if (!isAdd) {
            isAdd = true;
            Map<String, Object> map = new HashMap<>();
            map.put("count", insightsCount + 1);
            DatabaseService.Collections.insightsCount()
                    .document(UserService.getInstance().getCurrentUserId())
                    .update(map)
                    .addOnCompleteListener(task -> {
                        Logger.e("======%s", "add成功");
                    });
        }
    }

    public void initIsShowUploadPro() {
        if (!isPro) {
            if (insightsCount > insightsLimitCount) {
                isShowUploadPro.set(true);
                uc.refIsShowUploadPro.setValue(true);
            } else {
                isShowUploadPro.set(false);
                uc.refIsShowUploadPro.setValue(false);
            }
        } else {
            isShowUploadPro.set(false);
            uc.refIsShowUploadPro.setValue(false);
        }


    }


    @SuppressLint("ResourceType")
    @Override
    public void initToolbar() {
        setTitleString("Insights");
        setRightFirstImgIcon(R.mipmap.ic_calendar);
        setRightFirstImgVisibility(View.VISIBLE);
    }

    @Override
    protected void clickRightFirstImgButton() {
        if (!isShowUploadPro.get()) {
            uc.clickCal.call();
        }
    }

    public class UIEventObservable {
        public SingleLiveEvent<Void> clickCal = new SingleLiveEvent<>();
        public SingleLiveEvent<Boolean> refIsShowUploadPro = new SingleLiveEvent<>();

    }

    public UIEventObservable uc = new UIEventObservable();


}
