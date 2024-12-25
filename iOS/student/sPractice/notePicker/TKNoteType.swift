//
//  TKNoteType.swift
//  TuneKey
//
//  Created by zyf on 2020/6/16.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation

/// 音符
enum TKNoteType: String {
    /// 全音符
    case full = "1|1"

    /// 二分音符 * 2
    case half_2 = "1|2*2"

    /// 二分休止符 + 二分音符
    case half_rest_and_half = "1|0_2"

    /// 二分音符 * 3
    case half_3 = "1|2*3"

    /// 二分休止符 + 二分音符 * 2
    case half_rest_and_half_2 = "1|0_2*2"

    /// 二分音符 + 二分休止符 + 二分音符
    case half_and_half_rest_and_half = "1|2_0_2"

    /// 二分音符 * 2 + 二分休止符
    case half_2_and_half_rest = "1|2*2_0"

    /// 二分休止符 + 二分音符 + 二分休止符
    case half_rest_and_half_and_half_rest = "1|0_2_0"

    /// 四分音符 * 4
    case quarter_4 = "1|4*4"

    /// 四分休止符 + 四分音符 + 四分休止符 + 四分音符
    case quarter_rest_and_quarter_and_quarter_rest_and_quarter = "1|0_4_0_4"

    /// 四分音符 * 2 + 二分音符
    case quarter_2_and_half = "1|4*2_2"

    /// 二分音符 + 四分音符 * 2
    case half_and_quarter_2 = "1|2_4*2"

    /// 附点二分音符 + 四分音符
    case dotted_half_and_quarter = "1|2.5_4"

    /// 四分音符 + 附点二分音符
    case quarter_and_dotted_half = "1|4_2.5"

    /// 四分音符 + 二分音符 + 四分音符
    case quarter_and_half_and_quarter = "1|4_2_4"

    /// 二分音符 * 1
    case half = "2|2"

    /// 四分音符 * 2
    case quarter_2 = "2|4*2"

    /// 四分休止符 + 四分音符
    case quarter_rest_and_quarter = "2|0_4"

    /// 四分音符 * 3
    case quarter_3 = "2|4*3"

    /// 四分休止符 + 四分音符 * 2
    case quarter_rest_and_quarter_2 = "2|0_4*2"

    /// 四分音符 + 四分休止符 + 四分音符
    case quarter_and_quarter_rest_and_quarter = "2|4_0_4"

    /// 四分音符 * 2 + 四分休止符
    case quarter_2_and_quarter_rest = "2|4*2_0"

    /// 四分休止符 + 四分音符 + 四分休止符
    case quarter_rest_and_quarter_and_quarter_rest = "2|0_4_0"

    /// 八分音符 * 4
    case eighth_4 = "2|8*4"

    /// 八分休止符 + 八分音符 + 八分休止符 + 八分音符
    case eighth_rest_and_eighth_and_eighth_rest_and_eighth = "2|0_8_0_8"

    /// 八分音符 * 2 + 四分音符
    case eighth_2_and_quarter = "2|8*2_4"

    /// 四分音符 + 八分音符 * 2
    case quarter_and_eighth_2 = "2|4_8*2"

    /// 附点四分音符 + 八分音符
    case dotted_quarter_and_eighth = "2|4.5_8"

    /// 八分音符 + 附点四分音符
    case eighth_and_dooted_quarter = "2|8_4.5"

    /// 八分音符 + 四分音符 + 八分音符
    case eighth_and_quarter_and_eighth = "2|8_4_8"

    /// 四分音符
    case quarter = "4|4"

    /// 八分音符 * 2
    case eighth_2 = "4|8*2"

    /// 八分休止符 + 八分音符
    case eighth_rest_and_eighth = "4|0_8"

    /// 八分音符 * 3
    case eighth_3 = "4|8*3"

    /// 八分休止符 + 八分音符 * 2
    case eighth_rest_and_eighth_2 = "4|0_8*2"

    /// 八分音符 + 八分休止符 + 八分音符
    case eighth_and_eighth_rest_and_eighth = "4|8_0_8"

    /// 八分音符 * 2 + 八分休止符
    case eighth_2_and_eighth_rest = "4|8*2_0"

    /// 八分休止符 + 八分音符 + 八分休止符
    case eighth_rest_and_eighth_and_eighth_rest = "4|0_8_0"

    /// 十六分音符 * 4
    case sixteenth_4 = "4|16*4"

    /// 十六分休止符 + 十六分音符 + 十六分休止符 + 十六分音符
    case sixteenth_rest_and_sixteenth_and_sixteenth_rest_and_sixteenth = "4|0_16_0_16"

    /// 十六分音符 * 2 + 八分音符
    case sixteenth_2_and_eighth = "4|16*2_8"

    /// 八分音符 + 十六分音符 * 2
    case eighth_and_sixteenth_2 = "4|8_16*2"

    /// 八分附点音符 + 十六分音符
    case dotted_eighth_and_sixteenth = "4|8.5_16"

    /// 十六分音符 + 八分附点音符
    case sixteenth_and_dotted_eighth = "4|16_8.5"

    /// 十六分音符 + 八分音符 + 十六分音符
    case sixteenth_and_eighth_and_sixteenth = "4|16_8_16"

    /// 八分音符
    case eighth = "8|8"

    /// 十六分音符
    case sixteenth_2 = "8|16*2"

    /// 十六分休止符 + 十六分音符
    case sixteenth_rest_and_sixteenth = "8|0_16"

    /// 十六分音符 * 3
    case sixteenth_3 = "8|16*3"

    /// 十六分休止符 + 十六分音符 * 2
    case sixteenth_rest_and_sixteenth_2 = "8|0_16*2"

    /// 十六分音符 + 十六分休止符 + 十六分音符
    case sixteenth_and_sixteenth_rest_and_sixteenth = "8|16_0_16"

    /// 十六分音符 * 2 + 十六分休止符
    case sixteenth_2_and_sixteenth_rest = "8|16*2_0"

    /// 十六分休止符 + 十六分音符 + 十六分休止符
    case sixteenth_rest_and_sixteenth_and_sixteenth_rest = "8|0_16_0"

    /// 三十二分音符 * 4
    case thirty_second_4 = "8|32*4"

    /// 三十二分休止符 + 三十二分音符 + 三十二分休止符 + 三十二分音符
    case thirty_second_rest_and_thirty_second_and_thirty_second_rest_thirty_second = "8|0_32_0_32"

    /// 三十二分音符 * 2 + 十六分音符
    case thirty_second_2_and_sixteenth = "8|32*2_16"

    /// 十六分音符 + 三十二分音符 * 2
    case sixteenth_and_thirty_second_2 = "8|16_32*2"

    /// 附点十六分音符 + 三十二分音符
    case dotted_sixteenth_and_thirty_second = "8|16.5_32"

    /// 三十二分音符 + 附点十六分音符
    case thirty_second_and_dotted_sixteenth = "8|32_16.5"

    /// 三十二分音符 + 十六分音符 + 三十二分音符
    case thirty_second_and_sixteenth_and_thirty_second = "8|32_16_32"
}
