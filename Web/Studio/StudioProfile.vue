<template>
  <div>
    <div class="tk-g-root-container tk-layout-flex-row">
      <div class="tk-layout-flex-1 tk-layout-flex-column tk-layout-full-height">
        <!-- title -->
        <div class="tk-page-title tk-px-margin-bottom-px16">
          {{ $t("admin.studio.title") }}
        </div>

        <!-- content -->
        <div class="tk-layout-flex-1 tk-layout-flex-row tk-overflow-y">
          <div class="tk-layout-page-left tk-layout-full-height tk-overflow-y">
            <!-- studio type -->
            <card
              v-if="$tkVersion.isNew"
              outerClass="tk-base-shadow-item tk-bg-color-transparent tk-cursor-pointer"
              bottom="tk-px-margin-bottom-px16"
              :class="{
                'tk-border-bottom-color-gray-200':
                  currentStep != step.STUDIO_TYPE,
                'tk-border-color-main tk-px-border-px2':
                  currentStep == step.STUDIO_TYPE,
              }"
              innerClass="tk-px-padding-px16"
              @onClick="currentStep = step.STUDIO_TYPE"
            >
              <div class="tk-text-base-bold tk-px-margin-bottom-px4">
                {{ $t("admin.studio.studio_type") }}
              </div>
              <div
                class="tk-text-base tk-font-color-gray tk-font-lineHeight-general"
              >
                {{
                  isNull(currentStudioType)
                    ? ""
                    : formatFirstLetterUpper(
                        currentStudioType.split("_")[0] +
                          " " +
                          currentStudioType.split("_")[1]
                      )
                }}
              </div>
            </card>

            <!-- branding -->
            <card
              outerClass="tk-base-shadow-item tk-bg-color-transparent tk-cursor-pointer"
              bottom="tk-px-margin-bottom-px16"
              :class="{
                'tk-border-bottom-color-gray-200': currentStep != step.BRANDING,
                'tk-border-color-main tk-px-border-px2':
                  currentStep == step.BRANDING,
              }"
              innerClass="tk-px-padding-px16"
              @onClick="currentStep = step.BRANDING"
            >
              <div class="tk-text-base-bold tk-px-margin-bottom-px8">
                {{ $t("admin.studio.branding") }}
              </div>
              <div class="tk-font-color-gray">
                {{ $t("admin.studio.branding_desc") }}
              </div>
            </card>

            <!-- storefront -->
            <card
              outerClass="tk-base-shadow-item tk-bg-color-transparent tk-cursor-pointer"
              bottom="tk-px-margin-bottom-px16"
              :class="{
                'tk-border-bottom-color-gray-200':
                  currentStep != step.STOREFRONT,
                'tk-border-color-main tk-px-border-px2':
                  currentStep == step.STOREFRONT,
              }"
              innerClass="tk-px-padding-px16"
              @onClick="currentStep = step.STOREFRONT"
            >
              <!-- :innerClass="
                currentStep != step.STOREFRONT
                  ? 'tk-px-padding-bottom-px16 tk-px-padding-lr-px0 tk-px-padding-top-px0'
                  : 'tk-px-padding-px16'
              " -->
              <div class="tk-text-base-bold tk-px-margin-bottom-px8">
                {{ $t("admin.studio.storefront") }}
              </div>
              <div class="tk-font-color-gray">
                {{ $t("admin.studio.storefront_desc") }}
              </div>
            </card>

            <!-- contact -->
            <card
              v-if="$tkVersion.isNew"
              outerClass="tk-base-shadow-item tk-bg-color-transparent tk-cursor-pointer"
              bottom="tk-px-margin-bottom-px16"
              :class="{
                'tk-border-bottom-color-gray-200': currentStep != step.CONTACT,
                'tk-border-color-main tk-px-border-px2':
                  currentStep == step.CONTACT,
              }"
              @onClick="currentStep = step.CONTACT"
            >
              <div class="tk-text-base-bold tk-px-margin-bottom-px4">
                {{ $t("admin.studio.contact") }}
              </div>
              <div
                class="tk-text-base tk-font-color-gray tk-font-lineHeight-general"
              >
                {{ $t("admin.studio.contact_desc") }}
              </div>
            </card>

            <!-- Address -->
            <card
              v-if="$tkVersion.isNew"
              outerClass="tk-base-shadow-item tk-bg-color-transparent tk-cursor-pointer"
              bottom="tk-px-margin-bottom-px16"
              :class="{
                'tk-border-bottom-color-gray-200': currentStep != step.ADDRESS,
                'tk-border-color-main tk-px-border-px2':
                  currentStep == step.ADDRESS,
              }"
              @onClick="currentStep = step.ADDRESS"
            >
              <div class="tk-text-base-bold tk-px-margin-bottom-px4">
                {{ $t("admin.studio.address") }}
              </div>
              <div
                class="tk-text-base tk-font-color-gray tk-font-lineHeight-general"
              >
                {{
                  isNull(formatAddr())
                    ? $t("admin.need_configuration")
                    : formatAddr()
                }}
              </div>
            </card>

            <!-- timezone -->
            <card
              outerClass="tk-no-shadow tk-bg-color-transparent"
              bottom="tk-px-margin-bottom-px16"
              :class="{
                'tk-border-bottom-color-gray-200': currentStep != step.TIMEZONE,
                'tk-border-color-main tk-px-border-px2':
                  currentStep == step.TIMEZONE,
                'tk-cursor-pointer tk-base-shadow-item': $tkVersion.isNew,
              }"
            >
              <!-- @onClick="
                $tkVersion.isNew
                  ? (currentStep = step.TIMEZONE)
                  : (currentStep = currentStep)
              " -->
              <div class="tk-text-base-bold tk-px-margin-bottom-px4">
                {{ $t("admin.studio.timezone") }}
              </div>
              <div
                class="tk-text-base tk-font-color-gray tk-font-lineHeight-general"
              >
                {{ formatTimeZoneStr().full }}
              </div>
            </card>
          </div>

          <div
            class="tk-layout-page-right tk-layout-flex-column tk-layout-full-height"
          >
            <!-- TODO: multiple studio -->
            <div
              v-if="
                currentStep != step.STUDIO_TYPE &&
                $commons.studioIsMultipleStudios(studioInfo)
              "
              class="tk-overflow-x tk-px-margin-bottom-px32"
              id="studioContainer"
            >
              <div
                class="tk-layout-width-fit tk-text-nowrap tk-scrollbar"
                :style="{
                  margin: $commons.studioIsMultipleStudios(studioInfo)
                    ? '0'
                    : '0 auto',
                }"
              >
                <div
                  class="tk-layout-inline-block tk-px-radius-px6"
                  :class="{
                    'tk-px-padding-px2 tk-px-margin-right-px20':
                      currentStudioType == studioType.multipleStudios,
                    'tk-bg-color-main': studioInfo.id == item.id,
                  }"
                  :style="{ width: getLeftPartWidth() + 'px' }"
                  v-for="(item, index) in studios"
                  :key="index"
                >
                  <studio-item
                    :data="item"
                    :extraOptions="{
                      showIcon: index > 0,
                      icon: 'fas fa-trash',
                    }"
                    bottom="tk-px-margin-bottom-px0"
                    :logo="logo"
                    :storefrontColor="
                      '#' +
                      (isNull(item.storefrontColor)
                        ? '71d9c2'
                        : item.storefrontColor)
                    "
                    :textColor="
                      '#' +
                      (isNull(item.titlesColor) ? 'ffffff' : item.titlesColor)
                    "
                    itemClass="tk-cursor-pointer tk-px-padding-px16 tk-px-border-px2 tk-layout-inline-block tk-layout-full-width"
                    :class="[
                      studioInfo.id == item.id &&
                      currentStudioType == studioType.multipleStudios
                        ? 'tk-border-color-white'
                        : 'tk-border-color-transparent',
                    ]"
                    @onClick="initStudio(index)"
                    @onClickIcon="
                      showDeleteStudioAlert = true;
                      deleteStudioIndex = index;
                    "
                  ></studio-item>
                </div>

                <div
                  class="tk-cursor-pointer tk-layout-inline-block tk-font-color-main tk-text-base-bold"
                  v-if="$commons.studioIsMultipleStudios(studioInfo)"
                  @click.stop="addStudio"
                >
                  <i class="fas fa-plus tk-px-margin-right-px10"></i>
                  <span>{{ $t("admin.studio.add_studio") }}</span>
                </div>
              </div>
            </div>

            <div class="tk-overflow-y tk-layout-flex-1 tk-scrollbar">
              <slide-x-left-transition :duration="300" mode="out-in">
                <!-- studio type -->
                <div
                  :key="step.STUDIO_TYPE"
                  v-if="currentStep == step.STUDIO_TYPE"
                  class="tk-position-relative tk-layout-full-width tk-layout-full-height"
                >
                  <div>
                    <div class="tk-text-base-bold">
                      {{ $t("admin.studio.change_studio_type") }}
                    </div>
                    <div class="tk-text-base tk-font-color-gray">
                      {{ $t("admin.studio.change_studio_type_desc") }}
                    </div>
                  </div>

                  <div class="tk-px-width-px335" style="margin: 100px auto">
                    <studio-type-item
                      :label="$t('admin.studio.single_instructor')"
                      bottom="tk-px-margin-bottom-px32"
                      style="margin: 0 auto"
                      :extraOptions="{
                        showSelected:
                          currentStudioType == studioType.singleInstructor,
                        type: 'SINGLE_USER',
                      }"
                      :style="{ width: boxSize + 'px' }"
                      @onClick="
                        studios[0] &&
                        studios[0].studioTypeChangeHistory.length > 0 &&
                        $moment().unix() <=
                          $moment(
                            studios[0].studioTypeChangeHistory[0].datetime *
                              1000
                          )
                            .add(1, 'months')
                            .unix()
                          ? false
                          : (currentStudioType = studioType.singleInstructor)
                      "
                    ></studio-type-item>
                    <studio-type-item
                      :label="$t('admin.studio.multiple_instructor')"
                      bottom="tk-px-margin-bottom-px32"
                      style="margin: 0 auto"
                      :extraOptions="{
                        showSelected:
                          currentStudioType == studioType.multipleInstructors,
                        type: 'MULTIPLE_USERS',
                      }"
                      :style="{ width: boxSize + 'px' }"
                      @onClick="
                        studios[0] &&
                        studios[0].studioTypeChangeHistory.length > 0 &&
                        $moment().unix() <=
                          $moment(
                            studios[0].studioTypeChangeHistory[0].datetime *
                              1000
                          )
                            .add(1, 'months')
                            .unix()
                          ? false
                          : (currentStudioType = studioType.multipleInstructors)
                      "
                    ></studio-type-item>
                    <studio-type-item
                      :label="$t('admin.studio.multiple_studio')"
                      bottom="tk-px-margin-bottom-px32"
                      style="margin: 0 auto"
                      :extraOptions="{
                        showSelected:
                          currentStudioType == studioType.multipleStudios,
                        type: 'MULTIPLE_LOCATIONS',
                      }"
                      :style="{ width: boxSize + 'px' }"
                      @onClick="
                        studios[0] &&
                        studios[0].studioTypeChangeHistory.length > 0 &&
                        $moment().unix() <=
                          $moment(
                            studios[0].studioTypeChangeHistory[0].datetime *
                              1000
                          )
                            .add(1, 'months')
                            .unix()
                          ? false
                          : (currentStudioType = studioType.multipleStudios)
                      "
                    ></studio-type-item>

                    <div class="tk-text-center">
                      <base-button
                        v-if="
                          studios[0] &&
                          (studios[0].studioTypeChangeHistory.length == 0 ||
                            (studios[0].studioTypeChangeHistory.length > 0 &&
                              $moment().unix() >
                                $moment(
                                  studios[0].studioTypeChangeHistory[0]
                                    .datetime * 1000
                                )
                                  .add(1, 'months')
                                  .unix()))
                        "
                        type="main"
                        class="tk-px-width-px160 tk-border-none"
                        :class="[
                          currentStudioType == studioInfo.studioType
                            ? 'tk-no-shadow tk-text-base-bold tk-font-color-gray tk-bg-color-disableBtn'
                            : 'tk-base-shadow-item tk-text-base-bold tk-font-color-white tk-bg-color-main',
                        ]"
                        @click.stop="showAlert(currentStep)"
                        >{{ $t("general.save").toUpperCase() }}</base-button
                      >
                      <span
                        v-if="
                          studios[0] &&
                          studios[0].studioTypeChangeHistory.length > 0 &&
                          $moment().unix() <=
                            $moment(
                              studios[0].studioTypeChangeHistory[0].datetime *
                                1000
                            )
                              .add(1, 'months')
                              .unix()
                        "
                        >You changed the your studio type on
                        {{
                          $moment(
                            studios[0].studioTypeChangeHistory[0].datetime *
                              1000
                          ).format("M/D/YYYY")
                        }}
                        and the studio type can only be changed once within 24
                        hours.</span
                      >
                    </div>
                  </div>
                </div>

                <!-- branding -->
                <div
                  :key="step.BRANDING"
                  class="card tk-px-margin-bottom-px0 tk-no-shadow"
                  v-if="currentStep == step.BRANDING"
                >
                  <div
                    class="card-body tk-px-padding-px32"
                    style="min-height: 120px"
                    id="logoContainer"
                  >
                    <card-loading v-if="loading"></card-loading>
                    <template v-else>
                      <!-- studio name -->
                      <input-with-label
                        bottom="tk-px-margin-bottom-px32"
                        :label="$t('admin.studio.studio_name')"
                        :value="studioInfo.name"
                        @input="saveName"
                      >
                      </input-with-label>

                      <div>
                        <div
                          class="tk-text-base-bold tk-px-margin-bottom-px10 tk-layout-flex-row"
                        >
                          <div class="tk-font-color-gray tk-layout-flex-1">
                            Logo
                          </div>
                          <div
                            class="tk-font-color-main tk-cursor-pointer"
                            v-if="
                              logoExist && $tools.isNull(newLogo) && !showUpload
                            "
                            @click.stop="showUpload = true"
                          >
                            Reset
                          </div>
                          <div
                            class="tk-font-color-main tk-cursor-pointer"
                            v-if="
                              logoExist && !$tools.isNull(newLogo) && showUpload
                            "
                            @click.stop="
                              newLogo = '';
                              showUpload = false;
                            "
                          >
                            <!-- {{ $tools.isNull(newLogo) ? "Cancel" : "Restore" }} -->
                            Restore
                          </div>
                        </div>
                        <avatar-upload
                          v-if="showUpload"
                          class="tk-avatar-upload-empty"
                          @onUpdateAvatar="onUpdateLogo"
                        ></avatar-upload>
                        <div
                          v-else
                          class="tk-avatar-upload"
                          :style="{
                            background:
                              'url(' + (newLogo || logo) + ') no-repeat center',
                          }"
                        ></div>
                      </div>
                      <template v-if="false">
                        <div class="tk-font-color-gray">
                          {{ $t("admin.studio.logo") }}
                        </div>
                        <div
                          v-if="!showUpload"
                          class="tk-cursor-pointer tk-px-height-px200 tk-position-relative tk-px-width-px200 tk-px-radius-px200"
                          id="previewLogo"
                          ref="previewLogo"
                          @mouseenter="showCamera = true"
                          @mouseleave="showCamera = false"
                          @click.stop="
                            showUpload = true;
                            showCamera = false;
                          "
                          style="margin: 0 auto"
                        >
                          <!-- @click.stop="selectFile" -->
                          <div
                            class="tk-layout-full-width tk-layout-full-height tk-position-center tk-bg-color-gray-100 tk-px-radius-px100"
                            style="overflow: hidden"
                          >
                            <img
                              v-if="isNull(crop)"
                              class="tk-layout-inline-block"
                              style="max-height: 100%; max-width: 100%"
                              :src="isNull(crop) ? logo : crop"
                            />
                          </div>

                          <div
                            class="tk-layout-full-width tk-layout-full-height tk-position-center tk-avatar-outer rounded-circle"
                            v-if="showCamera"
                          >
                            <i
                              class="fas fa-camera tk-position-center tk-text-xxl"
                            ></i>
                          </div>
                        </div>

                        <div
                          id="imgCutterModal"
                          v-if="showUpload"
                          :class="{ 'tk-px-margin-top-px20': showUpload }"
                          style="overflow: hidden; height: auto"
                        >
                          <div>
                            <ImgCutter
                              v-if="boxSize > 0"
                              ref="imgCutterModal"
                              label="Select Image"
                              :crossOrigin="false"
                              crossOriginHeader="*"
                              rate="1:1"
                              :tool="false"
                              toolBgc="none"
                              :isModal="false"
                              :showChooseBtn="true"
                              :lockScroll="false"
                              :boxWidth="boxSize"
                              :boxHeight="boxSize"
                              :cutWidth="parseInt((boxSize / 5) * 4)"
                              :cutHeight="parseInt((boxSize / 5) * 4)"
                              :sizeChange="true"
                              :moveAble="true"
                              :originalGraph="false"
                              WatermarkText=" "
                              :smallToUpload="true"
                              :saveCutPosition="false"
                              :scaleAble="true"
                              :previewMode="true"
                              @cutDown="onCutDown"
                              @error="onCutError"
                              @onChooseImg="onChooseImg"
                              @onPrintImg="onPrintImg"
                              @onClearAll="onClearAll"
                            ></ImgCutter>
                          </div></div
                      ></template>

                      <div class="tk-text-center tk-px-margin-top-px32">
                        <base-button
                          type="main"
                          class="tk-footer-btn-base"
                          :class="[
                            studios[studioIndex].name != studioInfo.name ||
                            !isNull(newLogo)
                              ? 'tk-base-shadow-item tk-text-base-bold tk-font-color-white tk-bg-color-main'
                              : 'tk-no-shadow tk-text-base-bold tk-font-color-gray tk-bg-color-disableBtn',
                          ]"
                          @click.stop="
                            saveBranding(
                              studios[studioIndex].name != studioInfo.name ||
                                !isNull(newLogo)
                            )
                          "
                          >{{ $t("general.save").toUpperCase() }}</base-button
                        >
                      </div>
                    </template>
                  </div>
                </div>

                <!-- strorefront -->
                <div
                  :key="step.STOREFRONT"
                  v-if="currentStep == step.STOREFRONT"
                >
                  <!-- storefront color -->
                  <div class="card tk-px-margin-bottom-px32 tk-no-shadow">
                    <div
                      class="card-body tk-px-padding-px32"
                      style="min-height: 120px"
                    >
                      <card-loading v-if="loading"></card-loading>
                      <template v-else>
                        <div>
                          <div
                            class="tk-px-margin-right-px16 tk-layout-inline-block-top"
                            style="width: calc(50% - 1rem)"
                          >
                            <!-- default color -->
                            <div
                              class="tk-font-color-gray tk-px-margin-bottom-px16"
                            >
                              {{ $t("admin.studio.storefront_color") }}
                            </div>
                            <!-- choose color -->
                            <div
                              class="btn-group btn-group-toggle btn-group-colors event-tag text-left tk-position-relative tk-layout-block tk-px-margin-top-px6"
                            >
                              <label
                                v-for="(color, index) in defaultColors"
                                :key="color"
                                class="btn tk-px-margin-bottom-px16 tk-px-height-px48"
                                :style="{
                                  backgroundColor: '#' + color + ' !important',
                                }"
                                style="
                                  width: calc((100% - 3rem) / 4);
                                  border-radius: 4px !important;
                                "
                                :class="[
                                  'tk-bg-color-main',
                                  {
                                    'active focused':
                                      studioInfo.storefrontColor == color,
                                    'tk-px-margin-right-px8 tk-px-margin-left-px0':
                                      index == 0 || index == 4,
                                    'tk-px-margin-left-px8 tk-px-margin-right-px0':
                                      index == 3 || index == 7,
                                    'tk-px-margin-lr-px8':
                                      index !== 0 &&
                                      index !== 3 &&
                                      index !== 4 &&
                                      index !== 7,
                                  },
                                ]"
                                @click.stop="
                                  changeColor('storefrontColor', color)
                                "
                              >
                                <input
                                  v-model="studioInfo.storefrontColor"
                                  type="radio"
                                  name="event-tag"
                                  :value="color"
                                  autocomplete="off"
                                />
                              </label>
                            </div>
                            <!-- custom color -->
                            <div>
                              <input-with-label
                                :showLabel="false"
                                type="text"
                                bottom="tk-px-margin-bottom-px0"
                                inputClass="tk-text-center tk-font-letter-spacing-6"
                                :value="studioInfo.storefrontColor"
                                @input="saveColor"
                              ></input-with-label>

                              <label
                                class="form-control-label tk-px-margin-top-px14"
                              >
                                <span v-if="isHexColor()">{{
                                  $t("admin.studio.custom_color")
                                }}</span>
                                <span v-else class="tk-font-color-red">{{
                                  $t("admin.studio.wrong_custom_color")
                                }}</span>
                                <el-tooltip placement="bottom" effect="light">
                                  <div slot="content">
                                    <div
                                      class="tk-text-center tk-text-sm-medium"
                                    >
                                      {{ $t("admin.studio.hex_prompt.title") }}
                                    </div>
                                    <div
                                      class="tk-px-margin-top-px16 tk-text-sm"
                                    >
                                      <div
                                        v-for="(step, index) in $t(
                                          'admin.studio.hex_prompt.content'
                                        )"
                                        :key="index"
                                        :class="{
                                          'tk-px-margin-top-px8': index > 0,
                                        }"
                                      >
                                        {{ $t("admin.studio.hex_prompt.step") }}
                                        {{ index + 1 }}:
                                        {{ step }}
                                      </div>
                                    </div>
                                    <div
                                      class="tk-text-center tk-text-sm-medium tk-cursor-pointer tk-font-color-main tk-px-margin-top-px16"
                                      @click.stop="goToColorPicker"
                                    >
                                      {{
                                        $t(
                                          "admin.studio.hex_prompt.color_picker"
                                        )
                                      }}
                                    </div>
                                  </div>
                                  <i
                                    class="fas fa-info-circle tk-cursor-pointer tk-text-base tk-font-color-lightGray tk-px-margin-left-px10"
                                  ></i>
                                </el-tooltip>
                              </label>
                            </div>
                          </div>

                          <!-- text color -->
                          <div
                            class="tk-px-margin-left-px16 tk-layout-inline-block-top"
                            style="width: calc(50% - 1rem)"
                          >
                            <div
                              class="tk-font-color-gray tk-px-margin-bottom-px16"
                            >
                              {{ $t("admin.studio.text_color") }}
                            </div>
                            <div class="tk-px-margin-top-px4">
                              <div
                                class="tk-px-radius-px4 tk-px-padding-px2 tk-px-margin-bottom-px16"
                                :class="{
                                  'tk-bg-color-main':
                                    studioInfo.titlesColor == 'ffffff',
                                }"
                              >
                                <base-button
                                  class="tk-font-color-white tk-text-xl-bold tk-no-shadow tk-layout-full-width tk-px-radius-px4 tk-text-left tk-px-border-px4 tk-border-color-white"
                                  :style="{
                                    backgroundColor:
                                      '#' + studioInfo.storefrontColor,
                                  }"
                                  @click.stop="
                                    changeColor('titlesColor', 'ffffff')
                                  "
                                  >{{ $t("admin.studio.welcome") }}
                                  {{ studioInfo.name }}!</base-button
                                >
                              </div>
                              <div
                                class="tk-px-radius-px4 tk-px-padding-px2"
                                :class="{
                                  'tk-bg-color-main':
                                    studioInfo.titlesColor == '33363b',
                                }"
                              >
                                <base-button
                                  class="tk-font-color-black2 tk-text-xl-bold tk-no-shadow tk-layout-full-width tk-px-radius-px4 tk-text-left tk-px-border-px4 tk-border-color-white"
                                  :style="{
                                    backgroundColor:
                                      '#' + studioInfo.storefrontColor,
                                  }"
                                  @click.stop="
                                    changeColor('titlesColor', '33363b')
                                  "
                                  >{{ $t("admin.studio.welcome") }}
                                  {{ studioInfo.name }}!</base-button
                                >
                              </div>
                            </div>
                          </div>
                        </div>

                        <div class="tk-text-center tk-px-margin-top-px32">
                          <base-button
                            type="main"
                            class="tk-px-width-px160 tk-border-none"
                            :class="[
                              studios[
                                studioIndex
                              ].storefrontColor.toLowerCase() !=
                                studioInfo.storefrontColor ||
                              studios[studioIndex].titlesColor.toLowerCase() !=
                                studioInfo.titlesColor
                                ? 'tk-base-shadow-item tk-text-base-bold tk-font-color-white tk-bg-color-main'
                                : 'tk-no-shadow tk-text-base-bold tk-font-color-gray tk-bg-color-disableBtn',
                            ]"
                            @click.stop="
                              saveStorefront(
                                studios[
                                  studioIndex
                                ].storefrontColor.toLowerCase() !=
                                  studioInfo.storefrontColor ||
                                  studios[
                                    studioIndex
                                  ].titlesColor.toLowerCase() !=
                                    studioInfo.titlesColor
                              )
                            "
                            >{{ $t("general.save").toUpperCase() }}</base-button
                          >
                        </div>
                      </template>
                    </div>
                  </div>

                  <!-- preview -->
                  <div
                    id="preview"
                    class="card tk-px-margin-bottom-px0 tk-px-margin-ta-px0"
                    style="width: 64%; min-width: 20rem"
                    v-if="!loading"
                    :style="{
                      backgroundColor: '#' + studioInfo.storefrontColor,
                    }"
                  >
                    <!-- width: boxSize + 'px', -->
                    <div
                      class="card-body tk-border-none tk-px-radius-px8 tk-position-relative tk-px-padding-px20"
                      style="min-height: 600px"
                    >
                      <div class="tk-px-margin-bottom-px32 tk-layout-flex-row">
                        <div
                          class="tk-text-xl-bold tk-layout-flex-1"
                          :class="[getStoreFrontTextColor()]"
                          style="white-space: pre-line"
                        >
                          {{ $t("admin.studio.preview_welcome") }}
                          {{ studioInfo.name }}!
                        </div>
                        <!-- logo -->
                        <avatar
                          sizeClass="avatar-lg"
                          textClass="text-lg"
                          :picUrl="logo"
                          :studioId="studioInfo.id"
                          :name="studioInfo.name"
                        ></avatar>
                      </div>

                      <!-- lesson type -->
                      <div
                        class="tk-px-margin-bottom-px32"
                        v-if="lessonTypes.length > 0"
                      >
                        <div
                          class="tk-text-base tk-px-margin-bottom-px10"
                          :class="[getStoreFrontTextColor()]"
                        >
                          <span>{{ $t("admin.studio.lesson_type") }}</span>
                          <span
                            class="tk-layout-float-right tk-cursor-pointer"
                            v-if="false"
                          >
                            <span class="tk-px-margin-right-px10">{{
                              $t("admin.studio.list")
                            }}</span>
                            <i class="fas fa-angle-right"></i>
                          </span>
                        </div>
                        <lesson-type-item
                          :data="lessonTypes[0]"
                          bottom=""
                          descriptionClass="tk-font-color-gray"
                          :instrumentUrl="
                            lessonTypes[0] &&
                            lessonTypes[0].instrumentId &&
                            instruments[lessonTypes[0].instrumentId]
                              ? instruments[lessonTypes[0].instrumentId]
                                  .minPictureUrl
                              : ''
                          "
                        ></lesson-type-item>
                      </div>

                      <!-- policy -->
                      <div class="tk-px-margin-bottom-px32">
                        <div
                          class="tk-text-base tk-px-margin-bottom-px10"
                          :class="[getStoreFrontTextColor()]"
                        >
                          {{ $t("admin.studio.policy") }}
                        </div>
                        <div class="card tk-no-scroll">
                          <div
                            class="card-body tk-px-padding-px16 tk-position-relative tk-no-scroll"
                            :style="{
                              height: showAllPolicy ? 'auto' : '160px',
                            }"
                          >
                            <p style="white-space: pre-line">
                              {{ policy.description }}
                            </p>

                            <div
                              class="tk-text-base tk-font-color-main tk-text-center tk-layout-full-width tk-bg-color-white tk-cursor-pointer"
                              :class="{
                                'tk-position-absolute tk-px-padding-top-px10 tk-px-padding-bottom-px10':
                                  !showAllPolicy,
                              }"
                              style="bottom: 0; left: 0"
                              @click.stop="showAllPolicy = !showAllPolicy"
                            >
                              {{
                                showAllPolicy
                                  ? $t("general.collapse")
                                  : $t("general.view_all")
                              }}
                            </div>
                          </div>
                        </div>
                      </div>

                      <!-- info -->
                      <div
                        class="tk-px-margin-bottom-px32"
                        v-if="
                          !isNull(phoneNumber.phoneNumber) ||
                          !isNull(studioInfo.email) ||
                          !isNull(studioInfo.website) ||
                          !isNull(formatAddr())
                        "
                      >
                        <div
                          class="tk-text-base tk-px-margin-bottom-px10"
                          :class="[getStoreFrontTextColor()]"
                        >
                          {{ $t("admin.studio.info") }}:
                        </div>

                        <!-- phone -->
                        <div
                          class="card tk-px-margin-bottom-px16"
                          v-if="!isNull(phoneNumber.phoneNumber)"
                        >
                          <div
                            class="card-body tk-px-padding-px16 tk-text-base-bold tk-layout-flex-row tk-layout-flex-vertical-center"
                          >
                            <div
                              class="tk-px-margin-right-px16 tk-layout-flex-1"
                            >
                              {{
                                formatPhone(
                                  phoneNumber.country,
                                  phoneNumber.phoneNumber
                                ).string
                              }}
                            </div>
                            <div
                              class="tk-px-width-px40 tk-px-height-px40 tk-bg-color-green tk-font-color-white tk-position-relative tk-px-radius-px40"
                            >
                              <i class="fas fa-phone tk-position-center"></i>
                            </div>
                          </div>
                        </div>

                        <!-- email -->
                        <div
                          class="card tk-px-margin-bottom-px16"
                          v-if="!isNull(studioInfo.email)"
                        >
                          <div
                            class="card-body tk-px-padding-px16 tk-text-base-bold tk-layout-flex-row tk-layout-flex-vertical-center"
                          >
                            <div
                              class="tk-layout-flex-1 tk-px-margin-right-px16"
                            >
                              {{ studioInfo.email }}
                            </div>
                            <div
                              class="tk-px-width-px40 tk-px-height-px40 tk-bg-color-orange tk-font-color-white tk-position-relative tk-px-radius-px40"
                            >
                              <i class="fas fa-envelope tk-position-center"></i>
                            </div>
                          </div>
                        </div>

                        <!-- website -->
                        <div
                          class="card tk-px-margin-bottom-px16"
                          v-if="!isNull(studioInfo.website)"
                        >
                          <div
                            class="card-body tk-px-padding-px16 tk-text-base-bold tk-layout-flex-row tk-layout-flex-vertical-center"
                          >
                            <div
                              class="tk-layout-flex-1 tk-px-margin-right-px16"
                            >
                              {{ studioInfo.website }}
                            </div>
                            <div
                              class="tk-px-width-px40 tk-px-height-px40 tk-bg-color-card8 tk-font-color-white tk-position-relative tk-px-radius-px40"
                            >
                              <i class="fas fa-link tk-position-center"></i>
                            </div>
                          </div>
                        </div>

                        <!-- address -->
                        <div
                          class="card tk-px-margin-bottom-px16"
                          v-if="!isNull(formatAddr())"
                        >
                          <div
                            class="card-body tk-px-padding-px16 tk-text-base-bold tk-layout-flex-row tk-layout-flex-vertical-center"
                          >
                            <div
                              class="tk-layout-flex-1 tk-px-margin-right-px16"
                            >
                              {{ formatAddr() }}
                            </div>
                            <div
                              class="tk-px-width-px40 tk-px-height-px40 tk-bg-color-card6 tk-font-color-white tk-position-relative tk-px-radius-px40"
                            >
                              <i
                                class="fas fa-map-marker-alt tk-position-center"
                              ></i>
                            </div>
                          </div>
                        </div>
                      </div>

                      <!-- QR code -->
                      <div>
                        <div
                          class="tk-text-base tk-px-margin-bottom-px10"
                          :class="[getStoreFrontTextColor()]"
                        >
                          <span>{{ $t("admin.studio.qr_code") }}</span>
                          <span
                            class="tk-layout-float-right tk-cursor-pointer"
                            @click.stop="downloadQRcode"
                          >
                            <i class="fa-solid fa-download"></i>
                          </span>
                        </div>
                        <div class="card tk-px-margin-bottom-px0">
                          <div
                            class="card-body tk-px-padding-px16 tk-position-relative"
                          >
                            <div id="qrcode" ref="qrcode"></div>

                            <div
                              class="tk-px-padding-px10 tk-bg-color-selectedBg tk-px-margin-top-px10 tk-layout-flex-row"
                            >
                              <div
                                class="tk-layout-flex-1 tk-px-padding-right-px16 tk-text-wrap"
                              >
                                {{ inviteLink }}
                              </div>
                              <div
                                class="tk-icon-container-base tk-font-color-lightGray tk-cursor-pointer"
                                v-clipboard:copy="inviteLink"
                                v-clipboard:error=""
                                v-clipboard:success="onCopySuccess"
                              >
                                <i class="fas fa-copy tk-position-center"></i>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- contact -->
                <div
                  :key="step.CONTACT"
                  class="card tk-px-margin-bottom-px32 tk-no-shadow"
                  v-if="currentStep == step.CONTACT"
                >
                  <div
                    class="card-body tk-px-padding-px20"
                    style="min-height: 300px"
                  >
                    <card-loading v-if="loading"></card-loading>
                    <template v-else>
                      <!-- email -->
                      <input-with-label
                        :label="$t('general.email_address')"
                        :value="studioInfo.email"
                        :underText="
                          isInvalid ? $t('general.invalid_email') : ''
                        "
                        underTextColor="red"
                        @input="saveEmail"
                      >
                      </input-with-label>

                      <!-- phone -->
                      <tk-input-phone-number
                        :label="$t('admin.studio.office_phone')"
                        :forceOrigin="true"
                        :value="phoneNumber.phoneNumber"
                        :code="phoneNumber.country"
                        @input="savePhone"
                        innerClass="tk-layout-inline-block-top tk-px-margin-right-px20"
                        style="width: calc((100% - 20px) / 2)"
                      ></tk-input-phone-number>

                      <!-- website -->
                      <input-with-label
                        :label="$t('admin.studio.website')"
                        :value="studioInfo.website"
                        @input="saveWebsite"
                        innerClass="tk-layout-inline-block-top"
                        style="width: calc((100% - 20px) / 2)"
                      >
                      </input-with-label>

                      <div class="tk-text-center tk-px-margin-top-px32">
                        <base-button
                          type="main"
                          class="tk-px-width-px160 tk-border-none"
                          :class="[
                            studios[studioIndex].email != studioInfo.email ||
                            studios[studioIndex].phoneNumber.country !=
                              phoneNumber.country ||
                            studios[studioIndex].phoneNumber.phoneNumber !=
                              phoneNumber.phoneNumber ||
                            studios[studioIndex].website != studioInfo.website
                              ? 'tk-base-shadow-item tk-text-base-bold tk-font-color-white tk-bg-color-main'
                              : 'tk-no-shadow tk-text-base-bold tk-font-color-gray tk-bg-color-disableBtn',
                          ]"
                          @click.stop="
                            saveContact(
                              studios[studioIndex].email != studioInfo.email ||
                                studios[studioIndex].phoneNumber.country !=
                                  phoneNumber.country ||
                                studios[studioIndex].phoneNumber.phoneNumber !=
                                  phoneNumber.phoneNumber ||
                                studios[studioIndex].website !=
                                  studioInfo.website
                            )
                          "
                          >{{ $t("general.save").toUpperCase() }}</base-button
                        >
                      </div>
                    </template>
                  </div>
                </div>

                <!-- address -->
                <div
                  :key="step.ADDRESS"
                  class="card tk-no-shadow"
                  v-if="currentStep == step.ADDRESS"
                >
                  <div
                    class="card-body tk-px-padding-px20"
                    style="min-height: 300px"
                  >
                    <card-loading v-if="loading"></card-loading>
                    <template v-else>
                      <!-- street -->
                      <input-with-label
                        :label="$t('admin.studio.address')"
                        :value="addressDetail.line1"
                        @toggleFocus="showCityList = false"
                        @input="saveStreetLine"
                      ></input-with-label>

                      <!-- city -->
                      <input-with-label
                        :label="$t('admin.studio.city')"
                        :value="addressDetail.city"
                        @toggleFocus="toggleFocusCity"
                        @input="saveCity"
                        innerClass="tk-layout-inline-block-top tk-px-margin-right-px20"
                        style="width: calc((100% - 20px) / 2)"
                      >
                        <ul
                          class="list-group tk-layout-height-fit tk-overflow-y tk-position-absolute tk-layout-full-width tk-base-shadow"
                          style="max-height: 200px; z-index: 1"
                          v-if="showCityList"
                        >
                          <template v-for="(item, index) in cityDataResult">
                            <li
                              class="list-group-item tk-text-base tk-transition tk-cursor-pointer"
                              :class="{
                                active: item.city == addressDetail.city,
                              }"
                              :key="index"
                              @click.stop="selectCity(item)"
                            >
                              <span
                                v-html="
                                  highlights(item.city, addressDetail.city)
                                "
                              ></span>
                            </li>
                          </template>
                        </ul>
                      </input-with-label>

                      <!-- country -->
                      <input-with-label
                        :label="$t('admin.studio.country')"
                        :value="addressDetail.country"
                        @toggleFocus="showCityList = false"
                        @input="saveCountry"
                        innerClass="tk-layout-inline-block-top"
                        style="width: calc((100% - 20px) / 2)"
                      ></input-with-label>

                      <!-- state -->
                      <input-with-label
                        :label="$t('admin.studio.state_province')"
                        :value="addressDetail.state"
                        @toggleFocus="showCityList = false"
                        @input="saveState"
                        innerClass="tk-layout-inline-block-top tk-px-margin-right-px20"
                        style="width: calc((100% - 20px) / 2)"
                      ></input-with-label>

                      <!-- zip -->
                      <input-with-label
                        :label="$t('admin.studio.zip_postal')"
                        :isInt="true"
                        type="number"
                        bottom="tk-px-margin-bottom-px0"
                        :value="addressDetail.postal_code"
                        @toggleFocus="showCityList = false"
                        @input="saveCode"
                        innerClass="tk-layout-inline-block-top"
                        style="width: calc((100% - 20px) / 2)"
                      ></input-with-label>

                      <div class="tk-text-center tk-px-margin-top-px32">
                        <base-button
                          type="main"
                          class="tk-px-width-px160 tk-border-none"
                          :class="[
                            formatAddr(studios[studioIndex].addressDetail) !=
                            formatAddr()
                              ? 'tk-base-shadow-item tk-text-base-bold tk-font-color-white tk-bg-color-main'
                              : 'tk-no-shadow tk-text-base-bold tk-font-color-gray tk-bg-color-disableBtn',
                          ]"
                          @click.stop="
                            saveAddress(
                              studios[studioIndex].addressDetail.line1 !=
                                addressDetail.line1 ||
                                studios[studioIndex].addressDetail.city !=
                                  addressDetail.city ||
                                studios[studioIndex].addressDetail.state !=
                                  addressDetail.state ||
                                studios[studioIndex].addressDetail.country !=
                                  addressDetail.country ||
                                studios[studioIndex].addressDetail
                                  .postal_code != addressDetail.postal_code
                            )
                          "
                          >{{ $t("general.save").toUpperCase() }}</base-button
                        >
                      </div>
                    </template>
                  </div>
                </div>

                <!-- timezone -->
                <div
                  :key="step.TIMEZONE"
                  class="card tk-no-shadow tk-px-margin-bottom-px0 tk-layout-full-height"
                  v-if="currentStep == step.TIMEZONE"
                >
                  <div
                    class="card-body tk-px-padding-px20 tk-px-margin-bottom-px0 tk-layout-full-height"
                  >
                    <card-loading v-if="loading"></card-loading>
                    <template v-else>
                      <!-- current tz -->
                      <div class="tk-px-margin-bottom-px20">
                        <div
                          class="tk-text-sm tk-font-color-gray tk-px-margin-bottom-px8"
                        >
                          {{ $t("admin.studio.current") }}
                        </div>

                        <div>
                          <span
                            class="tk-text-base-bold tk-font-color-black2"
                            >{{ currentTimeZone }}</span
                          >

                          <span
                            class="tk-text-sm tk-font-color-gray tk-px-margin-left-px20"
                          >
                            {{ formatTimeZoneStr().short }}
                          </span>
                        </div>
                      </div>

                      <!-- search tz -->
                      <search-bar-with-button
                        @onInput="searchTimeZone"
                        bottom="tk-px-margin-bottom-px20"
                      ></search-bar-with-button>

                      <div
                        class="tk-overflow-y tk-scrollbar"
                        style="height: calc(100% - 198px)"
                      >
                        <!-- 100% - 52px - 20px - 38px - 20px - 48px - 20px -->
                        <ul class="list-group">
                          <template v-for="(item, index) in timeZoneList">
                            <li
                              :key="index"
                              class="tk-position-relative tk-cursor-pointer list-group-item list-group-item-action"
                              style="padding: 10px 16px"
                              v-if="
                                isNull(searchTz) ||
                                item.name
                                  .toLowerCase()
                                  .indexOf(searchTz.toLowerCase()) > -1
                              "
                              @click.stop="saveZone(item.name)"
                            >
                              <span
                                class="tk-text-base-bold"
                                v-html="highlights(item.name, searchTz)"
                              ></span>
                              <br />
                              <span class="tk-text-sm tk-font-color-gray"
                                >{{ formatTimeZoneStr(item.name).time }},
                              </span>
                              <span class="tk-text-sm tk-font-color-gray">{{
                                formatTimeZoneStr(item.name).short
                              }}</span>
                              <i
                                class="fas fa-check tk-position-vertical-center tk-font-color-main"
                                style="right: 20px"
                                v-if="studioInfo.timeZone == item.name"
                              ></i>
                            </li>
                          </template>
                        </ul>
                      </div>

                      <div class="tk-text-center tk-px-margin-top-px20">
                        <base-button
                          type="main"
                          class="tk-px-width-px160 tk-border-none"
                          :class="[
                            studios[studioIndex].timeZone != studioInfo.timeZone
                              ? 'tk-base-shadow-item tk-text-base-bold tk-font-color-white tk-bg-color-main'
                              : 'tk-no-shadow tk-text-base-bold tk-font-color-gray tk-bg-color-disableBtn',
                          ]"
                          @click.stop="
                            saveTimeZone(
                              studios[studioIndex].timeZone !=
                                studioInfo.timeZone
                            )
                          "
                          >{{ $t("general.save").toUpperCase() }}</base-button
                        >
                      </div>
                    </template>
                  </div>
                </div>
              </slide-x-left-transition>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧工具栏 -->
      <tool-bar :bars="funcBars" class="tk-right-tool-bar"></tool-bar>
    </div>

    <!-- alert: change studio type -->
    <alert
      :title="$t('admin.studio.change_studio_type')"
      :content="
        $t('alert').change_studio_type({
          from: studioInfo.studioType,
          to: currentStudioType,
        })
      "
      :left="$t('general.cancel')"
      :right="$t('general.confirm')"
      v-if="showStudioTypeChangeAlert"
      @onLeftTapped="showStudioTypeChangeAlert = false"
      @onRightTapped="onConfirmChangeStudioType"
      @close="showStudioTypeChangeAlert = false"
    >
    </alert>

    <!-- alert: delete -->
    <alert
      :title="$t('admin.studio.delete_studio')"
      :content="
        $t('alert').delete_studio({
          name: studioInfo.name,
        })
      "
      :left="$t('general.cancel')"
      :right="$t('general.confirm')"
      v-if="showDeleteStudioAlert"
      @onLeftTapped="showDeleteStudioAlert = false"
      @onRightTapped="onConfirmDeleteStudio"
    >
    </alert>
  </div>
