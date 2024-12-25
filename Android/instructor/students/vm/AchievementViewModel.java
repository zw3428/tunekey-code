package com.spelist.tunekey.ui.teacher.students.vm;

import android.annotation.SuppressLint;
import android.app.Application;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.utils.MessengerUtils;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.utils.SnowFlakeShortUrl;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

public class AchievementViewModel extends ToolbarViewModel {

    public MutableLiveData<Boolean> addAchievement = new MutableLiveData<>();
    public MutableLiveData<Integer> filterAchievement = new MutableLiveData<>();
    public MutableLiveData<Boolean> refList = new MutableLiveData<>();

    public boolean isStudentLook = false;
    public StudentListEntity studentData = new StudentListEntity();
    public List<AchievementEntity> data = new ArrayList<>();


    private int type;

    public AchievementViewModel(@NonNull Application application) {
        super(application);

    }

    @SuppressLint("ResourceType")
    @Override
    public void initToolbar() {
        setNormalToolbar("Award");
        setRightFirstImgIcon(R.mipmap.ic_filter_primary);
        setRightFirstImgVisibility(View.VISIBLE);

        if (!isStudentLook){
            setRightSecondImgIcon(R.mipmap.add_primary);
            setRightSecondImgVisibility(View.VISIBLE);
        }


    }

    @Override
    protected void clickRightSecondImgButton() {
        super.clickRightSecondImgButton();
        addAchievement.setValue(true);
    }

    @Override
    protected void clickRightFirstImgButton() {
        super.clickRightFirstImgButton();
        filterAchievement.setValue(type);
    }

//    @Override
//    protected void clickLeftImgButton() {
//        super.clickLeftImgButton();
//        finish();
//    }

    //给RecyclerView添加ObservableList
    public ObservableList<AchievementItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<AchievementItemViewModel> itemBinding = ItemBinding.of(new OnItemBind<AchievementItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, AchievementItemViewModel item) {
            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.item_student_achievement);
        }
    });

    public void initData() {
        observableList.clear();
        try{
            data.sort((t0, t1) -> Integer.parseInt(t1.getCreateTime()) - Integer.parseInt(t0.getCreateTime()));
        }catch (Exception e){
        }
        for (int i = 0; i < data.size(); i++) {
            AchievementItemViewModel item = new AchievementItemViewModel(this, data.get(i));
            observableList.add(item);
        }
        if (studentData == null || studentData.getId().equals("")){
            setRightFirstImgVisibility(View.GONE);
            setRightSecondImgVisibility(View.GONE);
        }
    }

    public void filterAchievement(int type) {
        observableList.clear();
        this.type = type;
        try{
            data.sort((t0, t1) -> Integer.parseInt(t1.getCreateTime()) - Integer.parseInt(t0.getCreateTime()));
        }catch (Exception e){
        }
        for (int i = 0; i < data.size(); i++) {
            if (type == data.get(i).getType()) {
                AchievementItemViewModel item = new AchievementItemViewModel(this, data.get(i));
                observableList.add(item);
            }
        }
    }


    public void addAchievement(int type, String name, String desc) {
        AchievementEntity achievementEntity = new AchievementEntity();
        //获取随机ID
        String id = String.valueOf(SnowFlakeShortUrl.nextId());
        achievementEntity
                .setId(id)
                .setStudentId(studentData.getStudentId())
                .setTeacherId(studentData.getTeacherId())
                .setStudioId(studentData.getStudioId())
                .setScheduleId("")
                .setShouldDateTime(0)
                .setType(type)
                .setDate(System.currentTimeMillis() / 1000 + "")
                .setName(name)
                .setDesc(desc)
                .setCreateTime(System.currentTimeMillis() / 1000 + "")
                .setUpdateTime(System.currentTimeMillis() / 1000 + "");
        showDialog();
        Logger.e("=====开始上传=" + id);
        addSubscribe(UserService
                .getStudioInstance()
                .addAchievement(achievementEntity)
                .subscribe(status -> {
                    dismissDialog();
                    Messenger.getDefault().sendNoMsg(MessengerUtils.TEACHER_ACHIEVEMENT_LIST_CHANGE);

                    AchievementItemViewModel item = new AchievementItemViewModel(this, achievementEntity);
                    observableList.add(item);
                    data.add(achievementEntity);
                    refList.setValue(true);
                    SLToast.success("Save successfully!");
                }, throwable -> {
                    Logger.e("=====上传失败=" + throwable.getMessage());
                    dismissDialog();
                    SLToast.error("Save failed, please try again!");
                }));
    }


}
