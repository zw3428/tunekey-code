package com.spelist.tunekey.ui.teacher.materials;

import android.app.Application;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.spelist.tools.viewModel.ToolbarViewModel;

import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

/**
 * Author WHT
 * Description:
 * Date :2019-12-10
 */
public class PreviewPdfVM extends ToolbarViewModel {

    public ObservableField<String> pageTvString = new ObservableField<>();
    public ObservableField<Integer> pageTvVisibility = new ObservableField<>(View.GONE);

    public PreviewPdfVM(@NonNull Application application) {
        super(application);
    }

    public UIClickObservable uc = new UIClickObservable();

    public static class UIClickObservable {
        public SingleLiveEvent<Void> clickShare = new SingleLiveEvent<>();
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Preview pdf");
        setRightButtonText("Share");

    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    @Override
    protected void clickRightTextButton() {
        super.clickRightTextButton();
        uc.clickShare.call();
    }
}
