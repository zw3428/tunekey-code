package com.spelist.tunekey.ui.student.sAchievement.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.ui.student.sAchievement.fragment.StudentAchievementMilestoneViewModel;
import com.spelist.tunekey.utils.MessengerUtils;

import org.jetbrains.annotations.NotNull;

import java.util.HashMap;
import java.util.Map;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.bus.Messenger;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

/**
 * com.spelist.tunekey.ui.sAchievement.vm
 * 2021/6/2
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MilestonesInsightVM extends BaseViewModel {
    public ObservableField<String> totalAchievement = new ObservableField<>("");
    public ObservableField<String> topRated = new ObservableField<>("None");
    public String studentId = "";

    public MilestonesInsightVM(@NonNull @NotNull Application application) {
        super(application);
        initData();
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.PARENT_SELECT_KIDS_DONE, this::initData);
    }

    private void initData() {
        studentId = ListenerService.shared.studentData.getUser().getUserId();
        addSubscribe(
                UserService
                        .getInstance()
                        .getAchievementForStudent(UserService.getInstance().getCurrentUserId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            milestoneDataList.clear();
                            Map<String, Integer> map = new HashMap<>();
                            for (AchievementEntity datum : data) {
                                if (map.get(datum.getTypeString()) == null) {
                                    map.put(datum.getTypeString(), 1);
                                } else {
                                    map.put(datum.getTypeString(), map.get(datum.getTypeString()) + 1);
                                }
                                milestoneDataList.add(new StudentAchievementMilestoneViewModel(this, datum));
                            }
                            if (map.size()>0){
                                String topRated = "";
                                int topCount = 0;

                                for (Map.Entry<String, Integer> m : map.entrySet()) {
                                    if (m.getValue()>topCount){
                                        topCount=m.getValue();
                                        topRated = m.getKey();
                                    }
                                }
                                this.topRated.set(topRated);


                            }

                            totalAchievement.set(data.size() + "");
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    public ObservableList<StudentAchievementMilestoneViewModel> milestoneDataList = new ObservableArrayList<>();
    public ItemBinding<StudentAchievementMilestoneViewModel> itemMilestoneBinding
            = ItemBinding.of(new OnItemBind<StudentAchievementMilestoneViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, StudentAchievementMilestoneViewModel item) {
            itemMilestoneBinding.set(com.spelist.tunekey.BR.itemMilestoneViewModel, R.layout.item_milestone);
        }
    });

}
