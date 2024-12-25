package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.EditEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.entity.chat.TKConversation;
import com.spelist.tunekey.ui.chat.activity.ChatActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddLessonStepActivity;
import com.spelist.tunekey.ui.teacher.students.activity.StudentDetailV2Ac;
import com.spelist.tunekey.utils.MessengerUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

/**
 * com.spelist.tunekey.ui.students.vm
 * 2020/11/23
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentsItemFragmentVM extends BaseViewModel {
    //0: Active, 1: Inactive, 2: Archived
    public int type = 0;
    public List<StudentListEntity> data = new ArrayList<>();
    public MutableLiveData<StudentListEntity> invite = new MutableLiveData<>();
    public MutableLiveData<UserEntity> inActive = new MutableLiveData<>();

    private boolean isEdit = false;

    public StudentsItemFragmentVM(@NonNull Application application) {
        super(application);
        initMessenger();
    }

    //给RecyclerView添加ObservableList
    public ObservableList<StudentItemVM> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<StudentItemVM> itemBinding = ItemBinding.of(new OnItemBind<StudentItemVM>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, StudentItemVM item) {
            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.item_student_active);
        }
    });
    public UIEventObservable uc = new UIEventObservable();




    public static class UIEventObservable {

    }


    private void initMessenger() {
        Messenger.getDefault().register(this, MessengerUtils.EDIT, EditEntity.class, new BindingConsumer<EditEntity>() {
            @Override
            public void call(EditEntity editEntity) {
                initEditType(editEntity.getType());
            }
        });

        Messenger.getDefault().register(this, MessengerUtils.DELETE_STUDENT, Integer.class, new BindingConsumer<Integer>() {
            @Override
            public void call(Integer integer) {
                if (integer == type) {
                    archiveAndDeleteStudent(true);
                }
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.ARCHIVE_STUDENT, Integer.class, new BindingConsumer<Integer>() {
            @Override
            public void call(Integer integer) {
                if (integer == type) {
                    archiveAndDeleteStudent(false);
                }
            }
        });

    }

    /**
     * 初始化编辑状态
     *
     * @param type
     */
    private void initEditType(int type) {
        if (type == 1) {
            isEdit = true;
            for (int i = 0; i < observableList.size(); i++) {
                observableList.get(i).checkedVisibility(View.GONE);
                observableList.get(i).uncheckedVisibility(View.VISIBLE);
                //设置invite和箭头隐藏
                observableList.get(i).inviteVisibility.set(View.GONE);
                observableList.get(i).next.set(View.GONE);
                observableList.get(i).isEdit = true;
                observableList.get(i).isSelect = false;
            }
        } else if (type == 2) {
            isEdit = false;
            for (int i = 0; i < observableList.size(); i++) {
                observableList.get(i).checkedVisibility(View.GONE);
                observableList.get(i).uncheckedVisibility(View.GONE);
                observableList.get(i).inviteVisibility.set(View.VISIBLE);
                observableList.get(i).next.set(View.VISIBLE);
                observableList.get(i).isEdit = false;
                observableList.get(i).isSelect = false;
            }
        }
    }


    /**
     * 设置数据
     *
     * @param studentListEntities
     */
    public void setData(List<StudentListEntity> studentListEntities) {
        Logger.e("set data==>%s",studentListEntities.size());
        data = studentListEntities;
        observableList.clear();
        for (int i = 0; i < data.size(); i++) {
            StudentItemVM item = new StudentItemVM(this, data.get(i), i);
            observableList.add(item);
        }
    }


    public void clickItem(int pos) {
        if (isEdit) {
//            organizeStudentId(observableList.get(pos).data.getValue().getStudentId());
        } else {
            if (observableList.get(pos).data.getValue().getStudentApplyStatus() == 1) {
            }else if (observableList.get(pos).data.getValue().getUnConfirmedLessonConfig().size()>0){

                Bundle bundle = new Bundle();
                bundle.putSerializable("list",observableList.get(pos).data.getValue());
                startActivity(AddLessonStepActivity.class,bundle);
            }
            else {
                toStudentDetails(pos);
            }
        }
    }

    public void clickRightButton(StudentListEntity studentListEntity) {
        invite.setValue(studentListEntity);
    }


    private void toStudentDetails(int pos) {
        Bundle bundle = new Bundle();
        bundle.putSerializable("student", observableList.get(pos).data.getValue());
        startActivity(StudentDetailV2Ac.class, bundle);
    }


    public void resendInvitation(StudentListEntity studentListEntity) {
        Map<String, Object> map = new HashMap<>();
        map.put("email", studentListEntity.getEmail());
        map.put("studentName", studentListEntity.getName());
        map.put("teacherId", studentListEntity.getTeacherId());
        showDialog();
        CloudFunctions
                .resendInvitation(map)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.isSuccessful()) {
                        if (task.getResult() != null && task.getResult()) {
                            Logger.e("====== RESEND 成功:" + task.getResult());
                            SLToast.info("Invite successfully!");
                            dismissDialog();
                        }
                    } else {
                        if (task.getException()!=null){
                            Logger.e("====== RESEND 异常:" + task.getException().getMessage());
                        }
                    }
                });
    }

    public void archiveAndDeleteStudent(boolean isDelete) {
        List<String> studentId = new ArrayList<>();
        for (StudentItemVM activeItemViewModel : observableList) {
            Logger.e("activeItemViewModel%s===%s",activeItemViewModel.isEdit,activeItemViewModel.isSelect);
            if (activeItemViewModel.isSelect) {
                studentId.add(activeItemViewModel.userId.get());
            }
        }
        Logger.e("======%s",type);
        initEditType(2);
        if (studentId.size()==0){
            SLToast.warning("Please select at least one student!");
            return;
        }
        showDialog();

        if (isDelete) {
            CloudFunctions
                    .deleteStudent(studentId)
                    .addOnCompleteListener(task -> {
                        dismissDialog();
                        if (task.isSuccessful()) {
                            if (task.getResult() != null && task.getResult()) {
                                SLToast.success("Deleted Successfully!");
                                Logger.e("====== 删除 Student 成功:" + task.getResult());
                            } else {
                                SLToast.showError();

                            }
                        } else {
                            Logger.e("====== 删除 Student 异常:" + task.getException().getMessage());
                            SLToast.showError();
                        }

                    });
        } else {
            CloudFunctions
                    .archiveStudent(studentId)
                    .addOnCompleteListener(task -> {
                        dismissDialog();
                        if (task.isSuccessful()) {
                            if (task.getResult() != null && task.getResult()) {
                                Logger.e("====== archiveStudent 成功:" + task.getResult());
                                SLToast.success("Archive Successfully!");
                            } else {

                                SLToast.showError();

                            }
                        } else {
                            Logger.e("====== archiveStudent 异常:" + task.getException().getMessage());
                            SLToast.showError();
                        }

                    });
        }


    }

    public void deleteStudent(List<String> studentId) {
        showDialog();

    }

    /**
     * 拒绝学生
     * @param student
     */
    public void rejectStudent(StudentListEntity student) {
        showDialog();
        DatabaseService.Collections.teacherStudentList().document(student.getTeacherId()+":"+student.getStudentId())
                .delete()
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.getException()==null){
                        SLToast.success("Reject successfully!");
                    }else {
                        SLToast.showError();
                        Logger.e("======%s","拒绝失败"+task.getException().getMessage() );
                    }
                });
    }
    /**
     * 同意学生
     * @param student
     */
    public void acceptStudent(StudentListEntity student) {
        showDialog();
        Map<String,Object> map = new HashMap<>();
        map.put("studentApplyStatus",2);
        map.put("invitedStatus","1");
        DatabaseService.Collections.teacherStudentList().document(student.getTeacherId()+":"+student.getStudentId())
                .update(map)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.getException()==null){
                        SLToast.success("Accept successfully!");
                    }else {
                        SLToast.showError();
                        Logger.e("======%s","拒绝失败"+task.getException().getMessage() );
                    }
                });
    }

    /**
     * 进入聊天页面
     * @param conversation 会话
     */
    public void toConversion(TKConversation conversation) {
        Bundle bundle = new Bundle();
        bundle.putSerializable("conversation",conversation);
        startActivity(ChatActivity.class,bundle);

    }
}
