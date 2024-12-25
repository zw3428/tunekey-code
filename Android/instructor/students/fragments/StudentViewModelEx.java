package com.spelist.tunekey.ui.teacher.students.fragments;

import com.google.firebase.firestore.Source;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.reactivex.Observable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.bus.Messenger;

/**
 * com.spelist.tunekey.ui.teacher.students.fragments
 * 2023/1/10
 *
 * @author Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentViewModelEx {
    public static String showBirthdayDialog ="showBirthdayDialog";
    public static void getStudentUserData(List<StudentListEntity> studentList) {
        List<String> ids = new ArrayList<>();
        for (StudentListEntity student : studentList) {
            ids.add(student.getStudentId());
        }
        TApplication.addSubscribe(
                getUserIds(Source.SERVER, ids)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            if (studentList.size() <= 0) {
                                return;
                            }
                            List<StudentUserData> data = new ArrayList<>();
                            for (UserEntity userEntity : d) {
                                for (StudentListEntity item : studentList) {
                                    if (item.getStudentId().equals(userEntity.getUserId())) {
                                        StudentUserData e = new StudentUserData();
                                        e.setStudentListData(item);
                                        e.setUserData(userEntity);
                                        data.add(e);
                                    }
                                }
                            }

                            Logger.e("data==>%s", data.size());
                            List<UserEntity> birthDayStudentList = new ArrayList<>();
                            List<UserEntity> birthNext7DayStudentList = new ArrayList<>();

                            String nowMMdd = TimeUtils.timeFormat(TimeUtils.getCurrentTime(),"MM-dd");
                            //获取将来7天的MMdd
                            List<String> next7Days = new ArrayList<>();

                            for (int i = 1; i < 8; i++) {
                                String e = TimeUtils.timeFormat(TimeUtils.getCurrentTime() + i * 24 * 60 * 60, "MM-dd");
                                next7Days.add(e);
                            }

                            for (StudentUserData datum : data) {
                                double birthday = datum.getUserData().getBirthday();
                                if (birthday != 0) {
                                    if (nowMMdd.equals(TimeUtils.timeFormat((long) birthday,"MM-dd"))){
                                        birthDayStudentList.add(datum.getUserData());
                                    }else if (next7Days.contains(TimeUtils.timeFormat((long) birthday,"MM-dd"))){
                                        birthNext7DayStudentList.add(datum.getUserData());
                                    }
                                }
                            }
                            Logger.e("birthDayStudentList.size()==>%s",birthDayStudentList.size());
                            if (birthDayStudentList.size() == 0&&birthNext7DayStudentList.size() == 0) {
                                return;
                            }
                            Map<String,Object> map =new HashMap<>();
                            map.put("birthDayStudentList",birthDayStudentList);
                            map.put("birthNext7DayStudentList",birthNext7DayStudentList);
                            Messenger.getDefault().send(map,showBirthdayDialog);
                            Logger.e("????==>%s","???");
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    public static Observable<List<UserEntity>> getUserIds(List<String> ids) {
        return Observable.mergeDelayError(getUserIds(Source.CACHE, ids), getUserIds(Source.SERVER, ids));
    }

    public static Observable<List<UserEntity>> getUserIds(Source source, List<String> ids) {
        List<Observable<List<UserEntity>>> observables = new ArrayList<>();
        List<List<String>> lists = FuncUtils.splitToPieces(ids, 10);
        for (List<String> list : lists) {
            observables.add(getUserIdss(source, list));
        }
        List<UserEntity> list = new ArrayList<>();
        return Observable.zip(observables, objects -> {
            for (Object object : objects) {
                if (object instanceof List) {
                    List<UserEntity> object1 = (List<UserEntity>) object;
                    list.addAll(object1);
                }
            }
            return list;
        }).subscribeOn(Schedulers.io());
    }

    private static Observable<List<UserEntity>> getUserIdss(Source source, List<String> ids) {

        return Observable.create(emitter -> {
            DatabaseService.Collections.user()
                    .whereIn("userId", ids)
                    .get(source)
                    .addOnCompleteListener(task -> {
                        if (task.getException() != null) {
                            emitter.onError(task.getException());
                        } else {
                            if (task.getResult() != null) {
                                emitter.onNext(task.getResult().toObjects(UserEntity.class));
                            } else {
                                emitter.onNext(new ArrayList<>());
                            }
                            emitter.onComplete();
                        }
                    });
        });
    }

    public static class StudentUserData {
        private StudentListEntity studentListData;
        private UserEntity userData;

        //get方法
        public StudentListEntity getStudentListData() {
            return studentListData;
        }

        public UserEntity getUserData() {
            return userData;
        }

        //set方法
        public void setStudentListData(StudentListEntity studentListData) {
            this.studentListData = studentListData;
        }

        public void setUserData(UserEntity userData) {
            this.userData = userData;
        }
    }
}
