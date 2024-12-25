package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.AddressBookEntity;
import com.spelist.tools.custom.ContactType;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.network.MaterialService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.students.activity.NewContactActivity;
import com.spelist.tunekey.utils.SLCacheUtil;

import java.io.Serializable;
import java.text.Collator;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;


public class AddressBookViewModel extends ToolbarViewModel {

    public enum ContactTypes {
        addressBook, // 0
        googleContact, // 1
        appContact, // 2
        phoneContact

    }

    public ContactTypes typeFromContactTypes;

    public enum PageAction {
        addStudentFromAddressBook, // 0
        shareMaterial, // 1
        sendMessage, // 2
        shareStudioMaterial

    }

    public boolean isInFolder = false;

    public MutableLiveData<Boolean> clearSearchEdit = new MutableLiveData<>();
    public MutableLiveData<Boolean> bottomButtonIsEnable = new MutableLiveData<>();

    public MutableLiveData<Boolean> searchCloseIsVisible = new MutableLiveData<>();

    public MutableLiveData<Boolean> topRvIsVisible = new MutableLiveData<>();
    public MutableLiveData<Boolean> bottomBtnContainerIsVisible = new MutableLiveData<>();
    public MutableLiveData<Boolean> getGoogleContact = new MutableLiveData<>();
    public MutableLiveData<List<AddressBookEntity>> sendMessage = new MutableLiveData<>();
    public PageAction pageAction;
    //已选择的数据源
    public List<AddressBookEntity> checkedDate = new ArrayList<>();
    // to share material
    public List<MaterialEntity> selectedMaterials = new ArrayList<>();
    //  -----------  tt
    public List<AddressBookEntity> addressBookEntities = new ArrayList<>();

    public List<AddressBodyItemViewModel> allStudentList = new ArrayList<>();
    public String studioName = "";


    public AddressBookViewModel(@NonNull Application application) {
        super(application);
    }

