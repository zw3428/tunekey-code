package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.TimeUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.StudentListEntity;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

public class StudentDetailActivityFragmentViewModel extends ToolbarViewModel {
    private int studentAchievementSize;
    private String studentId = "";
    public ObservableField<String> total = new ObservableField<>();
    public ObservableField<String> lastDesc = new ObservableField<>();
    public ObservableField<String> top = new ObservableField<>();
    public ObservableField<String> notes = new ObservableField<>();
    public ObservableField<String> notesDate = new ObservableField<>();
    private List<StudentListEntity> studentListEntities = new ArrayList<>();



    public StudentDetailActivityFragmentViewModel(@NonNull Application application) {
        super(application);
    }

    public StudentDetailActivityFragmentViewModel.UIClickObservable uc = new StudentDetailActivityFragmentViewModel.UIClickObservable();

    @Override
    public void initToolbar() {

    }


    public void setDate(StudentListEntity studentListEntity){
        this.studentId = studentListEntity.getStudentId();
        getLessonSchedule();
    }

    public class UIClickObservable {
        public SingleLiveEvent<Void> linPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> linAchievement = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> linNotes = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> linMaterials = new SingleLiveEvent<>();

    }

    public BindingCommand linPractice = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.linPractice.call();
        }
    });

    public BindingCommand linAchievement = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.linAchievement.call();
        }
    });
    public BindingCommand linNotes = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.linNotes.call();
        }
    });
    public BindingCommand linMaterials = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.linMaterials.call();
        }
    });

    public void getStudentList() {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getStudentListForTeacher(false)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(value -> {
                            studentListEntities = value;
                            getTeacherAchievement();
                        }, throwable ->

                        {
                            dismissDialog();
                        }));
    }

    public void getTeacherAchievement() {

//        addSubscribe(
//                UserService
//                        .getInstance()
//                        .getAchievementForTeacher(false)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(value -> {
//                            dismissDialog();
//                            Map<String, Integer> map = new HashMap();
//
//                            //教师的achievementList 和学生列表 计算出每个学生有多少个achievement
//                            for (int i = 0; i < value.size(); i++) {
//                                for (int j = 0; j < studentListEntities.size(); j++) {
//                                    if (value.get(i).getStudentId().equals(studentListEntities.get(j).getStudentId())) {
//                                        if (map.containsKey(value.get(i).getStudentId())) {
//                                            map.put(value.get(i).getStudentId(), map.get(value.get(i).getStudentId()) + 1);
//                                        } else {
//                                            map.put(value.get(i).getStudentId(), 1);
//                                        }
//                                    }
//                                }
//                            }
//                            //map{pdlWWnn0fVgxkmDWTbjxvMEhY4B3=9, ZfEineOYzEZp3JAPHVgvlkk8wdj1=6}
//                            //计算学生的排名 冒泡排序之后获取名次
//                            LinkedHashMap<String, Integer> hashmap = mapSort(map);
//                            int Ranking = 0;
//                            for (int i = 0; i < hashmap.size(); i++) {
//                                for (String key : map.keySet()) {
//                                    if (key.equals(studentId)) {
//                                        Ranking = i + 1;
//                                    }
//                                }
//                            }
//                            // 用排名除以总人数
//                            if (hashmap.size() != 0) {
//                                top.set(String.valueOf(Ranking / hashmap.size() * 100) + "%");
//                            }
//                            getAchievementList(studentId, false);
//                        }, throwable -> {
//                            Logger.e("======" + throwable.getMessage());
//                            dismissDialog();
//                        }));
    }

    public void getAchievementList(String studentId, boolean isOnlyCache) {

        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getAchievementForStudent(studentId, isOnlyCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(value -> {
                            studentAchievementSize = value.size();
                            total.set(studentAchievementSize + " badges");
                            lastDesc.set(value.get(0).getDesc());
                            dismissDialog();
                        }, throwable -> {
                            Logger.e("======" + throwable.getMessage());
                            dismissDialog();
                        }));


    }

    /**
     * map的冒泡排序
     *
     * @param map
     * @return
     */
    public static LinkedHashMap<String, Integer> mapSort(Map<String, Integer> map) {
        LinkedHashMap<String, Integer> linkedHashMap = new LinkedHashMap<>();
        List<Map.Entry<String, Integer>> list = new ArrayList<Map.Entry<String, Integer>>(map.size());
        list.addAll(map.entrySet());
        int num = map.size();
        for (int i = 0; i < num - 1; i++) {
            for (int j = 0; j < num - i - 1; j++) {
                Map.Entry<String, Integer> e1 = list.get(j);
                Map.Entry<String, Integer> e2 = list.get(j + 1);
                if (e1.getValue() < e2.getValue()) {
                    Collections.swap(list, j, j + 1);
                }
            }
        }
        for (int n = 0; n <= num - 1; n++) {
            Map.Entry<String, Integer> entry = list.get(n);
            linkedHashMap.put(entry.getKey(), entry.getValue());
        }
        return linkedHashMap;
    }

    public void getLessonSchedule() {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getLessonScheduleForTeacher(false, studentId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(value -> {
                            if (value.size()>0){
                                notes.set(value.get(0).getTeacherNote());
                                notesDate.set(TimeUtils.timeDate(value.get(0).getShouldDateTime()));
                            }
                        }, throwable ->{
                            dismissDialog();
                        }));
    }

}
