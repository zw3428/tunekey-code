package com.spelist.tunekey.ui.teacher.materials.fragments.dialogs;

import android.annotation.SuppressLint;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;

import com.leocardz.linkpreview.sample.library.SourceContent;
import com.leocardz.linkpreview.sample.library.TextCrawler;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLImageUtils;

import io.reactivex.Observer;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.Disposable;
import io.reactivex.schedulers.Schedulers;

@SuppressLint("NonConstantResourceId")
public class DialogAddMaterial extends DialogFragment {

  

    enum AddMaterialType {
        addFolder,
        normal,
        addLink,
        addMaterialName,
        youtubeLink,
        normalLink,
        selectHomeOrFolder,
        addFolderName
    }

    private View view;
    private View mDecorView;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    public DialogCallback dialogCallback;
    private boolean isClick = false;//过滤重复点击

//    @BindView(R.id.upload_from_computer)
//    TextView uploadFromComputer;
//    @BindView(R.id.phone_or_video_material)
//    TextView phoneOrVideoMaterial;
//    @BindView(R.id.camera)
//    TextView camera;
//    @BindView(R.id.file)
//    TextView file;
//    @BindView(R.id.google_drive_material)
//    TextView googleDriveMaterial;
//    @BindView(R.id.google_google_photo_material)
//    TextView googlePhotoMaterial;
//    @BindView(R.id.link_material)
//    TextView linkMaterial;
//    @BindView(R.id.cancel_bottom_dialog)
//    TextView cancelBottomDialog;
//    @BindView(R.id.link_info_name)
//    TextView linkInfoName;
//    @BindView(R.id.link_info_url)
//    TextView linkInfoUrl;
//    @BindView(R.id.select_material_type)
//    LinearLayout selectMaterialType;
//    @BindView(R.id.type_material_url)
//    LinearLayout typeMaterialUrl;
//    @BindView(R.id.url_info)
//    LinearLayout urlInfo;
//    @BindView(R.id.materials_url)
//    EditText materialsUrl;
//    @BindView(R.id.cancel_button)
//    Button cancelButton;
//    @BindView(R.id.confirm_button_disable)
//    SubmitButton confirmButtonDisable;
//    @BindView(R.id.confirm_button)
//    SubmitButton confirmButton;
//    @BindView(R.id.button_filling)
//    View buttonFilling;
//    @BindView(R.id.material_preview_image)
//    ImageView previewImage;
//    @BindView(R.id.material_preview_play)
//    ImageView previewPlay;
//    @BindView(R.id.add_urls_prompt)
//    TextView addUrlsPrompt;
//    @BindView(R.id.video_material)
//    RelativeLayout videoMaterial;
//    @BindView(R.id.normal_link)
//    ImageView normalLink;
//    @BindView(R.id.audio_record_material)
//    TextView audioRecord;


    //解析链接需要用到的
    private Disposable linkPreviewDisposable;
    private TextCrawler textCrawler;

    // data connection
    private AddMaterialType type;
    public String editTextContent;
    public Boolean isEditing = false;
    public int materialType = 0;

    public DialogAddMaterial(){

    }

    /**
     * 通讯回调接口
     */
    public interface DialogCallback {
        void openUploadViaEmailPopup();
        void addFolder();

        //打开相册
        void openPhoto();

        void openFile();

        void openCamera();

        void openGoogleDrive();

        void openGooglePhoto();

        void openAudioRecord();

        void confirmMaterialName(String name);

        void confirmYoutubeLink(String title, CharSequence url);

        void confirmNormalLink(String title, CharSequence url);

        void openLink();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        view = inflater.inflate(R.layout.dialog_add_material, container, false);
        initView();

        int t = getArguments().getInt("type");
        materialType = t;
        editTextContent = getArguments().getString("name");
        String from = getArguments().getString("from");
        if (from.equals("MaterialFragment")) {
            uploadFromComputer.setVisibility(View.VISIBLE);
        }
        // 初始化 Dialog type
        initDialogType(t);
        //初始化 Dialog view
        initDialogView();
        return view;
    }
    private TextView audioRecord;
    private TextView addFolder;

