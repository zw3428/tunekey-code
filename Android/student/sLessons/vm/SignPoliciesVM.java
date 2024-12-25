package com.spelist.tunekey.ui.student.sLessons.vm;

import android.app.Application;
import android.graphics.Bitmap;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.StorageUtils;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.Map;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/18
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class SignPoliciesVM extends ToolbarViewModel {
    public MutableLiveData<String> policiesString = new MutableLiveData<>("");
    public MutableLiveData<Boolean> isCheck = new MutableLiveData<>(false);

    public MutableLiveData<Integer> checkImg = new MutableLiveData<>(R.mipmap.checkbox_red);
    public MutableLiveData<String> name = new MutableLiveData<>("");
    public MutableLiveData<String> studentId = new MutableLiveData<>("");
    public MutableLiveData<String> infoString = new MutableLiveData<>("");
    public MutableLiveData<String> signaturePath = new MutableLiveData<>("");
    public MutableLiveData<String> signatureTimeString = new MutableLiveData<>("");
    public MutableLiveData<Boolean> isSign = new MutableLiveData<>(false);
    public MutableLiveData<Boolean> isLook = new MutableLiveData<>(false);

    private StudentListEntity studentData;
    private PolicyEntity policiesData;


    public SignPoliciesVM(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Sign Policies");
        setLeftImgButtonVisibility(View.GONE);

    }

    public void initData(PolicyEntity policiesData, StudentListEntity studentData) {
        this.policiesData = policiesData;
        this.studentData = studentData;
        if (policiesData!=null){
            if (policiesData.getDescription().equals("")) {
                policiesString.setValue(policiesData.getDefaultDescription());
            } else {
                policiesString.setValue(policiesData.getDescription());
            }
        }

        name.setValue(studentData.getName());
        studentId.setValue(studentData.getStudentId());
        if (studentData.getSignPolicyTime()!=0){
            isSign.setValue(true);
            isLook.setValue(true);
            String signTime = TimeUtils.timeFormat(studentData.getSignPolicyTime(), "MM/dd/yyyy");
            infoString.setValue("Signed on "+ signTime);
            signatureTimeString.setValue(signTime);
            signaturePath.setValue("/signature/"+studentData.getTeacherId()+":"+studentData.getStudentId()+".png");
        }else {
            isSign.setValue(false);
        }
    }

    public BindingCommand clickCheck = new BindingCommand(() -> {

        checkImg.setValue(isCheck.getValue() ? R.mipmap.checkbox_red : R.mipmap.check);
        isCheck.setValue(!isCheck.getValue());
    });
   public UIEventObservable uc = new UIEventObservable();

    public void uploadSign(Bitmap bitmap) {


        showDialog();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 80, baos);
        byte[] data = baos.toByteArray();
        addSubscribe(
                StorageUtils
                        .uploadForByte(data,"/signature/"+studentData.getTeacherId()+":"+studentData.getStudentId()+".png")
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(),true)
                        .subscribe(d -> {
                            Logger.e("======%s", "上传成功");
                            updateStudentList(bitmap);
                        }, throwable -> {
                            dismissDialog();
                            Logger.e("uploadSign失败,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })

        );
    }
    private void updateStudentList(Bitmap bitmap){
        Map<String,Object> map = new HashMap<>();
        map.put("signPolicyTime",TimeUtils.getCurrentTime());
        addSubscribe(
                UserService
                        .getInstance()
                        .updateStudentList(studentData.getStudentId(), studentData.getStudioId(),map)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(),true)
                        .subscribe(data -> {
                            SLToast.success("Submit successfully!");
                            studentData.setSignPolicyTime(TimeUtils.getCurrentTime());
                            isSign.setValue(true);
                            String signTime = TimeUtils.timeFormat(studentData.getSignPolicyTime(), "MM/dd/yyyy");
                            infoString.setValue("Signed on "+ signTime);
                            signatureTimeString.setValue(signTime);
                            dismissDialog();
                            setLeftImgButtonVisibility(View.VISIBLE);

                        }, throwable -> {
                            dismissDialog();
                            Logger.e("updateStudentList失败,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })

        );
    }

    public static class UIEventObservable {
           public SingleLiveEvent<Void> clickSignNow = new SingleLiveEvent<>();
       }


    public TKButton.ClickListener clickLater = tkButton -> {
        finish();
    };
    public TKButton.ClickListener clickSign = tkButton -> {
        uc.clickSignNow.call();
    };
}
