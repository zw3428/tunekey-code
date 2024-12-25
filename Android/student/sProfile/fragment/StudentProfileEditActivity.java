package com.spelist.tunekey.ui.student.sProfile.fragment;

import static com.shuyu.gsyvideoplayer.GSYVideoADManager.TAG;

import android.annotation.SuppressLint;
import android.app.DatePickerDialog;
import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.text.Editable;
import android.text.InputFilter;
import android.text.InputType;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.widget.DatePicker;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.DialogFragment;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

//import com.luck.picture.lib.PictureSelector;
import com.luck.picture.lib.basic.PictureSelector;
import com.luck.picture.lib.config.PictureConfig;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.entity.LocalMedia;
import com.luck.picture.lib.language.LanguageConfig;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.InputDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.SetAddressDialog;
import com.spelist.tunekey.customView.dialog.SetPhoneDialog;
import com.spelist.tunekey.databinding.ActivityStudentProfileEditBinding;
import com.spelist.tunekey.databinding.ItemProfileLoginMethodBinding;
import com.spelist.tunekey.entity.LoginMethodEntity;
import com.spelist.tunekey.entity.StudioInfoEntity;
import com.spelist.tunekey.entity.TKAddress;
import com.spelist.tunekey.notification.TKNotificationUtils;
import com.spelist.tunekey.ui.loginAndOnboard.login.LoginActivity;
import com.spelist.tunekey.ui.teacher.profileTeacher.AccountActivity;
import com.spelist.tunekey.ui.teacher.profileTeacher.EditProfileActivity;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerAdapter;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerHolder;
import com.spelist.tunekey.utils.GlideEngine;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLImageUtils;
import com.spelist.tunekey.utils.SLTools;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.base.BaseActivity;

