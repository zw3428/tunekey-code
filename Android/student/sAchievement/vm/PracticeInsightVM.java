package com.spelist.tunekey.ui.student.sAchievement.vm;

import android.annotation.SuppressLint;
import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.TimeUtils;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

/**
 * com.spelist.tunekey.ui.insights.vm
 * 2021/5/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PracticeInsightVM extends BaseViewModel {

    public ObservableField<String> total = new ObservableField<>("0");
    public ObservableField<String> sessions = new ObservableField<>("0");
    public ObservableField<Boolean> isShowValue = new ObservableField<>(true);
    public List<Double> timeChartData = new ArrayList<>();
    public List<Integer> sessionsChartData = new ArrayList<>();
    public List<TKPractice> practiceList = new ArrayList<>();
    public long rangeStartTime = TimeUtils.addDay(TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis(), -7);
    public long rangeEndTime = TimeUtils.getTwelveTimeOfDay(System.currentTimeMillis());

    public PracticeInsightVM(@NonNull @NotNull Application application) {
        super(application);
        initData();
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();

        Messenger.getDefault().register(this, MessengerUtils.STUDENT_PRACTICE_CHANGED, this::getPractice);
    }

    public UIEventObservable uc = new UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<Void> update = new SingleLiveEvent<>();
    }

    public void initData() {
        getPractice();
    }

    @SuppressLint("DefaultLocale")
    private void getPractice() {
        timeChartData.clear();
        sessionsChartData.clear();
        practiceList.clear();
        int daysBetween = TimeUtils.getDaysBetween(rangeStartTime, rangeEndTime);
        for (int i = 0; i <= daysBetween; i++) {
            timeChartData.add(0D);
            sessionsChartData.add(0);
        }
        List<TKPractice> practiceData = ListenerService.shared.studentData.getPracticeData();
        practiceList.addAll(practiceData.stream().filter(item -> {
            boolean isFilter = false;

            long time = item.getStartTime() * 1000L;
            if (time >= rangeStartTime && time <= rangeEndTime) {
                isFilter = true;
            }

            return isFilter;
        }).collect(Collectors.toList()));

        practiceList.sort((o1, o2) -> o1.getStartTime() - o2.getStartTime());
        double totalTimeLength = 0;
        int sessionCount = 0 ;
        for (TKPractice item : practiceList) {
            int index = TimeUtils.getDaysBetween(rangeStartTime, item.getStartTime() * 1000L);
            double timeLength = 0;
            if (index >= 0 && index < timeChartData.size()) {
                timeChartData.set(index, timeChartData.get(index) + item.getTotalTimeLength());
                if (item.getTotalTimeLength()>0){
                    sessionCount+=1;
                    sessionsChartData.set(index, sessionsChartData.get(index) + 1);
                }
                totalTimeLength += item.getTotalTimeLength();
            }
        }
        for (int i = 0; i < timeChartData.size(); i++) {
            double time = 0;
            if (timeChartData.get(i)/ 60D / 60D > 0) {
                if (timeChartData.get(i) / 60D / 60D < 0.1) {
                    time = 0.1;
                } else {
                    time = timeChartData.get(i) / 60D / 60D;
                }
            }
            timeChartData.set(i,time);
        }

        if (totalTimeLength/ 60D / 60D > 0) {
            if (totalTimeLength / 60D / 60D < 0.1) {
                totalTimeLength = 0.1;
            } else {
                totalTimeLength = totalTimeLength / 60D / 60D;
            }
        }
        if (totalTimeLength == 0) {
            total.set("0");
        } else {
            total.set(String.format("%.1f", totalTimeLength));
        }
        sessions.set(sessionCount + "");
        uc.update.call();
    }

}
