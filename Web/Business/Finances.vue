<template>
  <div class="tk-bg-color-selectedBg">
    <div class="tk-container-base" id="tkFinances">
      <div class="tk-layout-flex-row tk-layout-full">
        <div
          class="tk-layout-page-left tk-layout-full-height tk-overflow-y tk-scrollbar"
        >
          <invoice-and-payout-and-setting
            @preview="preview"
            @hidePreview="hidePreview"
            @onClickAdd="onClickAdd"
            @onClickDelete="onClickDelete"
            @initSetting="initSetting"
          >
          </invoice-and-payout-and-setting>
        </div>
        <div
          class="tk-layout-page-right tk-layout-flex-column tk-layout-full-height"
        >
          <div
            class="tk-layout-full tk-overflow-y tk-scrollbar"
            v-if="showPreview"
          >
            <slide-x-left-transition :duration="300" mode="out-in">
              <!-- invoice -->
              <template v-if="previewData.type == businessTabsValue.invoice">
                <invoice-or-receipt
                  v-if="previewData.data"
                  :data="previewData.data"
                  :id="previewData.data.id"
                ></invoice-or-receipt>
              </template>

              <!-- setting -->
              <template v-if="previewData.type == businessTabsValue.setting">
                <!-- invoice title -->
                <div
                  class="card tk-px-margin-bottom-px0 tk-no-shadow tk-layout-full-height tk-layout-flex-column"
                  :key="previewData.settingType"
                  v-if="previewData.settingType == settingType.INVOICE_TITLE"
                >
                  <div
                    class="tk-layout-flex-1 tk-scrollbar tk-overflow-y tk-px-padding-px32"
                  >
                    <tk-input-with-label
                      label="Business Info"
                      :labelBold="true"
                      :value="
                        previewData.data ? previewData.data.businessInfo : ''
                      "
                      @input="updateSetting($event, 'businessInfo')"
                    ></tk-input-with-label>

                    <tk-text-area-with-label
                      label="Address"
                      :labelBold="true"
                      :value="
                        previewData.data
                          ? $dataModules.format.address(
                              previewData.data.address || {}
                            )
                          : ''
                      "
                      :forceOrigin="true"
                      @toggleFocus="showAddressModal"
                    ></tk-text-area-with-label>

                    <tk-text-area-with-label
                      label="Branding"
                      :labelBold="true"
                      :value="previewData.data ? previewData.data.branding : ''"
                      @input="updateSetting($event, 'branding')"
                      class="tk-px-margin-bottom-px0"
                    ></tk-text-area-with-label>
                  </div>

                  <!-- button -->
                  <div class="tk-text-center tk-px-margin-tb-px32">
                    <base-button
                      type="main"
                      class="tk-footer-btn-base"
                      @click.stop="saveInvoiceTitle"
                      >{{ $t("button.save").toUpperCase() }}</base-button
                    >
                  </div>
                </div>

                <!-- auto invoicing -->
                <div
                  class="card tk-px-margin-bottom-px0 tk-no-shadow tk-layout-full-height tk-layout-flex-column"
                  :key="previewData.settingType"
                  v-if="previewData.settingType == settingType.AUTO_INVOICING"
                >
                  <div
                    class="tk-layout-flex-1 tk-scrollbar tk-overflow-y tk-px-padding-px32"
                  >
                    <!-- auto invoice -->
                    <!-- <tk-item-with-switch
                      label="Auto-invoicing general settings"
                      :labelBold="true"
                    >
                      <label
                        class="tk-font-color-gray tk-text-base tk-px-margin-top-px0 tk-px-margin-bottom-px16"
                        >Manage student's general Auto-invoicing settings, and setup customizable invoice template.</label
                      >
                    </tk-item-with-switch> -->

                    <!-- flat amount -->
                    <tk-item-with-switch
                      label="Flat Amount"
                      :labelBold="true"
                      :value="
                        previewData.data.autoInvoicingSetting.flatAmount.enable
                      "
                      @input="
                        previewData.data.autoInvoicingSetting.flatAmount.enable =
                          $event
                      "
                    >
                      <tk-input-with-label
                        v-if="
                          previewData.data.autoInvoicingSetting.flatAmount
                            .enable
                        "
                        :showLabel="false"
                        :value="
                          previewData.data.autoInvoicingSetting.flatAmount
                            .amount
                        "
                        :prefix="$tkCurrency.symbol"
                        suffix="for cycle"
                        type="number"
                        @input="
                          previewData.data.autoInvoicingSetting.flatAmount.amount =
                            $event
                        "
                      ></tk-input-with-label>
                      <div
                        class="tk-font-color-gray tk-text-base tk-px-margin-bottom-px16"
                      >
                        Turn this on if you charge a fixed sum for the entire
                        billing cycle.
                      </div>
                    </tk-item-with-switch>

                    <!-- sales tax & late fee & other fees -->
                    <card
                      outerClass="tk-border-color-gray-200 tk-no-shadow tk-no-scroll"
                      innerClass="tk-px-padding-px16"
                      bottom="tk-px-margin-bottom-px20"
                    >
                      <!-- sale tax & late fee -->
                      <div class="tk-layout-flex-row tk-px-margin-bottom-px32">
                        <!-- sale tax -->
                        <tk-number-with-type
                          class="tk-layout-flex-1 tk-px-margin-right-px32"
                          bottom="tk-px-margin-bottom-px0"
                          label="Sales Tax"
                          :labelBold="true"
                          :value="salesTax"
                          :showType="false"
                          :max="100"
                          type="PERCENTAGE"
                          @input="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.salesTax'
                            )
                          "
                        ></tk-number-with-type>

                        <!-- late fee -->
                        <tk-number-with-type
                          class="tk-layout-flex-1"
                          bottom="tk-px-margin-bottom-px0"
                          label="Late Fee"
                          :labelBold="true"
                          :value="lateFee"
                          :max="100"
                          :type="lateFeeType"
                          @input="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.lateFee'
                            )
                          "
                        ></tk-number-with-type>
                      </div>

                      <!-- currency -->
                      <div class="tk-layout-flex-row tk-px-margin-bottom-px32">
                        <tk-input-with-label
                          :showInput="false"
                          label="Currency"
                          :labelBold="true"
                          class="tk-layout-flex-1 tk-px-margin-right-px32"
                          bottom="tk-px-margin-bottom-px0"
                        >
                          <template slot="content">
                            <div
                              class="form-control-muted tk-px-radius-px4 tk-text-base-bold tk-cursor-pointer tk-px-padding-px16 tk-layout-flex-row"
                              @click.stop="showCurrencyModel = true"
                            >
                              <span class="tk-layout-flex-1">{{
                                studioInfo.currency && studioInfo.currency.name
                                  ? studioInfo.currency.name
                                  : ""
                              }}</span>

                              <i
                                class="fa-solid fa-right-left tk-font-color-main tk-px-margin-left-px16"
                              ></i>
                            </div>
                          </template>
                        </tk-input-with-label>
                        <div class="tk-layout-flex-1"></div>
                      </div>

                      <!-- other fee -->
                      <tk-number-with-type
                        v-for="(item, index) in otherFees"
                        bottom="tk-px-margin-bottom-px32"
                        :key="index"
                        :label="item.title"
                        :labelBold="true"
                        :value="item.amount"
                        :type="item.amountType"
                        :showDelete="true"
                        @onDelete="deleteOtherFee(index)"
                        @input="
                          updateSetting(
                            $event,
                            'autoInvoicingSetting.otherFees',
                            index
                          )
                        "
                      >
                        {{ item.amountType }}
                      </tk-number-with-type>

                      <!-- other fee -->
                      <div
                        class="tk-text-center tk-text-base-bold tk-font-color-main tk-cursor-pointer"
                        @click.stop="showOtherFee = true"
                      >
                        <span>Add other fees</span>
                      </div>
                    </card>

                    <!-- send automatically -->
                    <tk-item-with-switch
                      label="Send Invoice Automatically"
                      :labelBold="true"
                      :value="
                        previewData.data.autoInvoicingSetting
                          .isSendAutomatically
                      "
                      @input="
                        updateSetting(
                          $event,
                          'autoInvoicingSetting.isSendAutomatically'
                        )
                      "
                    >
                      <label
                        class="tk-font-color-gray tk-text-base tk-px-margin-top-px0 tk-px-margin-bottom-px16"
                        >If turn on, the invoices will be sent automatically on
                        the invoice date. If turn off, you can find and send
                        invoices manually by navigating to the "Business >
                        Invoices" tab.</label
                      >
                    </tk-item-with-switch>

                    <!-- add lessons to first auto invoice -->
                    <tk-item-with-switch
                      label="Including Unsettled Items"
                      :labelBold="true"
                      :value="
                        previewData.data.autoInvoicingSetting
                          .addLessonToFirstInvoice
                      "
                      @input="
                        updateSetting(
                          $event,
                          'autoInvoicingSetting.addLessonToFirstInvoice'
                        )
                      "
                    >
                      <label
                        class="tk-font-color-gray tk-text-base tk-px-margin-top-px0 tk-px-margin-bottom-px16"
                        >If you turn on and change the billing cycle, the first
                        invoice of the new cycle will include any unsettled
                        items from the previous billing cycle.</label
                      >
                    </tk-item-with-switch>

                    <!-- billing cycle & invoice date & due date & late date -->
                    <card
                      outerClass="tk-border-color-gray-200 tk-no-shadow tk-no-scroll "
                      innerClass="tk-px-padding-px16"
                      bottom="tk-px-margin-bottom-px20"
                    >
                      <!-- billing cycle -->
                      <div class="tk-px-margin-bottom-px32">
                        <label
                          class="form-control-label tk-text-base-bold tk-px-margin-bottom-px6"
                          >General Billing Cycle</label
                        >
                        <single-select
                          :selections="billingCyclesType"
                          :labelBold="true"
                          :data="billingCycle"
                          itemClass="tk-text-center"
                          @onClick="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.billingCycle'
                            )
                          "
                        ></single-select>
                        <div class="tk-font-color-gray tk-px-margin-top-px10">
                          The studio's general billing cycle will be set as the
                          default.
                          <!-- To set a billing cycle for a specific
                          student, click on
                          <span
                            class="tk-font-color-main tk-cursor-pointer"
                            @click.stop="
                              onClickAdd($dataModules.invoice.type.AUTO_INVOICE)
                            "
                            >"Personalize"</span
                          > -->
                        </div>
                      </div>

                      <!-- billing cycle date -->
                      <div class="tk-px-margin-bottom-px32">
                        <div
                          class="tk-layout-flex-row tk-layout-flex-vertical-center"
                        >
                          <div
                            class="tk-text-base-bold tk-px-margin-bottom-px6 tk-layout-flex-1"
                          >
                            Start Date
                          </div>
                          <!-- weekly -->
                          <div
                            v-if="
                              billingCycle.id == billingCyclesType[0].id &&
                              weekCycle.filter(
                                (item) => item.id == billingCycleDate.id
                              ).length > 0
                            "
                            class="tk-px-margin-bottom-px6 tk-font-color-gray"
                          >
                            Every
                            {{
                              $tools.formatWeekdayStrFull(
                                billingCycleDate.id - 1
                              )
                            }}
                          </div>
                          <!-- biweekly -->
                          <div
                            v-if="
                              billingCycle.id == billingCyclesType[1].id &&
                              weekCycle.filter(
                                (item) => item.id == billingCycleDate.id
                              ).length > 0
                            "
                            class="tk-px-margin-bottom-px6 tk-font-color-gray"
                          >
                            Every other
                            {{
                              $tools.formatWeekdayStrFull(
                                billingCycleDate.id - 1
                              )
                            }}
                          </div>
                          <!-- monthly -->
                          <div
                            v-if="
                              billingCycle.id == billingCyclesType[2].id &&
                              monthCycle.filter(
                                (item) =>
                                  item.id == billingCycleDate.id &&
                                  weekCycle.filter((wk) => wk.name == item.name)
                                    .length == 0
                              ).length > 0
                            "
                            class="tk-px-margin-bottom-px6 tk-font-color-gray"
                          >
                            <template v-if="billingCycleDate.id < 0">{{
                              billingCycleDate.name
                            }}</template>
                            <template v-else
                              >Every
                              {{
                                monthCycle.filter(
                                  (item) => item.id == billingCycleDate.id
                                )[0].name
                              }}
                              of each month</template
                            >
                          </div>
                        </div>
                        <!-- . every monday > . every other Monday > . every 1st of
                        each month > -->
                        <single-select
                          :selections="
                            billingCycle.id == billingCyclesType[2].id
                              ? monthCycle
                              : weekCycle
                          "
                          :labelBold="true"
                          :data="billingCycleDate"
                          @onClick="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.billingCycleDate'
                            )
                          "
                          itemClass="tk-text-center"
                        ></single-select>
                        <div class="tk-font-color-gray tk-px-margin-top-px10">
                          Set beginning date of the billing cycle
                        </div>
                      </div>

                      <div class="tk-layout-flex-row">
                        <!-- invoice date -->
                        <tk-input-with-label
                          class="tk-layout-flex-1 tk-px-margin-right-px32"
                          bottom="tk-px-margin-bottom-px32"
                          label="Invoice Date"
                          underText="Set # of the days before billing cycle to send invoice"
                          :labelBold="true"
                          type="number"
                          :isInt="true"
                          :value="
                            previewData.data.autoInvoicingSetting.invoiceDate
                          "
                          @input="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.invoiceDate'
                            )
                          "
                          :suffix="
                            previewData.data.autoInvoicingSetting.invoiceDate >
                            0
                              ? 'days'
                              : ''
                          "
                          :min="1"
                          :max="15"
                          :forceMin="true"
                        ></tk-input-with-label>

                        <!-- due date -->
                        <tk-input-with-label
                          class="tk-layout-flex-1"
                          bottom="tk-px-margin-bottom-px32"
                          label="Due Date"
                          underText="Set # of the days before billing cycle as due day for the invoice"
                          :labelBold="true"
                          type="number"
                          :isInt="true"
                          :value="previewData.data.autoInvoicingSetting.dueDate"
                          @input="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.dueDate'
                            )
                          "
                          :suffix="
                            previewData.data.autoInvoicingSetting.dueDate > 0
                              ? 'days'
                              : previewData.data.autoInvoicingSetting.dueDate ==
                                0
                              ? 'Same day'
                              : 'No due day'
                          "
                          :max="
                            previewData.data.autoInvoicingSetting.invoiceDate -
                            1
                          "
                          :min="0"
                        ></tk-input-with-label>
                      </div>

                      <div class="tk-layout-flex-row">
                        <!-- late date -->
                        <tk-input-with-label
                          class="tk-layout-flex-1 tk-px-margin-right-px32"
                          bottom="tk-px-margin-bottom-px0"
                          label="Late Date"
                          underText="Set # of the days pass the billing cycle date as late day"
                          :labelBold="true"
                          type="number"
                          :isInt="true"
                          :value="
                            previewData.data.autoInvoicingSetting.lateDate
                          "
                          @input="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.lateDate'
                            )
                          "
                          :suffix="
                            previewData.data.autoInvoicingSetting.lateDate > 0
                              ? 'days'
                              : 'No late day'
                          "
                          :max="7"
                        ></tk-input-with-label>
                        <div class="tk-layout-flex-1"></div>
                      </div>
                    </card>

                    <!-- invoice notes & email -->
                    <card
                      outerClass="tk-border-color-gray-200 tk-no-shadow tk-no-scroll"
                      innerClass="tk-px-padding-px16"
                      bottom="tk-px-margin-bottom-px20"
                    >
                      <!-- invoice notes -->
                      <tk-text-area-with-label
                        label="Invoice Notes"
                        bottom="tk-px-margin-bottom-px32"
                        :labelBold="true"
                        :value="previewData.data.autoInvoicingSetting.notes"
                        @input="
                          updateSetting($event, 'autoInvoicingSetting.notes')
                        "
                      ></tk-text-area-with-label>

                      <!-- invoice email -->
                      <template>
                        <div class="tk-px-margin-bottom-px32">
                          <div class="tk-layout-flex-row">
                            <span class="tk-layout-flex-1"
                              >Invoice Email on Issue Date</span
                            >
                            <span
                              class="tk-font-color-main tk-cursor-pointer"
                              @click.stop="
                                targetTemplate = $tools.equalValue(
                                  emailTemplatesMap.issue
                                );
                                showInvoiceEmailTemplate = true;
                              "
                              >Edit</span
                            >
                          </div>
                          <div
                            class="tk-font-color-gray tk-px-margin-top-px4"
                            v-html="
                              formatReminderText(
                                emailTemplatesMap.issue.subject,
                                {
                                  prefix: 'Subject: ',
                                }
                              )
                            "
                          ></div>
                        </div>

                        <div class="tk-px-margin-bottom-px32">
                          <div class="tk-layout-flex-row">
                            <span class="tk-layout-flex-1"
                              >Invoice Email on Due Date</span
                            >
                            <span
                              class="tk-font-color-main tk-cursor-pointer"
                              @click.stop="
                                targetTemplate = $tools.equalValue(
                                  emailTemplatesMap.due
                                );
                                showInvoiceEmailTemplate = true;
                              "
                              >Edit</span
                            >
                          </div>
                          <div
                            class="tk-font-color-gray tk-px-margin-top-px4"
                            v-html="
                              formatReminderText(
                                emailTemplatesMap.due.subject,
                                {
                                  prefix: 'Subject: ',
                                }
                              )
                            "
                          ></div>
                        </div>

                        <div class="tk-px-margin-bottom-px32">
                          <div class="tk-layout-flex-row">
                            <span class="tk-layout-flex-1"
                              >Invoice Email on Late Date</span
                            >
                            <span
                              class="tk-font-color-main tk-cursor-pointer"
                              @click.stop="
                                targetTemplate = $tools.equalValue(
                                  emailTemplatesMap.late
                                );
                                showInvoiceEmailTemplate = true;
                              "
                              >Edit</span
                            >
                          </div>
                          <div
                            class="tk-font-color-gray tk-px-margin-top-px4"
                            v-html="
                              formatReminderText(
                                emailTemplatesMap.late.subject,
                                {
                                  prefix: 'Subject: ',
                                }
                              )
                            "
                          ></div>
                        </div>

                        <div>Invoice Email Destination</div>
                        <multiple-select
                          :selections="emailTo"
                          :labelBold="true"
                          :data="emailNoticeDestination"
                          @onClick="
                            updateSetting(
                              $event,
                              'autoInvoicingSetting.emailNoticeDestination'
                            )
                          "
                        ></multiple-select>
                      </template>
                    </card>

                    <!-- enable students -->
                    <card
                      outerClass="tk-border-color-gray-200 tk-no-shadow tk-no-scroll"
                      innerClass="tk-px-padding-px16"
                    >
                      <div>
                        <div class="tk-layout-flex-row">
                          <div class="tk-text-base-bold tk-layout-flex-1">
                            Toggle & Personlize ({{
                              $commons
                                .mapToArray(invoiceConfigsMap)
                                .filter(
                                  (item) =>
                                    item.status ==
                                    $dataModules.invoiceConfig.status.active
                                ).length
                            }}
                            / {{ Object.keys(invoiceConfigsMap || {}).length }})
                          </div>
                          <div
                            class="tk-text-base-bold tk-font-color-main tk-cursor-pointer"
                            v-if="!showEnableStudent"
                            @click.stop="showEnableStudent = true"
                          >
                            Set
                          </div>
                          <div class="tk-text-base-bold" v-else>
                            <span
                              class="tk-font-color-orange tk-cursor-pointer"
                              @click.stop="onClickToggleAll(false)"
                              >Disable All</span
                            >
                            <span
                              class="tk-px-margin-left-px20 tk-font-color-main tk-cursor-pointer"
                              @click.stop="onClickToggleAll(true)"
                              >Enable All</span
                            >
                            <span
                              class="tk-px-margin-left-px20 tk-font-color-main tk-cursor-pointer"
                              @click.stop="showEnableStudent = false"
                              >Confirm</span
                            >
                          </div>
                        </div>

                        <div
                          class="tk-font-color-gray tk-px-margin-top-px10"
                          v-if="!showEnableStudent"
                        >
                          Toggle to enable auto-invoicing and personlize
                          settings for specific students.
                        </div>

                        <div
                          class="tk-font-color-gray tk-px-margin-top-px10"
                          v-else
                        >
                          Turn on to enable auto-invoicing and tap on student
                          name to personalize settings.
                        </div>

                        <!-- !showEnableStudent && -->
                        <div
                          v-if="showEnableStudent"
                          class="tk-px-margin-top-px10"
                        >
                          <div class="row tk-px-margin-lr-px0">
                            <template
                              v-for="(item, index) in ascStudentListArray"
                            >
                              <div
                                class="col-6 tk-px-padding-px0"
                                v-if="item"
                                :key="item.id"
                              >
                                <card
                                  :class="[
                                    index % 2 == 0
                                      ? 'tk-px-margin-right-px8'
                                      : 'tk-px-margin-left-px8',
                                  ]"
                                  :bottom="
                                    index < ascStudentListArray.length - 2
                                      ? 'tk-px-margin-bottom-px16'
                                      : 'tk-px-margin-bottom-px0'
                                  "
                                  outerClass="tk-border-color-gray-200 tk-no-shadow"
                                  innerClass="tk-px-padding-px16"
                                  @onClick="onClickStudent(item)"
                                >
                                  <div class="tk-layout-flex-row">
                                    <div
                                      class="tk-layout-flex-1 tk-cursor-pointer"
                                      @click.stop="
                                        onClickAdd(
                                          $dataModules.invoice.type
                                            .AUTO_INVOICE,
                                          studentsListMap[item.studentId]
                                        )
                                      "
                                    >
                                      {{ studentsListMap[item.studentId].name }}
                                    </div>
                                    <base-switch
                                      v-if="
                                        invoiceConfigsMap[
                                          studioInfo.id + ':' + item.studentId
                                        ]
                                      "
                                      :value="
                                        invoiceConfigsMap[
                                          studioInfo.id + ':' + item.studentId
                                        ].status ==
                                        $dataModules.invoiceConfig.status.active
                                      "
                                      @input="
                                        $event
                                          ? (invoiceConfigsMap[
                                              studioInfo.id +
                                                ':' +
                                                item.studentId
                                            ].status =
                                              $dataModules.invoiceConfig.status.active)
                                          : (invoiceConfigsMap[
                                              studioInfo.id +
                                                ':' +
                                                item.studentId
                                            ].status =
                                              $dataModules.invoiceConfig.status.stopped)
                                      "
                                      on-text="Yes"
                                      off-text="No"
                                      type="main"
                                    ></base-switch>
                                  </div>
                                  <!-- <div
                                    class="tk-font-color-gray tk-px-margin-top-px10"
                                    v-if="
                                      !$tools.isNull(
                                        formatConfigDesc(item) &&
                                          item.isCustomized
                                      )
                                    "
                                  >
                                    {{ formatConfigDesc(item) }}
                                  </div> -->
                                  <div
                                    class="tk-font-color-gray tk-px-margin-top-px10 tk-bg-color-selectedBg tk-px-padding-px10 tk-cursor-pointer"
                                    v-if="
                                      !$tools.isNull(
                                        formatCustomizeConfigDesc(item)
                                      )
                                    "
                                  >
                                    {{ formatCustomizeConfigDesc(item) }}
                                  </div>
                                </card>
                              </div>
                            </template>
                          </div>
                        </div>
                      </div>
                    </card>
                  </div>

                  <div class="tk-text-center tk-px-margin-tb-px32">
                    <base-button
                      type="main"
                      class="tk-footer-btn-base"
                      @click.stop="
                        saveAutoInvoicing(
                          !previewData.data.autoInvoicingSetting
                            .isSendAutomatically
                        )
                      "
                      >{{ $t("button.save").toUpperCase() }}</base-button
                    >
                  </div>
                </div>

                <!-- online payment -->
                <div
                  class="card tk-px-margin-bottom-px0 tk-no-shadow tk-layout-full-height tk-layout-flex-column"
                  :key="previewData.settingType"
                  v-if="previewData.settingType == settingType.ONLINE_PAYMENT"
                >
                  <div
                    class="tk-layout-flex-1 tk-scrollbar tk-overflow-y tk-px-padding-px32"
                  >
                    <tk-item-with-switch
                      label="Online Payment"
                      :labelBold="true"
                      :value="previewData.data.enableOnlinePayments"
                      @input="updateSetting($event, 'enableOnlinePayments')"
                    >
                      <label
                        class="tk-font-color-gray tk-text-base tk-px-margin-top-px0 tk-px-margin-bottom-px16"
                        >Let students pay by Credit card, ACH, or others.</label
                      >
                    </tk-item-with-switch>

                    <div class="tk-text-base tk-px-margin-top-px20">
                      Stripe Connect-Express will charge $2 per active user per
                      month, and 0.25% + 25¢ per transfer:
                      <br />
                      <br />
                      1. If tune on Auto-Payouts, a $2 flat fee for first month
                      will be charged by Stripe.
                      <br />
                      <br />
                      2. A 0.25% + 254 transaction fee will be deducted per
                      transfer.
                      <br />
                      <br />
                      3. If no payout within 28 days, "Auto-Payouts" will be
                      tune off automaticcally.
                    </div>

                    <!-- <template
                      v-if="
                        previewData.data.enableOnlinePayments &&
                        cardDebitBankData.length > 0
                      "
                    >
                      <financial-info
                        @update="updatedFinancial"
                      ></financial-info>
                    </template> -->
                  </div>
                </div>

                <!-- payment method -->
                <div
                  class="card tk-col-right"
                  :class="[
                    paymentMethods.length > 0
                      ? 'tk-border-color-gray-200'
                      : 'tk-bg-color-transparent tk-border-none',
                  ]"
                  :key="previewData.settingType"
                  v-if="previewData.settingType == settingType.PAYMENT_METHOD"
                >
                  <div class="row" v-if="paymentMethods.length > 0">
                    <div
                      v-for="(item, index) in paymentMethods"
                      :key="index"
                      class="col-6"
                    >
                      <payment-method-card
                        :data="item"
                        bottom=""
                        itemClass="tk-cursor-pointer"
                        @onClick="onClickPaymentMethod"
                      ></payment-method-card>
                    </div>
                  </div>
                  <div class="tk-position-relative tk-layout-full" v-else>
                    <loading v-if="loadingPaymentAccount"></loading>
                    <div
                      v-else
                      class="tk-position-center tk-layout-full-width tk-text-center"
                    >
                      <img
                        src="/img/icons/tk/img_payment_method.png"
                        class="tk-px-margin-bottom-px32"
                        style="width: 64%; display: "
                      />
                      <br />

                      <!-- <base-button
                        class="tk-footer-btn-fit tk-px-margin-right-px0"
                        type="main"
                        @click.stop="funcBars[0].onClick()"
                        >ADD DIRECT PAYMENET LINK</base-button
                      > -->

                      <el-dropdown
                        trigger="click"
                        class="dropdown"
                        v-if="funcBars[0]"
                      >
                        <base-button
                          class="tk-footer-btn-fit tk-px-margin-right-px0"
                          type="main"
                          >ADD ACCEPTED PAYMENET METHOD</base-button
                        >

                        <el-dropdown-menu
                          class="dropdown-menu dropdown-menu-arrow show"
                          slot="dropdown"
                        >
                          <el-dropdown-item
                            v-for="(obj, i) in funcBars[0].list"
                            :key="i"
                          >
                            <div
                              class="tk-text-base-medium tk-font-lineHeight-xxxl tk-position-relative tk-font-color-black2"
                              @click="obj.onItemClick"
                            >
                              <div
                                class="tk-layout-inline-block tk-px-margin-right-px10 tk-position-relative tk-px-width-px22 tk-px-height-px22"
                                v-if="!$tools.isNull(obj.icon)"
                              >
                                <i
                                  v-if="obj.icon"
                                  :class="[obj.icon]"
                                  class="tk-position-center"
                                ></i>
                              </div>
                              <div class="tk-layout-inline-block">
                                {{ obj.text }}
                              </div>
                            </div>
                          </el-dropdown-item>
                        </el-dropdown-menu>
                      </el-dropdown>
                    </div>
                  </div>
                </div>
              </template>
            </slide-x-left-transition>
          </div>

          <div
            v-else
            class="tk-position-relative tk-layout-full"
            style="height: calc(100vh - 2.5rem)"
          >
            <img
              class="tk-position-center"
              src="/img/icons/tk/img_invoice.png"
              style="width: 100%"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- 右侧工具栏 -->
    <tool-bar :bars="showPreview ? funcBars : []"></tool-bar>

    <div
      id="studioNameWidth"
      style="display: none; font-size: 32px; font-family: 'Quicksand-medium'"
    ></div>

    <a id="addAcceptedPaymentMethod" style="display: none" target="_blank"></a>

    <address-modal
      class="tk-popup-outer"
      v-if="showAddress"
      :data="previewData.data.addressDetail || previewData.data.address"
      @close="showAddress = false"
      @update="updateAddress"
    ></address-modal>

    <other-fee
      class="tk-popup-outer"
      :data="otherFeeItem"
      v-if="showOtherFee"
      @add="updateOtherFee"
      @update="updateOtherFee"
      @close="showOtherFee = false"
    ></other-fee>

    <!-- email template -->
    <modal :show.sync="showInvoiceEmailTemplate" class="tk-popup-outer">
      <template slot="header">
        <h5 class="modal-title" id="exampleModalLabel">Email Template</h5>
      </template>
      <div class="tk-popup-content">
        <!-- <email-template
          v-if="showInvoiceEmailTemplate"
          :subject="studioInfo.name + ' Invoice #[Number]'"
          toName="[Student Name]"
          :fromName="studioInfo.name"
          :content="
            'The attached is the invoice #[Number] issued today. It\'s $[Total Amount] for [Count] lesson(s), and will be due on ' +
            (billingCycleDate && billingCycleDate.name
              ? billingCycle.id == billingCyclesType[2].id
                ? billingCycleDate.name.toLowerCase()
                : billingCycleDate.name
              : '[Due Date]') +
            '.'
          "
          :extraMsg="emailText"
          @onInput="updateSetting($event, 'autoInvoicingSetting.email')"
        >
        </email-template> -->
        <notice-template
          v-if="showInvoiceEmailTemplate && targetTemplate.type"
          type="email"
          :subject="targetTemplate.subject"
          :content="targetTemplate.body"
          :variables="variablesMap"
          @onUpdate="onUpdateTemplate"
        >
        </notice-template>
      </div>
      <template slot="footer">
        <div class="text-center tk-layout-full-width">
          <base-button
            type="white"
            @click.stop="
              showInvoiceEmailTemplate = false;
              emailText = previewData.data.autoInvoicingSetting.email || '';
              targetTemplate = {};
            "
            class="tk-font-color-main tk-footer-btn-base tk-base-shadow-item tk-border-color-gray-200"
          >
            {{ $t("button.cancel").toUpperCase() }}
          </base-button>
          <base-button
            v-if="
              !$tools.isNull(targetTemplate.subject) &&
              !$tools.isNull(targetTemplate.body)
            "
            type="main"
            @click.stop="
              showInvoiceEmailTemplate = false;
              previewData.data.autoInvoicingSetting.email = emailText;
              emailTemplatesMap[targetTemplate.type].subject =
                $tools.equalValue(targetTemplate.editedSubject);
              emailTemplatesMap[targetTemplate.type].body = $tools.equalValue(
                targetTemplate.editedBody
              );
              targetTemplate = {};
            "
            class="tk-font-color-white tk-footer-btn-base tk-base-shadow-item"
          >
            {{ $t("button.confirm").toUpperCase() }}
          </base-button>
        </div>
      </template>
    </modal>

    <!-- add/edit payment link -->
    <alert
      class="tk-popup-outer"
      v-if="showPaymentLinkModal"
      :title="
        paymentLinkModal.isContent ? 'Payment Link' : 'Payment processing steps'
      "
      :left="
        paymentLinkModal.isContent
          ? $t('general.cancel').toUpperCase()
          : $t('general.go_back').toUpperCase()
      "
      :right="
        paymentLinkModal.isContent
          ? $t('general.confirm').toUpperCase()
          : paymentLinkModal.isEdit
          ? 'Edit Payment Link'.toUpperCase()
          : 'Add Payment Link'.toUpperCase()
      "
      :bottom="
        paymentLinkModal.isEdit && paymentLinkModal.isContent
          ? 'Delete payment link'
          : ''
      "
      :leftClass="
        paymentLinkModal.isContent
          ? 'tk-px-width-px160 tk-font-color-main'
          : 'tk-font-color-main'
      "
      :rightClass="
        paymentLinkModal.isContent
          ? 'tk-px-width-px160 tk-font-color-white'
          : 'tk-font-color-white'
      "
      @onLeftTapped="clearPaymentLinkModal"
      @onRightTapped="paymentLinkModal.onRightTapped"
      @onBottomTapped="paymentLinkModal.onBottomTapped"
      @close="clearPaymentLinkModal"
    >
      <div v-if="paymentLinkModal.isContent">
        <input-with-label
          :showLabel="false"
          :value="paymentLinkModal.link"
          @input="updateModalPaymentLink"
          bottom="tk-px-margin-bottom-px0"
        >
        </input-with-label>
      </div>
      <payment-step
        v-else
        type="PAYMENT_LINK"
        :studioInfo="studioInfo"
      ></payment-step>
    </alert>

    <!-- add/edit card, debit, bank -->
    <alert
      class="tk-popup-outer"
      v-if="showCardDebitBankkModal"
      :title="
        cardDebitBankkModal.isNext
          ? 'Be ready to enable service'
          : !$tools.isNull(accountInfo)
          ? 'Edit Beneficiary Account'
          : 'Add Beneficiary Account'
      "
      :left="$t('general.go_back').toUpperCase()"
      :right="
        cardDebitBankkModal.isNext
          ? 'Enable Service'.toUpperCase()
          : !$tools.isNull(accountInfo)
          ? 'Edit Bene\'s A/C'.toUpperCase()
          : $t('general.next').toUpperCase()
      "
      :bottom="!$tools.isNull(accountInfo) ? 'Delete beneficiary account' : ''"
      :leftClass="
        !cardDebitBankkModal.isNext
          ? 'tk-font-color-main tk-footer-btn-base'
          : 'tk-font-color-main'
      "
      :rightClass="
        !cardDebitBankkModal.isNext
          ? 'tk-font-color-white tk-footer-btn-base'
          : 'tk-font-color-white'
      "
      @onLeftTapped="clearCardDebitBankkModal"
      @onRightTapped="cardDebitBankkModal.onRightTapped"
      @onBottomTapped="cardDebitBankkModal.onBottomTapped"
      @close="clearCardDebitBankkModal"
    >
      <template v-if="cardDebitBankkModal.isNext">
        <div>
          <p>{{ cardDebitBankkModal.nextContent.desc }}</p>
          <ul class="tk-px-margin-top-px20 tk-px-margin-left--px24">
            <li
              v-for="(item, index) in cardDebitBankkModal.nextContent.list"
              :key="index"
              class="tk-px-margin-bottom-px10"
            >
              <span class="tk-text-base-medium tk-px-margin-right-px10">{{
                item.content
              }}</span>
              <span v-if="item.desc">{{ item.desc }}</span>
            </li>
          </ul>
        </div>

        <div
          slot="bottom"
          class="tk-px-margin-top-px20 tk-layout-full-width tk-text-center"
        >
          <span>
            Secured by
            <a
              href="https://stripe.com/docs/payouts"
              target="_blank"
              class="tk-font-color-main tk-font-underline"
              >Stripe Connect</a
            >
          </span>
        </div>
      </template>
      <payment-step
        v-else
        type="CREDTI_DEBIT_BANK"
        :studioInfo="studioInfo"
      ></payment-step>
    </alert>

    <!-- activation fee -->
    <alert
      v-if="showActivationFeeAlert"
      title="Activation Fee"
      :left="$t('general.go_back').toUpperCase()"
      :right="'Pay activation fee'.toUpperCase()"
      @onLeftTapped="showActivationFeeAlert = false"
      @onRightTapped="payActivationFee"
      @close="showActivationFeeAlert = false"
    >
      <div>
        A $2.37 activation fee will be charged. The first month flat fee ($2.00)
        will be waived after you pay.
      </div>
      <br />
      <fees-in-us class="tk-px-margin-top-px20"></fees-in-us>
    </alert>

    <!-- 账户有余额或有处理中的payment，提示不能删除账号 -->
    <alert
      v-if="showRemoveAccountAlert"
      title="Remove Beneficiary A/C"
      :left="$t('general.go_back').toUpperCase()"
      :right="$t('general.remove').toUpperCase()"
      rightClass="tk-bg-color-red tk-font-color-white"
      @close="showRemoveAccountAlert = false"
      @onLeftTapped="showRemoveAccountAlert = false"
      @onRightTapped="deleteStudioAccountInfo"
    >
      <div v-if="accountBalance.available > 0">
        There is a ${{ accountBalance.available }} balance in your account, your
        balance will be transferred to your beneficiary account on the scheduled
        day, the beneficiary account will be removed when the transaction is
        completed.
      </div>
      <div
        v-else-if="
          accountBalance.pending > 0 || accountBalance.instant_available > 0
        "
      >
        A pending payment is in processing, the beneficiary account can't be
        removed before the payment is completed.
      </div>
      <template v-if="accountInfo && accountInfo.accountInfo">
        <div v-if="!accountInfo.accountInfo.charges_enabled">
          Your beneficiary account will be removed, you will receive a $2.37
          refund for the activation fee once you tap on REMOVE.
        </div>
        <div v-else>
          Your beneficiary account will be removed once you tap on REMOVE, The
          auto-payouts will be turned off and the $2.37 activation fee won’t be
          refunded
        </div>
        <br />
        <fees-in-us></fees-in-us>
      </template>
    </alert>

    <!-- pay fee to add card debit bank -->
    <!-- ct_gp: currentGroup -->
    <!-- ct_sg: currentSetting -->
    <!-- pt_id: paymentId -->
    <payment-intent
      title="Pay Activation Fee"
      :data="feePaymentrIntent"
      :extraOptions="{
        redirect: 'if_required',
      }"
      v-if="showPayActivationFeeAlert"
      @close="showPayActivationFeeAlert = false"
      @paymentSucceeded="createStudioAccountInfo"
    >
    </payment-intent>

    <!-- payment received -->
    <alert
      v-if="showPaymentReceivedAlert"
      title="Payment received!"
      :left="'later'.toUpperCase()"
      :right="'Add Bene\'s A/C'.toUpperCase()"
      @onLeftTapped="showPaymentReceivedAlert = false"
      @onRightTapped="
        showBeneficialInfo = true;
        showPaymentReceivedAlert = false;
      "
      @close="showPaymentReceivedAlert = false"
    >
      <div>
        The online payment service has been activated. Now, your student can pay
        with credit card, debit card, or bank account. If no payment comes
        within 28 days, this service will be terminated automatically.
      </div>
    </alert>

    <!-- create auto invoice -->
    <auto-invoice
      v-if="showCreateAutoInvoice"
      :modifyInvoice="modifyInvoice"
      :student="
        !$tools.isNull(modifyInvoice.id)
          ? studentsListMap[modifyInvoice.studentId]
          : !$tools.isNull(modifyInvoiceConfigStudent.id)
          ? modifyInvoiceConfigStudent
          : {}
      "
      @close="
        showCreateAutoInvoice = false;
        modifyInvoice = {};
        modifyInvoiceConfigStudent = {};
        if (previewData.type != businessTabsValue.setting) {
          hidePreview();
        }
      "
      @update="updatePersonalizeSetting"
      left="Close"
      right="Create"
      class="tk-popup-outer"
    ></auto-invoice>

    <!-- create manual invoice -->
    <manual-invoice
      v-if="showCreateManualInvoice"
      @close="showCreateManualInvoice = false"
    ></manual-invoice>

    <!-- beneficial info / preview upcoming invoice -->
    <slide-x-right-transition
      :duration="300"
      mode="out-in"
      v-show="showBeneficialInfo || showPreviewInvoice"
    >
      <div
        class="tk-position-fixed tk-full-screen tk-bg-color-black_48"
        style="top: 0; left: 0; z-index: 999"
      >
        <bank-debit
          class="tk-bg-color-selectedBg tk-slide-right-part tk-slide-right-part-sm"
          v-if="showBeneficialInfo"
          :accountId="studioInfo.id"
          :accountInfoData="accountInfo"
          :role="$dataModules.user.roleId.studioManager"
          @update="updateStripeInfo"
          @back="showBeneficialInfo = false"
        ></bank-debit>

        <detail-in-slide
          v-if="showPreviewInvoice && !$tools.isNull(currentUpcomingInvoiceId)"
          @back="showPreviewInvoice = false"
          title="Preview"
        >
          <template slot="content">
            <invoice-or-receipt
              :data="upcomingInvoicesMap[currentUpcomingInvoiceId]"
              :id="currentUpcomingInvoiceId"
            ></invoice-or-receipt>
          </template>
        </detail-in-slide>
      </div>
    </slide-x-right-transition>

    <!-- save auto invoicing -->
    <alert
      v-if="showSaveSettingAlert"
      :title="
        upcomingInvoicesMapLength > 0
          ? 'Haven\'t saved yet!'
          : 'Saved Successfully'
      "
      :left="
        upcomingInvoicesMapLength > 0 ? $t('button.go_back').toUpperCase() : ''
      "
      :right="upcomingInvoicesMapLength > 0 ? 'CONFIRM' : ''"
      :center="upcomingInvoicesMapLength > 0 ? '' : 'I\'m Done'"
      @onLeftTapped="showSaveSettingAlert = false"
      @onCenterTapped="
        saveAutoInvoicing(true, () =>
          $bus.$emit('goToInvoices', manualUpcommingInvoicesMap)
        )
      "
      @onRightTapped="
        saveAutoInvoicing(true, () =>
          $bus.$emit('goToInvoices', manualUpcommingInvoicesMap)
        )
      "
      @close="showSaveSettingAlert = false"
    >
      <template v-if="upcomingInvoicesMapLength > 0">
        <div>
          The settings will be saved and the invoices below will be sent
          immediately if you tap on CONFIRM. You could optionally turn on Send
          Manually and review them later on the Business > Invoices tab. Would
          you like to confirm?
        </div>
        <template
          v-for="item in $commons.mapToArray(
            upcomingInvoicesMap,
            'asc',
            'billingTimestamp'
          )"
        >
          <div
            v-if="item.sendTime <= $moment().unix()"
            :key="item.id"
            class="card tk-cursor-pointer tk-base-shadow-item tk-px-margin-bottom-px0 tk-px-margin-top-px16 tk-border-color-gray-200"
          >
            <div class="card-body tk-px-padding-px16">
              <!-- student name + totalAmount -->
              <div
                class="tk-text-base-bold tk-layout-flex-row"
                @click.stop="currentUpcomingInvoiceId = item.id"
              >
                <div class="tk-text-overflow tk-layout-flex-1">
                  {{
                    studentsListMap[item.studentId].name ||
                    studentsMap[item.studentId].name
                  }}
                </div>
                <div class="text-right tk-text-overflow tk-px-width-px100">
                  {{ $commons.formatPrice(item.totalAmount, 2, $tkCurrency) }}
                </div>
              </div>

              <!-- number + status -->
              <div
                class="tk-font-color-gray tk-layout-flex-row tk-layout-flex-row-vertical-center tk-px-margin-top-px4"
              >
                <div
                  class="tk-text-left tk-text-overflow tk-layout-flex-1 tk-px-margin-right-px16"
                >
                  {{ $moment(item.sendTime * 1000).format("M/D/YYYY") }}
                </div>
                <div
                  class="tk-px-margin-right-px16"
                  :class="[
                    Boolean(manualUpcommingInvoicesMap[item.id])
                      ? 'tk-font-color-black2'
                      : 'tk-font-color-gray',
                  ]"
                >
                  Send manually
                </div>
                <base-switch
                  :value="Boolean(manualUpcommingInvoicesMap[item.id])"
                  @input="
                    $event
                      ? (manualUpcommingInvoicesMap[item.id] = item)
                      : delete manualUpcommingInvoicesMap[item.id];
                    $forceUpdate();
                  "
                  on-text="Yes"
                  off-text="No"
                  type="main"
                ></base-switch>
              </div>
            </div>
          </div>
        </template>
      </template>
      <template v-else>
        <div>
          General invoicing settings have been saved. You can review
          auto-generated invoices on the Business > Invoices tab.
        </div>
      </template>
    </alert>

    <!-- delete manually send invoice -->
    <alert
      v-if="showDeleteInvoiceAlert"
      title="Delete Invoice?"
      :right="$t('button.go_back').toUpperCase()"
      left="DELETE"
      leftClass="tk-bg-color-red tk-font-color-white"
      @onRightTapped="showDeleteInvoiceAlert = false"
      @onLeftTapped="onClickDelete(modifyInvoice, true)"
      @close="showDeleteInvoiceAlert = false"
    >
      <div>Tap on DELETE to remove this invoice permanently.</div>
    </alert>

    <!-- select currency -->
    <select-currency
      class="tk-popup-outer tk-select-instrument"
      v-if="showCurrencyModel"
      @close="showCurrencyModel = false"
      @onSelect="updateCurrency"
    ></select-currency>

    <!-- consolidate invoice -->
    <consolidate-invoice
      v-if="showConsolidateInvoiceModel"
      class="tk-popup-outer tk-select-instrument"
      :data="issuedUnsentInvoicesMap"
      @close="showConsolidateInvoiceModel = false"
      @onPreview="previewInvoiceData = $event"
    ></consolidate-invoice>

    <!-- pending  -->
    <alert
      v-if="showPendingCardDebitBankAlert"
      title="Added Card/Debit/Bank?"
      left="RE-ADD"
      right="COMPLETE"
      @onRightTapped="initPaymentMethods()"
      @onLeftTapped="initStripeAccountLink(true)"
      @close="showPendingCardDebitBankAlert = false"
    >
      <div>
        Have you successfully added a card, debit, or bank as a accepted payment
        method?
      </div>
    </alert>
  </div>
