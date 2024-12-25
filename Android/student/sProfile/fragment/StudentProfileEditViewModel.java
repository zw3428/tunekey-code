package com.spelist.tunekey.ui.student.sProfile.fragment;

import android.annotation.SuppressLint;
import android.app.Application;
import android.os.Handler;
import android.view.View;
import android.view.ViewParent;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModelLazy;

import com.google.android.gms.identity.intents.model.UserAddress;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.StorageUtils;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.LoginMethodEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKAddress;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTools;
import com.spelist.tunekey.utils.SharePreferenceUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.goldze.mvvmhabit.utils.SPUtils;

public class StudentProfileEditViewModel extends ToolbarViewModel {
    public MutableLiveData<Integer> storagePlaceholderRes = new MutableLiveData<>(R.mipmap.avatar_back);
    public MutableLiveData<String> userId = new MutableLiveData<>("");
    //    public boolean isProfileComeIn = true;
    public MutableLiveData<String> name = new MutableLiveData<>();
    public MutableLiveData<Boolean> logout = new MutableLiveData<>();
    public MutableLiveData<String> email = new MutableLiveData<>();
    public MutableLiveData<String> tel = new MutableLiveData<>();
    public MutableLiveData<String> url = new MutableLiveData<>();
    public FirebaseAuth mAuth;
    public MutableLiveData<Boolean> isBack = new MutableLiveData<>();
    public UserEntity userEntity;
    public String oldEmail = "";
    public MutableLiveData<String> birthdayString = new MutableLiveData<>("");
    public double birthday = 0;
    public List<LoginMethodEntity> loginMethodData = new ArrayList<>();
    public boolean isStudioEdit;
    public ObservableField<Boolean> isActivity = new ObservableField<>(true);
    public boolean isEditParent;
    public MutableLiveData<Boolean> isStudioEditParent = new MutableLiveData<>(false);
    public String studentId = "";


    public StudentProfileEditViewModel(@NonNull Application application) {
        super(application);
        isBack.setValue(false);
    }

    @SuppressLint("ResourceType")
    @Override
    public void initToolbar() {
        setTitleString("Edit Profile");
        setLeftButtonIcon(R.drawable.ic_back_primary);
        setLeftImgButtonVisibility(View.VISIBLE);
        setRightButtonText("Sign out");
        setRightButtonTextColor(ContextCompat.getColor(getApplication().getApplicationContext(), R.color.red));


    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        //Messenger.getDefault().send("edit", MessengerUtils.STUDENT_PROFILE);
        finish();
        isBack.setValue(true);
    }

    @Override
    protected void clickRightTextButton() {
        super.clickRightTextButton();
        SharePreferenceUtils.clear(getApplication());
        mAuth = FirebaseAuth.getInstance();
        mAuth.signOut();
        logout.setValue(true);
    }

    public void updateUserName(String name) {
        setIsShowProgress(true);
        List<String> studioIds = new ArrayList<>();
        if (isStudioEdit) {
            studioIds.add(SLCacheUtil.getCurrentStudioId());
        } else {
            if (ListenerService.shared.studentData != null && ListenerService.shared.studentData.getStudentData() != null && ListenerService.shared.studentData.isHaveTeacher()) {
                studioIds.add(ListenerService.shared.studentData.getStudentData().getStudioId());
            }
        }
        String userId = UserService.getInstance().getCurrentUserId();
        if (isStudioEdit) {
            userId = this.userId.getValue();
        }
        userEntity.setName(name);
        addSubscribe(
                UserService
                        .getInstance()
                        .updateStudentName(isStudioEdit, isEditParent, userId, name, studioIds)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (isEditParent) {
                                List<StudentListEntity> studentListEntity = new ArrayList<>();
                                for (StudentListEntity student : AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId())) {
                                    if (student.getParents() != null && student.getParents().size() > 0) {
                                        if (student.getParents().get(0).getUserId().equals(userEntity.getUserId())) {
                                            List<UserEntity> d = new ArrayList<>();
                                            d.add(userEntity);
                                            student.setParents(d);
                                            studentListEntity.add(student);
                                        }
                                    }

                                }
                                AppDataBase.getInstance().studentListDao().insertAll(CloneObjectUtils.cloneObject(studentListEntity));
                            }
                            setIsShowProgress(false);
                            if (isEditParent) {
                                Messenger.getDefault().send(userEntity, "EDIT_PARENT_PROFILE");
                            } else {
                                Messenger.getDefault().sendNoMsg(MessengerUtils.STUDENT_PROFILE);
                            }
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            setIsShowProgress(false);
                            SLToast.error("Save failed, please try again!");
                        })
        );