</template>

<script>
import { Select, Option } from "element-ui";
import ImgCutter from "vue-img-cutter";
import "firebase/storage";
import QRCode from "qrcodejs2";
import { SlideXLeftTransition } from "vue2-transitions";

export default {
  components: {
    [Select.name]: Select,
    [Option.name]: Option,
    ImgCutter,
    SlideXLeftTransition,
    ToolBar: () => import("@/tkViews/components/layout/RightToolbar.vue"),
    Avatar: () => import("@/tkViews/components/layout/Avatar"),
    CardLoading: () => import("@/tkViews/components/layout/CardLoading"),
    Card: () => import("@/tkViews/components/layout/Card"),
    InputWithLabel: () =>
      import("@/tkViews/components/Inputs/TkInputWithLabel"),
    TkInputPhoneNumber: () =>
      import("@/tkViews/components/Inputs/TkInputPhoneNumber.vue"),
    LessonTypeItem: () =>
      import("@/tkViews/components/layout/Item/LessonTypeItem.vue"),
    StudioItem: () => import("@/tkViews/components/layout/Item/StudioItem.vue"),
    StudioTypeItem: () =>
      import("@/tkViews/components/layout/Item/StudioTypeItem.vue"),
    SearchBarWithButton: () =>
      import("@/tkViews/components/layout/SearchBarWithButton"),
    Alert: () => import("../components/Modal/Alert"),
    AvatarUpload: () => import("@/tkViews/components/layout/AvatarUpload"),
  },
  data() {
    return {
      loading: true,
      funcBars: [],

      currentStep: "BRANDING",
      step: {
        BRANDING: "BRANDING",
        STOREFRONT: "STOREFRONT",
        CONTACT: "CONTACT",
        ADDRESS: "ADDRESS",
        STUDIO_TYPE: "STUDIO_TYPE",
        TIMEZONE: "TIMEZONE",
      },

      boxSize: 0,
      logo: "",
      crop: "",
      newLogo: "",
      logoExist: false,
      isClear: false,
      showUpload: false,
      showCamera: false,

      isInvalid: false,
      focusCity: false,
      showCityList: false,
      countryStateCityData: [],
      cityData: [],
      cityDataResult: [],
      cityDisplayLength: 100,
      stateData: [],
      countryData: [],
      phoneNumber: {},
      addressDetail: {},

      defaultColors: [
        "71d9c2",
        "97bddd",
        "f38577",
        "f6af02",
        "5e71f5",
        "ccabd8",
        "a1e456",
        "7fdefe",
      ],

      studios: [],
      policy: {},
      studioInfo: {},
      studioIndex: -1,
      deleteStudioIndex: -1,
      userInfo: {},

      studioType: {},
      currentStudioType: "",
      showStudioTypeChangeAlert: false,
      showDeleteStudioAlert: false,
      showSaveStudioAlert: false,
      currentTimeZone: "",

      instruments: {},
      lessonTypesMap: {},
      lessonTypes: [],

      inviteLink: "",
      showPreview: false,
      showAllPolicy: false,

      moment: null,
      searchTz: "",
      timeZoneList: [],
    };
  },
  watch: {
    currentStep(newVal) {
      let self = this;
      self.currentStudioType = self.studioInfo.studioType;
      self.searchTz = "";
      if (newVal == self.step.STOREFRONT) {
        self.getInviteLink();
      } else if (newVal == self.step.TIMEZONE) {
        self.currentTimeZone =
          self.studioInfo?.timeZone || self.userInfo?.timeZone;
      }
    },
    logoExist(newVal) {
      console.log("logo 是否存在: ", newVal);
      if (!newVal) {
        this.showUpload = true;
      }
    },
  },
  async created() {
    let self = this;
    self.initBasicData();
  },
  async mounted() {
    let self = this;

    self.boxSize = $(".tk-left-list-part").width();

    window.onresize = (e) => {
      // console.log(e);
      self.boxSize = $(".tk-left-list-part").width();
      if ($("#previewLogo").width()) {
        $("#previewLogo").animate({
          height: $("#previewLogo").width(),
        });
      }
    };

    // console.log(self.$moment.tz.names())
  },
  methods: {
    onConfirmChangeStudioType() {
      let self = this;
      let now = self.$moment().unix();
      let updateStudioType = self.$functionsService.updateStudioType;
      let option = {
        studioId: self.studios[0].id,
        newStudioType: self.currentStudioType,
      };

      console.log("option: ", option);

      self.showStudioTypeChangeAlert = false;

      self.$bus.$emit("showFullCover", {
        text: self.$i18n.t("notification.loading.save"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      updateStudioType(option)
        .then(async (res) => {
          self.studios[0] = await self.$userService.studioAction.get(
            option.studioId
          );
          self.$bus.$emit("hideFullCover", {
            text: self.$i18n.t("notification.success.save"),
            type: "success",
            unix: now,
          });
        })
        .catch((err) => {
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.failed.save"),
            type: "error",
            unix: now,
          });
        });
    },
    onConfirmDeleteStudio() {
      let self = this;
      let now = self.$moment().unix();
      if (self.deleteStudioIndex > -1) {
        self.studios[0].subStudios.splice(self.deleteStudioIndex - 1, 1);
        self.showDeleteStudioAlert = false;

        self.$bus.$emit("showFullCover", {
          text: self.$i18n.t("notification.loading.delete_studio"),
          type: "loading",
          timeout: 0,
          unix: now,
        });

        self.$studioService.studioInfoAction.update(
          self.studios[0].id,
          {
            subStudios: self.studios[0].subStudios,
          },
          (err) => {
            self.$bus.$emit("hideFullCover", {
              message: err
                ? self.$i18n.t("notification.failed.delete_studio")
                : self.$i18n.t("notification.success.delete_studio"),
              type: err ? "error" : "success",
              unix: now,
            });

            if (!err) {
              self.studios.splice(self.deleteStudioIndex, 1);
              self.initStudio(self.deleteStudioIndex - 1);
            }
          }
        );
      }
    },
    addStudio() {
      let self = this;
      let id = self.$commons.generateId();
      let newStudio = JSON.parse(
        JSON.stringify(self.$dataModules.studioInfo.default)
      );
      let now = self.$moment().unix();

      newStudio.id = id;
      newStudio.name = self.$i18n.t("admin.studio.new_studio");
      newStudio.storefrontColor = self.studios[0].storefrontColor;
      newStudio.titlesColor = self.studios[0].titlesColor;
      newStudio.memberLevelId = self.studios[0].memberLevelId;
      newStudio.studioType = self.studios[0].studioType;
      newStudio.creatorId = self.userInfo.userId;
      newStudio.createTime = String(now);
      newStudio.updateTime = String(now);
      newStudio.timeZone = self.userInfo.timeZone;
      newStudio.hourFromGMT = self.userInfo.hourFromGMT;

      self.studios.push(newStudio);
      self.studios[0].subStudios.push(newStudio);

      self.$bus.$emit("showFullCover", {
        text: self.$i18n.t("notification.loading.add_studio"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      self.$studioService.studioInfoAction.update(
        self.studios[0].id,
        {
          subStudios: self.studios[0].subStudios,
        },
        (err) => {
          self.$bus.$emit("hideFullCover", {
            message: err
              ? self.$i18n.t("notification.failed.add_studio")
              : self.$i18n.t("notification.success.add_studio"),
            type: err ? "error" : "success",
            unix: now,
          });

          if (!err) {
            self.initStudio(self.studios.length - 1);
          }
        }
      );
    },
    // 上传photo
    async uploadLogo(unix) {
      let self = this;
      // 上传图片
      await self.$studioService.uploadTaskListener(
        self.$studioService.uploadFileFromDataUrl(
          self.newLogo,
          "images/studio_logos/" + self.studioInfo.id + ".jpg"
        ),
        (res) => {
          if (res.downloadURL) {
            self.$bus.$emit("hideFullCover", {
              message: self.$i18n.t("notification.success.save"),
              type: "success",
              unix: unix,
            });

            self.$bus.$emit("refreshAvatar");

            self.logo = self.$tools.equalValue(self.newLogo);
            self.newLogo = "";
            self.showUpload = false;
          }
        }
      );
      self.showUpload = false;
    },
    async saveBranding(save) {
      let self = this;
      let now = self.$moment().unix();

      if (save) {
        self.$bus.$emit("showFullCover", {
          text: self.$i18n.t("notification.loading.save"),
          type: "loading",
          timeout: 0,
          unix: now,
        });

        let content = {
          updateTime: String(now),
        };

        if (self.studioIndex == 0) {
          content.name = self.studioInfo.name;
        } else {
          self.studios[0].subStudios[self.studioIndex - 1].name =
            self.studioInfo.name;

          content.subStudios = self.studios[0].subStudios;
        }

        self.$studioService.studioInfoAction.update(
          self.studios[0].id,
          content,
          async (err) => {
            if (!self.isNull(self.newLogo)) {
              self.uploadLogo(now);
              self.logoExist = true;
              self.showUpload = false;
            } else {
              self.$bus.$emit("hideFullCover", {
                message: err
                  ? self.$i18n.t("notification.failed.save")
                  : self.$i18n.t("notification.success.save"),
                type: err ? "error" : "success",
                unix: now,
              });
            }

            if (!err) {
              self.studios[self.studioIndex].name = JSON.parse(
                JSON.stringify(self.studioInfo.name)
              );
            }
          }
        );
      }
    },
    async saveStorefront(save) {
      let self = this;
      let now = self.$moment().unix();

      if (save) {
        self.$bus.$emit("showFullCover", {
          text: self.$i18n.t("notification.loading.save"),
          type: "loading",
          timeout: 0,
          unix: now,
        });

        let content = {
          updateTime: String(now),
        };

        if (self.studioIndex == 0) {
          content.storefrontColor = self.studioInfo.storefrontColor;
          content.titlesColor = self.studioInfo.titlesColor;
        } else {
          self.studios[0].subStudios[self.studioIndex - 1].storefrontColor =
            self.studioInfo.storefrontColor;
          self.studios[0].subStudios[self.studioIndex - 1].titlesColor =
            self.studioInfo.titlesColor;

          content.subStudios = self.studios[0].subStudios;
        }

        self.$studioService.studioInfoAction.update(
          self.studios[0].id,
          content,
          (err) => {
            self.$bus.$emit("hideFullCover", {
              message: err
                ? self.$i18n.t("notification.failed.save")
                : self.$i18n.t("notification.success.save"),
              type: err ? "error" : "success",
              unix: now,
            });

            if (!err) {
              self.studios[self.studioIndex].storefrontColor = JSON.parse(
                JSON.stringify(self.studioInfo.storefrontColor)
              );
              self.studios[self.studioIndex].titlesColor = JSON.parse(
                JSON.stringify(self.studioInfo.titlesColor)
              );
            }
          }
        );
      }
    },
    async saveContact(save) {
      let self = this;
      let now = self.$moment().unix();

      if (save) {
        self.$bus.$emit("showFullCover", {
          text: self.$i18n.t("notification.loading.save"),
          type: "loading",
          timeout: 0,
          unix: now,
        });

        let phone = self.formatPhone(
          self.phoneNumber.country,
          self.phoneNumber.phoneNumber
        ).string;

        let content = {
          updateTime: String(self.$moment().unix()),
        };

        if (self.studioIndex == 0) {
          content.phoneNumber = self.studioInfo.phoneNumber;
          content.phone = self.studioInfo.phone;
          content.email = self.studioInfo.email;
          content.website = self.studioInfo.website;
        } else {
          self.studios[0].subStudios[self.studioIndex - 1].phoneNumber =
            self.studioInfo.phoneNumber;
          self.studios[0].subStudios[self.studioIndex - 1].phone =
            self.studioInfo.phone;
          self.studios[0].subStudios[self.studioIndex - 1].email =
            self.studioInfo.email;
          self.studios[0].subStudios[self.studioIndex - 1].website =
            self.studioInfo.website;

          content.subStudios = self.studios[0].subStudios;
        }

        self.$studioService.studioInfoAction.update(
          self.studios[0].id,
          content,
          (err) => {
            self.$bus.$emit("hideFullCover", {
              message: err
                ? self.$i18n.t("notification.failed.save")
                : self.$i18n.t("notification.success.save"),
              type: err ? "error" : "success",
              unix: now,
            });

            if (!err) {
              self.studios[self.studioIndex].phoneNumber = JSON.parse(
                JSON.stringify(self.phoneNumber)
              );
              self.studios[self.studioIndex].phone = phone;
              self.studios[self.studioIndex].email = JSON.parse(
                JSON.stringify(self.studioInfo.email)
              );
              self.studios[self.studioIndex].website = JSON.parse(
                JSON.stringify(self.studioInfo.website)
              );
            }
          }
        );
      }
    },
    async saveAddress(save) {
      let self = this;
      let now = self.$moment().unix();

      if (save) {
        self.$bus.$emit("showFullCover", {
          text: self.$i18n.t("notification.loading.save"),
          type: "loading",
          timeout: 0,
          unix: now,
        });

        let content = {
          updateTime: String(self.$moment().unix()),
        };

        if (!self.$tools.isNull(self.studioInfo.addressDetail?.postal_code)) {
          self.studioInfo.addressDetail.postal_code = String(
            self.studioInfo.addressDetail.postal_code
          );
        }

        if (self.studioIndex == 0) {
          content.addressDetail = self.studioInfo.addressDetail;
        } else {
          self.studios[0].subStudios[self.studioIndex - 1].addressDetail =
            self.studioInfo.addressDetail;

          content.subStudios = self.studios[0].subStudios;
        }

        self.$studioService.studioInfoAction.update(
          self.studios[0].id,
          content,
          (err) => {
            self.$bus.$emit("hideFullCover", {
              message: err
                ? self.$i18n.t("notification.failed.save")
                : self.$i18n.t("notification.success.save"),
              type: err ? "error" : "success",
              unix: now,
            });

            if (!err) {
              self.studios[self.studioIndex].addressDetail = JSON.parse(
                JSON.stringify(self.addressDetail)
              );
            }
          }
        );
      }
    },
    async saveTimeZone(save) {
      let self = this;
      let now = self.$moment().unix();

      if (save) {
        self.$bus.$emit("showFullCover", {
          text: self.$i18n.t("notification.loading.save"),
          type: "loading",
          timeout: 0,
          unix: now,
        });

        let hourFromGMT = parseInt(
          self.$moment.tz(self.studioInfo.timeZone).utcOffset() / 60
        );

        let content = {
          updateTime: String(self.$moment().unix()),
        };

        if (self.studioIndex == 0) {
          content.timeZone = self.studioInfo.timeZone;
          content.hourFromGMT = self.studioInfo.hourFromGMT;
        } else {
          self.studios[0].subStudios[self.studioIndex - 1].timeZone =
            self.studioInfo.timeZone;
          self.studios[0].subStudios[self.studioIndex - 1].hourFromGMT =
            self.studioInfo.hourFromGMT;

          content.subStudios = self.studios[0].subStudios;
        }

        self.$studioService.studioInfoAction.update(
          self.studios[0].id,
          content,
          (err) => {
            self.$bus.$emit("hideFullCover", {
              message: err
                ? self.$i18n.t("notification.failed.save")
                : self.$i18n.t("notification.success.save"),
              type: err ? "error" : "success",
              unix: now,
            });

            if (!err) {
              self.studios[self.studioIndex].timeZone = JSON.parse(
                JSON.stringify(self.studioInfo.timeZone)
              );
              self.studios[self.studioIndex].hourFromGMT = hourFromGMT;
            }
          }
        );
      }
    },
    async getInviteLink() {
      let self = this;
      // dynamic params
      let dynamic = {
        studioId: self.studios[0].id,
      };
      if (self.studioIndex <= 0) {
        dynamic.subStudioId = self.studioInfo.id;
      }

      // signature
      let signature = self.$tools.getJsonKeyValueStr(dynamic);
      signature = signature.substring(0, signature.length - 1);

      // 生成短链接
      await self.$axios
        .post(
          "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyBdUyJmAAbAGEWq0hsbcidOUiaQU1aLxkM",
          {
            suffix: {
              option: "SHORT",
            },
            dynamicLinkInfo: {
              domainUriPrefix: "https://tunekey.app/invite",
              link:
                "https://www.tunekey.app/invitation/?studioId=" +
                dynamic.studioId +
                (!self.isNull(dynamic.subStudioId)
                  ? "&subStudioId=" + dynamic.subStudioId
                  : ""),
              androidInfo: {
                androidPackageName: "com.spelist.tunekey",
                androidFallbackLink: "https://www.tunekey.app/download",
                androidMinPackageVersionCode: "1",
              },
              iosInfo: {
                iosBundleId: "com.spelist.tunekey",
                iosIpadBundleId: "com.spelist.tunekey",
                iosAppStoreId: "1479006791",
              },
              navigationInfo: {
                enableForcedRedirect: false,
              },
              socialMetaTagInfo: {
                socialTitle: "",
                socialDescription: "",
                socialImageLink: dynamic.imageURL,
              },
            },
          }
        )
        .then(async (res) => {
          if (res.data.shortLink) {
            self.inviteLink = res.data.shortLink;
            self.qrcode(res.data.shortLink);
          }
        });
    },
    scrollStudio(index) {
      let self = this;
      let scrollLeft = index * (self.boxSize + 20) - self.boxSize / 2;
      $("#studioContainer").stop().animate({
        scrollLeft: scrollLeft,
      });
    },
    saveZone(data) {
      this.currentTimeZone = data;
      this.$forceUpdate();
    },
    searchTimeZone(data) {
      this.searchTz = data;
      this.$forceUpdate();
    },
    formatTimeZoneStr(tz) {
      let self = this;
      // TODO: 读取 studuioInfo
      // let timeZone = tz ?? self.studioInfo.timeZone;
      let timeZone =
        tz ?? (self.studioInfo?.timeZone || self.userInfo?.timeZone);

      let abbr = self.$moment.tz(timeZone).zoneAbbr();
      let hour = "GMT" + self.$moment.tz(timeZone).format("Z");
      let city = timeZone?.split("/")[1] ?? tz;

      return {
        zone: timeZone,
        abbr: abbr,
        hour: hour,
        city: city,

        full: timeZone + " " + abbr + " (" + hour + ")",
        short:
          (abbr.indexOf("GMT") > -1 || hour.indexOf(abbr) > -1 ? city : abbr) +
          " (" +
          hour +
          ")",
        time: self.$moment.tz(timeZone).format("h:mm A"),
      };
    },
    showAlert(step) {
      let self = this;
      if (step) {
        switch (step) {
          case self.step.STUDIO_TYPE:
            self.showStudioTypeChangeAlert =
              self.currentStudioType != self.studioInfo.studioType;
            break;
        }
      } else {
        self.showSaveStudioAlert = true;
      }
    },
    getLeftPartWidth() {
      return $(".tk-left-list-part").width();
    },
    qrcode(link) {
      let self = this;
      // let size = parseInt((self.boxSize / 5) * 4);
      let size = $("#preview").width();
      let qrcode = new QRCode("qrcode", {
        width: size, // 二维码宽度，单位像素
        height: size, // 二维码高度，单位像素
        text: link, // 生成二维码的链接
      });
    },
    downloadQRcode() {
      let self = this;
      let base64 = $("#qrcode").find("img").eq(0).attr("src");
      let aLink = document.createElement("a");
      let blob = self.$tools.base64ToBlob(base64); //new Blob([content]);
      let evt = document.createEvent("HTMLEvents");
      evt.initEvent("click", true, true); //initEvent 不加后两个参数在FF下会报错  事件类型，是否冒泡，是否阻止浏览器的默认行为
      aLink.download = "Invite Link QR-code";
      aLink.href = URL.createObjectURL(blob);
      aLink.dispatchEvent(
        new MouseEvent("click", {
          bubbles: true,
          cancelable: true,
          view: window,
        })
      ); //兼容火狐
    },
    onCopySuccess() {
      let self = this;
      self.$notify({
        message: self.$i18n.t("notification.success.copy"),
        type: "success",
      });
    },
    getDefaultDescription() {
      let self = this;
      let noticeRequired1 = self.policy.refundNoticeRequired !== 0;
      let noticeRequired2 = self.policy.rescheduleNoticeRequired !== 0;
      let makeupPeriodMonths = {
        label: "",
        value: self.policy.limitDays,
      };

      if (self.policy.limitDays > 56) {
        makeupPeriodMonths.label =
          parseInt(self.policy.limitDays / 7 / 4) + "month(s)";
      } else {
        makeupPeriodMonths.label =
          parseInt(self.policy.limitDays / 7) + "week(s)";
      }

      let cancelationMonths = parseInt(self.policy.refundLimitTimesPeriod / 30);
      let makeupMonths = parseInt(self.policy.rescheduleLimitTimesPeriod / 30);

      let text1 =
        "This is a policies statement and it is provided for you in order to have a clear understanding of what is expected from you and/or your child, as well as what is expected from me as your instructor. By following these guidelines, you and your instructor will avoid unnecessary conflict, better optimize lesson time, and keep learning enjoyable and productive!";
      let text2 = "\n\nCancelation policies:\n",
        text3 = "",
        text4 = "";

      if (self.policy.allowRefund) {
        if (noticeRequired1) {
          text3 =
            "- Request to cancel " +
            self.policy.refundNoticeRequired +
            " hours in advance of lesson to receive a refund.";
        }

        if (self.policy.refundLimitTimes) {
          text4 =
            "\n- Refunding is limited to " +
            self.policy.refundLimitTimesAmount +
            " time" +
            (self.policy.refundLimitTimesAmount > 1 ? "s per " : " per ") +
            cancelationMonths +
            " month" +
            (cancelationMonths > 1 ? "s." : ".");
        }

        if (!noticeRequired1 && !self.policy.refundLimitTimes) {
          text4 = "- Allow refund";
        }
      } else {
        text3 = "- No refund for cancellation";
      }

      let text5 = "\n\nMakeup/Rescheduling policies:",
        text6 = "",
        text7 = "";
      if (self.policy.allowReschedule) {
        if (noticeRequired2) {
          text6 =
            "\n- Request to reschedule " +
            self.policy.rescheduleNoticeRequired +
            " hours in advance of lesson.";
        }
        if (self.policy.rescheduleLimitTimes) {
          text7 =
            "\n- Makeups is limited to " +
            self.policy.rescheduleLimitTimesAmount +
            " time" +
            (self.policy.rescheduleLimitTimesAmount > 1 ? "s per " : " per ") +
            makeupMonths +
            " month" +
            (makeupMonths > 1 ? "s." : ".");
        }
        if (!noticeRequired2 && !self.policy.rescheduleLimitTimes) {
          text7 = "- Allow makeups";
        }
      } else {
        text6 = "\n- Make ups are not allowed";
      }

      let text8 =
        "\nThese policies may be overwhelming, but after all, we are here to have a good time and to exercise our passion! The purpose of this policies statement is for nothing but the benefit and convenience of the student and instructor, so please follow it with the same amount of commitment with which you expect your instructor to follow. If you have any additional questions, feel free to contact me. Thanks!";

      return (
        text1 + text2 + text3 + text4 + text5 + text6 + text7 + "\n" + text8
      );
    },
    goToColorPicker() {
      window.open("https://color.adobe.com/create/image");
    },
    isHexColor() {
      let self = this;
      let hex = self.studioInfo.storefrontColor;
      let reg = /^[A-Fa-f0-9]{6}$/;
      let reg2 = /^[A-Fa-f0-9]{3}$/;
      return reg.test(hex) || reg2.test(hex);
    },
    isNull(obj) {
      return this.$tools.isNull(obj);
    },
    highlights(val, keyword) {
      let index = val.toLowerCase().indexOf(keyword.toLowerCase());
      if (index > -1) {
        //判断这个字段中是否包含keyword
        //如果包含的话，就把这个字段中的那一部分进行替换成html字符
        let str = val.substring(index, keyword.length + index);
        return val.replace(
          str,
          `<span class='tk-text-base-medium tk-font-color-main'>${str}</span>`
        );
      } else {
        return val;
      }
    },
    saveColor(data) {
      this.studioInfo.storefrontColor = data;
    },
    formatFirstLetterUpper(data) {
      let self = this;
      let arr = data.split(" ");

      arr.some((item, i) => {
        let str = item.toLowerCase();
        str = self.$tools.makeFirstLetterUpper(str);
        arr[i] = str;
      });
      let str = arr.join(" ");

      return str;
    },
    selectCity(item) {
      let self = this;
      self.studioInfo.addressDetail.city = self.formatFirstLetterUpper(
        item.city
      );
      self.studioInfo.addressDetail.state = item.state;
      self.studioInfo.addressDetail.country = item.country;
      self.addressDetail = self.studioInfo.addressDetail;
      self.showCityList = false;
      this.$forceUpdate();
    },
    saveCode(data) {
      this.studioInfo.addressDetail.postal_code = data;
      this.addressDetail.postal_code = data;
      this.$forceUpdate();
    },
    saveState(data) {
      this.studioInfo.addressDetail.state = data;
      this.addressDetail.state = data;
      this.$forceUpdate();
    },
    saveCountry(data) {
      this.studioInfo.addressDetail.country = data;
      this.addressDetail.country = data;
      this.$forceUpdate();
    },
    saveCity(data) {
      let self = this;
      let str = self.formatFirstLetterUpper(data);

      self.studioInfo.addressDetail.city = str;
      self.addressDetail.city = str;

      self.showCityList = self.focusCity && data.length > 0;
      self.cityDataResult = [];
      self.cityDataResult = self.cityData.filter((item) => {
        return (
          item.city.toLowerCase().indexOf(data.toLowerCase()) > -1 &&
          (self.addressDetail.country?.toLowerCase() ==
            item.country?.toLowerCase() ||
            self.isNull(self.addressDetail.country)) &&
          self.addressDetail.city.length > 2
        );
      });
      this.$forceUpdate();
    },
    saveStreetLine(data) {
      this.studioInfo.addressDetail.line1 = data;
      this.addressDetail.line1 = data;
      this.$forceUpdate();
    },
    saveWebsite(data) {
      this.studioInfo.website = data;
      this.$forceUpdate();
    },
    formatPhone(code, phone) {
      return this.$dataModules.format.phoneNumberModule(
        code ?? this.phoneNumber.country,
        phone ?? this.phoneNumber.phoneNumber
      );
    },
    formatAddr(addressDetail) {
      let address = this.$dataModules.format.address(
        addressDetail ?? this.addressDetail
      );
      return address;
    },
    savePhone(data) {
      let self = this;
      self.phoneNumber = self.formatPhone(data.areaCode, data.phone).module;
      self.studioInfo.phoneNumber = self.phoneNumber;
      self.studioInfo.phone = self.formatPhone(
        data.areaCode,
        data.phone
      ).string;
    },
    saveEmail(data) {
      this.studioInfo.email = data;
      this.validationEmail();
    },
    saveName(data) {
      this.studioInfo.name = data;
    },
    toggleFocusCity(focus) {
      this.focusCity = focus;
    },
    // 获取 storefront 文字颜色
    getStoreFrontTextColor() {
      let self = this;
      if (self.studioInfo.titlesColor == "ffffff") {
        return "tk-font-color-white";
      } else {
        return "tk-font-color-black2";
      }
    },
    getLessonTypeUrl(lessonType) {
      let self = this;
      console.log(
        lessonType.instrumentId,
        self.instruments[lessonType.instrumentId],
        self.instruments
      );
      let url = self.instruments[lessonType?.instrumentId]?.minPictureUrl ?? "";
      return url;
    },
    async initStudio(index) {
      let self = this;

      let currentStudio = self.studios[index];

      await self.$tools.setCache("c_so_io", currentStudio);
      self.studioIndex = index;
      self.studioInfo = self.$tools.equalValue(currentStudio);
      self.inviteLink = "";

      if (self.isNull(self.studioInfo.phoneNumber)) {
        let phoneNumberModule = self.formatPhone(
          "+1",
          self.studioInfo.phone
        ).module;

        self.studioInfo.phoneNumber = phoneNumberModule;
        self.studios[index].phoneNumber = phoneNumberModule;
      }
      self.phoneNumber = self.studioInfo.phoneNumber;

      if (self.isNull(self.studioInfo.website)) {
        self.studioInfo.website = "";
        self.studios[index].website = "";
      }

      if (self.isNull(self.studioInfo.titlesColor)) {
        self.studioInfo.titlesColor = "ffffff";
        self.studios[index].titlesColor = "ffffff";
      }
      self.studioInfo.titlesColor = self.studioInfo.titlesColor.toLowerCase();

      if (self.isNull(self.studioInfo.storefrontColor)) {
        self.studioInfo.storefrontColor = "71d9c2";
        self.studios[index].storefrontColor = "71d9c2";
      }
      self.studioInfo.storefrontColor =
        self.studioInfo.storefrontColor.toLowerCase();

      self.logo = self.$commons.studioLogoPath(self.studioInfo.id);

      if (self.isNull(self.studioInfo.addressDetail)) {
        self.studioInfo.addressDetail = self.$dataModules.format.addressModule;
        self.studios[index].addressDetail =
          self.$dataModules.format.addressModule;
      }
      self.addressDetail = self.studioInfo.addressDetail;

      // address
      self.countryStateCityData.some((country) => {
        self.countryData.push(country.country);

        country.state.some((state) => {
          self.stateData.push({
            country: country.country,
            state: state.state,
          });

          state.cities.some((city) => {
            self.cityData.push({
              country: country.country,
              state: state.state,
              city: city,
            });
          });
        });
      });
      self.countryData.sort((a, b) => {
        return (a.toUpperCase() + "").localeCompare(b.toUpperCase() + "");
      });
      self.stateData.sort((a, b) => {
        return (a.state.toUpperCase() + "").localeCompare(
          b.state.toUpperCase() + ""
        );
      });
      self.cityData.sort((a, b) => {
        return (a.city.toUpperCase() + "").localeCompare(
          b.city.toUpperCase() + ""
        );
      });

      // timezone
      // if (self.isNull(self.studioInfo.timeZone)) {
      //   self.studioInfo.timeZone = self.userInfo.timeZone;
      //   self.studioInfo.hourFromGMT = self.userInfo.hourFromGMT;
      //   self.studios[index].timeZone = self.userInfo.timeZone;
      //   self.studios[index].hourFromGMT = self.userInfo.hourFromGMT;

      //   self.$studioService.studioInfoAction.update(self.studioInfo.id, {
      //     timeZone: self.userInfo.timeZone,
      //     hourFromGMT: self.userInfo.hourFromGMT,
      //     updateTime: String(self.$moment().unix()),
      //   });
      // }

      self.currentStudioType = self.studioInfo.studioType;
      self.scrollStudio(self.studioIndex);

      console.log("logo: ", self.logo);
      await self.checkLogo((res) => {
        self.loading = false;
        console.log("logo: ", self.logo);
        console.log("logoExist: ", self.logoExist);
      });
      self.$forceUpdate();
    },
    async initBasicData() {
      let self = this;

      self.moment = self.$moment;
      let studioInfo = await self.$userService.studioInfo();
      self.studioInfo = self.$tools.equalValue(studioInfo);

      if (self.isNull(self.studioInfo?.studioTypeChangeHistory)) {
        self.studioInfo.studioTypeChangeHistory = [];
      } else {
        self.studioInfo.studioTypeChangeHistory.sort((a, b) => {
          return b.datetime - a.datetime;
        });
      }

      self.userInfo = await self.$userService.userInfo();
      self.instruments = await self.$studioService.instrumentV2();
      self.policy = (await self.$studioService.policy()) ?? {};
      self.lessonTypesMap = await self.$studioService.lessonTypes();
      self.countryStateCityData = self.$stableData.countryStateCity;
      self.studios = studioInfo.subStudios ?? [];
      self.studioType = self.$dataModules.studioInfo.studioType;
      self.studios.unshift(self.studioInfo);

      // timezone
      self.currentTimeZone =
        self.studioInfo?.timeZone || self.userInfo?.timeZone;

      // sub studios
      if (self.isNull(self.studioInfo.subStudios)) {
        self.studioInfo.subStudios = [];
      }

      // lesson type
      for (let id in self.lessonTypesMap) {
        let item = self.lessonTypesMap[id];
        if (!item.delete) {
          self.lessonTypes.push(item);
        }
      }
      self.lessonTypes.sort((a, b) => {
        return parseInt(b.createTime) - parseInt(a.createTime);
      });
      // policy
      if (self.isNull(self.policy.description)) {
        self.policy.description = self.getDefaultDescription();
      }

      // timeZone list
      self.timeZoneList = [];
      let arr = [];
      self.$moment.tz.names().some((item) => {
        if (
          item.indexOf("GMT+") < 0 &&
          item.indexOf("GMT-") < 0 &&
          item.indexOf("GMT0") < 0 &&
          item !== "GMT"
        ) {
          self.timeZoneList.push({
            name: item,
            hour: parseInt(self.$moment.tz(item).format("Z")),
          });
          // arr.push(item)
        }
      });
      self.timeZoneList.sort((a, b) => {
        return a.hour - b.hour;
      });
      // console.log('arr: ', arr);

      self.initStudio(0);
    },
    async checkLogo(callback) {
      let self = this;

      var ImgObj = new Image();
      ImgObj.src = self.logo;
      ImgObj.onload = (res) => {
        self.logoExist = true;
        if (callback) {
          callback();
        }
      };
      ImgObj.onerror = (err) => {
        self.logoExist = false;
        self.logo = "";
        self.showUpload = true;
        if (callback) {
          callback();
        }
      };
    },
    initBranding() {
      let listen = setInterval(() => {
        if ($("#previewLogo").width()) {
          $("#previewLogo").animate({
            height: $("#previewLogo").width(),
          });
          clearInterval(listen);
        }
      }, 500);
    },
    selectFile() {
      $("#tkSelectUploadImgFileBtn").click();
    },
    changeColor(colorName, color) {
      let self = this;
      self.studioInfo[colorName] = color;
      self.$forceUpdate();
    },
    validationEmail() {
      let self = this;

      if (self.isNull(self.studioInfo.email)) {
        self.isInvalid = false;
      } else {
        self.isInvalid = !self.$tools.isEmail(self.studioInfo.email);
      }
    },
    onCutDown(data) {
      let self = this;
      console.log("onCutDown", data);
      self.isClear = true;
      self.logo = data.dataURL;
      self.newLogo = data;
      self.showUpload = false;
    },
    onCutError(data) {
      let self = this;
      console.log("onCutError", data);
      self.showUpload = false;
    },
    onChooseImg(data) {
      console.log("onChooseImg", data);
      let self = this;
      self.isClear = false;
      self.showUpload = true;
    },
    onPrintImg(data) {
      // console.log("onPrintImg", data);
      let self = this;
      if (self.isClear) {
        self.crop = "";
      } else {
        self.crop = data.dataURL;
      }
    },
    onClearAll(data) {
      let self = this;
      console.log("onClearAll", data);
      self.crop = "";
      self.isClear = true;
      self.showUpload = false;
    },
    onUpdateLogo(base64) {
      let self = this;
      if (base64) {
        self.newLogo = base64;
      } else {
        self.newLogo = "";
      }
      self.$forceUpdate();
    },
  },
};
</script>
<style scoped>
.btn-group-colors > .btn:before {
  line-height: 48px;
}
</style>