public class StudentProfileEditActivity extends BaseActivity<ActivityStudentProfileEditBinding, StudentProfileEditViewModel> {
    private static int EDIT_OK = 0;
    private String name = "";
    private String email = "";
    private String phone = "";
    private BaseViewBindingRecyclerAdapter<LoginMethodEntity> adapter;


    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_profile_edit;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        viewModel.isStudioEdit = getIntent().getBooleanExtra("isStudioEdit", false);
        if (viewModel.isStudioEdit) {
            String userId = getIntent().getStringExtra("userId");
            viewModel.getUserById(userId);
            viewModel.isEditParent = getIntent().getBooleanExtra("isEditParent", false);
            if (viewModel.isEditParent ) {
                viewModel.studentId = getIntent().getStringExtra("studentId");
//                viewModel.studentId = getIntent().getStringExtra("studentId");
                viewModel.isStudioEditParent.setValue(true);
            }
            binding.birthdayLayout.setVisibility(View.GONE);

        } else {
            viewModel.getUser();
        }
//        viewModel.isProfileComeIn = getIntent().getBooleanExtra("isProfileComeIn", true);
//        if (viewModel.isProfileComeIn){
////            viewModel.setRightButtonVisibility(View.VISIBLE);
//        }

    }

    @Override
    public void initView() {
        super.initView();
        binding.unbindingButton.setClickListener(v -> {
//            viewModel.logout();
            Dialog confirmDialog = SLDialogUtils.showTwoButtonButtonRed(this, "Unbind parent", "Unbind parent for student? tap 'Unbind' to continue", "Unbind", "Go back");
            confirmDialog.findViewById(R.id.left_button).setOnClickListener(view -> {
                confirmDialog.dismiss();
                viewModel.unbindingParent(viewModel.studentId,viewModel.userId.getValue(), SLCacheUtil.getCurrentStudioId());
            });
        });
        binding.addressLayout.setOnClickListener(view -> {

            TKAddress tkAddress = new TKAddress();
            if (viewModel.userEntity.getAddresses() != null && viewModel.userEntity.getAddresses().size() > 0) {
                tkAddress = viewModel.userEntity.getAddresses().get(0);
            }
            SetAddressDialog dialog = new SetAddressDialog(this, this, tkAddress);
            dialog.showDialog();
            dialog.setClickListener(data -> {
                List<TKAddress> addresses = new ArrayList<>();
                addresses.add(data);
                binding.inputAddress.setInputText(data.toShowString());
                viewModel.userEntity.setAddresses(addresses);
                viewModel.updateAddress();
            });
        });

        binding.birthdayClickView.setOnClickListener(view -> {
            DatePickerFragment newFragment = new DatePickerFragment(viewModel.birthday);
            newFragment.show(getSupportFragmentManager(), "datePicker");
            newFragment.setOnClickSaveListener(time -> {
                viewModel.birthday = time;
                viewModel.birthdayString.setValue(TimeUtils.timeFormat((long) viewModel.birthday, "MM/dd/yyyy"));
                viewModel.updateBirthday();
            });
        });
//        binding.inputBirthday.prohibitInput();
//        binding.inputPhone.editTextView.setFilters(new InputFilter[]{new InputFilter.LengthFilter(20)});
        binding.inputEmail.editTextView.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        binding.toSignOption.setText(SLStringUtils.getSpan("Change sign-in email?\nGo to \"Settings > Sign-in options\"", ContextCompat.getColor(this, R.color.main), "Settings > Sign-in options"));
        binding.toSignOption.setOnClickListener(v -> startActivity(AccountActivity.class));
        binding.phoneLayout.setOnClickListener(v -> {

            StudioInfoEntity.TKPhoneNumber tkPhoneNumber = viewModel.userEntity.getPhoneNumber();
            String phone = tkPhoneNumber.getCountry() + "-" + (tkPhoneNumber.getPhoneNumber().replace("-", ""));
            SetPhoneDialog dialog = new SetPhoneDialog(this, phone, "Phone Number");
            dialog.showDialog();
            dialog.setClickListener((phoneString, code, phoneNumber) -> {
                binding.inputPhone.setInputText(phoneString);
                viewModel.userEntity.setPhoneNumber(new StudioInfoEntity.TKPhoneNumber().setCountry(code).setPhoneNumber(phoneNumber));
                viewModel.userEntity.setPhone(phoneString);
                viewModel.updateUserPhone();
                dialog.dismiss();
            });
        });
        initLoginMethod();
        binding.changeButton.setOnClickListener(v -> {
            if (viewModel.isStudioEdit) {
                String oldEmail = "";
                for (LoginMethodEntity loginMethodEntity : viewModel.userEntity.getLoginMethod()) {
                    if (loginMethodEntity.getMethod() == 1) {
                        oldEmail = loginMethodEntity.getAccount();

                    }
                }
                InputDialog dialog = new InputDialog(this, oldEmail, "Edit login email", "Email", "", "SAVE", InputDialog.Type.EMAIL);
                dialog.showDialog();
                dialog.setClickListener(email -> {
//                    viewModel.updateEmail(email);
                    viewModel.checkEmail(email);
                });
            } else {
                startActivity(AccountActivity.class);
                finish();
            }
        });
    }

    private void initLoginMethod() {
        adapter = new BaseViewBindingRecyclerAdapter<LoginMethodEntity>(this, viewModel.loginMethodData, R.layout.item_profile_login_method) {
            @Override
            public void convert(BaseViewBindingRecyclerHolder holder, LoginMethodEntity item, int position, boolean isScrolling) {
                if (!(holder.getBinding() instanceof ItemProfileLoginMethodBinding)) {
                    return;
                }
                ItemProfileLoginMethodBinding binding = (ItemProfileLoginMethodBinding) holder.getBinding();
                binding.loginMethodTv.setText(item.getAccount());
                switch (item.getMethod()) {
                    case 0:
                        binding.loginMethodIv.setImageResource(R.mipmap.login_phone);
                        break;
                    case 1:
                        binding.loginMethodIv.setImageResource(R.mipmap.account_email);
                        break;
                    case 2:
                        binding.loginMethodIv.setImageResource(R.mipmap.login_google);
                        break;
                    case 3:
                        binding.loginMethodIv.setImageResource(R.mipmap.account_fb);
                        break;
                    case 4:
                        binding.loginMethodIv.setImageResource(R.mipmap.login_apple);
                        break;
                }
            }
        };

        binding.loginMethodRv.setLayoutManager(new LinearLayoutManager(this));
        binding.loginMethodRv.setAdapter(adapter);
    }


    @SuppressLint("HandlerLeak")
    private final Handler mHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            if (EDIT_OK == 2) {
                viewModel.updateUserName(name);
            } else if (EDIT_OK == 3) {
                viewModel.updateUserEmail(email);
            } else if (EDIT_OK == 4) {
//                viewModel.updateUserPhone(phone);
            }
        }
    };
    private final Runnable mRunnable = new Runnable() {
        @Override
        public void run() {
            mHandler.sendEmptyMessage(EDIT_OK);
        }
    };


    @Override
    public void initViewObservable() {
        viewModel.uc.showEditLoginEmail.observe(this, data -> {
            if (data.getType().equals(StudentProfileEditViewModel.CheckType.emailIsTeacherOrStudio)){
                SLDialogUtils.showOneButton(this,"Email Conflict Detected","This email is linked to an active teacher’s account with students or lessons. Tap “Go Back” to correct it and add a new one, or reach out to the account owner requesting removal." ,"Go Back");

            }else {
                String title = "Duplicate Email Alert";
                String message = "";
                String buttonString = "";
                switch (data.getType()){
                    case StudentProfileEditViewModel.CheckType.emailNoLessonNoKids:
                        //修改的邮箱, 被注册了 但是没有课也没孩子且不是老师或者studio--直接修改,不需要合并等其他操作
                        //学生没课✅
                        message = "The email is linked to an existing account. Tap REPLACE to update with a new account. Or tap GO BACK to use a different email.";
                        buttonString = "Replace";
                        break;
                    case StudentProfileEditViewModel.CheckType.editStudentEmailHaveLesson:
                        //修改该学生邮箱, 邮箱被注册成了学生, 而且有课 ✅
                        message ="This email is linked to an active student with lessons. Tap MERGE to merge with the existing account. Or tap “GO BACK” to use a different email.";
                        buttonString ="Merge";
                        break;
                    case StudentProfileEditViewModel.CheckType.editStudentEmailHaveKids:
                        //修改该学生邮箱, 邮箱被注册成了家长, 而且有孩子✅
                        message ="The email is linked to an active parent account with student. Tap STUDENT & PARENT to set up a student account under the existing parent. Or tap 'GO BACK' to use a different email.";
                        buttonString ="Student & Parent";
                        break;
                    case StudentProfileEditViewModel.CheckType.editParentEmailHaveLesson:
                        //修改该家长邮箱, 邮箱被注册成了学生, 而且有课✅
                        message ="The email is linked to an active student account with lessons. Tap PARENT & STUDENT to set up a parent account on the top of existing student.  Or tap 'GO BACK' to use a different email.";
                        buttonString ="Parent & Student";
                        break;
                    case StudentProfileEditViewModel.CheckType.editParentEmailHaveKids:
                        //修改该家长邮箱, 邮箱被注册成了家长, 而且有孩子
                        message ="The email is linked to an active parent account with student. Tap MERGE to combine with the existing account. Or tap “GO BACK” to use a different email.";
                        buttonString ="Merge";
                        break;
                }
                Dialog dialog = SLDialogUtils.showTwoButtonSmallButton(this, title, message,buttonString , "Go Back");
                dialog.findViewById(R.id.left_button).setOnClickListener(v -> {
                    viewModel.changeLoginEmail(data);
                    dialog.dismiss();
                });


            }


        });
        viewModel.uc.refreshLoginData.observe(this, unused -> adapter.refreshData(viewModel.loginMethodData));

        viewModel.birthdayString.observe(this, s -> {
            binding.inputBirthday.setInputTextNoFocus(s);
        });

        viewModel.name.observe(this, new Observer<String>() {
            @Override
            public void onChanged(String s) {
                binding.inputName.setInputText(viewModel.name.getValue());
                new Handler().postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        binding.inputName.editTextView.addTextChangedListener(new TextWatcher() {
                            @Override
                            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

                            }

                            @Override
                            public void onTextChanged(CharSequence s, int start, int before, int count) {

                            }

                            @Override
                            public void afterTextChanged(Editable s) {
                                if (s.toString().equals("")) {
                                    binding.nameLine.setBackgroundColor(ContextCompat.getColor(StudentProfileEditActivity.this, R.color.red));
                                } else {
                                    binding.nameLine.setBackgroundColor(ContextCompat.getColor(StudentProfileEditActivity.this, R.color.dividing_lineColor));

                                    mHandler.removeCallbacks(mRunnable);
                                    mHandler.postDelayed(mRunnable, 1000);
                                    EDIT_OK = 2;
                                    name = s.toString();
                                }
                            }
                        });
                    }
                }, 450);

            }
        });

        viewModel.email.observe(this, new Observer<String>() {
            @Override
            public void onChanged(String s) {
                binding.inputEmail.setInputText(viewModel.email.getValue());
                new Handler().postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        binding.inputEmail.editTextView.addTextChangedListener(new TextWatcher() {
                            @Override
                            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

                            }

                            @Override
                            public void onTextChanged(CharSequence s, int start, int before, int count) {

                            }

                            @Override
                            public void afterTextChanged(Editable s) {
                                if (SLStringUtils.isEmail(s.toString())) {
                                    mHandler.removeCallbacks(mRunnable);
                                    mHandler.postDelayed(mRunnable, 1000);
                                    EDIT_OK = 3;
                                    email = s.toString();
                                    binding.emailLine.setBackgroundColor(ContextCompat.getColor(StudentProfileEditActivity.this, R.color.dividing_lineColor));

                                } else {
                                    if (SLStringUtils.isEmail(viewModel.oldEmail)) {
                                        mHandler.removeCallbacks(mRunnable);
                                        mHandler.postDelayed(mRunnable, 1000);
                                        EDIT_OK = 3;
                                        email = viewModel.oldEmail;
                                    }
                                    binding.emailLine.setBackgroundColor(ContextCompat.getColor(StudentProfileEditActivity.this, R.color.red));

                                }
                            }
                        });
                    }
                }, 450);

            }
        });

        viewModel.tel.observe(this, new Observer<String>() {
            @Override
            public void onChanged(String s) {
                binding.inputPhone.setInputText(viewModel.tel.getValue());
                TKAddress tkAddress = new TKAddress();
                if (viewModel.userEntity.getAddresses() != null && viewModel.userEntity.getAddresses().size() > 0) {
                    tkAddress = viewModel.userEntity.getAddresses().get(0);
                }
                binding.inputAddress.setInputText(tkAddress.toShowString());
//                new Handler().postDelayed(new Runnable() {
//                    @Override
//                    public void run() {
//                        binding.inputPhone.editTextView.addTextChangedListener(new TextWatcher() {
//                            @Override
//                            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
//
//                            }
//
//                            @Override
//                            public void onTextChanged(CharSequence s, int start, int before, int count) {
//
//                            }
//
//                            @Override
//                            public void afterTextChanged(Editable s) {
//                                mHandler.removeCallbacks(mRunnable);
//                                mHandler.postDelayed(mRunnable, 1000);
//                                EDIT_OK = 4;
//                                phone = s.toString();
//                            }
//                        });
//                    }
//                }, 450);

            }
        });

        viewModel.uc.changImg.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                selectStudioImage();
            }
        });
        viewModel.logout.observe(this, new Observer<Boolean>() {
            @Override
            public void onChanged(Boolean aBoolean) {
                TKNotificationUtils.closeLessonNotification(StudentProfileEditActivity.this);
                logOut();
            }
        });

    }

    public void logOut() {
        Intent intent = new Intent(this, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    /**
     * 选择图片
     */
    private void selectStudioImage() {
        SLTools.showSelectImageByLogo(this, true);
//        PictureSelector.create(StudentProfileEditActivity.this)
//                .openGallery(PictureMimeType.ofImage())
//                .isAndroidQTransform(true)// 是否需要处理Android Q 拷贝至应用沙盒的操作，只针对compress(false); && enableCrop(false);有效
//                .maxSelectNum(1)
//                .setPictureStyle(SLImageUtils.getPictureParameterStyle())// 动态自定义相册主题
//                .loadImageEngine(GlideEngine.createGlideEngine())// 外部传入图片加载引擎，必传项
//                .setLanguage(LanguageConfig.ENGLISH)
//                .selectionMode(PictureConfig.SINGLE)
//                .previewImage(true)
//                .previewVideo(true)
//                .queryMaxFileSize(50)//只查多少M以内的图片、视频、音频  单位M
//                .isCamera(true)
//                .compress(true)
//                .isGif(false)
//                .synOrAsy(false)
//                .enableCrop(true)
//                .circleDimmedLayer(true)
//                .showCropFrame(false)
//                .showCropGrid(false)
//                .minimumCompressSize(100)
////                        .setLanguage(PictureSelectionConfig.)
//                .forResult(PictureConfig.CHOOSE_REQUEST);//结果回调onActivityResult code
    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK) {

            switch (requestCode) {
                case PictureConfig.CHOOSE_REQUEST:
                    // 图片选择结果回调
                    List<LocalMedia> localMedia = PictureSelector.obtainSelectorList(data);
                    // 例如 LocalMedia 里面返回五种path
                    // 1.media.getPath(); 为原图path
                    // 2.media.getCutPath();为裁剪后path，需判断media.isCut();是否为true
                    // 3.media.getCompressPath();为压缩后path，需判断media.isCompressed();是否为true
                    // 4.media.getOriginalPath()); media.isOriginal());为true时此字段才有值
                    // 5.media.getAndroidQToPath();为Android Q版本特有返回的字段，此字段有值就用来做上传使用
                    // 如果同时开启裁剪和压缩，则取压缩路径为准因为是先裁剪后压缩
                    if (localMedia != null && localMedia.size() > 0) {
                        LocalMedia media = localMedia.get(0);
                        Log.e(TAG, "压缩::" + media.getCompressPath());
                        Log.e(TAG, "原图::" + media.getPath());
                        Log.e(TAG, "裁剪::" + media.getCutPath());
                        if (SLStringUtils.isNoNull(media.getCutPath())) {
                            viewModel.uploadAvatar(media.getCutPath());
                            SLImageUtils.loadRoundLocalImage(binding.cfImageView.avatarImg, media.getCutPath());
                            SLImageUtils.loadRoundLocalImage(binding.cfImageView.backgroundView, media.getCutPath());

                        } else if (SLStringUtils.isNoNull(media.getCompressPath())) {
                            viewModel.uploadAvatar(media.getCompressPath());
                            SLImageUtils.loadRoundLocalImage(binding.cfImageView.avatarImg, media.getCompressPath());
                            SLImageUtils.loadRoundLocalImage(binding.cfImageView.backgroundView, media.getCutPath());

                        } else if (SLStringUtils.isNoNull(media.getPath())) {
                            viewModel.uploadAvatar(media.getPath());
                            SLImageUtils.loadRoundLocalImage(binding.cfImageView.avatarImg, media.getPath());
                            SLImageUtils.loadRoundLocalImage(binding.cfImageView.backgroundView, media.getCutPath());
                        }
                    }
                    break;
            }
        }
    }

    public static class DatePickerFragment extends DialogFragment
            implements DatePickerDialog.OnDateSetListener {
        private double time = 0;

        public DatePickerFragment() {
        }

        public DatePickerFragment(double time) {
            this.time = time;
        }

        private OnClickSaveListener onClickSaveListener;

        public interface OnClickSaveListener {
            void onClickSave(long time);
        }

        public void setOnClickSaveListener(OnClickSaveListener onClickSaveListener) {
            this.onClickSaveListener = onClickSaveListener;
        }


        @Override
        public Dialog onCreateDialog(Bundle savedInstanceState) {
            // Use the current date as the default date in the picker

            final Calendar c = Calendar.getInstance();
            if (time != 0) {
                c.setTimeInMillis((long) (time * 1000));
            }
            int year = c.get(Calendar.YEAR);
            int month = c.get(Calendar.MONTH);
            int day = c.get(Calendar.DAY_OF_MONTH);

            // Create a new instance of DatePickerDialog and return it
            DatePickerDialog datePickerDialog = new DatePickerDialog(getActivity(), this, year, month, day);
            datePickerDialog.getDatePicker().setMaxDate(System.currentTimeMillis());
            return datePickerDialog;
        }

        public void onDateSet(DatePicker view, int year, int month, int day) {
            month = month + 1;
            long time = TimeUtils.timeToStamp((year + "/" + month + "/" + day + " 00:00:01"), "yyyy/MM/dd hh:mm:ss");
            onClickSaveListener.onClickSave(time / 1000);
        }
    }
}
