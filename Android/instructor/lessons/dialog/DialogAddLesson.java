package com.spelist.tunekey.ui.teacher.lessons.dialog;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddEventActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.SelectStudentActivity;
import com.spelist.tunekey.ui.teacher.lessons.adapter.DialogLessonTypeAdapter;
import com.spelist.tunekey.ui.teacher.lessons.adapter.DialogLessonTypeData;
import com.spelist.tunekey.ui.teacher.lessons.fragments.LessonsFragment;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddEventActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.SelectStudentActivity;
import com.spelist.tunekey.ui.teacher.lessons.adapter.DialogLessonTypeAdapter;
import com.spelist.tunekey.ui.teacher.lessons.adapter.DialogLessonTypeData;
import com.spelist.tunekey.ui.teacher.lessons.fragments.LessonsFragment;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLCacheUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;

public class DialogAddLesson extends DialogFragment {
    private View view;
    private View mDecorView;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    public DialogCallback dialogCallback;
    private boolean isClick = false;//过滤重复点击

//    @BindView(R.id.lesson)
//    TextView lesson;
//    @BindView(R.id.event)
//    TextView event;
//    @BindView(R.id.block)
//    TextView block;
//    @BindView(R.id.lessonDiv)
//    View lessonDiv;
//    @BindView(R.id.cancel_bottom_dialog)
//    TextView cancelBottomDialog;
//    @BindView(R.id.select_to_add)
//    LinearLayout selectToAdd;
//    @BindView(R.id.select_lesson_type)
//    LinearLayout selectLessonType;
//    @BindView(R.id.select_lesson_type_container)
//    LinearLayout selectLessonTypeContainer;
//    @BindView(R.id.lesson_type_list)
//    RecyclerView lessonTypeList;
//    @BindView(R.id.no_lesson_type)
//    TextView noLessonType;

    private LessonsFragment lessonsFragment;
    private List<DialogLessonTypeData> dataList = new ArrayList<>();
    private boolean isShowAddTakeDayOff = true;
    private TextView lesson;
    private View lessonDiv;
    private TextView event;
    private TextView block;
    private TextView cancelBottomDialog;
    private LinearLayout selectLessonTypeContainer;
    private TextView noLessonType;
    private RecyclerView lessonTypeList;
    public DialogAddLesson(){

    }

    public DialogAddLesson(LessonsFragment lessonsFragment, boolean isShowAddTakeDayOff) {
        this.lessonsFragment = lessonsFragment;
        this.isShowAddTakeDayOff = isShowAddTakeDayOff;
    }

    public interface DialogCallback {
        void addLesson();

        void addEvent();

        void addBlock();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        view = inflater.inflate(R.layout.dialog_add_lesson, container, false);
        initVieww();
        mDecorView = FuncUtils.initBottomDialogView(Objects.requireNonNull(getDialog()), getResources());
        return view;
    }

    public void setDialogCallback(DialogCallback dialogCallback) {
        this.dialogCallback = dialogCallback;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

//        initLessonTypeView();
        initLessonType();
        initView();
        FuncUtils.initBottomDialogAnimationIn(mIntoSlide, view);
        initListener();
        touchOutShowDialog();
        getFocus();
    }

    private void initView() {
        if (isShowAddTakeDayOff) {
            block.setVisibility(View.VISIBLE);
            lessonDiv.setVisibility(View.VISIBLE);
        } else {
            block.setVisibility(View.GONE);
            lessonDiv.setVisibility(View.GONE);
        }
    }
    private void initVieww(){
        lesson = (TextView) view.findViewById(R.id.lesson);
        lessonDiv = (View) view.findViewById(R.id.lessonDiv);
        event = (TextView) view.findViewById(R.id.event);
        block = (TextView) view.findViewById(R.id.block);
        cancelBottomDialog = (TextView) view.findViewById(R.id.cancel_bottom_dialog);
        selectLessonTypeContainer = (LinearLayout) view.findViewById(R.id.select_lesson_type_container);
        noLessonType = (TextView) view.findViewById(R.id.no_lesson_type);
        lessonTypeList = (RecyclerView) view.findViewById(R.id.lesson_type_list);
    }

