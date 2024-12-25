package com.spelist.tunekey.ui.teacher.materials;

import androidx.recyclerview.widget.RecyclerView;

/**
 * 2020/12/23
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public interface MoveCallbackItemTouch {
    void itemTouchOnMove(RecyclerView.ViewHolder holder, int oldPosition, int newPosition, RecyclerView.ViewHolder target);

}