    private TextView googlePhotoMaterial;
    private ImageView previewImage;
    private ImageView previewPlay;
    private TextView phoneOrVideoMaterial;
    private TextView camera;
    private TextView file;
    private TextView linkMaterial;
    private TextView uploadFromComputer;
    private TextView googleDriveMaterial;
    private TextView cancelBottomDialog;
    private TextView addUrlsPrompt;
    private EditText materialsUrl;
    private RelativeLayout videoMaterial;
    private ImageView normalLink;
    private TextView linkInfoName;
    private TextView linkInfoUrl;
    private Button cancelButton;
    private View buttonFilling;
    private SubmitButton confirmButtonDisable;
    private SubmitButton confirmButton;

    private void initView() {
        addFolder = view.findViewById(R.id.add_folder);
        audioRecord = (TextView) view.findViewById(R.id.audio_record_material);
        googlePhotoMaterial = (TextView) view.findViewById(R.id.google_google_photo_material);
        previewImage = (ImageView) view.findViewById(R.id.material_preview_image);
        previewPlay = (ImageView) view.findViewById(R.id.material_preview_play);
        phoneOrVideoMaterial = (TextView) view.findViewById(R.id.phone_or_video_material);
        camera = (TextView) view.findViewById(R.id.camera);
        file = (TextView) view.findViewById(R.id.file);
        linkMaterial = (TextView) view.findViewById(R.id.link_material);
        uploadFromComputer = (TextView) view.findViewById(R.id.upload_from_computer);
        googleDriveMaterial = (TextView) view.findViewById(R.id.google_drive_material);
        cancelBottomDialog = (TextView) view.findViewById(R.id.cancel_bottom_dialog);
        addUrlsPrompt = (TextView) view.findViewById(R.id.add_urls_prompt);
        materialsUrl = (EditText) view.findViewById(R.id.materials_url);
        videoMaterial = (RelativeLayout) view.findViewById(R.id.video_material);
        normalLink = (ImageView) view.findViewById(R.id.normal_link);
        linkInfoName = (TextView) view.findViewById(R.id.link_info_name);
        linkInfoUrl = (TextView) view.findViewById(R.id.link_info_url);
        cancelButton = (Button) view.findViewById(R.id.cancel_button);
        buttonFilling = (View) view.findViewById(R.id.button_filling);
        confirmButtonDisable = (SubmitButton) view.findViewById(R.id.confirm_button_disable);
        confirmButton = (SubmitButton) view.findViewById(R.id.confirm_button);
    }

    public void setDialogCallback(DialogCallback dialogCallback) {
        this.dialogCallback = dialogCallback;
    }