    /**
     * 初始化监听
     */
    private void initListener() {
        selectLessonTypeContainer.setOnClickListener(v -> {
        });
        event.setOnClickListener(v -> {
            lessonsFragment.startActivity(AddEventActivity.class);
            dismissDialog();
        });
        block.setOnClickListener(v -> {
            //  lessonsFragment.startActivity(AddBlockActivity.class);
            Logger.e("lessonsFragment.lessonDisplayType%s", lessonsFragment.lessonDisplayType);
            if (lessonsFragment.lessonDisplayType == 4 && SLCacheUtil.getHaveLesson()) {
                lessonsFragment.takeDayOffDialog();
            } else {
                lessonsFragment.showSelectTakeDayOffDialog(null);
            }
            dismissDialog();
        });
        lesson.setOnClickListener(v -> {
            lessonsFragment.startActivity(SelectStudentActivity.class);
            dismissDialog();
        });
        cancelBottomDialog.setOnClickListener(v -> {
            //执行关闭的动画
            dismissDialog();
            //将其他控件内条目设置成不可以点击的状态
            lesson.setClickable(false);
            event.setClickable(false);
            block.setClickable(false);
        });
    }

    /**
     * 关闭弹窗，过滤重复点滴
     */
    public void dismissDialog() {
        if (isClick) {
            return;
        }
        isClick = true;
        initOutAnimation();
    }

    private void initOutAnimation() {
        mOutSlide = FuncUtils.initBottomDialogAnimationOut(mOutSlide, view);
        mOutSlide.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {

            }

            @Override
            public void onAnimationEnd(Animation animation) {
                isClick = false;
                DialogAddLesson.this.dismiss();
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
        mDecorView.setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) {
                //弹框消失的动画执行相关代码
                dismissDialog();
            }
            return true;
        });
    }

    /**
     * 监听主界面back键
     * 当点击back键时，执行弹窗动画
     */
    private void getFocus() {
        getView().setFocusableInTouchMode(true);
        getView().requestFocus();
        getView().setOnKeyListener((v, keyCode, event) -> {
            // 监听到back键(悬浮手势)返回按钮点击事件
            if (event.getAction() == KeyEvent.ACTION_UP && keyCode == KeyEvent.KEYCODE_BACK) {
                //判断弹窗是否显示
                if (DialogAddLesson.this.getDialog().isShowing()) {
                    //关闭弹窗
                    dismissDialog();
                    return true;
                }
            }
            return false;
        });
    }


    // data connection
    @SuppressLint("CheckResult")
    public void initLessonType() {
        UserService
                .getStudioInstance()
                .getLessonTypeList(false)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(lessonTypeEntities -> {
                    dataList.clear();
                    if (lessonTypeEntities.size() > 0) {
                        for (int i = 0; i < lessonTypeEntities.size(); i++) {
                            DialogLessonTypeData item = new DialogLessonTypeData();
                            LessonTypeEntity lesson = lessonTypeEntities.get(i);
                            item.setId(lesson.getId());
                            item.setImgUrl(lesson.getStoragePath());
                            item.setTimeLength(lesson.getTimeLength());
                            item.setPrice(lesson.getPrice());
                            item.setTitle(lesson.getName());
                            item.setType(lesson.getType());
                            dataList.add(item);
                        }
                        lessonTypeList.setVisibility(View.VISIBLE);
                        noLessonType.setVisibility(View.GONE);
                    } else {
                        lessonTypeList.setVisibility(View.GONE);
                        noLessonType.setVisibility(View.VISIBLE);
                    }
                    LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getActivity().getApplication());
                    lessonTypeList.setLayoutManager(linearLayoutManager);
                    DialogLessonTypeAdapter mAdapter = new DialogLessonTypeAdapter(dataList, getActivity());
                    lessonTypeList.setAdapter(mAdapter);
                    Logger.e("-*-*-*-*-*-*-*- 获取 lesson type 成功 *-*-*-*-*--*-*-*");
                }, throwable -> {
                    Logger.e("-**-*-*-*-*-*-*- 获取 lesson type 失败: " + throwable.getMessage());
                });
    }

}