//        Map<String, Object> objectMap = new HashMap<>();
//        objectMap.put("name", name);
//
//        addSubscribe(UserService
//                .getStudioInstance()
//                .updateUser(objectMap)
//                .subscribe(aBoolean -> {
//
//                    setIsShowProgress(false);
//
//                }, throwable -> {
//                    setIsShowProgress(false);
//
//                    SLToast.error("Creation failed, please try again!");
//                }));
    }

    public void updateAddress() {
        setIsShowProgress(true);
        Map<String, List<TKAddress>> d = new HashMap<>();
        d.put("addresses", userEntity.getAddresses());
        DatabaseService.Collections.user()
                .document(userEntity.getUserId())
                .set(d, SetOptions.merge())
                .addOnCompleteListener(task -> {
                    if (task.isSuccessful()) {
                        if (isEditParent) {
                            List<StudentListEntity> studentListEntity = new ArrayList<>();
                            for (StudentListEntity student : AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId())) {
                                if (student.getParents() != null && student.getParents().size() > 0) {
                                    if (student.getParents().get(0).getUserId().equals(userEntity.getUserId())) {
                                        student.getParents().get(0).setAddresses(userEntity.getAddresses());
                                        studentListEntity.add(student);
                                    }
                                }

                            }
                            AppDataBase.getInstance().studentListDao().insertAll(studentListEntity);

                        }
                        Logger.e("成功==>%s", "");
                        if (isEditParent) {
                            Messenger.getDefault().send(userEntity, "EDIT_PARENT_PROFILE");
                        } else {
                            Messenger.getDefault().sendNoMsg(MessengerUtils.STUDENT_PROFILE);
                        }
                        setIsShowProgress(false);
                    } else {
                        Logger.e("失败==>%s", "");
                        setIsShowProgress(false);
//                        SLToast.error("Save failed, please try again!");
//                        SLToast.showError();
                    }
                });

    }


    public void updateUserPhone() {
        setIsShowProgress(true);
        List<String> studioIds = new ArrayList<>();
        if (isStudioEdit) {
            studioIds.add(SLCacheUtil.getCurrentStudioId());
        } else {
            if (ListenerService.shared.studentData != null && ListenerService.shared.studentData.getStudentData() != null && ListenerService.shared.studentData.isHaveTeacher()) {
                studioIds.add(ListenerService.shared.studentData.getStudentData().getStudioId());
            }
        }
        addSubscribe(
                UserService
                        .getInstance()
                        .updateStudentPhone(userEntity, isEditParent, studioIds)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (isEditParent) {
                                List<StudentListEntity> studentListEntity = new ArrayList<>();
                                for (StudentListEntity student : AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId())) {
                                    if (student.getParents() != null && student.getParents().size() > 0) {
                                        if (student.getParents().get(0).getUserId().equals(userEntity.getUserId())) {
                                            student.getParents().get(0).setPhone(userEntity.getPhone());
                                            student.getParents().get(0).setPhoneNumber(userEntity.getPhoneNumber());
                                            studentListEntity.add(student);
                                        }
                                    }

                                }
                                AppDataBase.getInstance().studentListDao().insertAll(studentListEntity);
                            }
                            if (isEditParent) {
                                Messenger.getDefault().send(userEntity, "EDIT_PARENT_PROFILE");
                            } else {
                                Messenger.getDefault().sendNoMsg(MessengerUtils.STUDENT_PROFILE);
                            }
                            setIsShowProgress(false);
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            setIsShowProgress(false);
                            SLToast.error("Save failed, please try again!");
                        })
        );
    }

    public void updateUserEmail(String email) {
        setIsShowProgress(true);
        List<String> studioIds = new ArrayList<>();
        if (isStudioEdit) {
            studioIds.add(SLCacheUtil.getCurrentStudioId());
        } else {
            if (ListenerService.shared.studentData != null && ListenerService.shared.studentData.getStudentData() != null && ListenerService.shared.studentData.isHaveTeacher()) {
                studioIds.add(ListenerService.shared.studentData.getStudentData().getStudioId());
            }
        }
        String userId = UserService.getInstance().getCurrentUserId();
        if (isStudioEdit) {
            userId = this.userId.getValue();
        }
        oldEmail = email;
        userEntity.setEmail(email);
        addSubscribe(
                UserService
                        .getInstance()
                        .updateStudentEmail(userId, isEditParent, email, studioIds)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (isEditParent) {
                                List<StudentListEntity> studentListEntity = new ArrayList<>();
                                for (StudentListEntity student : AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId())) {
                                    if (student.getParents() != null && student.getParents().size() > 0) {
                                        if (student.getParents().get(0).getUserId().equals(userEntity.getUserId())) {
                                            student.getParents().get(0).setEmail(email);
                                            studentListEntity.add(student);
                                        }
                                    }

                                }
                                AppDataBase.getInstance().studentListDao().insertAll(studentListEntity);
                            }
                            if (isEditParent) {
                                Messenger.getDefault().send(userEntity, "EDIT_PARENT_PROFILE");
                            } else {
                                Messenger.getDefault().sendNoMsg(MessengerUtils.STUDENT_PROFILE);
                            }
                            setIsShowProgress(false);
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            setIsShowProgress(false);
                            SLToast.error("Save failed, please try again!");
                        })
        );

    }

    //封装一个点击事件观察者
    public UIClickObservable uc = new UIClickObservable();

    public void changeLoginEmail(CheckData data) {
        Map<String, Object> uploadData = new HashMap<>();
        uploadData.put("userId",userEntity.getUserId());
        uploadData.put("targetUserId",data.getId());
        uploadData.put("email",data.getEmail());
        uploadData.put("studioId",SLCacheUtil.getCurrentStudioId());

        showDialog();
        switch (data.getType()) {
            case StudentProfileEditViewModel.CheckType.emailNoLessonNoKids:
                //修改的邮箱, 被注册了 但是没有课也没孩子且不是老师或者studio--直接修改,不需要合并等其他操作
                //新的为学生 且没有课
                uploadData.put("mode","convert");

                break;
            case StudentProfileEditViewModel.CheckType.editStudentEmailHaveLesson:
            case StudentProfileEditViewModel.CheckType.editParentEmailHaveKids:
                //修改该家长邮箱, 邮箱被注册成了家长, 而且有孩子
                //修改该学生邮箱, 邮箱被注册成了学生, 而且有课
                uploadData.put("mode","convert");
                break;
            case StudentProfileEditViewModel.CheckType.editStudentEmailHaveKids:
            case StudentProfileEditViewModel.CheckType.editParentEmailHaveLesson:
                //修改该家长邮箱, 邮箱被注册成了学生, 而且有课
                //修改该学生邮箱, 邮箱被注册成了家长, 而且有孩子
                uploadData.put("mode","link");
                break;

        }
        Logger.e("uploadData==>%s",SLJsonUtils.toJsonString(uploadData));
        addSubscribe(
                        TKApi.updateUserLoginEmail(uploadData)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(),true)
                        .subscribe(d -> {
                            for (LoginMethodEntity loginMethodEntity : userEntity.getLoginMethod()) {
                                if (loginMethodEntity.getMethod() == 1) {
                                    loginMethodEntity.setAccount(data.getEmail());
                                }
                            }
                            loginMethodData = userEntity.getLoginMethod();
                            uc.refreshLoginData.call();
                            dismissDialog();
                            SLToast.showSuccess();
                            switch (data.getType()){
                                case StudentProfileEditViewModel.CheckType.emailNoLessonNoKids:

                                    break;
                                case StudentProfileEditViewModel.CheckType.editStudentEmailHaveLesson:

                                    break;
                                case StudentProfileEditViewModel.CheckType.editStudentEmailHaveKids:
                                    //修改该学生邮箱, 邮箱被注册成了家长, 而且有孩子
                                    data.getUserData().getKids().add(userEntity.getUserId());
                                    userEntity.getParents().clear();
                                    userEntity.getParents().add(data.getUserData().getUserId());
                                    StudentListEntity byStudentId = AppDataBase.getInstance().studentListDao().getByStudentId(userEntity.getUserId());
                                    byStudentId.getParents().clear();
                                    byStudentId.getParents().add(data.getUserData());
                                    AppDataBase.getInstance().studentListDao().insert(byStudentId);
                                    break;
                                case StudentProfileEditViewModel.CheckType.editParentEmailHaveLesson:
                                    //修改该家长邮箱, 邮箱被注册成了学生, 而且有课
                                    try {
                                        userEntity.getKids().add(data.getUserData().getUserId());
                                        StudentListEntity studentData = AppDataBase.getInstance().studentListDao().getByStudentId(data.getUserData().getUserId());
                                        studentData.getParents().clear();
                                        studentData.getParents().add(data.getUserData());
                                        studentData.getUserData().getParents().clear();
                                        studentData.getUserData().getParents().add(userEntity.getUserId());
                                        AppDataBase.getInstance().studentListDao().insert(studentData);
                                    }catch (Exception e){
                                        e.printStackTrace();
                                    }


                                    break;
                                case StudentProfileEditViewModel.CheckType.editParentEmailHaveKids:
                                    //修改该家长邮箱, 邮箱被注册成了家长, 而且有孩子
                                    data.getUserData().getKids().addAll(userEntity.getKids());
                                    List<StudentListEntity> byStudioIdFromList = AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId());
                                    for (StudentListEntity studentListEntity : byStudioIdFromList) {
                                        studentListEntity.getParents().clear();
                                        studentListEntity.getParents().add(data.getUserData());
                                        studentListEntity.getUserData().getParents().clear();
                                        studentListEntity.getUserData().getParents().add(data.getUserData().getUserId());
                                    }
                                    AppDataBase.getInstance().studentListDao().insertAll(byStudioIdFromList);
                                    break;
                            }


                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );

    }

    public class UIClickObservable {
        public SingleLiveEvent<Void> changImg = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> refreshLoginData = new SingleLiveEvent<>();
        public SingleLiveEvent<CheckData> showEditLoginEmail = new SingleLiveEvent<>();


    }

    public BindingCommand changImg = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.changImg.call();
        }
    });


    //    public void getStudioInfo() {
