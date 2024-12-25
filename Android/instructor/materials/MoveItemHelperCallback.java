package com.spelist.tunekey.ui.teacher.materials;

/**
 * 2020/12/23
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */

import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

/**
 * Created by guo on 2018/7/24.
 */

public class MoveItemHelperCallback extends ItemTouchHelper.Callback{
    MoveCallbackItemTouch callbackItemTouch; // interface
    public boolean dragIsEnable = true;
    public MoveItemHelperCallback(MoveCallbackItemTouch callbackItemTouch){
        this.callbackItemTouch = callbackItemTouch;
    }

    public void setDragIsEnable(boolean dragIsEnable){
        this.dragIsEnable = dragIsEnable;
    }


    @Override
    public boolean isLongPressDragEnabled() {
        return dragIsEnable;
    }

    @Override
    public boolean isItemViewSwipeEnabled() {
        return false; // swiped disabled
    }

    @Override
    public int getMovementFlags(RecyclerView recyclerView, RecyclerView.ViewHolder viewHolder) {
        // movements drag 设置可自由拖动的方向
        int dragFlags = ItemTouchHelper.UP | ItemTouchHelper.DOWN | ItemTouchHelper.LEFT| ItemTouchHelper.RIGHT;
        return makeFlag( ItemTouchHelper.ACTION_STATE_DRAG , dragFlags);
    }

    @Override
    public boolean onMove(RecyclerView recyclerView, RecyclerView.ViewHolder viewHolder, RecyclerView.ViewHolder target) {
        //当拖拽时的回调方法， callbackItemTouch就是我们刚刚写的回调接口啦，待会我们会在activity中重写这个子类。
        callbackItemTouch.itemTouchOnMove(viewHolder,viewHolder.getAdapterPosition(),target.getAdapterPosition(),target); // information to the interface
        return false;
    }

    @Override
    public void onSwiped(RecyclerView.ViewHolder viewHolder, int direction) {
        // swiped disabled
    }

}

