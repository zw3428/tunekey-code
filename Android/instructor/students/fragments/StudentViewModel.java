package com.spelist.tunekey.ui.teacher.students.fragments;

import android.annotation.SuppressLint;
import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableInt;
import androidx.lifecycle.MutableLiveData;
import androidx.room.migration.Migration;
import androidx.sqlite.db.SupportSQLiteDatabase;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.ChatService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.entity.EditEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.TeacherInfoEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.entity.chat.ConversationType;
import com.spelist.tunekey.entity.chat.TKConversation;
import com.spelist.tunekey.entity.chat.TKConversationUser;
import com.spelist.tunekey.entity.chat.TKMessage;
import com.spelist.tunekey.ui.chat.activity.ChatActivity;
import com.spelist.tunekey.ui.teacher.students.activity.SearchActivity;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.text.Collator;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.reactivex.Observable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import retrofit2.http.HEAD;

/**
 * Author WHT
 * Description:
 * Date :2019-10-07
 */
public class StudentViewModel extends ToolbarViewModel {
    public boolean isLoadBirthday = false;
    //封装一个点击事件观察者
    public StudentViewModel.UIClickObservable uc = new StudentViewModel.UIClickObservable();
    public ObservableInt emptyLayoutVisibility = new ObservableInt();
    public MutableLiveData<Boolean> currentUserIsPro = new MutableLiveData<>();
    public List<StudentListEntity> studentListEntities = new ArrayList<>();
    public EditEntity editEntity = new EditEntity();
    public MutableLiveData<List<StudentListEntity>> mutArchivedList = new MutableLiveData<>(new ArrayList<>());
    public MutableLiveData<List<StudentListEntity>> mutActiveList = new MutableLiveData<>(new ArrayList<>());
    public MutableLiveData<List<StudentListEntity>> mutInactiveList = new MutableLiveData<>(new ArrayList<>());
    public ObservableInt noStudent = new ObservableInt();
    public ObservableInt linSearch = new ObservableInt();
    public ObservableInt studentVisible = new ObservableInt();
    public Boolean isTestStudent = false;
    private Boolean isEdit = false;
    private int tabPosition = 0;
    public MutableLiveData<Boolean> addNewStudent = new MutableLiveData<>();
    public MutableLiveData<Integer> refreshStudent = new MutableLiveData<>();

    public MutableLiveData<Boolean> addStudent = new MutableLiveData<>();
    public UserEntity userEntity;

    public TeacherInfoEntity teacherInfoData;
    public ObservableField<Boolean> isHaveStudent = new ObservableField<>(true);

    public List<TKConversation> conversations = new ArrayList<>();
    public boolean isCanCreateAndEditStudent = true;


    public StudentViewModel(@NonNull Application application) {
        super(application);
        studentListEntities.clear();
        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
            if (TKRoleAndAccess.getData() != null) {
                isCanCreateAndEditStudent = TKRoleAndAccess.getData().getAllowManageStudentAccount4CreateAndEdit();
            }
        }