    @Override
    public void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        //弹窗弹入屏幕的动画
        FuncUtils.initBottomDialogAnimationIn(mIntoSlide, view);
        //根据类型显示弹窗内容
        initDialogViewDisplayType();
        //初始化监听
        initListener();
        //手指点击弹窗外处理
        touchOutShowDialog();
        //back键处理
        getFocus();
    }

    /**
     * 根据业务需求，更改弹窗的一些样式
     */
    private void initDialogView() {
        mDecorView = getDialog().getWindow().getDecorView();
        //设置背景为透明
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            mDecorView.setBackground(new ColorDrawable(Color.TRANSPARENT));
        }

        Window window = getDialog().getWindow();
        WindowManager.LayoutParams layoutParams = window.getAttributes();
        //居屏幕底部
        layoutParams.gravity = Gravity.BOTTOM;
        //给window宽度设置成填充父窗体，解决窗体宽度过小问题
        layoutParams.width = WindowManager.LayoutParams.MATCH_PARENT;

        window.setAttributes(layoutParams);
        mDecorView.setPadding(0, 0, 0, 0);

        window.getDecorView().setMinimumWidth(getResources().getDisplayMetrics().widthPixels);

    }

    private void initDialogType(int t) {
        if (t < 0) {
            type = AddMaterialType.normal;
        } else if (t > 0) {
            type = AddMaterialType.addMaterialName;
        } else {
            type = AddMaterialType.addLink;
        }
    }

    private String initPromptTitle() {
        String title = "Add file";
        switch (materialType) {
            case 1:
                title = "Add photo";
                break;
            case 2:
                title = "Add ppt";
                break;
            case 3:
                title = "Add word";
                break;
            case 4:
                title = "Add audio";
                break;
            case 5:
                title = "Add video";
                break;
            case 8:
                title = "Add txt";
                break;
            case 9:
                title = "Add pdf";
                break;
            case 10:
                title = "Add excel";
                break;
        }
        return title;
    }

    private void initDialogViewDisplayType() {
        if (type == AddMaterialType.addMaterialName) {

            addUrlsPrompt.setText(initPromptTitle());
            materialsUrl.setHint("Title");
            materialsUrl.setText(editTextContent);
            isEditing = true;
            materialsUrl.requestFocus();
        } else if (type == AddMaterialType.normal) {
            addUrlsPrompt.setText("Add urls");
            materialsUrl.setHint("https://");
            isEditing = true;
            materialsUrl.requestFocus();
        }
    }

    private void initListener() {

        /**
         * 避免弹窗关闭
         */
        buttonFilling.setClickable(false);
        confirmButtonDisable.setClickable(false);

        videoMaterial.setClickable(false);
        normalLink.setClickable(false);

        /**
         * "取消"条目的点击事件
         * */
        cancelBottomDialog.setOnClickListener(view -> {
            //执行关闭的动画
            dismissDialog();
            //将其他控件内条目设置成不可以点击的状态
            uploadFromComputer.setClickable(false);
            phoneOrVideoMaterial.setClickable(false);
            camera.setClickable(false);
            file.setClickable(false);
            googleDriveMaterial.setClickable(false);
            linkMaterial.setClickable(false);
        });

        /**
         * 打开 upload via email 弹窗
         * */
        uploadFromComputer.setOnClickListener(view -> {
            //执行打开相机的回调方法
            dialogCallback.openUploadViaEmailPopup();
            //关闭弹窗
            dismissDialog();
        });

        /**
         * "打开相册"条目的点击事件
         * */
        phoneOrVideoMaterial.setOnClickListener(view -> {
            //执行打开相机的回调方法
            dialogCallback.openPhoto();
            //关闭弹窗
            dismissDialog();
        });

        /**
         *  click camera item
         */
        camera.setOnClickListener(view -> {
            dialogCallback.openCamera();
            //关闭弹窗
            dismissDialog();
        });

        /**
         *  click file item
         */
        file.setOnClickListener(view -> {
            dialogCallback.openFile();
            //关闭弹窗
            dismissDialog();
        });

        audioRecord.setOnClickListener(v -> {
            dialogCallback.openAudioRecord();
            dismissDialog();
        });
        addFolder.setOnClickListener(view1 -> {
            dialogCallback.addFolder();
            dismissDialog();
        });


        /**
         * click google drive item
         */
        googleDriveMaterial.setOnClickListener(view -> {
            dialogCallback.openGoogleDrive();
            //关闭弹窗
            dismissDialog();
        });
        googlePhotoMaterial.setOnClickListener(view -> {
            dialogCallback.openGooglePhoto();
            //关闭弹窗
            dismissDialog();
        });

        /**
         *  click link item
         */
        linkMaterial.setOnClickListener(view -> {
//            type = AddMaterialType.addLink;
//            textCrawler = new TextCrawler();
//            selectMaterialType.setVisibility(View.GONE);
            dialogCallback.openLink();
            dismissDialog();
        });

        /**
         * cancel dialog
         */
        cancelButton.setOnClickListener(v -> dismissDialog());

        /**
         * 监听link输入
         */
        materialsUrl.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                editTextContent = s.toString();
                if (type == AddMaterialType.normal) {
                    if (SLStringUtils.isNoNull(s.toString()) && SLStringUtils.isHttpUrl(s.toString())) {
                        confirmButtonDisable.setVisibility(View.GONE);
                        confirmButton.setVisibility(View.VISIBLE);
                    } else {
                        confirmButtonDisable.setVisibility(View.VISIBLE);
                        confirmButton.setVisibility(View.GONE);
                    }
                } else {
                    if (SLStringUtils.isNoNull(s.toString())) {
                        confirmButtonDisable.setVisibility(View.GONE);
                        confirmButton.setVisibility(View.VISIBLE);
                    } else {
                        confirmButtonDisable.setVisibility(View.VISIBLE);
                        confirmButton.setVisibility(View.GONE);
                    }
                }
            }
        });

        confirmButton.setOnClickListener(view -> {
            if (type == AddMaterialType.addLink) {
                linkPreview(materialsUrl.getText().toString());
            } else if (type == AddMaterialType.addMaterialName) {
                materialsUrl.setEnabled(false);
                toggleBottomBtn(false);
                dialogCallback.confirmMaterialName(editTextContent);
            } else if (type == AddMaterialType.youtubeLink) {
                toggleBottomBtn(false);
                dialogCallback.confirmYoutubeLink(editTextContent, linkInfoUrl.getText());
            } else if (type == AddMaterialType.normalLink) {
                toggleBottomBtn(false);
                dialogCallback.confirmNormalLink(editTextContent, linkInfoUrl.getText());
            } else {
                dismissDialog();
            }
        });
    }

    public void toggleBottomBtn(boolean show) {
        if (show) {
            cancelButton.setVisibility(View.VISIBLE);
            buttonFilling.setVisibility(View.VISIBLE);
            confirmButton.reset();
            confirmButton.setButtonStatus(0);
        } else {
            cancelButton.setVisibility(View.GONE);
            buttonFilling.setVisibility(View.GONE);
        }
    }

    /**
     * 解析链接
     *
     * @param link url
     */
    private void linkPreview(String link) {
        type = AddMaterialType.addLink;
//        buttonFilling.setVisibility(View.GONE);
        cancelButton.setVisibility(View.GONE);
        buttonFilling.setVisibility(View.GONE);

        String linkHttp = "", linkHttps = "";
        if (link.contains("http://")) {
            linkHttp = link;
        } else if (link.contains("https://")) {
            linkHttps = link;
        } else {
            linkHttp = "http://" + link;
            linkHttps = "https://" + link;
        }

        makePreview(linkHttps, linkHttp);



        /*textCrawler.makePreview(link)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new Observer<SourceContent>() {
                    @Override
                    public void onSubscribe(Disposable d) {
                        Logger.e("开始解析");
                        linkPreviewDisposable = d;
                    }

                    @Override
                    public void onNext(SourceContent sourceContent) {
                        Logger.e("-**-*-*-*-*-*-*- 解析成功");
                        initLinkView(sourceContent);
                    }

                    @Override
                    public void onError(Throwable e) {
                        Logger.e("====解析失败");
                        toggleBottomBtn(true);
                    }

                    @Override
                    public void onComplete() {

                    }
                });*/

    }

    public void makePreview(String linkHttps, String linkHttp) {
        textCrawler.makePreview(linkHttps)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new Observer<SourceContent>() {
                    @Override
                    public void onSubscribe(Disposable d) {
                        Logger.e("开始解析");
                        linkPreviewDisposable = d;
                    }

                    @Override
                    public void onNext(SourceContent sourceContent) {
                        Logger.e("-**-*-*-*-*-*-*- 解析成功");
                        initLinkView(sourceContent);
                    }

                    @Override
                    public void onError(Throwable e) {
                        Logger.e("====解析失败");
                        textCrawler.makePreview(linkHttp)
                                .subscribeOn(Schedulers.io())
                                .observeOn(AndroidSchedulers.mainThread())
                                .subscribe(new Observer<SourceContent>() {
                                    @Override
                                    public void onSubscribe(Disposable d) {
                                        Logger.e("开始解析");
                                        linkPreviewDisposable = d;
                                    }

                                    @Override
                                    public void onNext(SourceContent sourceContent) {
                                        Logger.e("-**-*-*-*-*-*-*- 解析成功");
                                        initLinkView(sourceContent);
                                    }

                                    @Override
                                    public void onError(Throwable e) {
                                        Logger.e("====解析失败");
                                        toggleBottomBtn(true);
                                        SLToast.error("Please type a correct url!");
                                    }

                                    @Override
                                    public void onComplete() {

                                    }
                                });
                    }

                    @Override
                    public void onComplete() {

                    }
                });
    }

    /**
     * 解析完成开始初始化LinkView
     *
     * @param sourceContent link
     */
    private void initLinkView(SourceContent sourceContent) {
//        Logger.json(SLJsonUtils.toJsonString(sourceContent));
        FuncUtils.toggleSoftInput(materialsUrl, true);
        editTextContent = "";
        toggleBottomBtn(true);
        String title = sourceContent.getTitle();
        String url = sourceContent.getUrl();
        materialsUrl.setHint("Title");
        materialsUrl.setText(title);
        linkInfoName.setText(title);
        linkInfoUrl.setText(url);
        materialsUrl.requestFocus();

        if (sourceContent.getImages() != null && sourceContent.getImages().size() != 0) {
            Logger.e("======%s", sourceContent.getImages().get(0));
            SLImageUtils.normalLoadImage(previewImage, sourceContent.getImages().get(0));
        } else {
            previewImage.setImageResource(R.mipmap.ic_logo);
        }
        if (sourceContent.getCanonicalUrl().equals("www.youtube.com") || sourceContent.getCanonicalUrl().equals("m.youtube.com")) {
            // youtube link
            videoMaterial.setVisibility(View.VISIBLE);
            normalLink.setVisibility(View.GONE);
            type = AddMaterialType.youtubeLink;
            previewPlay.setVisibility(View.VISIBLE);
        } else {
            //normal link
            normalLink.setVisibility(View.VISIBLE);
            videoMaterial.setVisibility(View.GONE);
            type = AddMaterialType.normalLink;
            previewPlay.setVisibility(View.GONE);
        }

    }

    /**
     * 过滤重复点击
     */
    public void dismissDialog() {
        if (isClick) {
            return;
        }
        isClick = true;
        initOutAnimation();
    }

    /**
     * 弹窗弹出屏幕的动画
     */
    private void initOutAnimation() {
        mOutSlide = FuncUtils.initBottomDialogAnimationOut(mOutSlide, view);
        /**
         * 弹出屏幕动画的监听
         */
        mOutSlide.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
            }

            @Override
            public void onAnimationEnd(Animation animation) {
                //过滤重复点击的标记
                isClick = false;
                if (linkPreviewDisposable != null) {
                    if (!linkPreviewDisposable.isDisposed()) {
                        linkPreviewDisposable.dispose();
                    }
                }
                //销毁弹窗
                DialogAddMaterial.this.dismiss();
                clearDialog();
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });

    }

    /**
     * 拦截手势(弹窗外区域)
     */
    @SuppressLint("ClickableViewAccessibility")
    private void touchOutShowDialog() {
//        if (!isEditing) {
        mDecorView.setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) {
                //弹框消失的动画执行相关代码
                dismissDialog();
            }
            return true;
        });
//        }
    }

    /**
     * 监听主界面back键
     * 当点击back键时，执行弹窗动画
     */
    private void getFocus() {
//        if (!isEditing) {
        getView().setFocusableInTouchMode(true);
        getView().requestFocus();
        getView().setOnKeyListener((v, keyCode, event) -> {
            // 监听到back键(悬浮手势)返回按钮点击事件
            if (event.getAction() == KeyEvent.ACTION_UP && keyCode == KeyEvent.KEYCODE_BACK) {
                //判断弹窗是否显示
                if (DialogAddMaterial.this.getDialog().isShowing()) {
                    //关闭弹窗
                    dismissDialog();
                    return true;
                }
            }
            return false;
        });
//        }
    }

    /**
     * 清空弹窗内容
     */
    private void clearDialog() {

        materialsUrl.setText("");
        confirmButton.setVisibility(View.GONE);
        confirmButtonDisable.setVisibility(View.VISIBLE);

    }
}