    //给RecyclerView添加ObservableList（顶部横向RecyclerView）
    public ObservableList<AddressBookItemViewModel> headerObservableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<AddressBookItemViewModel> headerItemBinding = ItemBinding.of(new OnItemBind<AddressBookItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, AddressBookItemViewModel item) {
            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.headimg_layout);

        }
    });
    //底部纵向RecyclerView
    public ObservableList<AddressBodyItemViewModel> bottomObservableList = new ObservableArrayList<>();
    public ItemBinding<AddressBodyItemViewModel> bottomItemBinding = ItemBinding.of(new OnItemBind<AddressBodyItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, AddressBodyItemViewModel item) {
            itemBinding.set(BR.itemViewModel, R.layout.address_book_layout);
        }
    });

    public void initData() {
        bottomBtnContainerIsVisible.setValue(false);
        topRvIsVisible.setValue(false);
        searchCloseIsVisible.setValue(false);
        switch (typeFromContactTypes) {
            case appContact:
                getAppContact();
                break;
            case googleContact:
                getGoogleContact.setValue(true);
                break;
            case addressBook:
                getDeviceContact();
                break;
            case phoneContact:
                getDeviceContactPhone();
                break;
        }

    }

    public void getGoogleContact(List<AddressBookEntity> data) {
        addressBookEntities = data;
        addressBookEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

        List<StudentListEntity> studentList = SLCacheUtil.getStudentList(UserService.getInstance().getCurrentUserId());
        for (int i = 0; i < addressBookEntities.size(); i++) {
            boolean isHave = false;
            for (StudentListEntity item : studentList) {
                if (item.getEmail().equals(addressBookEntities.get(i).getEmail())) {
                    isHave = true;
                }
            }
            if (!isHave) {
                AddressBookEntity addressBookEntity = addressBookEntities.get(i);
                addressBookEntity.setId(i);
                AddressBodyItemViewModel item = new AddressBodyItemViewModel(this, addressBookEntity);
                bottomObservableList.add(item);
                allStudentList.add(item);
            }

        }
    }


    public BindingCommand clickSearchClose = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            searchCloseIsVisible.setValue(false);
            bottomObservableList.clear();
            bottomObservableList.addAll(allStudentList);
            clearSearchEdit.setValue(true);
        }
    });
    public TKButton.ClickListener clickBottomRightButton = tkButton -> {
        tkButton.startLoading();
        shareMaterialToStudents(tkButton);
    };
    public TKButton.ClickListener clickBottomLiftButton = tkButton -> {
        finish();
    };

    public BindingCommand<String> changeSearch = new BindingCommand<>(s -> {
        bottomObservableList.clear();

        if (s.equals("")) {
            searchCloseIsVisible.setValue(false);
            bottomObservableList.addAll(allStudentList);
        } else {
            searchCloseIsVisible.setValue(true);
            for (AddressBodyItemViewModel addressBodyItemViewModel : allStudentList) {
                if (addressBodyItemViewModel.name.getValue() != null) {
                    if (addressBodyItemViewModel.name.getValue().toLowerCase().contains(s.toLowerCase())) {
                        bottomObservableList.add(addressBodyItemViewModel);
                    }
                }
            }
        }

    });

    /**
     * 获取通讯录中的email
     */
    private void getDeviceContact() {
        setIsShowProgress(true);
        ContactType contactType = new ContactType(TApplication.getInstance().getBaseContext());
        addSubscribe(
                contactType.getContacts(true)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            setIsShowProgress(false);
                            addressBookEntities = data;
                            addressBookEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

                            List<StudentListEntity> studentList = SLCacheUtil.getStudentList(UserService.getInstance().getCurrentUserId());
                            for (int i = 0; i < addressBookEntities.size(); i++) {
                                addressBookEntities.get(i).setId(i);
                                boolean isHave = false;
                                for (StudentListEntity item : studentList) {
                                    if (item.getEmail().equals(addressBookEntities.get(i).getEmail())) {
                                        isHave = true;
                                    }
                                }
                                if (!isHave) {
                                    AddressBookEntity addressBookEntity = addressBookEntities.get(i);
                                    addressBookEntity.setId(i);
                                    AddressBodyItemViewModel item = new AddressBodyItemViewModel(this, addressBookEntity);
                                    bottomObservableList.add(item);
                                    allStudentList.add(item);
                                }
                            }
                        }, throwable -> {
                            setIsShowProgress(false);
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    /**
     * 获取通讯录中的Phone
     */
    private void getDeviceContactPhone() {
        setIsShowProgress(true);
        ContactType contactType = new ContactType(TApplication.getInstance().getBaseContext());
        addSubscribe(
                contactType.getContacts(false)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            setIsShowProgress(false);
                            addressBookEntities = data;
                            for (int i = 0; i < addressBookEntities.size(); i++) {
                                AddressBookEntity addressBookEntity = addressBookEntities.get(i);
                                addressBookEntity.setId(i);
                                AddressBodyItemViewModel item = new AddressBodyItemViewModel(this, addressBookEntity);
                                bottomObservableList.add(item);
                                allStudentList.add(item);

                            }
                        }, throwable -> {
                            setIsShowProgress(false);
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    /**
     * 获取教师的学生列表 (students_list)
     */
    public void getAppContact() {
        List<StudentListEntity> studentList = SLCacheUtil.getStudentList(UserService.getInstance().getCurrentUserId());
        if (pageAction == PageAction.shareStudioMaterial){
            studentList = AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId());
        }
        addressBookEntities.clear();
        bottomObservableList.clear();
        allStudentList.clear();
        boolean isMultipleSelect = selectedMaterials.size() == 1;
        List<String> selectedIds = new ArrayList<>();
        for (MaterialEntity selectedMaterial : selectedMaterials) {
            selectedIds.addAll(selectedMaterial.getStudentIds());
        }


        if (studentList.size() > 0) {
            toggleShowBodyItemListView(true);
            studentList.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

            for (int i = 0; i < studentList.size(); i++) {
                AddressBookEntity addressBookEntity = new AddressBookEntity();
                addressBookEntity.setEmail(studentList.get(i).getEmail());
                addressBookEntity.setuId(studentList.get(i).getStudentId());
                addressBookEntity.setName(studentList.get(i).getName());
                addressBookEntities.add(addressBookEntity);

                AddressBodyItemViewModel item = new AddressBodyItemViewModel(this, studentList.get(i));
                if (selectedIds.contains(studentList.get(i).getStudentId())) {
                    item.setSelect(true);
                    item.isEnable = isMultipleSelect;
                    AddressBookItemViewModel headerItem = new AddressBookItemViewModel(this, addressBookEntity, headerObservableList.size());
                    headerItem.isEnable = isMultipleSelect;
                    headerObservableList.add(headerItem);
                    checkedDate.add(addressBookEntity);
                }
                bottomObservableList.add(item);
                allStudentList.add(item);
            }
            setShowHeaderRv();
        }
    }


    public void changChecked(AddressBookEntity data) {

        for (int i = 0; i < bottomObservableList.size(); i++) {
            if (typeFromContactTypes == ContactTypes.appContact) {
                if (bottomObservableList.get(i).data.getValue().getuId().equals(data.getuId())) {
                    bottomObservableList.get(i).setSelect(false);
                }
            } else {
                if (bottomObservableList.get(i).data.getValue().getId() == data.getId()) {
                    bottomObservableList.get(i).setSelect(false);
                }
            }
        }
        int pos = 0;
        for (int i = 0; i < headerObservableList.size(); i++) {
            if (typeFromContactTypes == ContactTypes.appContact) {
                if (headerObservableList.get(i).data.getValue().getuId().equals(data.getuId())) {
                    pos = i;
                }
            } else {
                if (headerObservableList.get(i).data.getValue().getId() == data.getId()) {
                    pos = i;
                }
            }
        }

        headerObservableList.remove(pos);
        checkedDate.remove(pos);
        setShowHeaderRv();
    }


    public void changeDate(AddressBookEntity data, boolean isSelect) {

        int addressBookPos = 0;
        for (int i = 0; i < addressBookEntities.size(); i++) {
            if (typeFromContactTypes == ContactTypes.appContact) {
                if (addressBookEntities.get(i).getuId().equals(data.getuId())) {
                    addressBookPos = i;
                }
            } else {
                if (addressBookEntities.get(i).getId() == data.getId()) {
                    addressBookPos = i;
                }
            }

        }
        int allStudentListPos = 0;
        if (typeFromContactTypes == ContactTypes.appContact) {
            for (int i = 0; i < allStudentList.size(); i++) {
                if (allStudentList.get(i).data.getValue().getuId().equals(data.getuId())) {
                    allStudentListPos = i;
                }
            }
        } else {
            for (int i = 0; i < allStudentList.size(); i++) {
                if (allStudentList.get(i).data.getValue().getId() == data.getId()) {
                    allStudentListPos = i;
                }
            }
        }


        AddressBookItemViewModel item = new AddressBookItemViewModel(this, addressBookEntities.get(addressBookPos), headerObservableList.size());
        allStudentList.get(allStudentListPos).isSelect = isSelect;

        if (isSelect) {
            headerObservableList.add(item);
            checkedDate.add(addressBookEntities.get(addressBookPos));
        } else {
            for (int a = 0; a < headerObservableList.size(); a++) {
                if (typeFromContactTypes == ContactTypes.appContact) {
                    if (headerObservableList.get(a).data.getValue().getuId().equals(addressBookEntities.get(addressBookPos).getuId())) {
                        headerObservableList.remove(a);
                        checkedDate.remove(a);
                    }
                } else {
                    if (headerObservableList.get(a).data.getValue().getId() == addressBookEntities.get(addressBookPos).getId()) {
                        headerObservableList.remove(a);
                        checkedDate.remove(a);
                    }
                }

            }
        }
        setShowHeaderRv();


    }

    private void setShowHeaderRv() {


        boolean value = headerObservableList.size() > 0;
        topRvIsVisible.setValue(value);
        bottomButtonIsEnable.setValue(value);
    }


    @Override
    public void initToolbar() {
        setLeftImgButtonVisibility(View.VISIBLE);
        setLeftButtonIcon(R.mipmap.ic_back_primary);
        if (pageAction == PageAction.shareMaterial||pageAction == PageAction.shareStudioMaterial) {
            setTitleString("Contacts");
        } else if (pageAction == PageAction.addStudentFromAddressBook) {
            if (typeFromContactTypes == ContactTypes.addressBook) {
                setTitleString("Device contacts");
            } else if (typeFromContactTypes == ContactTypes.googleContact) {
                setTitleString("Google contacts");
            }
        } else if (pageAction == PageAction.sendMessage) {
            setTitleString("Device contacts");
        }
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    public void toggleShowBodyItemListView(boolean show) {
        if (show) {
            bottomBtnContainerIsVisible.setValue(true);
        } else {
            bottomBtnContainerIsVisible.setValue(false);
        }
    }

    public static class UIEventObservable {
        public SingleLiveEvent<Void> shareMaterial = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> toNewContact = new SingleLiveEvent<>();
    }

    public UIEventObservable uc = new UIEventObservable();

    public TKButton.ClickListener submitButton = tkButton -> {
        if (pageAction == PageAction.addStudentFromAddressBook) {
            addStudent();
        }
        if (pageAction == PageAction.sendMessage) {
            AtomicBoolean isSuccess = new AtomicBoolean(false);
            addSubscribe(
                    UserService
                            .getStudioInstance()
                            .getStudioInfo()
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(data -> {
                                if (!isSuccess.get()) {
                                    isSuccess.set(true);
                                    if (data.getName() != null && !data.getName().equals("")) {
                                        studioName = "[" + data.getName() + "] ";
                                    }

                                    sendMessage.setValue(checkedDate);
                                }

                            }, throwable -> {
                                if (!isSuccess.get()) {
                                    Logger.e("失败,失败原因" + throwable.getMessage());
                                }
                                sendMessage.setValue(checkedDate);
                            })

            );

        }
    };
//    public BindingCommand<SubmitButton> submitButton = new BindingCommand<>(new BindingConsumer<SubmitButton>() {
//        @Override
//        public void call(SubmitButton submitButton) {
//            if (pageAction == PageAction.addStudentFromAddressBook) {
//                addStudent();
//            }
//            if (pageAction == PageAction.sendMessage) {
//                AtomicBoolean isSuccess = new AtomicBoolean(false);
//                addSubscribe(
//                        UserService
//                                .getStudioInstance()
//                                .getStudioInfo()
//                                .subscribeOn(Schedulers.io())
//                                .observeOn(AndroidSchedulers.mainThread(), true)
//                                .subscribe(data -> {
//                                    if (!isSuccess.get()) {
//                                        isSuccess.set(true);
//                                        if (data.getName() != null && data.getName() != "") {
//                                            studioName = "[" + data.getName() + "] ";
//                                        }
//
//                                        sendMessage.setValue(checkedDate);
//                                    }
//
//                                }, throwable -> {
//                                    if (!isSuccess.get()) {
//                                        Logger.e("失败,失败原因" + throwable.getMessage());
//                                    }
//                                    sendMessage.setValue(checkedDate);
//                                })
//
//                );
//
//            }
//
//        }
//    });

    /**
     * 分享 material(s) 给选定的 student
     */
    public void shareMaterialToStudents(TKButton tkButton) {
        List<String> studentIds = new ArrayList<>();
        for (int i = 0; i < checkedDate.size(); i++) {
            studentIds.add(checkedDate.get(i).getuId());
        }
        //老版本的分享
//        addSubscribe(
//                MaterialService
//                        .getInstance()
//                        .shareMaterial(studentIds, selectedMaterials, isInFolder)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            SLToast.success("Share Successful!");
//                            tkButton.stopLoading();
//                            finish();
//                        }, throwable -> {
//                            Logger.e("失败,失败原因" + throwable.getMessage());
//                            tkButton.stopLoading();
//                            SLToast.showError();
//                        })
//
//        );

        //materialsids
        List<String> materialIds = new ArrayList<>();
        for (int i = 0; i < selectedMaterials.size(); i++) {
            materialIds.add(selectedMaterials.get(i).getId());
        }

        //新版本的分享
        addSubscribe(
                MaterialService.getInstance().shareMaterials(materialIds, studentIds,false)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            SLToast.success("Share Successful!");
                            tkButton.stopLoading();
                            finish();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            tkButton.stopLoading();
                            SLToast.showError();
                        })
        );


        //更老版本的分享
//        Map<String, Object> map = new HashMap<>();
//        map.put("studentIds", studentIds);
//        map.put("materialIds", selectedMaterialIds);
//        map.put("shareFromMaterial", true);
//
//
//        showDialog();
//        CloudFunctions
//                .shareMaterials(map)
//                .addOnCompleteListener(task -> {
//                    dismissDialog();
//                    if (task.isSuccessful()) {
//                        if (task.getResult() != null && task.getResult()) {
//                            finish();
//                            Logger.e("====== share 成功:" + task.getResult());
//                        }
//                    } else {
//                        Logger.e("====== share 异常:" + task.getException());
//                    }
//                    // 重新拉取 material
//
//                });
//
//        List<MaterialAccessControlEntity> entityList = new ArrayList<>();
//        String teacherId = UserService.getInstance().getCurrentUserId();
//        String time = System.currentTimeMillis() / 1000 + "";
//        for (int i = 0; i < selectedMaterialIds.size(); i++) {
//            for (int j = 0; j < studentIds.size(); j++) {
//                MaterialAccessControlEntity entity = new MaterialAccessControlEntity();
//                entity.setId(teacherId + ":" + studentIds.get(j) + ":" + selectedMaterialIds.get(i));
//                entity.setMaterialId(selectedMaterialIds.get(i));
//                entity.setTeacherId(teacherId);
//                entity.setStudentId(studentIds.get(j));
//                entity.setCreateTime(time);
//                entity.setUpdateTime(time);
//                entityList.add(entity);
//            }
//        }
//
//        addSubscribe(MaterialService
//                .getMaterialAccessControlInstance()
//                .createNewMaterialAccess(entityList).subscribeOn(Schedulers.io())
//                .observeOn(AndroidSchedulers.mainThread())
//                .subscribe(aBoolean -> {
//                    Logger.e("-**-*-*-*-*-*-*- 分享 materials 成功");
//                }, throwable -> {
//                    Logger.e("-**-*-*-*-*-*-*- 分享 materials 失败: " + throwable.getMessage());
//                }));


    }
    public void shareMaterialToStudents(){
        showDialog();
        List<String> materialIds = new ArrayList<>();
        for (int i = 0; i < selectedMaterials.size(); i++) {
            materialIds.add(selectedMaterials.get(i).getId());
        }
        List<String> studentIds = new ArrayList<>();
        for (int i = 0; i < checkedDate.size(); i++) {
            studentIds.add(checkedDate.get(i).getuId());
        }
        //新版本的分享
        addSubscribe(
                MaterialService.getInstance().shareMaterials(materialIds, studentIds,true)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();
                            SLToast.success("Share Successful!");
                            finish();
                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })
        );
    }

    /**
     * 添加新的学生
     *
     */
    private void addStudent() {
        showDialog();

//
        List<Map<String, Object>> data = new ArrayList<>();
        for (int i = 0; i < checkedDate.size(); i++) {
            Map<String, Object> map = new HashMap<>();
            map.put("name", checkedDate.get(i).getName());
            map.put("email", checkedDate.get(i).getEmail().trim());
            map.put("phone", "");
            map.put("invitedStatus", "-1");
            map.put("lessonTypeId", "");
            data.add(map);
        }
        Logger.e("????==>%s","?????"+ SLJsonUtils.toJsonString(data));
        CloudFunctions
                .addStudent(data)
                .addOnCompleteListener(task -> {
                    Logger.e("成功==");
                    new Handler().postDelayed(() -> {
                        dismissDialog();
                        if (task.isSuccessful()) {
                            Messenger.getDefault().sendNoMsg("AddStudentSuccess");
                            SLToast.success("Add Student Successful!");
                            finish();
//                            if (checkedDate.size() > 0) {
//                                for (int i = 0; i < checkedDate.size(); i++) {
//                                    checkedDate.get(i).setuId(task.getResult().get(i));
//                                }
////                            Bundle bundle = new Bundle();
////                            bundle.putSerializable("data", (Serializable) checkedDate);
////                            startActivity(NewContactActivity.class, bundle);
//                                //添加学生成功,请去 inactive中添加课程
//
//
//                            }
                        } else {
                            SLToast.showError();
                        }
                    },1000);

                });
    }
}