        initMessenger();
//        addSubscribe(
//                AppDataBase.getInstance().conversationDao().getAllTKConversation()
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(),true)
//                        .subscribe(data -> {
//                            Logger.e("会话刷新:%s",data.size());
//                        }, throwable -> {
//
//                        })
//
//        );
    }

    public void getPosition(int pos) {
        tabPosition = pos;
        editEntity.setId(tabPosition);
        Messenger.getDefault().send(editEntity, MessengerUtils.HIDE);
    }

    /**
     * id  1-active 2-inactive 3-archived
     * type 1-edit 2-cancel
     */

    @Override
    protected void clickLeftTextButton() {
        super.clickLeftTextButton();
//<<<<<<< HEAD
//        setLeftButtonIcon(R.mipmap.edit_new);
//        setLeftButtonText("");
//        setLeftButtonVisibility(View.GONE);
//        setLeftImgButtonVisibility(View.GONE);
//        setRightFirstImgVisibility(View.VISIBLE);
//        setRightSecondImgVisibility(isCanCreateAndEditStudent? View.VISIBLE:View.GONE);
//        editEntity.setId(tabPosition);
//        editEntity.setType(2);
//        Messenger.getDefault().send(editEntity, MessengerUtils.EDIT);
//        Messenger.getDefault().send(editEntity, MessengerUtils.HIDE);
//        isEdit = false;
//=======
        setLeftButtonIcon(R.mipmap.img_group_chat);
        setLeftButtonText("");
        setLeftButtonVisibility(View.VISIBLE);
        setLeftImgButtonVisibility(View.GONE);
        setRightFirstImgVisibility(View.VISIBLE);
        setRightSecondImgVisibility(View.VISIBLE);
        editEntity.setId(tabPosition);
        editEntity.setType(2);
        Messenger.getDefault().send(editEntity, MessengerUtils.EDIT);
        Messenger.getDefault().send(editEntity, MessengerUtils.HIDE);
        isEdit = false;
//>>>>>>> latest-release
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        getGroupChatConversation();
//        setLeftButtonText("Cancel");
//        setLeftButtonVisibility(View.GONE);
//        setLeftImgButtonVisibility(View.GONE);
//        setRightFirstImgVisibility(View.GONE);
//        setRightSecondImgVisibility(View.GONE);
//        editEntity.setId(tabPosition);
//        editEntity.setType(1);
//        Messenger.getDefault().send(editEntity, MessengerUtils.EDIT);
//        Messenger.getDefault().send(editEntity, MessengerUtils.HIDE);
//        isEdit = true;


    }

    @Override
    protected void clickRightFirstImgButton() {
        super.clickRightFirstImgButton();
        startActivity(SearchActivity.class);
    }

    @Override
    protected void clickRightSecondImgButton() {
        super.clickRightSecondImgButton();

        if (teacherInfoData != null) {
            if (studentListEntities.size() >= 5 && teacherInfoData.getMemberLevelId() == 1) {
            } else {
                addStudent.setValue(true);
            }
        }

    }

    public class UIClickObservable {
        public SingleLiveEvent<Void> showAddStudent = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> search = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> searchBack = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> showAddTestStudent = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> testStudentAutoAddLesson = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> refreshChatData = new SingleLiveEvent<>();
        public SingleLiveEvent<Integer> showAddStudentError = new SingleLiveEvent<>();


    }

    public TKButton.ClickListener showAddStudentByTK = tkButton -> uc.showAddStudent.call();
    public BindingCommand showAddTestStudent = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            AtomicBoolean isLoad = new AtomicBoolean(false);
            showDialog();
            addSubscribe(
                    UserService
                            .getInstance()
                            .getCurrentUserEntity()
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(value1 -> {
                                if (!isLoad.get()) {
                                    isLoad.set(true);
                                    userEntity = value1;
                                    dismissDialog();
                                    uc.showAddTestStudent.call();
                                }
                            }, throwable -> {
                                dismissDialog();
                            }));


        }
    });

    @SuppressLint("ResourceType")
    @Override
    public void initToolbar() {
        setTitleString("Students");
        setLeftButtonIcon(R.mipmap.img_group_chat);
        setLeftButtonVisibility(View.GONE);
        setLeftImgButtonVisibility(View.VISIBLE);

        setRightFirstImgIcon(R.mipmap.ic_search_primary);
        setRightFirstImgVisibility(View.GONE);
        setRightSecondImgIcon(R.mipmap.ic_add_primary);
        setRightSecondImgVisibility(View.GONE);

    }

    public void checkEmail(List<Map<String, Object>> data, boolean isTestStudent) {
        Map<String, Object> map = data.get(0);
        String email = String.valueOf(map.get("email"));
        showDialog();
        addSubscribe(
                UserService.
                        getInstance()
                        .getUserByEmail(email)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(user -> {
//                            Logger.e("user:%s", SLJsonUtils.toJsonString(user));
                            if (user.getUserId().equals("-1")) {
                                inviteStudent(data, isTestStudent);
                            } else {

                                if (user.getRoleIds().contains("1")) {
                                    dismissDialog();
                                    uc.showAddStudentError.setValue(1);
                                } else if (user.getRoleIds().contains("2")) {
                                    //如果获取出来的是学生 判断学生是否有老师
                                    DatabaseService.Collections.teacherStudentList()
                                            .whereEqualTo("email", email)
                                            .get()
                                            .addOnCompleteListener(task -> {
                                                if (task.getException() != null) {
                                                    dismissDialog();
                                                    SLToast.showError();
                                                } else {

                                                    List<StudentListEntity> studentListEntities = task.getResult().toObjects(StudentListEntity.class);
                                                    if (studentListEntities.size() > 0) {
                                                        dismissDialog();
                                                        uc.showAddStudentError.setValue(2);
                                                    } else {
                                                        inviteStudent(data, isTestStudent);
                                                    }
                                                }

                                            });

                                }
                            }
                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })

        );
    }

    public void inviteStudent(List<Map<String, Object>> data, boolean isTestStudent) {

        CloudFunctions
                .addStudent(data)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.isSuccessful()) {
                        if (task.getResult() != null && task.getResult().size() > 0) {
                            this.isTestStudent = isTestStudent;

                            new Handler().postDelayed(() -> {
                                refreshStudent.setValue(0);
                            }, 600);
                            if (isTestStudent) {
                                new Handler().postDelayed(() -> {
                                    uc.testStudentAutoAddLesson.call();
                                }, 500);

                            }
                        }
                    } else {
                        SLToast.error("Please check your connection and try again.");
                        Logger.e("====== 添加失败:" + task.getResult());
                    }

                });

    }

    public void sendEmail(String link) {
        showDialog();
        addSubscribe(
                CloudFunctions
                        .sendEmailToUser(UserService.getInstance().getCurrentUserId(), link)
                        .subscribe(data -> {
                            SLToast.success("Email send Successful!");
                            dismissDialog();
                            Logger.e("======%s", "成功");
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    private void initMessenger() {
        Messenger.getDefault().register(this, "AddStudentSuccess", () -> {
            refreshStudent.setValue(0);
        });

        Messenger.getDefault().register(this, MessengerUtils.TEACHER_CHAT_CONVERSION_CHANGE, () -> {

            conversations = ListenerService.shared.teacherData.getConversations();
            conversations = conversations.stream().filter(conversation -> conversation.getType().equals(ConversationType.privateType)).collect(Collectors.toList());

            if (conversations.size() > 0) {
                refreshChatData();
            }
        });

        Messenger.getDefault().register(this, MessengerUtils.TEACHER_STUDENT_LIST_CHANGED, () -> {
            List<StudentListEntity> studentList = ListenerService.shared.teacherData.getStudentList();
            SLCacheUtil.setStudentList(UserService.getInstance().getCurrentUserId(), studentList);
            setLeftButtonVisibility(View.GONE);
            if (studentList.size() > 0) {
                SLCacheUtil.setStudentList(UserService.getInstance().getCurrentUserId(), ListenerService.shared.teacherData.getStudentList());
                if (ListenerService.shared.teacherData.getStudentList().size() > 0) {
//                setLeftButtonVisibility(View.VISIBLE);

                    isHaveStudent.set(true);
                    setLeftImgButtonVisibility(View.VISIBLE);
                    setRightFirstImgVisibility(View.VISIBLE);
                    setRightSecondImgVisibility(isCanCreateAndEditStudent ? View.VISIBLE : View.GONE);
                    noStudent.set(View.GONE);
                    studentVisible.set(View.VISIBLE);
                    linSearch.set(View.GONE);
                    getStudentDetail(studentList);
//                getStudentDetail(ListenerService.shared.teacherData.getStudentList());
                    if (!isLoadBirthday) {
                        isLoadBirthday = true;
                        StudentViewModelEx.getStudentUserData(ListenerService.shared.teacherData.getStudentList());
                    }
                } else {
                    setLeftImgButtonVisibility(View.GONE);
                    isHaveStudent.set(false);
                    setLeftButtonVisibility(View.GONE);
                    setRightFirstImgVisibility(View.GONE);
                    setRightSecondImgVisibility(View.GONE);
                    noStudent.set(View.VISIBLE);
                    studentVisible.set(View.GONE);
                    linSearch.set(View.GONE);
                }


            }
        });
        Messenger.getDefault().register(this, MessengerUtils.DELETE_STUDENT, Integer.class, new BindingConsumer<Integer>() {
            @Override
            public void call(Integer integer) {
                if (ListenerService.shared.teacherData.getStudentList().size() > 0) {
                    setLeftImgButtonVisibility(View.VISIBLE);
                } else {
                    setLeftImgButtonVisibility(View.GONE);
                }
//                setLeftImgButtonVisibility(View.VISIBLE);
                setRightFirstImgVisibility(View.VISIBLE);
                setRightSecondImgVisibility(isCanCreateAndEditStudent ? View.VISIBLE : View.GONE);
                editEntity.setId(tabPosition);
                editEntity.setType(2);
                Messenger.getDefault().send(editEntity, MessengerUtils.HIDE);
                isEdit = false;
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.ARCHIVE_STUDENT, Integer.class, new BindingConsumer<Integer>() {
            @Override
            public void call(Integer integer) {
                Logger.e("==>%s","ARCHIVE_STUDENT");
                if (ListenerService.shared.teacherData.getStudentList().size() > 0) {
                    setLeftImgButtonVisibility(View.VISIBLE);
                } else {
                    setLeftImgButtonVisibility(View.GONE);
                }
//                setLeftImgButtonVisibility(View.GONE);
                setRightFirstImgVisibility(View.VISIBLE);
                setRightSecondImgVisibility(isCanCreateAndEditStudent ? View.VISIBLE : View.GONE);
                editEntity.setId(tabPosition);
                editEntity.setType(2);
                Messenger.getDefault().send(editEntity, MessengerUtils.HIDE);
                isEdit = false;
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.CHANGE_MEMBER_LEVEL_ID, Integer.class, new BindingConsumer<Integer>() {
            @Override
            public void call(Integer integer) {
                Logger.e("======%s", integer);

                if (integer == 1 && studentListEntities.size() >= 5) {
                    currentUserIsPro.setValue(true);
                } else {
                    currentUserIsPro.setValue(false);
                }
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.CLEAR_UNCONFIRMED_LESSONS, String.class, new BindingConsumer<String>() {
            @Override
            public void call(String studentId) {
                Logger.e("======要删除课程的学生Id:%s", studentId);
                if (mutInactiveList == null) {
                    return;
                }
                List<StudentListEntity> list = mutInactiveList.getValue();
                for (StudentListEntity item : list) {
                    if (item.getStudentId().equals(studentId)) {
                        item.setUnConfirmedLessonConfig(new ArrayList<>());
                    }
                }
                mutInactiveList.setValue(list);
            }
        });

    }

    /**
     * 查询是否是会员 显示Pro
     */
    public void getTeacherMemberLevel() {
        addSubscribe(
                UserService
                        .getStudioInstance()
                        .getTeacherInfoByUserId(UserService.getInstance().getCurrentUserId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(teacherInfo -> {
                            teacherInfoData = teacherInfo;
                            Logger.e("获取教师身份");
                            if (teacherInfo.getMemberLevelId() == 1 && studentListEntities.size() >= 5) {
                                currentUserIsPro.setValue(true);
                            } else {
                                currentUserIsPro.setValue(false);
                            }
                        }, throwable -> {
                            Logger.e("-**-*-*-*-*-*-*- 获取教师会员身份失败: " + throwable.getMessage());
                        })
        );
    }


    /**
     * 获取学生列表
     */

    public void getStudentList() {
//        showDialog();
//        isHaveStudent.set(false);
//<<<<<<<HEAD

        try {
            if (ListenerService.shared.teacherData != null) {
                List<StudentListEntity> studentList = ListenerService.shared.teacherData.getStudentList();
                if (studentList.size() > 0) {
                    isHaveStudent.set(true);
                    setLeftImgButtonVisibility(View.GONE);
                    setRightFirstImgVisibility(View.VISIBLE);
                    setRightSecondImgVisibility(isCanCreateAndEditStudent ? View.VISIBLE : View.GONE);
                    noStudent.set(View.GONE);
                    studentVisible.set(View.VISIBLE);
                    linSearch.set(View.GONE);
                    getStudentDetail(studentList);
                } else {
                    isHaveStudent.set(false);
                    setLeftImgButtonVisibility(View.GONE);
//                                setLeftButtonVisibility(View.GONE);
                    setRightFirstImgVisibility(View.GONE);
                    setRightSecondImgVisibility(View.GONE);
                    noStudent.set(View.VISIBLE);
                    studentVisible.set(View.GONE);
                    linSearch.set(View.GONE);
                }
            }
        } catch (Throwable e) {
            Logger.e("获取学生失败==>%s", e.getMessage());
        }


//        addSubscribe(
//                UserService
//                        .getInstance()
//                        .getStudentListForTeacher()
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(studentList -> {
//                            Logger.e("======获取到学生列表");
//                            dismissDialog();
//                            SLCacheUtil.setStudentList(UserService.getInstance().getCurrentUserId(), studentList);
//                            if (studentList.size() > 0) {
//                                isHaveStudent.set(true);
////                                setLeftButtonVisibility(View.VISIBLE);
//                                setLeftImgButtonVisibility(View.GONE);
//                                setRightFirstImgVisibility(View.VISIBLE);
//                                setRightSecondImgVisibility(View.VISIBLE);
//                                noStudent.set(View.GONE);
//                                studentVisible.set(View.VISIBLE);
//                                linSearch.set(View.GONE);
//                                getStudentDetail(studentList);
//                            } else {
//                                isHaveStudent.set(false);
//                                setLeftImgButtonVisibility(View.GONE);
////                                setLeftButtonVisibility(View.GONE);
//                                setRightFirstImgVisibility(View.GONE);
//                                setRightSecondImgVisibility(View.GONE);
//                                noStudent.set(View.VISIBLE);
//                                studentVisible.set(View.GONE);
//                                linSearch.set(View.GONE);
//                            }
//                        }, throwable -> {
//                            dismissDialog();
//                        }));
//=======
//        addSubscribe(
//                UserService
//                        .getInstance()
//                        .getStudentListForTeacher()
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(studentList -> {
//                            Logger.e("======获取到学生列表");
//                            dismissDialog();
//                            SLCacheUtil.setStudentList(UserService.getInstance().getCurrentUserId(), studentList);
//                            if (studentList.size() > 0) {
//                                isHaveStudent.set(true);
//                                setLeftImgButtonVisibility(View.VISIBLE);
////                                setLeftImgButtonVisibility(View.GONE);
//                                setRightFirstImgVisibility(View.VISIBLE);
//                                setRightSecondImgVisibility(View.VISIBLE);
//                                noStudent.set(View.GONE);
//                                studentVisible.set(View.VISIBLE);
//                                linSearch.set(View.GONE);
//                                getStudentDetail(studentList);
//                            } else {
//                                isHaveStudent.set(false);
//                                setLeftImgButtonVisibility(View.GONE);
//                                setLeftButtonVisibility(View.GONE);
//                                setRightFirstImgVisibility(View.GONE);
//                                setRightSecondImgVisibility(View.GONE);
//                                noStudent.set(View.VISIBLE);
//                                studentVisible.set(View.GONE);
//                                linSearch.set(View.GONE);
//                            }
//                        }, throwable -> {
//                            dismissDialog();
//                        }));
//>>>>>>>latest - release
    }

    private void getStudentUnconfirmedLessons(List<StudentListEntity> studentList) {
        addSubscribe(
                LessonService
                        .getInstance()
                        .getStudentUnconfirmedLesson(studentList)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (mutInactiveList.getValue() != null && mutInactiveList.getValue().size() > 0 && data.size() > 0) {
                                List<StudentListEntity> list = mutInactiveList.getValue();

                                for (StudentListEntity studentListEntity : list) {
                                    studentListEntity.setUnConfirmedLessonConfig(new ArrayList<>());
                                }
                                for (LessonScheduleConfigEntity datum : data) {

                                    for (StudentListEntity studentListEntity : list) {
                                        if (studentListEntity.getStudentId().equals(datum.getStudentId())) {
                                            studentListEntity.getUnConfirmedLessonConfig().add(datum);
                                        }
                                    }
                                }
                                mutInactiveList.setValue(list);
                            }
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    public void refreshChatData() {
        if (studentListEntities.size() == 0) {
            return;
        }
        List<StudentListEntity> archivedList = new ArrayList<>();
        List<StudentListEntity> activeList = new ArrayList<>();
        List<StudentListEntity> inactiveList = new ArrayList<>();
        studentListEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
        for (int i = 0; i < studentListEntities.size(); i++) {

            //设置会话数据
            for (TKConversation conversation : conversations) {
                List<TKConversationUser> users = new ArrayList<>();
                int unReadCount = 0;
                for (TKConversationUser user : conversation.getUsers()) {
                    if (user.getUserId().equals(studentListEntities.get(i).getStudentId())) {
                        users.add(user);
                    }
                    if (user.getUserId().equals(studentListEntities.get(i).getTeacherId())) {
                        unReadCount += user.getUnreadMessageCount();
                    }
                }
                if (users.size() > 0) {
                    studentListEntities.get(i).setConversation(conversation);
                    studentListEntities.get(i).setUnReadCount(unReadCount);
                }
            }


            String invitedStatus = studentListEntities.get(i).getInvitedStatus();
            if (invitedStatus.equals("-1")) {
                if (!studentListEntities.get(i).getLessonTypeId().equals("")) {
                    activeList.add(studentListEntities.get(i));

                } else {
                    inactiveList.add(studentListEntities.get(i));

                }
            } else if (invitedStatus.equals("3")) {
                archivedList.add(studentListEntities.get(i));
            } else {
                activeList.add(studentListEntities.get(i));
            }
        }
        //排序
        activeList = activeList.stream().sorted((t0, t1) -> {
            if (t0.getConversation() == null) {
                return 1;
            } else if (t1.getConversation() == null) {
                return -1;
            } else {
                return (int) (t1.getConversation().getLatestMessageTimestamp() - t0.getConversation().getLatestMessageTimestamp());
            }
        }).collect(Collectors.toList());
        inactiveList = inactiveList.stream().sorted((t0, t1) -> {
            if (t0.getConversation() == null) {
                return 1;
            } else if (t1.getConversation() == null) {
                return -1;
            } else {
                return (int) (t1.getConversation().getLatestMessageTimestamp() - t0.getConversation().getLatestMessageTimestamp());
            }
        }).collect(Collectors.toList());
        archivedList = archivedList.stream().sorted((t0, t1) -> {
            if (t0.getConversation() == null) {
                return 1;
            } else if (t1.getConversation() == null) {
                return -1;
            } else {
                return (int) (t1.getConversation().getLatestMessageTimestamp() - t0.getConversation().getLatestMessageTimestamp());
            }
        }).collect(Collectors.toList());

        mutActiveList.setValue(activeList);
        mutInactiveList.setValue(inactiveList);
        mutArchivedList.setValue(archivedList);
    }

    public void getStudentDetail(List<StudentListEntity> studentList) {
        conversations = ListenerService.shared.teacherData.getConversations();
        conversations = conversations.stream().filter(conversation -> conversation.getType().equals(ConversationType.privateType)).collect(Collectors.toList());
        List<StudentListEntity> archivedList = new ArrayList<>();
        List<StudentListEntity> activeList = new ArrayList<>();
        List<StudentListEntity> inactiveList = new ArrayList<>();
        studentListEntities = studentList;

        if (teacherInfoData != null) {

            if (studentListEntities.size() >= 5 && teacherInfoData.getMemberLevelId() == 1) {
                currentUserIsPro.setValue(true);
            } else {
                currentUserIsPro.setValue(false);
            }
        }

   studentListEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

        for (int i = 0; i < studentListEntities.size(); i++) {

            //设置会话数据
            for (TKConversation conversation : conversations) {
                List<TKConversationUser> users = new ArrayList<>();
                int unReadCount = 0;
                for (TKConversationUser user : conversation.getUsers()) {
                    if (user.getUserId().equals(studentListEntities.get(i).getStudentId())) {
                        users.add(user);
                    }
                    if (user.getUserId().equals(studentListEntities.get(i).getTeacherId())) {
                        unReadCount += user.getUnreadMessageCount();
                    }
                }
                if (users.size() > 0) {
                    studentListEntities.get(i).setConversation(conversation);
                    studentListEntities.get(i).setUnReadCount(unReadCount);
                }
            }


            String invitedStatus = studentListEntities.get(i).getInvitedStatus();
            if (invitedStatus.equals("-1")) {
                if (!studentListEntities.get(i).getLessonTypeId().equals("")) {
                    activeList.add(studentListEntities.get(i));

                } else {
                    inactiveList.add(studentListEntities.get(i));

                }
            } else if (invitedStatus.equals("3")) {
                archivedList.add(studentListEntities.get(i));
            } else {
                activeList.add(studentListEntities.get(i));
            }
        }
        activeList = activeList.stream().sorted((t0, t1) -> {
            if (t0.getConversation() == null) {
                return 1;
            } else if (t1.getConversation() == null) {
                return -1;
            } else {
                return (int) (t1.getConversation().getLatestMessageTimestamp() - t0.getConversation().getLatestMessageTimestamp());
            }
        }).collect(Collectors.toList());
        inactiveList = inactiveList.stream().sorted((t0, t1) -> {
            if (t0.getConversation() == null) {
                return 1;
            } else if (t1.getConversation() == null) {
                return -1;
            } else {
                return (int) (t1.getConversation().getLatestMessageTimestamp() - t0.getConversation().getLatestMessageTimestamp());
            }
        }).collect(Collectors.toList());
        archivedList = archivedList.stream().sorted((t0, t1) -> {
            if (t0.getConversation() == null) {
                return 1;
            } else if (t1.getConversation() == null) {
                return -1;
            } else {
                return (int) (t1.getConversation().getLatestMessageTimestamp() - t0.getConversation().getLatestMessageTimestamp());
            }
        }).collect(Collectors.toList());

        Logger.e("学生个数==>%s==>%s==>%s", activeList.size(), inactiveList.size(), archivedList.size());

        mutActiveList.setValue(activeList);
        mutInactiveList.setValue(inactiveList);
        mutArchivedList.setValue(archivedList);
        if (activeList.size() > 0) {
            refreshStudent.setValue(1);
        } else if (inactiveList.size() > 0) {
            refreshStudent.setValue(0);
        } else if (archivedList.size() > 0) {
            refreshStudent.setValue(2);
        }

        getStudentUnconfirmedLessons(studentList);
    }

    private void getGroupChatConversation() {
        String studioId = ListenerService.shared.teacherData.getStudioData().getId();
        addSubscribe(
                ChatService.getConversationInstance()
                        .getFromLocal(studioId)
                        .flatMap(conversation -> {
                            if (conversation.getId().equals("-1")) {
                                showDialog();
                                return ChatService.getConversationInstance().getConversationByIdFromCloud(studioId);
                            } else {
                                return Observable.create(emitter -> {
                                    emitter.onNext(conversation);
                                    emitter.onComplete();
                                });
                            }
                        })
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (data.getId().equals("-1")) {
                                //创建
                                createGroupChatConversation(studioId);
                            } else {
                                //打开
                                toGroupChatConversation(studioId, data);
                            }

                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败1,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })
        );
    }

    private void createGroupChatConversation(String studioId) {
        List<StudentListEntity> studentList = ListenerService.shared.teacherData.getStudentList();
        List<TKConversationUser> users = new ArrayList<>();
        String currentUserId = SLCacheUtil.getCurrentUserId();
        users.add(new TKConversationUser().setUserId(currentUserId).setConversationId(studioId).setUnreadMessageCount(0).setNickname(ListenerService.shared.teacherData.getStudioData().getName()));


        Map<String, Boolean> userMap = new HashMap<>();
        userMap.put(currentUserId, true);
        for (StudentListEntity studentListEntity : studentList) {
            TKConversationUser conversationUser = new TKConversationUser()
                    .setConversationId(studioId)
                    .setNickname(studentListEntity.getName())
                    .setUserId(studentListEntity.getStudentId())
                    .setUnreadMessageCount(0);
            users.add(conversationUser);
            userMap.put(studentListEntity.getStudentId(), true);
        }
        int nowTime = TimeUtils.getCurrentTime();
        TKConversation conversation = new TKConversation()
                .setId(studioId)
                .setType(ConversationType.groupType)
                .setTitle("Announcements")
                .setCreatorId(currentUserId)
                .setUserMap(userMap)
                .setUsers(users)
                .setCreateTime(nowTime)
                .setUpdateTime(nowTime)
                .setSpeechMode(TKConversation.ConversationSpeechMode.ONLY_CREATOR);
        addSubscribe(
                ChatService.getConversationInstance().saveToCloud(conversation)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            toGroupChatConversation(studioId, conversation);
                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })
        );


    }

    private void toGroupChatConversation(String studioId, TKConversation conversation) {
        dismissDialog();
        Bundle bundle = new Bundle();
        bundle.putSerializable("conversation", conversation);
        startActivity(ChatActivity.class, bundle);
    }

}
