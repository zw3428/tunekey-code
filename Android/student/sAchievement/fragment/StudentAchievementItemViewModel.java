package com.spelist.tunekey.ui.student.sAchievement.fragment;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tunekey.R;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

public class StudentAchievementItemViewModel extends ItemViewModel<StudentAchievementViewModel> {

    public StudentAchievementItemViewModel(@NonNull StudentAchievementViewModel viewModel, int i) {
        super(viewModel);

        if (i == 1) {
            addMilestoneData();
        }
    }

    // practice
    public String duration = "3";
    public String session = "4";
    public String period = "Weekly";

    // milestone
    public String totalAchievements = "7";

    public class UIEventObservable {
        public SingleLiveEvent<ObservableList<ItemViewModel>> milestoneObserverData = new SingleLiveEvent<>();
    }
    public UIEventObservable uc = new UIEventObservable();

    public ObservableField<LinearLayoutManager> linearLayoutManager = new ObservableField<>();
    public ObservableList<ItemViewModel> milestoneDataList = new ObservableArrayList<>();
    public ItemBinding<ItemViewModel> itemMilestoneBinding
            = ItemBinding.of(new OnItemBind<ItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, ItemViewModel item) {
            itemMilestoneBinding.set(com.spelist.tunekey.BR.itemMilestoneViewModel, R.layout.item_milestone);
        }
    });

    private void addMilestoneData() {
        ItemViewModel item1 = new StudentAchievementMilestoneViewModel(this.viewModel, "July 13", 0, "Perfected C sharp!", "Great work on the C Sharp!  \n" +
                "Don't forget to pick the right chord");
        ItemViewModel item2 = new StudentAchievementMilestoneViewModel(this.viewModel, "July 15", 2, "20 hours practice!", "Really impressive how you kept pushing until you were able to nail the beat");
        ItemViewModel item3 = new StudentAchievementMilestoneViewModel(this.viewModel, "July 24", 2, "20 hours practice!", "Really impressive how you kept pushing until you were able to nail the beat");
        milestoneDataList.add(item1);
        milestoneDataList.add(item2);
        milestoneDataList.add(item3);
        uc.milestoneObserverData.setValue(milestoneDataList);
    }
}