//        addSubscribe(UserService
//                .getStudioInstance()
//                .getStudioInfo(false)
//                .subscribe(studioInfoEntity -> {
//                    studioLogoPath.setValue(studioInfoEntity.getStudioLogoStoragePath());
//                    studioName.setValue(studioInfoEntity.getName());
//                    studioId = studioInfoEntity.getId();
//                }, throwable -> {
//                    Logger.e("==获取列表失败" + throwable.getMessage());
//                }));
//    }
    public void getUserById(String userId) {
        addSubscribe(UserService
                .getInstance()
                .getUserById(userId)
                .subscribe(userEntity -> {
                    isActivity.set(userEntity.isActive());
                    this.userEntity = userEntity;
                    this.userId.setValue(userEntity.getUserId());
                    oldEmail = userEntity.getEmail();
                    name.setValue(userEntity.getName());
                    email.setValue(userEntity.getEmail());
                    tel.setValue(userEntity.getPhone());
                    if (userEntity.getBirthday() == 0) {
                        birthdayString.setValue("");
                        birthday = 0;
                    } else {
                        birthday = userEntity.getBirthday();
                        birthdayString.setValue(TimeUtils.timeFormat((long) userEntity.getBirthday(), "MM/dd/yyyy"));
                    }
                    loginMethodData = userEntity.getLoginMethod();
                    uc.refreshLoginData.call();
                }, throwable -> {
                    Logger.e("==获取列表失败==" + throwable.getMessage());
                }));
    }

    public void getUser() {
        addSubscribe(UserService
                .getInstance()
                .getUserEntity()
                .subscribe(userEntity -> {
                    isActivity.set(userEntity.isActive());
                    this.userEntity = userEntity;
                    userId.setValue(userEntity.getUserId());
                    oldEmail = userEntity.getEmail();
                    name.setValue(userEntity.getName());
                    email.setValue(userEntity.getEmail());
                    tel.setValue(userEntity.getPhone());
                    if (userEntity.getBirthday() == 0) {
                        birthdayString.setValue("");
                        birthday = 0;
                    } else {
                        birthday = userEntity.getBirthday();
                        birthdayString.setValue(TimeUtils.timeFormat((long) userEntity.getBirthday(), "MM/dd/yyyy"));
                    }
                    loginMethodData = userEntity.getLoginMethod();
                    uc.refreshLoginData.call();
                }, throwable -> {
                    Logger.e("==获取列表失败==" + throwable.getMessage());
                }));
    }

    /**
     * 上传StudioLogo
     */
    public void uploadAvatar(String logoPath) {
        Logger.e("======%s", "开始上传头像");
        showDialog();
        String storagePath = userEntity.getUserStoragePath();
        addSubscribe(
                StorageUtils.uploadForFilePath(logoPath, storagePath)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(aBoolean -> {
                            dismissDialog();
                            String time = TimeUtils.getCurrentTimeString();
                            Map<String, Object> map = new HashMap<>();
                            map.put("updateTime", time);
                            DatabaseService.Collections.user()
                                    .document(userEntity.getUserId())
                                    .update(map);
                            SPUtils.getInstance().put("AVATAR_UPDATE_TIME" + userEntity.getUserId(), time);
                            Messenger.getDefault().send(time, MessengerUtils.REFRESH_AVATAR);
                            if (isEditParent) {
                                Messenger.getDefault().send(userEntity, "EDIT_PARENT_PROFILE");
                            }
                            Logger.e("上传成功");
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("上传失败:" + throwable.getMessage());
                        })
        );
    }

    public void updateBirthday() {
        setIsShowProgress(true);
        Map<String, Object> map = new HashMap<>();
        map.put("birthday", birthday);
        DatabaseService.Collections.user()
                .document(userEntity.getUserId())
                .set(map, SetOptions.merge())
                .addOnCompleteListener(runnable -> {
                    setIsShowProgress(false);
                });
    }

    /**
     * 修改学生邮件
     */
    public void updateEmail(String email) {
        showDialog();
        Map<String, Object> map = new HashMap<>();
        map.put("uId", userEntity.getUserId());
        map.put("email", email);
        showDialog();
        CloudFunctions
                .editEmail(map)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.isSuccessful() && task.getResult() != null && task.getResult()) {
                        SLToast.showSaveSuccess();
                        for (LoginMethodEntity loginMethodEntity : userEntity.getLoginMethod()) {
                            if (loginMethodEntity.getMethod() == 1) {
                                loginMethodEntity.setAccount(email);
                            }
                        }
                        loginMethodData = userEntity.getLoginMethod();
                        uc.refreshLoginData.call();


                    } else {
                        dismissDialog();
                        Logger.e("======  异常:");
                        SLToast.error("Update failed, please try again!");
                    }

                });
    }

    public void checkEmail(String email) {
        showDialog();
        addSubscribe(
                UserService.getInstance().checkEmailIsSignUp(email)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            if (d.size() > 0) {
                                UserEntity user = d.get(0);
                                if (user.getRoleIds().contains(UserEntity.UserRole.student)) {
                                    //被注册成了学生, 判断是否有课
                                    addSubscribe(
                                            TKApi.checkStudentHaveLesson(user.getUserId())
                                                    .subscribeOn(Schedulers.io())
                                                    .observeOn(AndroidSchedulers.mainThread(), true)
                                                    .subscribe(isHave -> {
                                                        dismissDialog();
                                                        CheckData checkData = new CheckData();
                                                        checkData.setId(user.getUserId());
                                                        checkData.setEmail(email);
                                                        checkData.setUserData(user);
                                                        if (isHave) {
                                                            if (isEditParent) {
                                                                checkData.setType(CheckType.editParentEmailHaveLesson);
                                                            } else {
                                                                checkData.setType(CheckType.editStudentEmailHaveLesson);
                                                            }
                                                        } else {
                                                            checkData.setType(CheckType.emailNoLessonNoKids);
                                                        }
                                                        uc.showEditLoginEmail.setValue(checkData);
                                                    }, throwable -> {
                                                        dismissDialog();
                                                        SLToast.showError();
                                                        Logger.e("失败,失败原因" + throwable.getMessage());
                                                    })
                                    );

                                } else if (user.getRoleIds().contains(UserEntity.UserRole.parents)) {
                                    dismissDialog();
                                    //被注册成了家长, 判断是否有孩子
                                    CheckData checkData = new CheckData();
                                    checkData.setId(user.getUserId());
                                    checkData.setEmail(email);
                                    checkData.setUserData(user);

                                    if (user.getKids().size() > 0) {
                                        if (isEditParent) {
                                            checkData.setType(CheckType.editParentEmailHaveKids);
                                        } else {
                                            checkData.setType(CheckType.editStudentEmailHaveKids);
                                        }
                                    } else {
                                        checkData.setType(CheckType.emailNoLessonNoKids);

                                    }
                                    uc.showEditLoginEmail.setValue(checkData);


                                } else {
                                    dismissDialog();
                                    //被注册成功studio或者teacher, 判断是否有课


                                    addSubscribe(
                                            TKApi.checkTeacherHaveLesson(user.getUserId())
                                                    .subscribeOn(Schedulers.io())
                                                    .observeOn(AndroidSchedulers.mainThread(), true)
                                                    .subscribe(isHave -> {
                                                        CheckData checkData = new CheckData();
                                                        checkData.setId(user.getUserId());
                                                        checkData.setEmail(email);
                                                        checkData.setUserData(user);

                                                        if (isHave) {
                                                            checkData.setType(CheckType.emailIsTeacherOrStudio);

                                                        } else {
                                                            checkData.setType(CheckType.emailNoLessonNoKids);

                                                        }
                                                        uc.showEditLoginEmail.setValue(checkData);
                                                    }, throwable -> {
                                                        dismissDialog();
                                                        SLToast.showError();
                                                        Logger.e("失败,失败原因" + throwable.getMessage());
                                                    })
                                    );
                                }
                            } else {
                                //没有注册过
                                updateEmail(email);
                            }

                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    static final class CheckType {
        //修改的邮箱, 邮箱被注册成了老师或者studio--直接拒绝
        static final String emailIsTeacherOrStudio = "emailIsTeacherOrStudio";
        //修改的邮箱, 被注册了 但是没有课也没孩子且不是老师或者studio--直接修改,不需要合并等其他操作
        static final String emailNoLessonNoKids = "emailNoLessonNoKids";

        //学生相关
        //修改该学生邮箱, 邮箱被注册成了学生, 而且有课
        static final String editStudentEmailHaveLesson = "editStudentEmailHaveLesson";

        //修改该学生邮箱, 邮箱被注册成了家长, 而且有孩子
        static final String editStudentEmailHaveKids = "editStudentEmailHaveKids";


        //家长相关
        //修改该家长邮箱, 邮箱被注册成了学生, 而且有课
        static final String editParentEmailHaveLesson = "editParentEmailHaveLesson";

        //修改该家长邮箱, 邮箱被注册成了家长, 而且有孩子
        static final String editParentEmailHaveKids = "editParentEmailHaveKids";


    }

    public class CheckData {
        public String id = "";
        public String email = "";
        public String type = CheckType.editStudentEmailHaveLesson;
        public UserEntity userData = new UserEntity();

        public UserEntity getUserData() {
            return userData;
        }

        public CheckData setUserData(UserEntity userData) {
            this.userData = userData;
            return this;
        }

        public String getId() {
            return id;
        }

        public CheckData setId(String id) {
            this.id = id;
            return this;
        }

        public String getEmail() {
            return email;
        }

        public CheckData setEmail(String email) {
            this.email = email;
            return this;
        }

        public String getType() {
            return type;
        }

        public CheckData setType(String type) {
            this.type = type;
            return this;
        }
    }

    public void unbindingParent(String studentId, String parentUserId, String studioId) {
        showDialog();
        addSubscribe(
                TKApi.unbindingParent(false, studentId, parentUserId, studioId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
//                            studentData.parents.clear();
                            if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                                List<StudentListEntity> studentList = ListenerService.shared.teacherData.getStudentList();
                                for (StudentListEntity studentListEntity : studentList) {
                                    if (studentListEntity.studentId.equals(studentId)) {
                                        studentListEntity.parents.clear();
                                        studentListEntity.userData.setParents(new ArrayList<>());
                                        AppDataBase.getInstance().studentListDao().insert(studentListEntity);
                                        break;
                                    }
                                }
                            }else {
                                StudentListEntity byIdNoFlow = AppDataBase.getInstance().studentListDao().getByStudentId(studentId);
                                if (byIdNoFlow.studentId.equals(studentId)) {
                                    byIdNoFlow.parents.clear();
                                    byIdNoFlow.userData.setParents(new ArrayList<>());
                                    AppDataBase.getInstance().studentListDao().insert(byIdNoFlow);
                                }
                            }
                            Messenger.getDefault().sendNoMsg(MessengerUtils.STUDIO_STUDENTS_CHANGED);

//                            initParentData();
                            dismissDialog();
                            SLToast.showSuccess();
                            finish();
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );

    }

}