</template>

<script>
import { SlideXLeftTransition, SlideXRightTransition } from "vue2-transitions";
import {
  Dropdown,
  DropdownItem,
  DropdownMenu,
  Table,
  TableColumn,
  Select,
  Option,
} from "element-ui";
import * as math from "mathjs";
export default {
  components: {
    [Dropdown.name]: Dropdown,
    [DropdownItem.name]: DropdownItem,
    [DropdownMenu.name]: DropdownMenu,
    [Table.name]: Table,
    [TableColumn.name]: TableColumn,
    [Select.name]: Select,
    [Option.name]: Option,
    SlideXLeftTransition,
    SlideXRightTransition,
    InvoiceAndPayoutAndSetting: () =>
      import("@/tkViews/Finances/InvoiceAndPayoutAndSetting"),
    AutoInvoice: () => import("@/tkViews/components/Modal/AutoInvoice"),
    ManualInvoice: () => import("@/tkViews/components/Modal/ManualInvoice"),
    toolBar: () => import("@/tkViews/components/layout/RightToolbar.vue"),
    TkInputWithLabel: () =>
      import("@/tkViews/components/Inputs/TkInputWithLabel.vue"),
    TkTextAreaWithLabel: () =>
      import("@/tkViews/components/Inputs/TkTextAreaWithLabel.vue"),
    AddressModal: () => import("@/tkViews/components/Modal/Address.vue"),
    OtherFee: () => import("@/tkViews/components/Modal/OtherFee.vue"),
    TkNumberWithType: () =>
      import("@/tkViews/components/Inputs/TkInputWithLabelAndNumberType.vue"),
    TkItemWithSwitch: () =>
      import("@/tkViews/components/Inputs/TkItemWithSwitch"),
    BankDebit: () => import("@/tkViews/components/layout/Bank&Debit.vue"),
    MultipleSelect: () =>
      import("@/tkViews/components/layout/Item/MultipleSelectWithCheck.vue"),
    SingleSelect: () =>
      import("@/tkViews/components/layout/Item/SingleSelectWithCheck.vue"),
    PaymentMethodCard: () =>
      import("@/tkViews/components/layout/Item/PaymentMethodCard.vue"),
    Loading: () => import("@/tkViews/components/layout/Loading.vue"),
    Alert: () => import("@/tkViews/components/Modal/Alert.vue"),
    PaymentStep: () => import("@/tkViews/components/layout/PaymentStep.vue"),
    InputWithLabel: () =>
      import("@/tkViews/components/Inputs/TkInputWithLabel"),
    PaymentIntent: () => import("@/tkViews/components/Modal/PaymentIntent.vue"),
    FeesInUs: () => import("@/tkViews/components/layout/Item/FeesInUS.vue"),
    InvoiceOrReceipt: () => import("@/tkViews/Finances/InvoiceOrReceipt.vue"),
    Card: () => import("@/tkViews/components/layout/Card"),
    EmailTemplate: () =>
      import("@/tkViews/components/layout/EmailTemplate.vue"),
    NoticeTemplate: () =>
      import("@/tkViews/components/layout/NoticeTemplate.vue"),
    DetailInSlide: () =>
      import("@/tkViews/components/layout/DetailInSlide.vue"),
    SelectCurrency: () =>
      import("@/tkViews/components/Modal/SelectCurrency.vue"),
    ConsolidateInvoice: () =>
      import("@/tkViews/components/Modal/ConsolidateInvoice.vue"),
  },
  data() {
    return {
      previewInvoiceData: {},
      previewData: {},
      studioName: "",
      address: "",
      phone: "",
      branding: "",

      dueType: 0,
      dueTypeList: [
        {
          value: 0,
          label: "Upon receipt",
        },
        {
          value: 1,
          label: "# days after first invoice",
        },
        {
          value: 2,
          label: "Upon completion",
        },
      ],
      daysAfterFirstInvoice: 1,

      logo: "",
      studioInfo: null,
      storefrontColor: "",
      teacherInfo: null,
      userInfo: null,
      invoiceConfigsMap: {},
      studentsListMap: {},
      studentsMap: {},
      upcomingInvoicesMap: {},
      currentUpcomingInvoiceId: "",
      manualUpcommingInvoicesMap: {},
      modifyInvoice: {},
      modifyInvoiceConfigStudent: {},
      issuedUnsentInvoicesMap: {},

      funcBars: [],
      settingType: {
        INVOICE_TITLE: "INVOICE_TITLE",
        INVOICE_TAX_AND_FEE: "INVOICE_TAX_AND_FEE",
        INVOICE_AND_DUE_DATE: "INVOICE_AND_DUE_DATE",
        INVOICE_NOTE_AND_EMAIL: "INVOICE_NOTE_AND_EMAIL",
        AUTO_INVOICING: "AUTO_INVOICING",
        PAYOUT_SETTING: "PAYOUT_SETTING",
        ONLINE_PAYMENT: "ONLINE_PAYMENT",
        PAYMENT_METHOD: "PAYMENT_METHOD",
        PAYMENT: "PAYMENT",
      },
      businessTabsValue: {
        invoice: "invoice",
        payout: "payout",
        setting: "setting",
      },

      salesTax: 0,
      lateFee: 0,
      lateFeeType: "FLAT",
      otherFees: [],
      otherFeeItem: {
        title: "",
        amount: 0,
        amountType: "FLAT",
      },
      invoiceEmail: "",
      emailNoticeDestination: {},
      emailTo: [
        {
          id: "STUDENT",
          name: "Cc student",
        },
        {
          id: "PARENT",
          name: "Cc parent",
        },
        {
          id: "INSTRUCTOR",
          name: "Cc instructor",
        },
        {
          id: "STUDIO_MANAGER",
          name: "Cc manager",
        },
      ],
      billingCyclesType: [
        { id: "WEEKLY", name: "Weekly" },
        { id: "BI_WEEKLY", name: "Bi-weekly" },
        { id: "MONTHLY", name: "Monthly" },
      ],
      billingCycle: { id: "WEEKLY", name: "Weekly" },
      weekCycle: [],
      monthCycle: [],
      billingCycleDate: {},

      showEnableStudent: false,
      showPreview: false,
      showAddress: false,
      showOtherFee: false,
      showInvoiceEmailTemplate: false,

      loadingPaymentAccount: false,
      paypalInfo: null,
      accountInfo: null,
      accountBalance: {
        available: 0,
        pending: 0,
        instant_available: 0,
        connect_reserved: 0,
      },
      cardDebitBankData: [],
      paymentLinks: [],
      feePaymentrIntent: null,

      showPaymentLinkModal: false,
      showCardDebitBankkModal: false,
      showActivationFeeAlert: false,
      showPaymentReceivedAlert: false,
      showBeneficialInfo: false,
      showPayActivationFeeAlert: false,
      showRemoveAccountAlert: false,
      showPreviewInvoice: false,
      showSaveSettingAlert: false,
      showDeleteInvoiceAlert: false,
      showCurrencyModel: false,
      showConsolidateInvoiceModel: false,

      showPendingCardDebitBankAlert: false,

      showCreateQuickInvoice: false,
      showCreateManualInvoice: false,
      showCreateAutoInvoice: false,

      paymentLinkModal: {
        isEdit: false,
        isContent: false,
        onBottomTapped: null,
        onRightTapped: null,
        link: "",
      },
      cardDebitBankkModal: {
        onBottomTapped: null,
        onRightTapped: null,
        isNext: false,
        nextContent: {
          desc: "To enable online payment service for credit/debit and bank, please be ready to pay an activation fee and provide necessary business & finance info:",
          list: [
            {
              content: "Bank account",
              desc: "(Routing #, Account #)",
            },
            {
              content: "Or debit card",
              desc: "(Card #, Expired date, CVC)",
            },
            {
              content: "Full name",
            },
            {
              content: "DoB",
            },
            {
              content: "SSN",
            },
            {
              content: "Photo ID",
            },
            {
              content: "Contact",
              desc: "(Email / Address / Phone number)",
            },
            {
              content: "EIN & Business name",
              desc: "(Company only)",
            },
          ],
        },
      },

      paymentMethods: [
        {
          // type: "MASTER",
          // name: "TEST NAME 1",
          // value: "**** **** **** 2568",
          // date: "09/24",
          // holderName: "User name",
          // cardNumber: "**** **** **** 2568",
          // bankName: "Wells Fargo Bank",
          // expireDate: "09/24",
          // brand: "VISA / Mastercard",
          // cardType: "Credit / Debit",
          // bankAccountType: "Checking / Saving",
        },
      ],

      variablesMap: this.$dataModules.userReminders.variables.invoice,
      emailTemplatesMap: {
        issue: {
          subject: `Invoice ${this.$dataModules.userReminders.variables.invoice.invoice_number} Payment Request`,
          body: `Please find attached invoice ${this.$dataModules.userReminders.variables.invoice.invoice_number}, issued today. The invoice is for ${this.$dataModules.userReminders.variables.invoice.total_amount} and includes ${this.$dataModules.userReminders.variables.invoice.lesson_quantity} item(s). The payment is due on ${this.$dataModules.userReminders.variables.invoice.invoice_due_date}.`,
          type: "issue",
          sendType: "on",
          day: 0,
        },
        due: {
          subject: `Invoice ${this.$dataModules.userReminders.variables.invoice.invoice_number} is due today`,
          body: `Please find attached invoice ${this.$dataModules.userReminders.variables.invoice.invoice_number}, issued on ${this.$dataModules.userReminders.variables.invoice.invoice_issue_date}. The invoice is for ${this.$dataModules.userReminders.variables.invoice.total_amount} and includes ${this.$dataModules.userReminders.variables.invoice.lesson_quantity} item(s). The due date is ${this.$dataModules.userReminders.variables.invoice.invoice_due_date}, which is today. Please make the payment as soon as possible. If you do not pay by ${this.$dataModules.userReminders.variables.invoice.invoice_late_date}, you may be charged a late fee. Thank you!`,
          type: "due",
          sendType: "on",
          day: 0,
        },
        late: {
          subject: `Invoice ${this.$dataModules.userReminders.variables.invoice.invoice_number} from ${this.$dataModules.userReminders.variables.invoice.invoice_issue_date} is overdue - please send payment ASAP`,
          body: `Please find attached invoice ${this.$dataModules.userReminders.variables.invoice.invoice_number}, issued on ${this.$dataModules.userReminders.variables.invoice.invoice_issue_date}. The invoice is for ${this.$dataModules.userReminders.variables.invoice.total_amount} and includes ${this.$dataModules.userReminders.variables.invoice.lesson_quantity} item(s). The payment was due on ${this.$dataModules.userReminders.variables.invoice.invoice_due_date}, and is now overdue for ${this.$dataModules.userReminders.variables.invoice.invoice_late_days} days. Please make the payment as soon as possible. You might be charged a late fee if you do not pay today. Thank you!`,
          type: "late",
          sendType: "on",
          day: 0,
        },
      },
      targetTemplate: {},

      livemode: process.env.NODE_ENV == "production",
    };
  },
  async created() {
    let self = this;

    // console.log('America/New_York: ', self.$momentTimezone.tz("20240124", "YYYYMMDD", "America/New_York").format("M/D/YYYY"));

    // 缓存占用
    // let size = 0;
    // for (let item in window.localStorage) {
    //   if (window.localStorage.hasOwnProperty(item)) {
    //     let perSize = window.localStorage.getItem(item).length;
    //     size += perSize;
    //     console.log(item + "使用：", (perSize / 1024).toFixed(2) + "KB");
    //   }
    // }
    // console.log("total 使用：", (size / 1024 / 1024).toFixed(2) + "MB");

    await self.initBasicData();
    self.initFuncBars();
  },
  mounted() {
    let self = this;
    self.$bus.$on("onCurrentChangeStudioInfo", (data) => {
      self.studioInfo = data;
      self.$forceUpdate();
    });
    self.$bus.$on("onChangePaypalAccount", (data) => {
      console.log("onChangePaypalAccount: ", data);
      self.initPaymentMethods();
      self.$forceUpdate();
    });
  },
  watch: {
    previewData: {
      handler(newVal, oldVal) {
        if (newVal.type === "invoices") {
          let subTotal = parseFloat(newVal.data.subTotal);
          let tax = parseFloat(newVal.data.salesTax);
          let fee = parseFloat(newVal.data.lateFee);
          let balance = parseFloat(newVal.data.balance);
          this.previewData.data.total = this.$commons.formatPrice(
            parseFloat(subTotal + subTotal * tax + subTotal * fee + balance),
            2,
            this.$tkCurrency
          );
        } else if (newVal.type === "setting") {
          if (newVal.data.autoInvoicingSetting.dueDate == -1) {
            newVal.data.autoInvoicingSetting.dueDate = NaN;
          }
          if (newVal.data.autoInvoicingSetting.lateDate == -1) {
            newVal.data.autoInvoicingSetting.lateDate = NaN;
          }
        }
      },
      deep: true,
    },
    currentUpcomingInvoiceId(newVal) {
      if (newVal?.length > 0) {
        this.showSaveSettingAlert = true;
      }
    },
  },
  computed: {
    ascStudentListArray() {
      return (
        this.$commons.mapToArray(this.studentsListMap, "asc", "name") ?? []
      );
    },
    upcomingInvoicesMapLength() {
      return Object.keys(this.upcomingInvoicesMap ?? {}).length;
    },
  },
  methods: {
    onUpdateTemplate(data) {
      let self = this;

      if (data?.target == "subject") {
        self.targetTemplate.editedSubject = data.text;
      } else {
        self.targetTemplate.editedBody = data.text;
      }

      console.log("onUpdateTemplate: ", self.targetTemplate);
    },
    formatReminderText(data, options) {
      let self = this;
      let template = data ?? "";

      let brPattern = new RegExp(/\n/, "g");
      template = template.replace(brPattern, "<br/>");

      Object.keys(self.variablesMap ?? {}).forEach((key) => {
        let item = self.variablesMap[key];

        if (template?.indexOf(item) > -1) {
          let pattern = new RegExp(`${item}`, "g");
          let replacement = `<div class='tk-template-variable tk-bg-color-gray-200 tk-font-color-gray tk-text-sm' contenteditable='false' data-val="${item}">${
            item.split("TK-")[1].split("-TK")[0]
          }</div>`;

          template = template.replace(pattern, replacement);
        }
      });

      if (!self.$tools.isNull(options?.prefix)) {
        template = `${options?.prefix}${template}`;
      }

      return template;
    },
    onClickToggleAll(enable) {
      let self = this;

      Object.keys(self.invoiceConfigsMap).forEach((key) => {
        self.invoiceConfigsMap[key].status = enable
          ? self.$dataModules.invoiceConfig.status.active
          : self.$dataModules.invoiceConfig.status.stopped;
      });
    },
    formatCustomizeConfigDesc(data) {
      let self = this;
      let key = `${self.studioInfo.id}:${data.userId || data.studentId}`;
      let invoiceConfig = self.invoiceConfigsMap[key];
      let desc = "";
      let arr = [];

      if (invoiceConfig?.isCustomized) {
        // console.log(
        //   "formatCustomizeConfigDesc: ",
        //   invoiceConfig,
        //   self.previewData.data.autoInvoicingSetting
        // );
        if (
          (invoiceConfig?.flatAmount?.enable &&
            self.previewData.data.autoInvoicingSetting.flatAmount.enable &&
            invoiceConfig?.flatAmount?.amount !=
              self.previewData.data.autoInvoicingSetting.flatAmount.amount) ||
          invoiceConfig?.flatAmount?.enable !=
            self.previewData.data.autoInvoicingSetting.flatAmount.enable
        ) {
          // flat
          arr.push("Flat amount");
        }

        if (
          invoiceConfig?.lateFee?.amount !=
          self.previewData.data.autoInvoicingSetting.lateFee?.amount
        ) {
          arr.push("Late fee");
        }

        if (invoiceConfig?.otherFees?.length != self.otherFees?.length) {
          let customOtherFeesMap = self.$commons.arrayToMap(
            invoiceConfig.otherFees,
            "title"
          );
          let otherFeesMap = self.$commons.arrayToMap(self.otherFees, "title");

          Object.keys(customOtherFeesMap).forEach((key) => {
            let item = customOtherFeesMap[key];
            if (!otherFeesMap[key]) {
              arr.push(item.title);
            } else {
              if (item.amount != otherFeesMap[key]?.amount) {
                arr.push(item.title);
              }
            }
          });
        }

        if (
          invoiceConfig?.billingCycle !=
          self.previewData.data.autoInvoicingSetting.billingCycle
        ) {
          arr.push("Billing cycle");
        }

        if (
          invoiceConfig?.billingCycleDate !=
          self.previewData.data.autoInvoicingSetting.billingCycleDate
        ) {
          arr.push("Billing cycle date");
        }

        if (
          invoiceConfig?.invoiceDate !=
          self.previewData.data.autoInvoicingSetting.invoiceDate
        ) {
          arr.push("Invoice date");
        }

        if (
          invoiceConfig?.dueDate !=
          self.previewData.data.autoInvoicingSetting.dueDate
        ) {
          arr.push("Due date");
        }

        if (
          invoiceConfig?.notes !=
          self.previewData.data.autoInvoicingSetting.notes
        ) {
          arr.push("Invoice notes");
        }

        if (
          invoiceConfig?.emailText !=
          self.previewData.data.autoInvoicingSetting.email
        ) {
          arr.push("Invoice email");
        }

        desc = arr.join(", ");
      }

      return desc;
    },
    formatConfigDesc(data) {
      let self = this;
      let key = `${self.studioInfo.id}:${data.userId || data.studentId}`;
      let invoiceConfig = self.invoiceConfigsMap[key];
      let billingCycle = invoiceConfig?.billingCycle;
      let billingCycleDate = invoiceConfig?.billingCycleDate;
      let invoiceDate = invoiceConfig?.invoiceDate;
      let str = "";

      if (billingCycle == self.$dataModules.invoiceConfig.billingCycle.weekly) {
        str = `Billing cycle starts from every ${self.$tools.formatWeekdayStrFull(
          billingCycleDate
        )}`;
      } else if (
        billingCycle == self.$dataModules.invoiceConfig.billingCycle.biWeekly
      ) {
        str = `Billing cycle starts from every other ${self.$tools.formatWeekdayStrFull(
          billingCycleDate
        )}`;
      } else {
        let dateStr =
          billingCycleDate == 1
            ? "1st"
            : billingCycleDate == 2
            ? "2nd"
            : billingCycleDate == 3
            ? "3rd"
            : billingCycleDate == -1
            ? "end"
            : `${billingCycleDate}th`;
        str = `Billing cycle starts from every ${dateStr} of the month`;
      }

      if (invoiceDate > 0) {
        str += `, issued ${invoiceDate} days in advance.`;
      } else if (invoiceDate == 0) {
        str += `, issued on the same day.`;
      } else {
        str = "";
      }

      if (str?.length > 0) {
        str += "(Customized)";
      }

      return str;
    },
    onClickStudent(data) {
      console.log(data);
    },
    onClickDelete(data, remove = false) {
      let self = this;
      let now = self.$moment().unix();

      if (remove) {
        let deleteInvoice = self.$functionsService.deleteInvoice;

        self.$bus.$emit("showFullCover", {
          text: self.$i18n.t("notification.loading.delete"),
          type: "loading",
          timeout: 0,
          unix: now,
        });

        if (self.previewData?.data?.id == data.if) {
          self.hidePreview();
        }

        console.log(data, data.id);

        deleteInvoice({
          id: data.id,
        })
          .then((res) => {
            self.$bus.$emit("hideFullCover", {
              message: self.$i18n.t("notification.success.delete"),
              type: "success",
              unix: now,
            });
            self.modifyInvoice = {};
            self.showDeleteInvoiceAlert = false;
          })
          .catch((err) => {
            self.$bus.$emit("hideFullCover", {
              message: self.$i18n.t("notification.failed.delete"),
              type: "error",
              unix: now,
            });
            self.showDeleteInvoiceAlert = false;
          });
      } else {
        self.modifyInvoice = self.$tools.equalValue(data);
        self.showDeleteInvoiceAlert = true;
      }
    },
    onClickAdd(type, data) {
      let self = this;

      if (!self.$tools.isNull(data?.id)) {
        if (!self.$tools.isNull(data?.configId)) {
          console.log("modify invoice: ", data);
          self.modifyInvoice = data;
        } else if (
          !self.$tools.isNull(data?.studentId) &&
          !self.$tools.isNull(data?.invitedStatus)
        ) {
          console.log("modify invoice config: ", data);
          self.modifyInvoiceConfigStudent = data;
        }
      }

      switch (type) {
        case self.$dataModules.invoice.type.QUICK_INVOICE:
          self.showCreateQuickInvoice = true;
          break;
        case self.$dataModules.invoice.type.MANUAL_INVOICE:
          self.showCreateManualInvoice = true;
          break;
        case self.$dataModules.invoice.type.AUTO_INVOICE:
          self.showCreateAutoInvoice = true;
          break;
        case "CONSOLIDATE_INVOICE":
          console.log("data: ", data);
          self.issuedUnsentInvoicesMap = self.$tools.equalValue(data);
          self.showConsolidateInvoiceModel = true;
          break;
      }
    },
    async initBasicData() {
      let self = this;

      self.userInfo = await self.$userService.userInfo();
      self.teacherInfo = await self.$userService.teacherInfo();
      self.studioInfo = await self.$userService.studioInfo();
      self.logo = self.$commons.studioLogoPath(self.studioInfo.studioId);
      self.storefrontColor = self.studioInfo.storefrontColor;
      self.invoiceConfigsMap = await self.$paymentService.invoiceConfig(true);
      self.studentsListMap = await self.$studioService.studentsList();
      self.studentsMap = await self.$studioService.studentUserInfo();

      Object.keys(self.studentsListMap).forEach((key) => {
        if (self.$tools.isNull(self.studentsListMap[key]?.name)) {
          self.studentsListMap[key].name = self.studentsMap[key]?.name ?? "";
        }
      });

      Object.keys(self.invoiceConfigsMap).forEach((key) => {
        if (self.$tools.isNull(self.invoiceConfigsMap[key]?.studentId)) {
          delete self.invoiceConfigsMap[key];
        }
      });

      // week cycle
      for (let i = 1; i < 8; i++) {
        self.weekCycle.push({
          id: i,
          name: self.$tools.formatWeekdayStrShort(i - 1),
        });
      }

      // month cycle
      for (let i = 0; i < 29; i++) {
        let id = i + 1;
        let name = "";

        if (id == 1) {
          name = "1st";
        } else if (id == 2) {
          name = "2nd";
        } else if (id == 3) {
          name = "3rd";
        } else if (id == 29) {
          id = -1;
          name = "End of month";
        } else {
          name = `${id}th`;
        }

        self.monthCycle.push({
          id: id,
          name: name,
        });
      }
    },
    initStripeAccountConnect(callback) {
      let self = this;
      let fetchStudioConnectAccount =
        self.$functionsService.fetchStudioConnectAccount;
      let now = self.$moment().unix();

      self.$bus.$emit("showFullCover", {
        text: self.$i18n.t("notification.loading.label"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      fetchStudioConnectAccount({
        studioId: self.studioInfo.id,
      })
        .then(async (res) => {
          console.log("fetchStudioConnectAccount success: ", res.data);

          // if (res.data?.data?.stripeAccount) {
          //   // 获取 bank & card
          //   bank = await self.$paymentService.getExternalBankAccount(
          //     self.studioInfo.id
          //   );
          //   card = await self.$paymentService.getExternalCardAccount(
          //     self.studioInfo.id
          //   );
          // }

          // self.cardDebitBankData = bank.concat(card);

          // console.log("accountInfo: ", accountInfo);
          // console.log("bank & card & debit: ", self.cardDebitBankData);

          if (callback == true) {
            // self.showPendingCardDebitBankAlert = true;
            // window.open(res.data.data.url);
            window.location = res.data.data.url;
          } else {
            callback(res.data);
          }
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.success.label"),
            type: "success",
            unix: now,
          });
        })
        .catch((err) => {
          console.log("fetchStudioConnectAccount failed: ", err);
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.failed.label"),
            type: "error",
            unix: now,
          });
        });
    },
    initStripeAccountLink(callback) {
      let self = this;
      let fetchStudioConnectAccountLink = self.livemode
        ? self.$functionsService.fetchStudioConnectAccountLink
        : self.$functionsService.fetchStudioConnectAccountLink4T;
      let now = self.$moment().unix();

      self.$bus.$emit("showFullCover", {
        text: self.$i18n.t("notification.loading.label"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      fetchStudioConnectAccountLink({
        studioId: self.studioInfo.id,
      })
        .then(async (res) => {
          console.log("fetchStudioConnectAccountLink success: ", res.data);

          if (callback == true) {
            // window.open(res.data.data.url);
            window.location = res.data.data.url;
          } else {
            callback(res.data);
          }
          // self.$bus.$emit("hideFullCover", {
          //   message: self.$i18n.t("notification.success.label"),
          //   type: "success",
          //   unix: now,
          // });
        })
        .catch((err) => {
          console.log("fetchStudioConnectAccountLink failed: ", err);
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.failed.label"),
            type: "error",
            unix: now,
          });
        });
    },
    initPaypalAccountLink(callback) {
      let self = this;
      let fetchOnboardingLink = self.$functionsService.fetchOnboardingLink;
      let now = self.$moment().unix();

      self.$bus.$emit("showFullCover", {
        text: self.$i18n.t("notification.loading.label"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      console.log("studioId: ", self.studioInfo.id);
      console.log("livemode: ", self.livemode);

      fetchOnboardingLink({
        studioId: self.studioInfo.id,
        livemode: self.livemode,
      })
        .then(async (res) => {
          console.log("fetchOnboardingLink success: ", res.data);
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.success.label"),
            type: "success",
            unix: now,
          });

          console.log("data: ", res.data);

          let url =
            res.data?.data?.links?.filter((item) => item.rel == "action_url")[0]
              ?.href ||
            res.data?.data?.onboardingLinks?.links?.filter(
              (item) => item.rel == "action_url"
            )[0]?.href;
          console.log("url: ", url);

          if (!self.$tools.isNull(url)) {
            window.location = url;
          }

          // if (callback == true) {
          //   // window.open(res.data.data.url);
          //   window.location = res.data.data.url;
          // } else {
          //   callback(res.data);
          // }
        })
        .catch((err) => {
          console.log("fetchOnboardingLink failed: ", err);
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.failed.label"),
            type: "error",
            unix: now,
          });
        });
    },
    toggleBtnStatus(loading, notify, timeout) {
      let self = this;
      let now = self.$moment().unix();

      if (loading) {
        self.$bus.$emit("showFullCover", {
          text: notify.message,
          type: notify.type,
          timeout: 0,
          unix: now,
        });
      } else {
        self.$bus.$emit("hideFullCover", {
          message: notify.message,
          type: notify.type,
          unix: now,
        });

        if (!self.$tools.isNull(timeout)) {
          clearTimeout(timeout);
        }
      }
    },
    initFuncBars(type) {
      let self = this;
      let funcBars = [];

      if (type) {
        switch (type) {
          case self.settingType.PAYMENT_METHOD:
            let addCardDebitBank = {
              icon: "fas fa-credit-card",
              text: "Credit, Debit or Bank",
              onItemClick() {
                self.initPaypalAccountLink();
              },
            };

            let addPaymentLink = {
              text: "Add direct Payment Link",
              icon: "fas fa-plus",
              onItemClick: () => {
                self.showPaymentLinkModal = true;

                self.paymentLinkModal.isEdit = false;
                self.paymentLinkModal.isContent = true;
                self.paymentLinkModal.link = "";

                self.paymentLinkModal.onRightTapped = () => {
                  if (self.$tools.isURL(self.paymentLinkModal.link)) {
                    self.addPaymentLink(self.paymentLinkModal.link);
                    self.clearPaymentLinkModal();
                  } else {
                    self.$notify({
                      message: "Please type correct payment link!",
                      type: "warning",
                    });
                  }
                };
                self.paymentLinkModal.onBottomTapped = () => {};
              },
            };

            // TODO:
            // if (self.$tools.isNull(self.accountInfo?.studioId)) {
            console.log("paypalInfo: ", self.paypalInfo);
            if (self.$tools.isNull(self.paypalInfo?.studioId)) {
              // 没有账户
              funcBars = [
                {
                  label: "Add accepted payment method",
                  icon: "fas fa-plus",
                  key: 0,
                  list: [addCardDebitBank, addPaymentLink],
                  onClick() {},
                },
              ];
            } else {
              // 有账户
              funcBars = [
                {
                  label: "Add direct Payment Link",
                  icon: "fas fa-plus",
                  onClick: addPaymentLink.onItemClick,
                },
              ];
            }

            funcBars = [
              {
                label: "Add direct Payment Link",
                icon: "fas fa-plus",
                onClick: addPaymentLink.onItemClick,
              },
            ];

            break;
        }
      } else {
        if (self.previewData.type == "invoice") {
          funcBars = [
            // {
            //   label: "View student",
            //   icon: "fas fa-graduation-cap",
            //   onClick() {},
            // },
            {
              label: "Download PDF",
              icon: "fas fa-file-download",
              onClick() {
                self.$bus.$emit("downloadInvoicePDF-InvoiceOrReceipt");
              },
            },
            // {
            //   label: "Mark as outstanding",
            //   icon: "fas fa-bookmark",
            //   onClick() {},
            // },
          ];

          switch (self.previewData?.data?.status) {
            // case self.$dataModules.invoice.status.created:
            //   funcBars.unshift({
            //     label: "Resend",
            //     icon: "fas fa-paper-plane",
            //     onClick() {},
            //   });
            //   funcBars.unshift({
            //     label: "Edit invoice",
            //     icon: "fas fa-edit",
            //     onClick() {
            //       // TODO: edit specific invoice
            //     },
            //   });
            //   break;
            case self.$dataModules.invoice.status.sent:
            case self.$dataModules.invoice.status.paid:
            case self.$dataModules.invoice.status.paying:
            case self.$dataModules.invoice.status.refunding:
            case self.$dataModules.invoice.status.refunded:
            case self.$dataModules.invoice.status.paidOffline:
            case self.$dataModules.invoice.status.waived:
            case self.$dataModules.invoice.status.wavied:
            case self.$dataModules.invoice.status.failed:
            case self.$dataModules.invoice.status.refundFailed:
              funcBars.unshift({
                label: "Share",
                icon: "fa-solid fa-share",
                onClick() {
                  let link = "";
                  if (href.indexOf("localhost:") > -1) {
                    link = "http://localhost:8080";
                  } else if (href.indexOf("tunekey-test") > -1) {
                    link = "https://tunekey-test.web.app";
                  } else {
                    link = "https://tunekey.app";
                  }
                  navigator.clipboard
                    .writeText(`${link}/invoice/${self.previewData?.data?.id}`)
                    .then((res) => {
                      self.$notify({
                        message: "Copied invoice link!",
                        type: "success",
                      });
                    });
                },
              });

            // funcBars.unshift({
            //   label: "Record payment",
            //   icon: "fas fa-clipboard",
            //   onClick() {},
            // });
            // funcBars.unshift({
            //   label: "Resend",
            //   icon: "fas fa-paper-plane",
            //   onClick() {},
            // });
            // funcBars.unshift({
            //   label: "Edit invoice",
            //   icon: "fas fa-edit",
            //   onClick() {
            //     // TODO: edit specific invoice
            //   },
            // });
          }
        }
        console.log("func bars:", self.funcBars);
      }

      self.funcBars = funcBars;
    },

    // Setting
    async createStudioAccountInfo() {
      let self = this;

      self.initPaymentMethods(async () => {
        self.accountInfo = await self.$paymentService.createStudioAccountInfo(
          self.studioInfo?.id
        );
        self.$bus.$emit("hideFullCover");
        self.showPayActivationFeeAlert = false;
        self.showPaymentReceivedAlert = true;
      });
    },
    async payActivationFee() {
      let self = this;
      self.showActivationFeeAlert = false;
      self.$bus.$emit("showFullCover");
      await self.initFeePaymentIntent();
      self.$bus.$emit("hideFullCover");
      self.showPayActivationFeeAlert = true;
    },
    async initFeePaymentIntent() {
      let self = this;
      self.feePaymentrIntent =
        await self.$paymentService.getClientSecretForPayoutFee(
          self.studioInfo?.id
        );
    },
    onClickPaymentMethod(data) {
      let self = this;
      if (data?.data?.object == "LINK") {
        self.showPaymentLinkModal = true;

        self.paymentLinkModal.isEdit = true;
        // self.paymentLinkModal.isContent = false;
        self.paymentLinkModal.isContent = true;
        self.paymentLinkModal.link = data?.data?.cardNumber;

        self.paymentLinkModal.onRightTapped = () => {
          // self.paymentLinkModal.isContent = true;
          // self.paymentLinkModal.link = data?.data?.value;

          self.paymentLinkModal.onRightTapped = () => {
            if (self.$tools.isURL(self.paymentLinkModal.link)) {
              self.updatePaymentLink(data?.data, self.paymentLinkModal.link);
              self.clearPaymentLinkModal();
            } else {
              self.$notify({
                message: "Please type correct payment link!",
                type: "warning",
              });
            }
          };
        };
        self.paymentLinkModal.onBottomTapped = () => {
          self.deletePaymentLink(data?.data);
          self.clearPaymentLinkModal();
        };
      } else {
        // self.showCardDebitBankkModal = true;

        // self.cardDebitBankkModal.onRightTapped = () => {
        //   self.showCardDebitBankkModal = false;
        //   self.showBeneficialInfo = true;
        // };
        // self.cardDebitBankkModal.onBottomTapped = async () => {
        //   // self.deleteStudioAccountInfo();
        //   await self.getStudioBalance();
        //   self.showRemoveAccountAlert = true;
        // };

        // self.initStripeAccountLink((res) => {
        //   let url = res?.data?.url;
        //   window.location = url;
        // });
        self.initPaypalAccountLink();
      }
    },
    updateModalPaymentLink(link) {
      this.paymentLinkModal.link = link;
    },
    showAddressModal(focus) {
      if (focus) {
        this.showAddress = true;
      }
    },
    showInvoiceEmail(focus) {
      if (focus) {
        this.showInvoiceEmailTemplate = true;
      }
    },
    updatedFinancial() {
      this.toggleBtnStatus(false, {
        message: this.$dataModules.notify.save.success,
        type: "success",
      });
    },
    updateStripeInfo(data) {
      let self = this;
      self.initPaymentMethods(() => {
        self.cardDebitBankData = data.data;
        self.accountInfo.accountInfo = self.$tools.equalValue(data.accountInfo);
      });
    },
    async saveData(data, callback) {
      let self = this;
      let now = self.$moment().unix();
      let updateBillingSetting = self.$functionsService.updateBillingSettingV2;

      console.log("data: ", {
        ...self.previewData.data,
        ...data,
        updateTimestamp: now,
      });

      self.toggleBtnStatus(true, {
        message: self.$i18n.t("notification.loading.save"),
        type: "loading",
      });

      let statusMap = {};
      Object.keys(self.invoiceConfigsMap).forEach((key) => {
        statusMap[key] =
          self.invoiceConfigsMap[key]?.status ==
          self.$dataModules.invoiceConfig.status.active;
      });
      console.log("statusMap: ", statusMap);

      let manualInvoiceIds = [];
      Object.keys(self.manualUpcommingInvoicesMap).forEach((key) => {
        manualInvoiceIds.push(key);
      });
      console.log("manualInvoiceIds: ", manualInvoiceIds);

      updateBillingSetting({
        studioId: self.studioInfo?.id,
        billingSetting: {
          ...self.previewData.data,
          ...data,
          updateTimestamp: now,
        },
        statusChangedInvoiceConfigs: statusMap,
        sendManuallyInvoices: manualInvoiceIds,
      })
        .then((res) => {
          self.toggleBtnStatus(false, {
            message: self.$i18n.t("notification.success.save"),
            type: "success",
          });

          if (callback) {
            callback();
          }
        })
        .catch((err) => {
          console.log("err: ", err, err?.response?.data?.message);
          self.toggleBtnStatus(false, {
            message: self.$i18n.t("notification.failed.save"),
            type: "error",
          });
        });
    },
    async saveInvoiceTitle() {
      let self = this;
      let data = {
        businessInfo: self.previewData?.data?.businessInfo ?? "",
        branding: self.previewData?.data?.branding ?? "",
      };

      if (!self.$tools.isNull(self.previewData.data.addressDetail)) {
        data.addressDetail = self.previewData?.data?.addressDetail ?? {};
        data.address = self.$dataModules.format.address(data.addressDetail);
      }

      await self.saveData(data);
    },
    async saveAutoInvoicing(save = false, callback) {
      let self = this;
      let data = {
        flatAmount:
          self.previewData.data.autoInvoicingSetting.flatAmount ??
          self.$dataModules.studioBillingSetting.autoInvoicingSetting
            .flatAmount,
        isSendAutomatically:
          self.previewData.data.autoInvoicingSetting.isSendAutomatically,
        enable: false,
        salesTax: self.previewData.data.autoInvoicingSetting.salesTax,
        lateFee: self.previewData.data.autoInvoicingSetting.lateFee,
        otherFees: self.previewData.data.autoInvoicingSetting.otherFees,
        billingCycle: self.previewData.data.autoInvoicingSetting.billingCycle,
        billingCycleDate:
          self.previewData.data.autoInvoicingSetting.billingCycleDate,
        invoiceDate: self.previewData.data.autoInvoicingSetting.invoiceDate,
        dueDate:
          isNaN(self.previewData.data.autoInvoicingSetting.dueDate) ||
          self.$tools.isNull(self.previewData.data.autoInvoicingSetting.dueDate)
            ? -1
            : self.previewData.data.autoInvoicingSetting.dueDate,
        lateDate:
          isNaN(self.previewData.data.autoInvoicingSetting.lateDate) ||
          self.$tools.isNull(
            self.previewData.data.autoInvoicingSetting.lateDate
          )
            ? -1
            : self.previewData.data.autoInvoicingSetting.lateDate,
        notes: self.previewData.data.autoInvoicingSetting.notes,
        email: self.previewData.data.autoInvoicingSetting.email,
        emailNoticeDestination:
          self.previewData.data.autoInvoicingSetting.emailNoticeDestination,

        emailTemplates: self.$commons.mapToArray(self.emailTemplatesMap),
      };

      console.log("saveAutoInvoicing: ", data);

      // return false;

      Object.keys(self.invoiceConfigsMap).forEach((key) => {
        if (
          self.$tools.isNull(
            self.invoiceConfigsMap[key]?.isSendAutomatically
          ) ||
          !self.invoiceConfigsMap[key]?.isCustomized
        ) {
          self.invoiceConfigsMap[key].isSendAutomatically =
            self.previewData.data.autoInvoicingSetting.isSendAutomatically ??
            true;
        }
      });

      if (save) {
        console.log("save auto-invoicing");
        await self.saveData(
          {
            autoInvoicingSetting: data,
          },
          callback
        );
        self.showSaveSettingAlert = false;
      } else {
        console.log("calc upcoming");
        let billingSetting = {
          ...self.previewData.data,
          ...{
            autoInvoicingSetting: data,
          },
        };
        let startUnix = self.$moment().startOf("date").unix();
        let endUnix = self.$moment().add(1, "months").endOf("date").unix();

        self.upcomingInvoicesMap =
          await self.$paymentService.calculateUpcomingInvoice({
            start: startUnix,
            end: endUnix,
            tempBillingSetting: billingSetting,
            tempInvoiceConfigsMap: self.invoiceConfigsMap,
          });
        self.manualUpcommingInvoicesMap = {};

        let invoicesMap = await self.$paymentService.invoiceAction.getByRange(
          startUnix,
          endUnix,
          self.studioInfo.id
        );

        Object.keys(invoicesMap).forEach((key) => {
          if (invoicesMap[key]?.isEmailSent) {
            delete self.upcomingInvoicesMap[key];
          }
        });

        self.showSaveSettingAlert = true;
        // self.showSaveSettingAlert =
        //   Object.keys(self.upcomingInvoicesMap)?.length > 0;

        // if (!self.showSaveSettingAlert) {
        //   self.saveAutoInvoicing(true);
        // }
      }
    },
    async saveInvoiceFees() {
      let self = this;
      let data = {
        salesTax: self.previewData.data.salesTax,
        lateFee: self.previewData.data.lateFee,
        otherFees: self.previewData.data.otherFees,
      };

      await self.saveData(data);
    },
    async saveInvoiceDate() {
      let self = this;

      let data = {
        dueDate: self.previewData.data.dueDate,
        invoiceDate: self.previewData.data.invoiceDate,
      };

      await self.saveData(data);
    },
    async saveInvoiceText() {
      let self = this;
      let data = {
        notes: self.previewData.data.notes,
        emailText: self.previewData.data.emailText,
        emailNoticeDestination: self.previewData.data.emailNoticeDestination,
      };

      await self.saveData(data);
    },
    clearOtherFeeItem() {
      this.otherFeeItem = this.$dataModules.format.amountModule;
    },
    deleteOtherFee(index) {
      let self = this;
      self.otherFees.splice(index, 1);
      self.updateSetting(self.otherFees, "autoInvoicingSetting.otherFees");
    },
    updateOtherFee(data) {
      let self = this;
      if (self.$tools.isNull(data.index)) {
        // create
        self.otherFees.push({
          title: data.title,
          amount: data.amount,
          amountType: data.amountType,
        });
      } else {
        // update
        self.otherFees[data.index] = {
          title: data.title,
          amount: data.amount,
          amountType: data.amountType,
        };
      }
      self.clearOtherFeeItem();
      self.showOtherFee = false;
      self.updateSetting(self.otherFees, "autoInvoicingSetting.otherFees");
    },
    updatePersonalizeSetting(data) {
      let self = this;
      console.log("updatePersonalizeSetting: ", data);
      self.invoiceConfigsMap[data.id] = data;
      self.$forceUpdate();
    },
    updateSetting(data, name) {
      let self = this;
      switch (name) {
        // text
        case "businessInfo":
        case "branding":
          self.previewData.data[name] = data.trim();
          break;
        case "autoInvoicingSetting.notes":
          self.previewData.data.autoInvoicingSetting.notes = data;
          break;
        case "autoInvoicingSetting.email":
          // self.previewData.data.autoInvoicingSetting[name.split(".")[1]] = data;
          self.emailText = data;
          break;
        case "autoInvoicingSetting.billingCycle":
          self.previewData.data.autoInvoicingSetting.billingCycle =
            data?.id ?? "";
          self.billingCycle = self.$tools.equalValue(data ?? {});
          break;
        // boolean
        case "autoInvoicingSetting.isSendAutomatically":
          self.previewData.data.autoInvoicingSetting.isSendAutomatically =
            Boolean(data);

          Object.keys(self.invoiceConfigsMap).forEach((key) => {
            if (!self.invoiceConfigsMap[key].isCustomized) {
              self.invoiceConfigsMap[key].isSendAutomatically = data;
            }
          });

          self.$forceUpdate();
          break;
        case "autoInvoicingSetting.addLessonToFirstInvoice":
          self.previewData.data.autoInvoicingSetting.addLessonToFirstInvoice =
            Boolean(data);

          Object.keys(self.invoiceConfigsMap).forEach((key) => {
            if (!self.invoiceConfigsMap[key].isCustomized) {
              self.invoiceConfigsMap[key].addLessonToFirstInvoice = data;
            }
          });

          self.$forceUpdate();
          break;
        // %
        case "autoInvoicingSetting.salesTax":
          self.salesTax = math
            .chain(data?.value ?? 0)
            .multiply(1)
            .done();
          self.previewData.data.autoInvoicingSetting.salesTax.amount = math
            .chain(data?.value ?? 0)
            .divide(100)
            .done();
          break;
        // int
        case "autoInvoicingSetting.invoiceDate":
          self.previewData.data.autoInvoicingSetting.invoiceDate = parseInt(
            data || 1
          );
          console.log(
            "invoiceDate: ",
            self.previewData.data.autoInvoicingSetting.invoiceDate
          );

          if (
            self.previewData.data.autoInvoicingSetting.invoiceDate <=
            self.previewData.data.autoInvoicingSetting.dueDate
          ) {
            self.previewData.data.autoInvoicingSetting.dueDate =
              self.previewData.data.autoInvoicingSetting.invoiceDate - 1;
          }
          break;
        case "autoInvoicingSetting.dueDate":
          self.previewData.data.autoInvoicingSetting.dueDate =
            parseInt(data || 0) >=
            self.previewData.data.autoInvoicingSetting.invoiceDate
              ? 0
              : parseInt(data);
          console.log(
            "dueDate: ",
            self.previewData.data.autoInvoicingSetting.dueDate
          );
          break;
        case "autoInvoicingSetting.lateDate":
          self.previewData.data.autoInvoicingSetting[name.split(".")[1]] =
            parseInt(data) == 0 ? 1 : parseInt(data);
          console.log(
            "lateDate: ",
            self.previewData.data.autoInvoicingSetting.lateDate
          );
          break;
        case "autoInvoicingSetting.billingCycleDate":
          self.previewData.data.autoInvoicingSetting.billingCycleDate =
            data?.id ?? 0;
          self.billingCycleDate = self.$tools.equalValue(data ?? {});
          break;
        // % & $
        case "autoInvoicingSetting.lateFee":
          self.lateFee = data?.value ?? 0;
          self.lateFeeType = data?.type ?? "FLAT";

          self.previewData.data.autoInvoicingSetting.lateFee.amount =
            self.lateFeeType == "PERCENTAGE"
              ? math
                  .chain(data?.value ?? 0)
                  .divide(100)
                  .done()
              : math
                  .chain(data?.value ?? 0)
                  .multiply(1)
                  .done();
          self.previewData.data.autoInvoicingSetting.lateFee.amountType =
            data.type;
          break;
        case "autoInvoicingSetting.otherFees":
          self.previewData.data.autoInvoicingSetting.otherFees = [];
          self.otherFees.some((item) => {
            self.previewData.data.autoInvoicingSetting.otherFees.push({
              title: item.title,
              amountType: item.amountType,
              amount:
                item.amountType == "PERCENTAGE"
                  ? math
                      .chain(item?.amount ?? 0)
                      .divide(100)
                      .done()
                  : math
                      .chain(item?.amount ?? 0)
                      .multiply(1)
                      .done(),
            });
          });
          break;
        // obj
        case "address":
          self.previewData.data.address = self.$tools.equalValue(data);
          break;
        // arr string
        case "autoInvoicingSetting.emailNoticeDestination":
          console.log("更新 email to");
          self.previewData.data.autoInvoicingSetting.emailNoticeDestination =
            [];
          self.emailNoticeDestination = data;

          for (let id in self.emailNoticeDestination) {
            self.previewData.data.autoInvoicingSetting.emailNoticeDestination.push(
              id
            );
          }

          break;
      }
      // self.$forceUpdate()
    },
    updateCurrency(data) {
      let self = this;
      self.studioInfo.currency = self.$tools.equalValue(data);
      self.$tkCurrency = self.$tools.equalValue(data);
      self.showCurrencyModel = false;
      self.$forceUpdate();
    },
    updateAddress(data) {
      let self = this;
      self.updateSetting(
        {
          line1: data.address,
          line2: "",
          city: data.city,
          state: data.state,
          country: data.country,
          postal_code: data.code,
        },
        "address"
      );
      self.showAddress = false;
    },
    initSetting(data) {
      console.log("init setting: ", data);
      let self = this;
      self.salesTax = math
        .chain(data?.autoInvoicingSetting?.salesTax?.amount ?? 0)
        .multiply(100)
        .done();
      self.lateFee =
        data.autoInvoicingSetting.lateFee?.amountType == "PERCENTAGE"
          ? math
              .chain(data?.autoInvoicingSetting?.lateFee?.amount ?? 0)
              .multiply(100)
              .done()
          : math
              .chain(data?.autoInvoicingSetting?.lateFee?.amount ?? 0)
              .multiply(1)
              .done();
      self.lateFeeType =
        data?.autoInvoicingSetting?.lateFee?.amountType ??
        self.$dataModules.format.amount().amountType.flat;
      self.otherFees = data?.autoInvoicingSetting?.otherFees ?? [];
      let emailNoticeDestination =
        data?.autoInvoicingSetting?.emailNoticeDestination ?? [];

      self.otherFees?.some((item) => {
        if (
          item.amountType ==
          self.$dataModules.format.amount().amountType.percentage
        ) {
          item.amount = math
            .chain(item?.amount ?? 0)
            .multiply(100)
            .done();
        }
      });

      self.emailNoticeDestination = {};
      emailNoticeDestination?.some((item) => {
        self.emailNoticeDestination[item] = {
          id: item,
          name:
            item == self.emailTo[0].id
              ? self.emailTo[0].name
              : item == self.emailTo[1].id
              ? self.emailTo[1].name
              : item == self.emailTo[2].id
              ? self.emailTo[2].name
              : self.emailTo[3].name,
        };
      });

      self.billingCycle.id =
        data?.autoInvoicingSetting?.billingCycle ??
        self.$dataModules.invoiceConfig.billingCycle.weekly;
      self.billingCycleDate.id =
        data?.autoInvoicingSetting?.billingCycleDate ?? 0;

      if (self.billingCycle == self.billingCyclesType[2].id) {
        self.billingCycleDate.name =
          self.monthCycle.filter(
            (item) => item.id == self.billingCycleDate.id
          )[0]?.name ?? "";
      }

      self.emailText = data?.autoInvoicingSetting?.email ?? "";

      console.log("billingCycle: ", self.billingCycle);
      console.log("billingCycleDate: ", self.billingCycleDate);
    },
    clearPaymentLinkModal() {
      let self = this;
      self.showPaymentLinkModal = false;

      self.paymentLinkModal.isEdit = false;
      self.paymentLinkModal.isContent = false;
      self.paymentLinkModal.link = "";

      self.paymentLinkModal.onBottomTapped = null;
      self.paymentLinkModal.onRightTapped = null;
    },
    clearCardDebitBankkModal() {
      let self = this;
      self.showCardDebitBankkModal = false;
      self.cardDebitBankkModal.isNext = false;
      self.cardDebitBankkModal.onBottomTapped = null;
      self.cardDebitBankkModal.onRightTapped = null;
    },
    async initPaymentMethods(init) {
      let self = this;
      self.paymentMethods = [];

      if (init) {
        await init();
      } else {
        self.loadingPaymentAccount = true;
        // await self.initCardDebitBank();
        // TODO:
        await self.initPaypalAccount();
        await self.initPaymentLink();
      }

      // if (self.accountInfo) {
      //   if (self.cardDebitBankData.length > 0) {
      //     self.cardDebitBankData.some((item) => {
      //       self.paymentMethods.push({
      //         object: item.object,
      //         bankAccountType:
      //           item.object == "bank_account"
      //             ? !self.$tools.isNull(item?.account_type)
      //               ? item.account_type.toUpperCase()
      //               : ""
      //             : null,
      //         cardType:
      //           item.object == "card"
      //             ? !self.$tools.isNull(item?.funding)
      //               ? item.funding.toUpperCase()
      //               : ""
      //             : null,
      //         brand: item?.brand ?? "",
      //         bankName: item?.bank_name ?? "",
      //         expireDate:
      //           item.object == "card"
      //             ? item.exp_month + "/" + item.exp_year
      //             : "",
      //         cardNumber: "**** **** **** " + item?.last4 ?? "****",
      //         holderName:
      //           (item?.name || item?.account_holder_name) ??
      //           (self.accountInfo?.accountInfo?.business_type == "company"
      //             ? self.accountInfo?.accountInfo?.company?.name
      //             : self.accountInfo?.accountInfo?.business_type == "individual"
      //             ? self.accountInfo?.accountInfo?.individual?.first_name +
      //               " " +
      //               self.accountInfo?.accountInfo?.individual?.last_name
      //             : self.accountInfo?.accountInfo?.business_profile?.name),
      //         type: !self.$tools.isNull(
      //           self.accountInfo?.accountInfo?.requirements?.disabled_reason
      //         )
      //           ? "REQUIRED_CONFIG"
      //           : item.object == "bank_account"
      //           ? item.bank_name.toUpperCase().replace(/ /g, "_")
      //           : item.object == "card"
      //           ? item.brand.toUpperCase().replace(/ /g, "_")
      //           : "",
      //         disableReason: self.getStripeAccountDisabledReason(),
      //         datetime:
      //           self.accountInfo?.updateTimestamp ??
      //           self.accountInfo?.createTimestamp,
      //       });
      //     });
      //   } else {
      //     console.log("添加config");
      //     self.paymentMethods.push({
      //       object: "",
      //       bankAccountType: "",
      //       cardType: "",
      //       brand: "",
      //       bankName: "",
      //       expireDate: "",
      //       cardNumber: "-- -- -- --",
      //       holderName:
      //         self.accountInfo?.accountInfo?.business_type == "company"
      //           ? self.accountInfo?.accountInfo?.company?.name
      //           : self.accountInfo?.accountInfo?.business_type == "individual"
      //           ? self.accountInfo?.accountInfo?.individual?.first_name ??
      //             "" +
      //               " " +
      //               self.accountInfo?.accountInfo?.individual?.last_name ??
      //             ""
      //           : self.accountInfo?.accountInfo?.business_profile?.name ?? "",
      //       type: "REQUIRED_CONFIG",
      //       disableReason: "REQUIRED_CONFIG",
      //       datetime:
      //         self.accountInfo?.updateTimestamp ??
      //         self.accountInfo?.createTimestamp,
      //     });
      //   }
      // }

      // TODO: Add paypal info
      if (self.paypalInfo?.studioId) {
        self.paymentMethods.push({
          bankName: "PayPal",
          holderName: self.studioInfo.name,
          type: "PAYPAL",
          email: self.paypalInfo?.email ?? self.studioInfo?.email,
        });
      }

      self.paymentLinks.some((item) => {
        self.paymentMethods.push({
          object: "LINK",
          bankAccountType: null,
          cardType: null,
          brand: "",
          bankName: "",
          expireDate: "",
          cardNumber: item.link,
          holderName: item.name.toUpperCase(),
          type: item.name.toUpperCase(),
          disableReason: "",
          datetime: item.datetime,
        });
      });

      self.paymentMethods.sort((a, b) => {
        return a.datetime - b.datetime;
      });

      self.loadingPaymentAccount = false;
      self.initFuncBars(self.settingType.PAYMENT_METHOD);
      self.showPendingCardDebitBankAlert = false;
      self.$forceUpdate();
    },
    getStripeAccountDisabledReason() {
      let self = this;
      let disabled_reason =
        self.accountInfo?.accountInfo.requirements.disabled_reason;

      if (!self.$tools.isNull(disabled_reason)) {
        switch (disabled_reason) {
          case "actionRequiredRequestedCapabilities":
            return "Capabilities request required";
          case "requirementsPastDue":
            return "Additional information required";
          case "requirementsPendingVerification":
            return "Pending for verfication";
          case "listed":
            return "Pending for verification (Account listed)";
          case "underReview":
            return "Pending for under review by Stripe";
          case "platformPaused":
            return "Platform paused";
          case "rejectedFraud":
            return "Rejected by FRAUD";
          case "rejectedIncompleteVerification":
            return "Rejected by INCOMPLETE VERIFICATION";
          case "rejectedListed":
            return "Rejected by LISTED";
          case "rejectedOther":
            return "Rejected by OTHER";
          case "rejectedTermsOfService":
            return "Rejected due to suspected terms of service violations";
          case "other":
            return "Configuration required by OTHER";
        }
        if (
          self.accountInfo?.accountInfo.payouts_enabled &&
          self.accountInfo?.accountInfo.charges_enabled
        ) {
          let data =
            self.accountInfo?.accountInfo?.external_accounts?.data?.filter(
              (item) => !Boolean(item?.exp_month) || !Boolean(item?.exp_year)
            )[0];
          if (data) {
            return "Configuration Required";
          }
        }

        return "Configuration Required";
      } else {
        return "";
      }
    },
    async initPaypalAccount() {
      let self = this;

      let studioPaypalInfoDoc = await self.$collections.studioPaypalInfo
        .doc(self.studioInfo?.id)
        .get();
      if (studioPaypalInfoDoc.exists) {
        self.paypalInfo = studioPaypalInfoDoc.data();
      }
    },
    async initPaymentLink(online) {
      let self = this;

      if (online) {
        let studioBillingSetting =
          await self.$studioService.studioBillingSetting(true);
        self.paymentLinks = studioBillingSetting?.paymentLinks ?? [];
        self.previewData.data.paymentLinks = self.paymentLinks;
      } else {
        self.paymentLinks = self.previewData?.data?.paymentLinks ?? [];
      }

      console.log("payment links: ", self.paymentLinks);
    },
    async addPaymentLink(link) {
      let self = this;
      let links = self.previewData?.data?.paymentLinks ?? [];
      let now = self.$moment().unix();
      let isRepeated = false;
      console.log("link: ", link);

      links.some((item) => {
        if (item.link == link) {
          isRepeated = true;
        }
      });

      if (isRepeated) {
        self.$notify({
          message: "Link already exists",
          type: "warning",
        });
      } else {
        links.push({
          link: link,
          name: self.$tools.getUrlName(link),
          datetime: self.$moment().unix(),
        });
        await self.savePaymentLink({
          data: links,
          isAdd: true,
        });
      }
    },
    async updatePaymentLink(data, value) {
      let self = this;
      let links = self.previewData.data.paymentLinks;

      for (let i = 0; i < links.length; i++) {
        if (links[i].datetime == data.datetime) {
          links[i].link = value;
          break;
        }
      }

      await self.savePaymentLink({
        data: links,
      });
    },
    async deletePaymentLink(data) {
      let self = this;
      let links = self.previewData.data.paymentLinks;

      for (let i = 0; i < links.length; i++) {
        if (links[i].datetime == data.datetime) {
          links.splice(i, 1);
          break;
        }
      }

      await self.savePaymentLink({
        data: links,
      });
    },
    async savePaymentLink({ data = [], isAdd = false }) {
      let self = this;
      let now = self.$moment().unix();
      self.previewData.data.paymentLinks = self.$tools.equalValue(data);

      console.log(self.previewData.data);

      await self.saveData({
        paymentLinks: self.$tools.equalValue(data),
      });

      // self.$bus.$emit("showFullCover", {
      //   message: isAdd
      //     ? self.$i18n.t("notification.loading.add")
      //     : self.$i18n.t("notification.loading.update"),
      //   type: "loading",
      //   timeout: 0,
      //   unix: now,
      // });

      // await self.$studioService.studioBillingSettingAction.update(
      //   self.studioInfo.id,
      //   {
      //     paymentLinks: self.previewData.data.paymentLinks,
      //   },
      //   (res) => {
      //     if (res) {
      //       self.$bus.$emit("hideFullCover", {
      //         message: isAdd
      //           ? self.$i18n.t("notification.success.add")
      //           : self.$i18n.t("notification.success.update"),
      //         type: "success",
      //         unix: now,
      //       });
      //     } else {
      //       self.$bus.$emit("hideFullCover", {
      //         message: isAdd
      //           ? self.$i18n.t("notification.failed.add")
      //           : self.$i18n.t("notification.failed.update"),
      //         type: "error",
      //         unix: now,
      //       });
      //     }
      //   }
      // );

      self.initPaymentMethods(self.initPaymentLink);
    },
    async initCardDebitBank() {
      let self = this;
      self.cardDebitBankData = [];

      let accountInfo = await self.$paymentService.getAccountInfo(
        self.studioInfo?.id
      );

      self.accountInfo = self.$tools.equalValue(accountInfo);

      if (accountInfo?.accountInfo) {
        self.cardDebitBankData =
          accountInfo?.accountInfo?.external_accounts?.data ?? [];
      }

      console.log("accountInfo: ", accountInfo);
      console.log("bank & card & debit: ", self.cardDebitBankData);
    },
    async getStudioBalance() {
      let self = this;
      self.$bus.$emit("showFullCover");

      // 1. 判断是否有余额
      // 2. 判断是否已经是激活的账号(已激活不退费)

      let balance = await self.$paymentService.getAccountBalance(
        self.studioInfo.id
      );

      self.$bus.$emit("hideFullCover");
      console.log("balance: ", balance);

      self.accountBalance.available = 0;
      self.accountBalance.pending = 0;
      self.accountBalance.instant_available = 0;
      self.accountBalance.connect_reserved = 0;

      if (balance?.available) {
        balance?.available.some((item) => {
          self.accountBalance.available += item?.amount ?? 0;
        });
      }

      if (balance?.pending) {
        balance?.pending.some((item) => {
          self.accountBalance.pending += item?.amount ?? 0;
        });
      }

      if (balance?.instant_available) {
        balance?.instant_available.some((item) => {
          self.accountBalance.instant_available += item?.amount ?? 0;
        });
      }

      if (balance?.connect_reserved) {
        balance?.connect_reserved.some((item) => {
          self.accountBalance.connect_reserved += item?.amount ?? 0;
        });
      }
    },
    async deleteStudioAccountInfo() {
      let self = this;
      let now = self.$moment().unix();
      self.showCardDebitBankkModal = false;
      self.showRemoveAccountAlert = false;

      self.$bus.$emit("showFullCover", {
        message: self.$i18n.t("notification.loading.delete"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      let success = await self.$paymentService.deleteStudioAccountInfo(
        self.studioInfo.id
      );

      if (success) {
        self.$bus.$emit("hideFullCover", {
          message: self.$i18n.t("notification.success.delete"),
          type: "success",
          unix: now,
        });
        self.initPaymentMethods(() => {
          self.accountInfo = null;
          self.cardDebitBankData = [];
        });
      } else {
        self.$bus.$emit("hideFullCover", {
          message: self.$i18n.t("notification.failed.delete"),
          type: "error",
          unix: now,
        });
      }
    },

    // preview
    preview(data) {
      let self = this;

      self.previewData = self.$tools.equalValue(data);
      console.log("preview: ", self.previewData);
      self.showPreview = true;

      if (data.type == self.businessTabsValue.invoice) {
        self.initFuncBars();
      } else if (data.type == self.businessTabsValue.payout) {
      } else if (data.type == self.businessTabsValue.setting) {
        let emailTemplates =
          data?.data?.autoInvoicingSetting?.emailTemplates ?? [];
        let emailTemplatesMap =
          self.$commons.arrayToMap(emailTemplates, "type") ?? {};
        Object.keys(emailTemplatesMap).forEach((key) => {
          let template = emailTemplatesMap[key];
          if (
            !self.$tools.isNull(template?.subject) &&
            !self.$tools.isNull(template?.body)
          ) {
            self.emailTemplatesMap[template.type] = template;
          }
        });

        if (data.settingType == self.settingType.PAYMENT_METHOD) {
          self.initPaymentMethods();
        }
      }
    },
    hidePreview() {
      this.showPreview = false;
      this.previewData = {};
    },
  },
};
</script>
<style scoped></style>
