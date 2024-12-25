<template>
	<div>
		<div class="tk-g-root-container tk-layout-flex-row">
			<div
				class="tk-layout-full-height tk-layout-flex-1 tk-layout-flex-column"
			>
				<!-- operations -->
				<div
					class="tk-px-margin-bottom-px16 tk-layout-flex-row"
					id="tkCalendarOperation"
				>
					<!-- title -->
					<div
						class="tk-px-width-px120 tk-px-margin-right-px32 tk-page-title"
					>
						{{ $t("calendar.lesson") }}
					</div>

					<!-- calendar view -->
					<div
						class="tk-text-nowrap tk-layout-flex-1 tk-layout-flex-row tk-layout-flex-vertical-center"
					>
						<!-- month -->
						<base-button
							class="btn btn-sm tk-btn-sm tk-bg-color-transparent tk-font-color-main tk-px-margin-right-px0 tk-px-width-px80 tk-px-height-px40"
							:class="[
								defaultView == viewType.month && !showMonitoring
									? 'tk-border-color-main '
									: 'tk-border-none',
								{ 'tk-border-color-gray-200': showMonitoring },
							]"
							@click="changeView(viewType.month)"
						>
							{{ $t("calendar.month") }}
						</base-button>

						<!-- week -->
						<base-button
							class="btn btn-sm tk-btn-sm tk-bg-color-transparent tk-font-color-main tk-px-margin-right-px0 tk-px-width-px80 tk-px-height-px40"
							:class="[
								defaultView == viewType.week && !showMonitoring
									? 'tk-border-color-main '
									: 'tk-border-none',
								{ 'tk-border-color-gray-200': showMonitoring },
							]"
							@click="changeView(viewType.week)"
						>
							{{ $t("calendar.week") }}
						</base-button>

						<!-- day -->
						<base-button
							class="btn btn-sm tk-btn-sm tk-bg-color-transparent tk-px-margin-right-px0 tk-px-width-px80 tk-px-height-px40 tk-font-color-main"
							:class="[
								defaultView == viewType.day && !showMonitoring
									? 'tk-border-color-main '
									: 'tk-border-none',
								{ 'tk-border-color-gray-200': showMonitoring },
							]"
							@click="changeView(viewType.day)"
						>
							{{ $t("calendar.day") }}
						</base-button>

						<template v-if="!showMonitoring">
							<!-- today -->
							<base-button
								class="btn btn-sm tk-btn-sm tk-px-margin-right-px0 tk-px-width-px80 tk-px-height-px40 tk-font-color-main"
								:class="[
									!showToday
										? 'tk-font-color-gray tk-no-shadow tk-bg-color-transparent'
										: 'tk-bg-color-transparent ',
								]"
								@click="today"
							>
								<!-- 'tk-font-color-gray tk-no-shadow tk-bg-color-disableBtn': -->
								{{ $t("calendar.today") }}
							</base-button>

							<!-- last -->
							<base-button
								class="btn btn-sm tk-btn-sm tk-bg-color-transparent tk-text-lg tk-px-margin-lr-px0 tk-px-margin-right-px0 tk-px-width-px80 tk-px-height-px40 tk-font-color-main"
								@click.prevent="prev"
							>
								<i
									class="fas fa-angle-left tk-position-center"
								></i>
							</base-button>

							<!-- current -->
							<div
								class="tk-text-base-bold tk-px-max-width-px240 tk-px-margin-lr-px16"
							>
								{{ title }}
							</div>

							<!-- next -->
							<base-button
								class="btn btn-sm tk-btn-sm tk-bg-color-transparent tk-text-lg tk-px-margin-lr-px0 tk-px-margin-right-px0 tk-px-width-px80 tk-px-height-px40 tk-font-color-main"
								@click.prevent="next"
							>
								<i
									class="fas fa-angle-right tk-position-center"
								></i>
							</base-button>
						</template>
					</div>

					<!-- filter for instructor / student -->
					<div
						class="avatar-group"
						id="tkUserFilter"
						v-if="!showMonitoring"
						@click.stop="showFilter = true"
					>
						<template
							v-for="(item, index) in $commons.mapToArray(
								filterUserMap
							)"
						>
							<avatar
								v-if="index < 3"
								:key="item.userId || item.studentId"
								:uId="item.userId || item.studentId"
								:name="item.name"
								sizeClass="avatar-xs"
								textClass="text-xs"
								class="tk-cursor-pointer"
							></avatar>
						</template>
						<span v-if="Object.keys(filterUserMap).length >= 3"
							>...</span
						>
					</div>
				</div>

				<div
					class="tk-layout-flex-1 tk-layout-flex-row"
					style="overflow-x: hidden"
					id="tkCalendarContainer"
				>
					<!-- monitoring -->
					<div
						class="tk-px-margin-top-px36 tk-px-margin-right-px32 card tk-bg-color-transparent"
						id="tkMonitorCardContainer"
						v-if="$tkVersion.isNew"
					>
						<template
							v-for="item in $commons.mapToArray(
								monitorTypesMap,
								'asc',
								'index'
							)"
						>
							<div
								v-if="
									($commons.userIsInstructor(userInfo) ||
										(!$commons.userIsInstructor(userInfo) &&
											item.type == 0)) &&
									item
								"
								class="tk-px-padding-tb-px16 tk-text-center tk-cursor-pointer tk-base-shadow-item tk-px-radius-px6"
								:class="[
									item.type == monitorType && showMonitoring
										? 'tk-border-color-main tk-px-border-px2'
										: 'tk-border-bottom-color-gray-200',
								]"
								:key="item.type"
								@click.stop="initMonitorCard(item.type)"
							>
								<div
									class="tk-px-margin-bottom-px10 tk-text-xxl-bold tk-font-lineHeight-1 tk-font-color-main"
								>
									{{ getMonitorCount(item.type) }}
								</div>
								<div class="tk-text-xs-bold">
									{{ item.title }}
								</div>
							</div>
						</template>
					</div>

					<!-- Fullcalendar -->
					<div
						class="card card-calendar tk-no-shadow tk-layout-flex-1 tk-layout-full-height tk-no-scroll tk-bg-color-transparent"
						id="tkCalendar"
					>
						<div
							class="card-body p-0 card-calendar-body"
							id="tkCalendarBody"
							:class="{ 'tk-opacity-0': !calendarReady }"
						>
							<div id="fullCalendar" class="calendar"></div>
						</div>

						<!-- monitor container -->
						<div
							v-if="showMonitoring"
							class="tk-position-absolute tk-layout-full tk-bg-color-selectedBg tk-layout-flex-row"
							style="top: 0; z-index: 10"
						>
							<!-- monitor item -->
							<div
								v-if="getMonitorData().length > 0"
								id="tkMonitorContainer"
								class="tk-layout-full-height tk-overflow-y tk-scrollbar tk-layout-flex-column"
							>
								<div
									class="tk-px-height-px36 tk-text-base-bold tk-font-color-gray tk-layout-flex-row"
								>
									<div class="tk-layout-flex-1">
										{{ formatMonitorSubTitle() }}
									</div>

									<!-- cancelation -->
									<div
										v-if="monitorType == 1"
										class="tk-text-right tk-font-color-main tk-cursor-pointer"
									>
										<span
											@click.stop="
												archiveAllCanceledLesson
											"
											>Archive All</span
										>
									</div>
								</div>
								<calendar-monitoring
									class="tk-px-margin-tb-px0 tk-layout-flex-1 tk-overflow-y tk-scrollbar tk-layout-full-width"
									:data="getMonitorData()"
									:type="monitorType"
									:extraOptions="{
										studioRoomsMap: studioRoomsMap,
										lessonConfigsMap: lessonConfigsMap,
										teachersMap: teachersMap,
										studentsMap: $commons.userIsInstructor(
											userInfo
										)
											? studentsListMap
											: kidsUserInfoMap,
										userInfo: userInfo,
										teacherInfo: teacherInfo,
										studioInfo: studioInfo,
										studiosMap: studiosMap,
									}"
									@close="showMonitoring = false"
									@onClickArchive="onClickArchive"
									@onClickMakeup="onClickMakeup"
									@onClickRetract="onClickRetract"
									@onClickRefund="onClickRefund"
									@onClickCredit="onClickCredit"
									@onClickCancelLesson="onClickCancelLesson"
									@onClickChange="onClickChange"
									@onClickItem="onClickMonitorItem"
									@onClickReschedule="onClickReschedule"
									@onClickConfirm="onClickConfirm"
									@onClickDecline="onClickDecline"
									@onClickIgnore="onClickIgnore"
									@onClickStudentCancelNewLesson="
										onClickStudentCancelNewLesson
									"
									id="tkMonitor"
								></calendar-monitoring>
							</div>

							<!-- monitor detail -->
							<div
								id="tkMonitorDetailContainer"
								class="tk-overflow-y tk-layout-full-height tk-scrollbar tk-layout-flex-1 tk-layout-flex-column"
								v-if="
									showLessonDetailForMonitorItem &&
									getMonitorData().length > 0 &&
									!$tools.objIsNull(
										lessonDetailForMonitorItem
									)
								"
							>
								<!-- lesson detail under monitor -->
								<div class="tk-px-margin-bottom-px16">
									<div
										class="tk-px-height-px36 tk-font-color-gray"
									>
										{{ $t("calendar.lesson_detail") }}
									</div>

									<lesson-detail-card
										v-if="
											!$tools.isNull(
												lessonDetailForMonitorItem
											)
										"
										@close="closeLessonDetailCard"
										@onClickInstructor="
											showInstructor = true
										"
										@onClickStudent="onClickStudent"
										:showLessonDetailIcon="false"
										:type="monitorType"
										:data="lessonDetailForMonitorItem"
										:teacher="
											teachersMap[
												lessonDetailForMonitorItem
													.teacherId
											]
										"
										:student="
											!$tools.isNull(
												lessonDetailForMonitorItem.studentId
											)
												? $commons.userIsInstructor(
														userInfo
												  )
													? studentsListMap[
															lessonDetailForMonitorItem
																.studentId
													  ]
													: $commons.userIsParent(
															userInfo
													  )
													? kidsUserInfoMap[
															lessonDetailForMonitorItem
																.studentId
													  ]
													: userInfo
												: {}
										"
										:lessonType="
											lessonTypesMap[
												lessonDetailForMonitorItem
													.lessonTypeId
											]
										"
										:lessonConfig="
											lessonConfigsMap[
												lessonDetailForMonitorItem
													.lessonScheduleConfigId
											]
										"
										:instrumentUrl="
											!isNull(
												lessonTypesMap[
													lessonDetailForMonitorItem
														.lessonTypeId
												]
											) &&
											!isNull(
												instruments[
													lessonTypesMap[
														lessonDetailForMonitorItem
															.lessonTypeId
													].instrumentId
												]
											)
												? instruments[
														lessonTypesMap[
															lessonDetailForMonitorItem
																.lessonTypeId
														].instrumentId
												  ].minPictureUrl
												: ''
										"
										:extraOptions="{
											timestamp: timestampForMonitorItem,
										}"
										:style="{
											minHeight: '160px',
										}"
									>
									</lesson-detail-card>
								</div>

								<!-- conversation history -->
								<div class="tk-layout-flex-1">
									<div
										class="tk-px-height-px36 tk-font-color-gray"
									>
										{{
											$t("calendar.conversation_history")
										}}
									</div>
									<conversation-card
										:id="currentFollowUpId"
										style="
											max-height: 360px;
											min-height: 160px;
										"
									></conversation-card>
								</div>
							</div>

							<!-- empty monitor item -->
							<div
								v-if="getMonitorData().length == 0"
								class="tk-overflow-y tk-layout-full-height tk-scrollbar tk-layout-flex-1"
							>
								<div
									class="tk-position-center tk-text-center tk-font-color-gray"
									style="width: 64%"
								>
									<img
										src="/img/icons/tk/img_calendar.png"
										style="width: 100%"
									/>
									<div class="tk-px-margin-top-px32">
										{{ monitorTypesMap[monitorType].empty }}
									</div>
								</div>
							</div>

							<!-- no focus monitor item -->
							<div
								v-if="
									!showLessonDetailForMonitorItem &&
									getMonitorData().length > 0
								"
								class="tk-overflow-y tk-layout-full-height tk-scrollbar tk-layout-flex-1"
							>
								<div
									class="tk-position-center tk-text-center tk-font-color-gray"
									style="width: 80%"
								>
									<img
										src="/img/icons/tk/img_calendar.png"
										style="width: 100%"
									/>
									<!-- <div class="tk-px-margin-top-px32">
                    {{ monitorTypesMap[monitorType].empty }}
                  </div> -->
								</div>
							</div>
						</div>
					</div>

					<!-- detail time in timeGrid -->
					<div
						class="tk-detail-time text-left tk-text-sm-bold"
						:class="{
							'tk-bg-gradient-7 tk-font-color-black2':
								!selectedTime.isPast,
							'tk-bg-gradient-8 tk-font-color-gray':
								selectedTime.isPast,
						}"
						v-show="showDetailTime"
						id="tkDetailTime"
						style="
							position: fixed;
							height: 4rem;
							top: 50%;
							left: 50%;
							line-height: 1;
							cursor: default;
							box-sizing: border-box;
							padding-top: 0.75rem;
							overflow: hidden;
							display: none;
							cursor: pointer;
						"
						:style="{
							paddingLeft:
								defaultView == viewType.week
									? '0.5rem'
									: '1.25rem',
							fontSize:
								defaultView == viewType.week
									? '0.75rem'
									: '0.875rem',
						}"
						@click.stop="getSelectTime"
						@mousewheel.stop="scrollOnDetailTime"
					>
						<span id="tkDetailTimeStr"></span>
						<template v-if="!selectedTime.isPast">
							<div
								class="tk-px-width-px24 tk-px-height-px24 tk-timegrid-add tk-position-absolute"
								style="right: 0; top: 6px"
							>
								<i class="fas fa-plus tk-position-center"></i>
							</div>
						</template>
						<div
							id="tkDetailTimeFirst"
							style="
								width: 100%;
								height: 5px;
								position: absolute;
								top: 15px;
								left: 0;
							"
						></div>
						<div
							id="tkDetailTimeSecond"
							style="
								width: 100%;
								height: 15px;
								position: absolute;
								top: 20px;
								left: 0;
							"
						></div>
						<div
							id="tkDetailTimeThird"
							style="
								width: 100%;
								height: 15px;
								position: absolute;
								top: 45px;
								left: 0;
							"
						></div>
					</div>
				</div>
			</div>

			<!-- 右侧工具栏 -->
			<tool-bar
				:bars="!$tkVersion.isNew ? [] : funcBars"
				class="tk-right-tool-bar"
			></tool-bar>
		</div>

		<!-- reschedule / makeup / profile / lesson / add lesson-->
		<slide-x-right-transition
			:duration="300"
			mode="out-in"
			v-show="showSlidePage()"
		>
			<div
				class="tk-position-fixed tk-full-screen tk-bg-color-black_48 tk-cursor-pointer"
				style="top: 0; left: 0; z-index: 9999"
				@click="closeSlidePage()"
			>
				<slide-x-right-transition :duration="300" mode="out-in">
					<!-- reschedule -->
					<div
						class="tk-bg-color-selectedBg tk-slide-right-part"
						key="RESCHEDULE"
						v-if="!objIsNull(lessonDetail) && showReschedule"
					>
						<schedule
							type="RESCHEDULE"
							:datetime="selectedTime"
							:data="lessonDetail"
							:lessonConfig="lessonScheduleConfig"
							:extraOptions="{
								isChangeReschedule: isChangeReschedule,
								isMakeupCancelation: isMakeupCancelation,
								isRescheduleAllLesson: isRescheduleAllLesson,
								isMakeupNoShow: isMakeupNoShow,
								mode: eventMode,
								followUpId: currentFollowUpId,
							}"
							@back="
								showReschedule = false;
								isChangeReschedule = false;
								isMakeupCancelation = false;
								isRescheduleAllLesson = false;
								isMakeupNoShow = false;
								showLessonPreview = false;
								eventMode = null;
							"
						></schedule>
					</div>

					<!-- schedule -->
					<div
						class="tk-bg-color-selectedBg tk-slide-right-part"
						key="SCHEDULE"
						v-if="showCreateNewSchedule"
					>
						<schedule
							:kidsMap="kidsUserInfoMap"
							:datetime="selectedTime"
							@back="showCreateNewSchedule = false"
						></schedule>
					</div>

					<!-- edit schedule -->
					<div
						class="tk-bg-color-selectedBg tk-slide-right-part"
						key="EDIT_SCHEDULE"
						v-if="showEditSchedule"
					>
						<schedule
							type="EDIT"
							:datetime="selectedTime"
							:data="lessonDetail"
							:lessonConfig="lessonScheduleConfig"
							:exptraOptions="{
								showLocation: showLocation,
							}"
							@back="showEditSchedule = false"
						></schedule>
					</div>

					<!-- instructor -->
					<div
						class="tk-bg-color-selectedBg tk-slide-right-part tk-slide-right-part-sm"
						key="INSTRUCTOR"
						v-if="
							(!objIsNull(lessonDetail) ||
								!objIsNull(lessonDetailForMonitorItem)) &&
							showInstructor
						"
					>
						<detail-in-calendar
							:userId="
								showMonitoring
									? lessonDetailForMonitorItem.teacherId
									: lessonDetail.teacherId
							"
							:roleId="roleType.instructor"
							:title="$t('calendar.instructor_profile')"
							@back="showInstructor = false"
						></detail-in-calendar>
					</div>

					<!-- student -->
					<div
						class="tk-bg-color-selectedBg tk-slide-right-part tk-slide-right-part-sm"
						key="STUDENT"
						v-if="
							(!objIsNull(lessonDetail) ||
								!objIsNull(lessonDetailForMonitorItem)) &&
							showStudent
						"
					>
						<detail-in-calendar
							:userId="
								(showMonitoring
									? lessonDetailForMonitorItem.studentId
									: lessonDetail.studentId) ||
								previewStudentId
							"
							:roleId="roleType.student"
							:title="
								$commons.userIsInstructor(userInfo)
									? $t('calendar.student_profile')
									: $t('title.page.profile')
							"
							:data="
								$commons.userIsInstructor(userInfo)
									? studentsListMap[
											showMonitoring
												? lessonDetailForMonitorItem.studentId
												: lessonDetail.studentId
									  ]
									: $commons.userIsParent(userInfo)
									? kidsUserInfoMap[
											(showMonitoring
												? lessonDetailForMonitorItem.studentId
												: lessonDetail.studentId) ||
												previewStudentId
									  ]
									: userInfo
							"
							@back="showStudent = false"
						></detail-in-calendar>
					</div>

					<!-- lesson detail -->
					<div
						class="tk-bg-color-selectedBg tk-slide-right-part"
						key="LESSON"
						v-if="
							(!objIsNull(lessonDetail) ||
								!objIsNull(lessonDetailForMonitorItem)) &&
							showLesson
						"
					>
						<lesson-detail
							:userId="lessonDetail.studentId"
							:data="lessonDetail"
							:student="
								$commons.userIsInstructor(userInfo)
									? studentsListMap[lessonDetail.studentId]
									: $commons.userIsParent(userInfo)
									? kidsUserInfoMap[lessonDetail.studentId]
									: userInfo
							"
							:teacher="teachersMap[lessonDetail.teacherId]"
							:lessonType="
								lessonTypesMap[lessonDetail.lessonTypeId]
							"
							:config="
								lessonConfigsMap[
									lessonDetail.lessonScheduleConfigId
								]
							"
							@back="showLesson = false"
						></lesson-detail>
					</div>
				</slide-x-right-transition>
			</div>
		</slide-x-right-transition>

		<!-- lesson detail -->
		<lesson-detail-card
			id="tkLessonPreview"
			:showShadow="true"
			v-show="showLessonPreview && userInfo.userId"
			@onHover="hoverOnLessonDetail = true"
			@mouseenter="hoverOnLessonDetail = true"
			@close="closeLessonPreview"
			@onClickEdit="onClickEdit"
			@onClickNoShow="onClickNoShow"
			@onClickCancel="onClickCancel"
			@onRescheduleClick="onRescheduleClick"
			@onClickLocation="onRescheduleClick"
			@onClickInstructor="showInstructor = true"
			@onClickStudent="onClickStudent"
			@onClickLessonType="showLesson = !lessonDetail.rescheduled"
			@addLocationForLesson="addLocationForLesson"
			@onClickGroupStudent="showSelectStudents = true"
			@onClickShare="onClickShare"
			style="
				width: 360px;
				position: fixed;
				z-index: 10;
				top: 50%;
				left: 50%;
				font-size: 1rem;
				height: fit-content;
				margin-bottom: 0 !important;
			"
			:style="{
				minHeight:
					lessonDetail.shouldDateTime &&
					lessonDetail.lessonScheduleConfigId
						? '240px'
						: '80px',
			}"
			:data="lessonDetail"
			:teacher="
				lessonDetail.teacherId
					? teachersMap[lessonDetail.teacherId]
					: {}
			"
			:student="
				!$tools.isNull(lessonDetail.studentId)
					? $commons.userIsInstructor(userInfo)
						? studentsListMap[lessonDetail.studentId]
						: $commons.userIsParent(userInfo)
						? kidsUserInfoMap[lessonDetail.studentId]
						: userInfo
					: {}
			"
			:lessonType="
				lessonDetail.lessonTypeId
					? lessonTypesMap[lessonDetail.lessonTypeId]
					: {}
			"
			:lessonConfig="
				lessonDetail.lessonScheduleConfigId
					? lessonConfigsMap[lessonDetail.lessonScheduleConfigId]
					: lessonDetail.config
					? lessonDetail.config
					: {}
			"
			:instrumentUrl="
				!isNull(lessonDetail.lessonTypeId) &&
				!isNull(lessonTypesMap[lessonDetail.lessonTypeId]) &&
				!isNull(
					instruments[
						lessonTypesMap[lessonDetail.lessonTypeId].instrumentId
					]
				)
					? instruments[
							lessonTypesMap[lessonDetail.lessonTypeId]
								.instrumentId
					  ].minPictureUrl
					: ''
			"
			:extraOptions="{
				timestamp:
					(lessonDetail.shouldDateTime || lessonDetail.startTime) *
					1000,
				displayKidsForParent:
					$commons.userIsParent(userInfo) &&
					lessonDetail.lessonScheduleConfigId
						? formatKidsInLesson(lessonDetail)
						: {},
			}"
		>
			<div class="triangle-right triangle-top triangle"></div>
			<div class="triangle-right triangle-bottom triangle"></div>
			<div class="triangle-left triangle-top triangle"></div>
			<div class="triangle-left triangle-bottom triangle"></div>
		</lesson-detail-card>

		<!-- color setting -->
		<calendar-color-setting
			class="tk-popup-outer"
			v-if="showColorSetting"
			:studioRooms="studioRoomsMap"
			:lessonTypes="lessonTypesMap"
			:studioEvents="studioEventsMap"
			:teachers="teachersMap"
			@close="showColorSetting = false"
			@confirm="confirmColorSetting"
		></calendar-color-setting>

		<!-- google calendar -->
		<sync-google-calendar
			class="tk-popup-outer"
			v-if="showSyncGoogleCalendar"
			:studioRooms="studioRoomsMap"
			:lessonTypes="lessonTypesMap"
			:studioEvents="studioEventsMap"
			:teachers="teachersMap"
			:instruments="instruments"
			@close="showSyncGoogleCalendar = false"
			@sync="
				showSyncGoogleCalendar = false;
				getGoogleEvents(null, true);
			"
			@unlink="
				showSyncGoogleCalendar = false;
				googleCalendarSyncRequest = {};
				removeGoogleEvents();
			"
		>
		</sync-google-calendar>

		<!-- filter -->
		<calendar-filter
			class="tk-popup-outer"
			v-if="showFilter"
			title="Filter"
			:availableHours="businessHours"
			:studioRooms="filterRoomMap"
			:lessonTypes="filterLessonTypeMap"
			:users="filterUserMap"
			:locations="filterOtherLocationMap"
			:studioTags="filterTagMap"
			@close="showFilter = false"
			@confirm="confirmFilter"
		></calendar-filter>

		<!-- multiple reschedule/cancel -->
		<future-lessons
			class="tk-popup-outer"
			v-if="showMultipleReschedule || showMultipleCancel"
			:type="showMultipleReschedule ? 'RESCHEDULE' : 'CANCELATION'"
			@close="
				showMultipleReschedule = false;
				showMultipleCancel = false;
			"
			@canceled="onCanceledMultipleSuccess"
		></future-lessons>

		<!-- alert -->
		<alert
			:title="alert.title"
			:content="
				alert.isNoShow || alert.isCancelation ? '' : alert.content
			"
			:left="alert.left"
			:right="alert.right"
			:leftClass="alert.leftClass"
			:rightClass="alert.rightClass"
			v-if="alert.show"
			@close="alert.show = false"
			@onLeftTapped="alert.onLeftTap"
			@onRightTapped="alert.onRightTap"
		>
			<div v-if="alert.isNoShow">
				<textarea
					autofocus
					style="height: 8rem"
					class="tk-textarea tk-layout-full-width tk-overflow-y"
					v-model="alert.content"
					placeholder="Notes(optional)"
				>
				</textarea>

				<div
					class="tk-font-color-gray tk-cursor-pointer tk-px-margin-top-px10"
					v-for="(item, index) in noShowNotes"
					:key="index"
					@click.stop="alert.content = item"
				>
					{{ item }}
				</div>
			</div>
			<div v-if="alert.isCancelation">
				<schedule-item
					v-for="item in canceledSchedules"
					:key="item.id"
					:data="{
						...item,
						desc: `${item.desc}, ${$momentTimezone
							.unix(item.shouldDateTime)
							.tz($commons.getTz())
							.format('DDD, M/D/YYYY')}`,
						showUser: false,
					}"
					itemClass="tk-border-color-gray-200"
					descriptionClass="tk-font-color-gray tk-text-delete"
				>
				</schedule-item>
			</div>
		</alert>

		<!-- select students for group lesson-->
		<select-users
			class="tk-popup-outer"
			v-if="showSelectStudents"
			:data="studentsListMap"
			:selectedDataMap="
				getActiveGroupLessonStudents(
					lessonConfigsMap[lessonDetail.lessonScheduleConfigId]
						.groupLessonStudents
				)
			"
			:multiple="true"
			mapKey="studentId"
			:max="lessonTypesMap[lessonDetail.lessonTypeId].maxStudents || -1"
			title="Select Students"
			@close="showSelectStudents = false"
			@confirm="onUpdateStudentsForGroupLesson"
		></select-users>
	</div>
</template>
<script>
import { Calendar } from "@fullcalendar/core";
// import FullCalendar from "@fullcalendar/vue";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import interactionPlugin from "@fullcalendar/interaction";
// import rrulePlugin from '@fullcalendar/rrule'
import momentTimezonePlugin from "@fullcalendar/moment-timezone";
import { Dropdown, DropdownItem, DropdownMenu } from "element-ui";
import { SlideXLeftTransition, SlideXRightTransition } from "vue2-transitions";
import { RRule, RRuleSet, rrulestr } from "rrule";
import ContactInfoVue from "./components/Modal/ContactInfo.vue";
export default {
	name: "calendar",
	components: {
		[Dropdown.name]: Dropdown,
		[DropdownItem.name]: DropdownItem,
		[DropdownMenu.name]: DropdownMenu,
		// FullCalendar,
		// SlideXLeftTransition,
		SlideXRightTransition,
		SelectUsers: () => import("@/tkViews/components/Modal/SelectUsers.vue"),
		// Card: () => import("@/tkViews/components/layout/Card"),
		LessonDetailCard: () =>
			import("@/tkViews/components/layout/LessonDetailCard.vue"),
		ConversationCard: () =>
			import("@/tkViews/components/layout/ConversationCard.vue"),
		Avatar: () => import("@/tkViews/components/layout/Avatar.vue"),
		CalendarFilter: () =>
			import("@/tkViews/components/Modal/CalendarFilter.vue"),
		CalendarColorSetting: () =>
			import("@/tkViews/components/Modal/CalendarColorSetting.vue"),
		SyncGoogleCalendar: () =>
			import("@/tkViews/components/Modal/SyncGoogleCalendar.vue"),
		CalendarMonitoring: () =>
			import("@/tkViews/components/layout/CalendarMonitoring.vue"),
		Alert: () => import("@/tkViews/components/Modal/Alert"),
		ToolBar: () => import("@/tkViews/components/layout/RightToolbar.vue"),
		Schedule: () => import("@/tkViews/Pages/Schedule.vue"),
		FutureLessons: () =>
			import("@/tkViews/components/Modal/FutureLessons.vue"),
		DetailInCalendar: () => import("@/tkViews/Pages/DetailInCalendar.vue"),
		LessonDetail: () => import("@/tkViews/Pages/LessonDetail.vue"),
		ScheduleItem: () =>
			import("@/tkViews/components/layout/Item/ScheduleItem.vue"),
		// TextareaWithLabel: () =>
		//   import("@/tkViews/components/Inputs/TkTextAreaWithLabel"),
	},
	data() {
		return {
			/* calendar */
			fullCalendar: null,
			// defaultView: "dayGridMonth",
			defaultView: "timeGridWeek",
			viewType: {
				month: "dayGridMonth",
				week: "timeGridWeek",
				day: "timeGridDay",
			},
			calendarReady: false,
			options: {
				timeZone: this.$commons.getTz(),
				plugins: [
					dayGridPlugin,
					timeGridPlugin,
					interactionPlugin,
					momentTimezonePlugin,
					// rrulePlugin
				],
				events: [],
				eventTimeFormat: {
					hour: "numeric",
					minute: "2-digit",
					meridiem: "short",
				},
				slotLabelFormat: {
					hour: "numeric",
					minute: "2-digit",
					omitZeroMinute: true,
					// meridiem: "short",
				},
				eventMinHeight: 13,
				slotDuration: "00:30:00",
				expandRows: true,
				selectable: true, // month true, other false
				selectOverlap: true,
				slotEventOverlap: true,
				nowIndicator: true,
				now: new Date(),
				initialView: "dayGridMonth",
				allDaySlot: false,
				allDayContent: "Event",
				headerToolbar: false,
				eventClick: this.onEventClick,
				eventMouseEnter: this.onEventMouseEnter,
				eventMouseLeave: this.onEventMouseLeave,
				// eventContent: this.onEventContent,
				eventDidMount: this.onEventRender,
				viewDidMount: this.setCalendarHeight,
				// viewDidMount: this.viewDidMount,
				windowResize: this.setCalendarHeight,
				select: this.onSelect,

				moreLinkDidMount: this.moreLinkDidMount,
				moreLinkClick: this.moreLinkClick,
				moreLinkContent: this.moreLinkContent,
				moreLinkClassNames: "",
				dayPopoverFormat: {
					month: "short",
					day: "numeric",
				},

				views: {
					timeGrid: {
						displayEventEnd: false,
						eventTimeFormat: {
							hour: "numeric",
							minute: "2-digit",
						},
					},
					dayGrid: {
						eventTimeFormat: {
							hour: "numeric",
							minute: "2-digit",
							omitZeroMinute: true,
							meridiem: "narrow",
						},
					},
				},
			},
			title: "",
			currentViewDays: [],
			businessHours: {
				daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
				startTime: "8:00",
				endTime: "22:00",
				start: 8,
				end: 22,
			},
			eventId: "",
			eventMode: "",
			eventModeType: {},

			eventShowTimeout: null,
			eventHideTimeout: null,
			hoverOnLessonDetail: false,

			/* filter */
			filterUserMap: {},
			filterRoomMap: {},
			filterTagMap: {},
			filterLessonTypeMap: {},
			filterOtherLocationMap: {},
			startTimestamp: 0,
			endTimestamp: 0,

			/* new lesson */
			selectedTime: {
				ymd: "",
				timeStr: "",
				isPast: false,
				timestamp: "",
			},
			newInvoice: {},

			/* basic info */
			user: null,
			userInfo: null,
			teacherInfo: null,
			studioInfo: null,
			addressBooksMap: {},
			onlineLinksMap: {},
			studioRoomsMap: {},
			teachersMap: {},
			teachersInfoMap: {},
			kidsUserInfoMap: {},
			studiosMap: {},
			studentsListMap: {},
			lessonSchedulesMap: {},
			lessonConfigsMap: {},
			instruments: {},
			lessonTypesMap: {},
			roleType: this.$dataModules.user.roleId,
			studioEventsMap: {},
			userCalendarColorPreference: {},
			colorPreferenceMap: {},
			bgColorsMap: {},
			borderColorsMap: {},
			googleCalendarSyncStatus: {},
			googleCalendarSyncRequest: {},
			googleEventsMap: {},

			/* followup */
			unconfirmed: 0,
			canceled: 0,
			rescheduled: 0,
			noShows: 0,

			followUpMap: {},
			lessonUnconfirmedMap: {},
			lessonUnconfirmeEventsMap: {},
			lessonCanceledMap: {},
			lessonRescheduledMap: {},
			lessonNoShowsMap: {},
			lessonUnconfirmed: [],
			lessonCanceled: [],
			lessonRescheduled: [],
			lessonNoShows: [],
			lessonDetailForMonitorItem: {},
			timestampForMonitorItem: [],
			currentFollowUpId: "",
			followUpId: "",
			noShowNotes: [
				"Late",
				"Unexcused",
				"Excused (Holiday)",
				"Excused (Weather)",
				"Excused (Medical situation)",
			],

			lessonDetail: {},
			showDetailTime: false,
			showLessonPreview: false,
			lessonTypeUrl: "",
			showSyncGoogleCalendar: false,
			showColorSetting: false,
			showFilter: false,
			showSelectUser: false,
			showMonitoring: false,
			showLessonDetailForMonitorItem: false,
			showCreateNewSchedule: false,
			showEditSchedule: false,
			showLocation: false,
			showToday: false,
			showSelectStudents: false,

			enableListener: false,

			showMultipleReschedule: false,
			showMultipleCancel: false,
			showReschedule: false,
			isMakeupCancelation: false,
			isMakeupNoShow: false,
			isChangeReschedule: false,
			isRescheduleAllLesson: false,
			showInstructor: false,
			showStudent: false,
			showLesson: false,
			previewStudentId: "",

			alert: {
				show: false,
				title: "",
				content: "",
				left: "",
				right: "",
				leftClass: "",
				rightClass: "",
				onLeftTap: null,
				onRightTap: null,
				isNoShow: false,
				isCancelation: false,
			},
			canceledSchedulesMap: {},

			monitorType: -1,
			monitorTypesMap: {
				0: {
					title: this.$i18n.t("calendar.unconfirmed"),
					empty: this.$i18n.t("calendar.no_unconfirmed"),
					type: 0,
					index: 0,
				},
				3: {
					title: this.$i18n.t("calendar.no_shows"),
					empty: this.$i18n.t("calendar.no_noshow"),
					type: 3,
					index: 1,
				},
				1: {
					title: this.$i18n.t("calendar.canceled"),
					empty: this.$i18n.t("calendar.no_canceled"),
					type: 1,
					index: 2,
				},
				2: {
					title: this.$i18n.t("calendar.rescheduled"),
					empty: this.$i18n.t("calendar.no_rescheduled"),
					type: 2,
					index: 3,
				},
			},
			funcBars: [],

			// access
			allowCreateLesson: false,

			// google
			googleCalendarSyncStatus: {},
			googleCalendarSyncRequest: {},
			googleAccessTokenCalendar: {},
			colorsMap: this.$commons.arrayToMap(
				this.$dataModules.userCalendarColorPreference.colors,
				"id"
			),

			dataVersion: {},
		};
	},
	async created() {
		let self = this;
		// let eventMinHeight = Math.round(window.innerHeight / 100);

		// if (eventMinHeight < 13) {
		//   eventMinHeight = 13;
		// }

		// if (eventMinHeight > 15) {
		//   eventMinHeight = 15;
		// }

		// self.options.eventMinHeight = eventMinHeight;

		// console.log("视窗高度: ", window.innerHeight, self.options.eventMinHeight);
	},
	async mounted() {
		let self = this;
		let now = self.$moment().unix();

		if (!self.userInfo?.userId) {
			self.userInfo = await self.$userService.userInfo();
		}

		// cache
		await self.initCache(now);

		// 初始化基本数据
		await self.initBasicData(now);

		// TODO: 鼠标在 dayGrid 下的移动事件
		// self.mouseMoveDayGrid();

		// TODO: 鼠标在 timeGrid 下的移动事件
		// self.mouseMoveTimeGrid();

		// studio_room
		self.$bus.$on("onAddStudioRoom", async (data) => {
			if (self.enableListener) {
				console.log("新添加 room: ", data);
				self.studioRoomsMap[data.id] = data;
			}
		});
		self.$bus.$on("onChangeStudioRoom", async (data) => {
			if (self.enableListener) {
				console.log("修改了 room: ", data);
				self.studioRoomsMap[data.id] = data;
			}
		});
		self.$bus.$on("onRemoveStudioRoom", async (data) => {
			if (self.enableListener) {
				console.log("删除了 room: ", data);
				delete self.studioRoomsMap[data.id];
			}
		});

		// lesson_schedule listener
		self.$bus.$on("onAddLessonSchedule", async (data) => {
			if (self.enableListener) {
				console.log("新添加 lesson: ", data);
				let eventItem = await self.initEventItem(data);
				self.addCalendarEvent(eventItem, true);
			}
		});
		self.$bus.$on("onChangeLessonSchedule", async (data) => {
			if (self.enableListener) {
				console.log("修改了 lesson: ", data);
				if (
					data.cancelled ||
					(data?.rescheduled &&
						!self.$tools.isNull(data.rescheduleId))
				) {
					self.removeCalendarEvent(data.id, true);
				} else {
					let eventItem = await self.initEventItem(data);
					self.addCalendarEvent(eventItem, true);
				}

				if (data.id == self.lessonDetail?.id) {
					self.lessonDetail = self.$tools.equalValue(data);
				}
			}
		});
		self.$bus.$on("onRemoveLessonSchedule", async (data) => {
			if (self.enableListener) {
				console.log("删除了 lesson: ", data);
				self.removeCalendarEvent(data.id, true);
			}
		});
		// self.$bus.$on("onRefreshLessonSchedule", async (data) => {
		//   if (self.enableListener) {
		//     console.log("更新了 lesson schedule -- ");
		//     self.reRenderEvent(data);
		//   }
		// });

		// lesson_schedule_config listener
		self.$bus.$on("onAddLessonScheduleConfig", async (data) => {
			if (self.enableListener) {
				console.log("添加了 lesson config: ", data);
				await self.updateCalendarEventByConfig(data);
			}
		});
		self.$bus.$on("onChangeLessonScheduleConfig", async (data) => {
			if (self.enableListener) {
				console.log("修改了 lesson config: ", data);
				await self.clearLessonsUnderConfig(data);
				await self.updateCalendarEventByConfig(data);
			}
		});
		self.$bus.$on("onRemoveLessonScheduleConfig", async (data) => {
			if (self.enableListener) {
				console.log("删除了 lesson config: ", data);
				await self.clearLessonsUnderConfig({
					...data,
					delete: true,
					remove: true,
				});
			}
		});
		// TODO:
		// self.$bus.$on("onRefreshLessonScheduleConfig", async (map) => {
		//   if (self.enableListener) {
		//     let targetLessonConfig = !self.$tools.isNull(self.eventId)
		//       ? map[
		//           self.lessonSchedulesMap[self.eventId]?.extendedProps?.data
		//             ?.lessonScheduleConfigId
		//         ]
		//       : null;

		//     if (!targetLessonConfig?.id) {
		//       // 创建
		//       console.log("创建 --- ")
		//       for (let item in map) {
		//         if (
		//           !self.lessonConfigsMap[item?.id] &&
		//           item.createTimestamp >
		//             self.$moment().subtract(5, "minutes").unix()
		//         ) {
		//           targetLessonConfig = self.$tools.equalValue(item);
		//           break;
		//         }
		//       }
		//     }
		//     console.log("更新了 lesson config: ", targetLessonConfig);

		//     await self.clearLessonsUnderConfig(targetLessonConfig);
		//     await self.updateCalendarEventByConfig(targetLessonConfig);

		//     self.lessonConfigsMap = self.$tools.equalValue(map);
		//     self.$forceUpdate();
		//   }
		// });

		// lesson_type listener
		self.$bus.$on("onAddStudioLessonType", async (data) => {
			if (self.enableListener) {
				console.log("新添加 lesson type: ", data);
				self.lessonTypesMap[data.id] = data;
			}
		});
		self.$bus.$on("onChangeStudioLessonType", async (data) => {
			if (self.enableListener) {
				console.log("修改了 lesson type: ", data);
				self.lessonTypesMap[data.id] = data;
			}
		});
		self.$bus.$on("onRemoveStudioLessonType", async (data) => {
			if (self.enableListener) {
				console.log("删除了 lesson type: ", data);
				delete self.lessonTypesMap[data.id];
			}
		});

		// follow up
		self.$bus.$on("onAddLessonFollowUp", async (data) => {
			if (self.enableListener) {
				console.log("----- new follow up: ", data);
				self.monitorOnChanged(data);

				// re-render old lesson
				if (
					data.column ==
						self.$dataModules.followUp.column.unconfirmed &&
					data.dataType ==
						self.$dataModules.followUp.dataType.reschedule &&
					!self.$tools.isNull(data?.data?.timeBefore)
				) {
					let schedule =
						await self.$scheduleService.lessonScheduleAction.get(
							data.data.scheduleId
						);
					let item = await self.initEventItem(schedule);
					self.addCalendarEvent(item);
				}
			}
		});
		self.$bus.$on("onChangeLessonFollowUp", async (data) => {
			if (self.enableListener) {
				console.log("----- change follow up: ", data);
				self.monitorOnChanged(data, {
					isChange: true,
				});
			}
		});
		self.$bus.$on("onRemoveLessonFollowUp", async (data) => {
			if (self.enableListener) {
				console.log("----- delete follow up: ", data);
				self.monitorOnChanged(data, {
					isRemove: true,
				});
			}
		});

		self.$bus.$on("updateAttendance", async (id, type) => {
			if (self.enableListener) {
				console.log("----- update attendance: ", type);
				self.currentFollowUpId = id;
				self.onClickNoShow(null, type);
			}
		});

		self.$bus.$on("onRefreshStudioEvents", async (dataMap) => {
			if (self.enableListener) {
				self.getStudioEvents(dataMap);
			}
		});

		// 更新 user calendar color preference
		self.$bus.$on("onRefreshUserCalendarColorPreference", async (data) => {
			if (self.enableListener) {
				console.log("onRefreshUserCalendarColorPreference: ", data);

				self.userCalendarColorPreference = data;
				self.initLessonColorPreference();
				await self.getLessons(self.startTimestamp, {
					readStudioEvents: true,
					readGoogleEvents: true,
				});
			}
		});

		// 更新 user Google Calendar Sync Status
		self.$bus.$on("onRefreshGoogleCalendarSyncStatus", async (data) => {
			if (self.enableListener) {
				console.log("onRefreshGoogleCalendarSyncStatus: ", data);
				self.googleCalendarSyncStatus = data;
			}
		});

		// 更新 user Google Calendar Sync Request
		self.$bus.$on("onRefreshGoogleCalendarSyncRequest", async (data) => {
			if (self.enableListener) {
				console.log("onRefreshGoogleCalendarSyncRequest: ", data);
				self.googleCalendarSyncRequest = data ?? {};
			}
		});

		// 更新 DataVersion
		self.$bus.$on("onCurrentChangeDataVersion", async (data) => {
			if (self.enableListener) {
				// console.log("onCurrentChangeDataVersion: ", data);

				if (
					data?.googleCalendarEventsVersion !==
					self.dataVersion?.googleCalendarEventsVersion
				) {
					console.log("google events changed");
					self.getGoogleEvents();
				}

				self.dataVersion = self.$tools.equalValue(data);
			}
		});

		// enable listener
		self.enableListener = true;
	},
	watch: {
		defaultView() {
			this.closeLessonPreview();
		},
		selectedTime: {
			deep: true,
			handler(newVal) {
				// 2021/8/2+3 9:45am
				if (!this.isNull(newVal.ymd) && !this.isNull(newVal.timeStr)) {
					let self = this;
					let ymd = newVal.ymd,
						hmap = newVal.timeStr,
						timestamp = 0,
						hhmm = hmap.substring(0, hmap.length - 2),
						ap = hmap.substring(hhmm.length, hmap.length),
						days = 0,
						hours = parseInt(hmap.substring(0, 2)),
						minutes = parseInt(hmap.substring(3, 5));

					if (ap.toUpperCase() == "PM" && parseInt(hours) < 12) {
						hours += 12;
					}

					if (ymd.indexOf("+") > -1) {
						days = parseInt(ymd.split("+")[1]);
						ymd = self
							.$moment(ymd, "YYYY/M/DD")
							.add(days, "days")
							.format("YYYY/M/DD");
						self.selectedTime.ymd = ymd;

						timestamp = self
							.$moment(ymd, "YYYY/M/DD")
							.hours(hours)
							.minutes(minutes)
							.unix();

						self.selectedTime.timestamp = timestamp;
						self.selectedTime.isPast =
							timestamp < self.$moment().unix();
					}
				}
			},
		},
		showMonitoring(newVal) {
			if (newVal) {
				this.calendarReady = false;
			}
		},
		monitorType(newVal, oldVal) {
			let self = this;
			if (oldVal == 2 && newVal !== 2) {
				// 设置 reschedule 已读
				self.$scheduleService.followUpAction.readReschedule(
					self.lessonRescheduledMap
				);
			}
		},
	},
	computed: {
		lessonScheduleConfig() {
			let self = this;
			if (self.showReschedule) {
				return self.lessonDetail.newLessonFromStudent
					? self.lessonDetail
					: self.lessonConfigsMap[
							self.lessonDetail.lessonScheduleConfigId
					  ];
			} else if (self.showEditSchedule) {
				return self.lessonConfigsMap[
					lessonDetail.lessonScheduleConfigId
				];
			}
		},
		hasFilter() {
			let self = this;

			return (
				Object.keys(self.filterUserMap).length +
					Object.keys(self.filterRoomMap).length +
					Object.keys(self.filterTagMap).length +
					Object.keys(self.filterLessonTypeMap).length +
					Object.keys(self.filterOtherLocationMap).length >
				0
			);
		},
		canceledSchedules() {
			let self = this;
			return self.$commons.mapToArray(
				self.canceledSchedulesMap,
				"asc",
				"shouldDateTime"
			);
		},
	},
	methods: {
		async reRenderEvent(data, isCache) {
			let self = this;

			if (!isCache) {
				let schedulesMap = self.$tools.equalValue(data);

				for (let key in schedulesMap) {
					let schedule = self.$tools.equalValue(schedulesMap[key]);

					if (
						schedule.shouldDateTime <
							self
								.$moment(self.startTimestamp)
								.subtract(7, "days")
								.unix() ||
						schedule.shouldDateTime >
							self
								.$moment(self.endTimestamp)
								.add(7, "days")
								.unix()
					) {
						continue;
					}

					let item = await self.initEventItem(schedule);
					let lessonItem = self.lessonSchedulesMap[key];

					if (
						schedule.shouldDateTime > self.$moment().unix() &&
						item
					) {
						console.log(
							"init item: ",
							new Date(schedule.shouldDateTime * 1000)
						);
					}

					if (
						schedule?.cancelled ||
						(schedule?.rescheduled &&
							!self.$tools.isNull(schedule?.rescheduleId))
					) {
						console.log(
							"delete cancelled || rescheduled: ",
							schedule
						);
						self.removeCalendarEvent(key);
					} else if (
						schedule?.rescheduled &&
						self.$tools.isNull(schedule?.rescheduleId)
					) {
						console.log("add rescheduled: ", schedule);
						self.addCalendarEvent(item);
					} else {
						if (
							self.$tools.isNull(lessonItem?.id) &&
							!self.$tools.isNull(item?.id) &&
							!schedule.cancelled &&
							!schedule.rescheduled
							// && schedule.shouldDateTime > self.$moment().unix()
						) {
							console.log("add new: ", schedule);
							self.addCalendarEvent(item);
						} else if (
							self.$commons.dataIsDifferent({
								oldData: lessonItem?.extendedProps?.data,
								newData: item?.extendedProps?.data,
								dataModulesName: "lessonSchedule",
							}) ||
							(lessonItem?.extendedProps?.data?.rescheduled &&
								!item?.extendedProps?.data?.rescheduled)
						) {
							console.log("update schedule: ", schedule);
							self.addCalendarEvent(item);
						}
					}
				}

				Object.keys(self.lessonSchedulesMap).forEach((key) => {
					let schedule =
						self.lessonSchedulesMap[key]?.extendedProps?.data;
					if (
						!schedulesMap[key] &&
						schedule.shouldDateTime >=
							self
								.$moment()
								.startOf("month")
								.subtract(7, "days")
								.unix() &&
						schedule.shouldDateTime <=
							self
								.$moment(self.endTimestamp)
								.add(7, "days")
								.unix() &&
						!schedule.isCalculated
					) {
						self.removeCalendarEvent(key);
					}
				});
				self.$tools.setCache(
					"temp_lessonSchedulesMap",
					self.lessonSchedulesMap
				);
			} else {
				self.calendarApi().setOption(
					"events",
					self.$commons.mapToArray(self.lessonSchedulesMap ?? {})
				);
				self.calendarApi().setOption(
					"timeZone",
					!self.$tools.isNull(self.$commons.getTz())
						? self.$commons.getTz()
						: "local"
				);
				self.calendarApi().render();
				self.getStudioEvents(self.studioEventsMap ?? {});
				self.getGoogleEvents(self.googleEventsMap ?? {});
				self.getFollowUpUnconfirmedEvents(
					self.lessonUnconfirmedMap ?? {}
				);
				console.log("re-render cache");
			}
		},
		showSlidePage() {
			let self = this;
			return (
				self.showReschedule ||
				self.showInstructor ||
				self.showStudent ||
				self.showLesson ||
				self.showCreateNewSchedule ||
				self.showEditSchedule
			);
		},
		closeSlidePage() {
			let self = this;
			self.showReschedule = false;
			self.showInstructor = false;
			self.showStudent = false;
			self.showLesson = false;
			self.showCreateNewSchedule = false;
			self.showEditSchedule = false;
		},
		async clearCacheAndReload(onlineConfig = true) {
			let self = this;
			let now = self.$moment().unix();

			self.$bus.$emit("showFullCover", {
				message: self.$i18n.t("notification.loading.load_lesson"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			self.$tools.removeCache("temp_lessonSchedulesMap");
			self.$tools.removeCache("ln_se_cg");
			self.enableListener = false;
			self.lessonConfigsMap =
				await self.$scheduleService.lessonScheduleConfig(onlineConfig);

			await self.initTitle({
				isRefresh: true,
			});
			self.enableListener = true;

			self.$bus.$emit("hideFullCover", {
				type: "success",
				unix: now,
			});
		},
		async initCache() {
			let self = this;
			console.log("init cache --- ");

			// business hour cache
			let businessHoursCache = await self.$tools.getCache(
				"temp_businessHours"
			);
			if (!self.$tools.isNull(businessHoursCache)) {
				self.businessHours = businessHoursCache;
			}

			// lesson cache
			self.lessonSchedulesMap =
				(await self.$tools.getCache("temp_lessonSchedulesMap")) ?? {};

			// studio events cache
			self.studioEventsMap = (await self.$tools.getCache("so_es")) ?? {};

			// google events cache
			self.googleEventsMap = (await self.$tools.getCache("ge_es")) ?? {};

			// color preference
			self.userCalendarColorPreference =
				(await self.$tools.getCache("ur_cr_cr_pe")) ?? {};
			self.initLessonColorPreference();

			// follow up cache
			self.followUpMap = (await self.$tools.getCache("fw_up")) ?? {};

			// fullCalendar options cache
			self.defaultView =
				(await self.$tools.getCache("temp_view")) ?? self.defaultView;
			self.options.initialView = self.defaultView;
			self.options.events = self.$commons.mapToArray(
				self.lessonSchedulesMap
			);
			self.options.slotMinTime = self.businessHours.startTime;
			self.options.slotMaxTime = self.businessHours.endTime;
			self.options.timeZone = !self.$tools.isNull(self.$commons.getTz())
				? self.$commons.getTz()
				: "local";
			// self.options.timeZone = "America/New_York";
			console.log("getTz: ", self.$commons.getTz());
			console.log("temp_view: ", self.defaultView);

			// monitor cache
			let tempUnconfirmedCache = await self.$tools.getCache(
				"temp_unconfirmed"
			);
			if (!self.isNull(tempUnconfirmedCache)) {
				self.unconfirmed =
					(await self.$tools.getCache("temp_unconfirmed")) ?? 0;
				self.rescheduled =
					(await self.$tools.getCache("temp_rescheduled")) ?? 0;
				self.canceled =
					(await self.$tools.getCache("temp_canceled")) ?? 0;
				self.noShows =
					(await self.$tools.getCache("temp_noShows")) ?? 0;
			}

			// 初始化 日历
			self.fullCalendar = await new Calendar(
				document.getElementById("fullCalendar"),
				self.options
			);
			self.fullCalendar?.render();

			console.log(
				" init cache: 缓存 schedule -- ",
				self.lessonSchedulesMap,
				Object.keys(self.lessonSchedulesMap ?? {}).length
			);

			if (Object.keys(self.lessonSchedulesMap ?? {}).length > 0) {
				// 初始化 日历标题
				await self.initTitle({
					cache: true,
				});
			}
		},
		async initBasicData(now) {
			let self = this;

			if (Object.keys(self.lessonSchedulesMap ?? {})?.length == 0) {
				console.log(
					" initBasicData: 缓存 schedule -- ",
					Object.keys(self.lessonSchedulesMap ?? {}).length
				);
				self.$bus.$emit("showFullCover", {
					message: self.$i18n.t("notification.loading.load_lesson"),
					type: "loading",
					timeout: 0,
					unix: now,
				});
			}

			if (self.$commons.userIsInstructor(self.userInfo)) {
				await Promise.all([
					self.$commons.user(),
					self.$studioService.instrumentV2(),
					self.$userService.userInfo(),
					self.$userService.teacherInfo(),
					self.$userService.studioInfo(),
				]).then((results) => {
					self.user = results[0];
					self.instruments = results[1];
					self.userInfo = results[2];
					self.teacherInfo = results[3];
					self.studioInfo = results[4];
				});

				await Promise.all([
					self.$studioService.lessonTypes(),
					self.$studioService.teacherUserInfo(),
					self.$studioService.studentsList(),
					self.$studioService.studioRoom(),
					self.initMonitor(),
				]).then((results) => {
					self.lessonTypesMap = results[0];
					self.teachersMap = results[1];
					self.studentsListMap = results[2];
					self.studioRoomsMap = results[3];
				});

				self.lessonConfigsMap =
					await self.$scheduleService.lessonScheduleConfig();
				self.userCalendarColorPreference =
					(await self.$userService.userCalendarColorPreferenceAction.get(
						self.userInfo?.userId
					)) ?? {};
				self.initLessonColorPreference();

				self.$tools.setCache(
					"ur_cr_cr_pe",
					self.userCalendarColorPreference
				);
				console.log(
					"userCalendarColorPreference: ",
					self.userCalendarColorPreference
				);
				self.addressBooksMap = self.$commons.arrayToMap(
					self.teacherInfo?.addressBooks ?? [],
					"id"
				);
				let onlineLinks = self.teacherInfo?.addressBooks?.filter(
					(item) =>
						item.type ==
						self.$dataModules.lessonSchedule.locationType.remote
				);
				self.onlineLinksMap = self.$commons.arrayToMap(
					onlineLinks ?? [],
					"remoteLink"
				);

				await self.initAccess();

				self.dataVersion =
					await self.$userService.dataVersionAction.get(
						self.userInfo.userId
					);
				self.googleCalendarSyncStatus =
					(await self.$userService.googleCalendarSyncStatusAction.get(
						self.userInfo?.userId
					)) ?? self.$dataModules.googleCalendarSyncStatus.default;
				self.googleCalendarSyncRequest =
					(await self.$userService.googleCalendarSyncRequestAction.get(
						self.userInfo?.userId
					)) ?? self.$dataModules.googleCalendarSyncRequest.default;
				self.googleAccessTokenCalendar =
					(await self.$userService.googleAccessTokenCalendarAction.get(
						self.userInfo?.userId
					)) ?? {};

				console.log(
					"googleCalendarSyncStatus",
					self.googleCalendarSyncStatus
				);
				console.log(
					"googleCalendarSyncRequest",
					self.googleCalendarSyncRequest
				);
				console.log(
					"googleAccessTokenCalendar",
					self.googleAccessTokenCalendar
				);

				if (
					!self.$tools.isNull(
						self.googleAccessTokenCalendar.refresh_token
					) &&
					self.googleAccessTokenCalendar?.expiry_date <=
						new Date().getTime()
				) {
					await self.getGoogleAccessToken();
				}

				self.initFuncBars();
			} else if (
				self.$commons.userIsStudent(self.userInfo) ||
				self.$commons.userIsParent(self.userInfo)
			) {
				await Promise.all([
					self.$commons.user(),
					self.$studioService.instrumentV2(),
					self.$scheduleService.lessonScheduleConfig(true),
					self.$userService.userInfo(),
					self.$userService.userKids(),
				]).then((results) => {
					self.user = results[0];
					self.instruments = results[1];
					self.lessonConfigsMap = results[2];
					self.userInfo = results[3];
					self.kidsUserInfoMap = results[4];
				});

				await Promise.all([
					self.$studentService.studiosLessonTypes(),
					self.$studentService.studiosTeacherUserInfos(),
					self.$studentService.teacherInfos(),
					self.$studentService.studioInfos(),
					self.$studentService.studioRooms(),
					self.initMonitor(),
				]).then((results) => {
					self.lessonTypesMap = results[0];
					self.teachersMap = results[1];
					self.teachersInfoMap = results[2];
					self.studiosMap = results[3];
					self.studioRoomsMap = results[4];
				});

				if (self.$commons.userIsStudent(self.userInfo)) {
					self.kidsUserInfoMap = {
						[self.userInfo?.userId]: self.userInfo,
					};
				}
			}

			if (
				Object.keys(self.lessonSchedulesMap ?? {}).length == 0 ||
				Object.keys(self.studioEventsMap ?? {}).length == 0
			) {
				console.log("获取课程 -- ");
				// 初始化 日历标题
				await self.initTitle();
			} else {
				await self.getGoogleEvents();
			}

			// setTimeout(() => {
			self.$bus.$emit("hideFullCover", {
				type: "success",
				unix: now,
			});
			// }, 200);
		},
		initLessonColorPreference() {
			let self = this;
			let colorPreferenceMap =
				self.$commons.arrayToMap(
					self.userCalendarColorPreference?.items?.filter(
						(item) =>
							item.category !=
								self.$dataModules.userCalendarColorPreference
									.category.studioEvents && item.isSelected
					) ?? [],
					"category"
				) ?? {};
			self.bgColorsMap = {};
			self.borderColorsMap = {};

			if (Object.keys(colorPreferenceMap)?.length > 0) {
				Object.keys(colorPreferenceMap).forEach((key) => {
					let item = colorPreferenceMap[key];
					if (item?.selectedStyle == "block") {
						self.bgColorsMap = self.$commons.arrayToMap(
							item?.colorCodes,
							"ref"
						);
					}
					if (item?.selectedStyle == "line") {
						self.borderColorsMap = self.$commons.arrayToMap(
							item?.colorCodes,
							"ref"
						);
					}
				});
			}

			self.colorPreferenceMap = colorPreferenceMap;
		},
		async getGoogleAccessToken(callback) {
			let self = this;
			let refreshAccessToken = self.$functionsService.refreshAccessToken;
			refreshAccessToken().then(async (res) => {
				self.googleAccessTokenCalendar = res.data.data;
				if (callback) {
					callback();
				}
			});
		},
		async initAccess() {
			let self = this;

			if (self.$commons.userIsInstructor(self.userInfo)) {
				self.allowCreateLesson = self.$tkVersion.isNew
					? await self.$accessService.allowCreateLesson(self.userInfo)
					: false;
			}
		},
		initFuncBars() {
			let self = this;
			let funcBars = [
				// TODO: sync google calendar
				// {
				//   label: "Sync Google Calendar",
				//   icon: "fa-brands fa-google",
				//   type: "google",
				//   onClick() {
				//     self.showSyncGoogleCalendar = true;
				//   },
				// },
				{
					label: "Color-code Setting",
					icon: "fa-solid fa-palette",
					onClick() {
						self.showColorSetting = true;
					},
				},
				{
					label: self.$i18n.t("general.filter"),
					icon: "fa-solid fa-sliders fa-rotate-90",
					key: "CalendarFilter",
					onClick() {
						self.showFilter = true;
					},
				},
				{
					label: "Reschedule multiple lessons",
					icon: "fa-solid fa-right-left",
					onClick() {
						self.eventMode = null;
						self.showMultipleReschedule = true;
					},
				},
				{
					label: "Cancel multiple lessons",
					icon: "fa-solid fa-circle-xmark",
					onClick() {
						self.eventMode = null;
						self.showMultipleCancel = true;
					},
				},
				{
					label: "Refresh",
					icon: "fa-solid fa-rotate-right",
					onClick() {
						self.clearCacheAndReload(true);
					},
				},
			];

			self.funcBars = funcBars;
		},
		async addLocationForLesson(data) {
			let self = this;
			if (data?.id) {
				self.lessonSchedulesMap[data.id] = self.$tools.equalValue(data);
				let eventItem = await self.initEventItem(data);
				self.addCalendarEvent(eventItem, true);
				console.log(
					"add location for lesson: ",
					self.lessonSchedulesMap[data.id]
				);
				self.showLessonPreview = false;
			}
		},
		getMonitorCount(type) {
			let self = this;
			switch (type) {
				case 0:
					return self.unconfirmed;
				case 1:
					return self.canceled;
				case 2:
					return self.rescheduled;
				case 3:
					return self.noShows;
			}
		},
		moreLinkContent({ num, text }) {
			let self = this;

			let el = document.createElement("div");
			el.classList.add("tk-font-lineHeight-1");
			el.classList.add("tk-text-xs-bold");
			el.classList.add("tk-transition");
			el.classList.add("tk-text-overflow");
			el.classList.add("tk-px-margin-lr-px5");

			el.innerHTML =
				"<span class='tk-px-margin-right-px5'>" +
				num +
				" more" +
				"</span>" +
				"<i class='fas fa-angle-down'></i>";

			let arrayOfDomNodes = [el];
			return { domNodes: arrayOfDomNodes };
		},
		moreLinkClick(arg) {
			let self = this;
			let data = arg.allSegs[0]?.event?.extendedProps?.data;
			self.getSelectTime(data);
			// let addDom =
			//   "" +
			//   "<div class='tk-timegrid-add'>" +
			//   "<i class='fas fa-plus'></i>" +
			//   "</div>";

			// if (data.shouldDateTime > self.$moment().unix()) {
			//   setTimeout(() => {
			//     $(".fc-popover > .fc-popover-body").append(addDom);
			//   }, 200);
			// }
		},
		moreLinkDidMount(arg) {
			let el = $(arg.el);
			el.css({
				top: arg.el.offsetTop - el.height() + 8 + "px",
				height: "fit-content",
			});
		},
		formatMonitorSubTitle() {
			let self = this;
			switch (self.monitorType) {
				case 0:
					// return "Unconfirmed lessons";
					return "Pending lessons";
				case 1:
					return "Canceled lessons";
				case 2:
					return "Rescheduled lessons";
				case 3:
					return "No-show lessons";
			}
		},
		async clearLessonsUnderConfig(config, callback) {
			let self = this;
			let lessonSchedules = self.$commons
				.mapToArray(self.lessonSchedulesMap)
				?.filter((item) => {
					return (
						item.extendedProps?.data?.lessonScheduleConfigId ==
						config.id
					);
				});
			console.log("清除 config 下的 lesson: ", config);

			for (let i = 0; i < lessonSchedules.length; i++) {
				let item = lessonSchedules[i];
				let shouldDateTime =
					self.lessonSchedulesMap[item?.id]?.shouldDateTime;
				let needClear =
					(shouldDateTime >= config?.endDate &&
						config.endType == 1 &&
						config?.repeatType != 0) ||
					config?.delete ||
					self.$tools.isNull(config?.id) ||
					self.$tools.isNull(shouldDateTime);

				console.log("need clear: ", needClear);
				console.log(
					"shouldDateTime ",
					self.lessonSchedulesMap[item?.id]?.shouldDateTime,
					new Date(
						self.lessonSchedulesMap[item?.id]?.shouldDateTime * 1000
					)
				);
				console.log("config.endType == 1", config.endType == 1);
				console.log("config.repeatType != 0 ", config?.repeatType != 0);
				if (needClear) {
					self.removeCalendarEvent(item.id);
				}
			}

			// if (config?.delete || self.$tools.isNull(config?.id)) {
			if (config?.remove || self.$tools.isNull(config?.id)) {
				delete self.lessonConfigsMap[config.id];
			}
			self.$tools.setCache(
				"temp_lessonSchedulesMap",
				self.lessonSchedulesMap
			);

			if (callback) {
				callback();
			}
		},
		async updateCalendarEventByConfig(config) {
			let self = this;
			self.lessonConfigsMap[config.id] = config;
			// let lessons =
			//   config?.delete == true
			//     ? []
			//     : await self.getLessonsByConfig(self.startTimestamp, config);
			let lessons = await self.getLessonsByConfig(
				self.startTimestamp,
				config
			);

			console.log(
				"更新 config 下的 lesson: ",
				config,
				new Date(config.startDateTime * 1000),
				lessons
			);

			lessons.some((item, i) => {
				// console.log("add lesson event: ", new Date(item.start));
				self.addCalendarEvent(item);
			});
			self.$tools.setCache(
				"temp_lessonSchedulesMap",
				self.lessonSchedulesMap
			);

			self.hideDetailTime();
			self.$forceUpdate();
		},
		initMonitorCard(type) {
			let self = this;
			self.monitorType = type;
			self.showMonitoring = true;
			self.closeLessonDetailCard();
			self.hideDetailTime();
			self.closeLessonPreview();
		},
		closeLessonDetailCard() {
			let self = this;
			self.showLessonDetailForMonitorItem = false;
			self.currentFollowUpId = "";
			self.$bus.$emit("clearSelectedMonitorItem");
		},
		getLessonScheduleIdInMonitorItem(data) {
			let self = this;

			switch (data.column) {
				case self.$dataModules.followUp.column.unconfirmed:
					return data?.data?.id || data?.data?.scheduleId;
				case self.$dataModules.followUp.column.cancelled:
					return data?.data?.data
						? data.data.data[0]?.oldScheduleId
						: data.data.oldScheduleId;
				case self.$dataModules.followUp.column.rescheduled:
					return data.data.rescheduleId?.length > 0
						? data.data.rescheduleId
						: data.data.scheduleId;
				case self.$dataModules.followUp.column.noshows:
					return data.data.lessonScheduleId;
			}
		},
		async initLessonDetailForMonitorItem(monitorItem) {
			let self = this;
			let lessonDetail = {};
			let data = self.$tools.equalValue(monitorItem);
			self.timestampForMonitorItem = [];
			self.currentFollowUpId = data.id;

			if (data?.data?.credit) {
				self.lessonDetail = data?.data?.lessonSchedule;
			} else {
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(data);

				lessonDetail =
					await self.$scheduleService.lessonScheduleAction.get(
						lessonScheduleId
					);
			}

			self.lessonDetail = self.$tools.equalValue(lessonDetail ?? {});
			self.lessonDetailForMonitorItem =
				data?.dataType ==
				self.$dataModules.followUp.dataType.studentLessonConfigRequests
					? {
							...data?.data?.config,
							newLessonFromStudent: true,
							shouldTimeLength:
								self.lessonTypesMap[
									data?.data?.config?.lessonTypeId
								]?.timeLength ?? 0,
							shouldDateTime: data?.data?.config?.startDateTime,
							lessonTypeId: data?.data?.config?.lessonTypeId,
							lessonScheduleConfigId: data?.data?.config?.id,
					  }
					: self.$tools.equalValue(lessonDetail);

			console.log(
				"lesson detail for monitor: ",
				self.lessonDetailForMonitorItem,
				monitorItem
			);

			if (data.data.data) {
				data.data.data?.some((item) => {
					self.timestampForMonitorItem.push(
						item?.shouldDateTime * 1000
					);
				});
			} else {
				self.timestampForMonitorItem.push(
					(data?.data?.shouldDateTime ||
						self.lessonDetail?.shouldDateTime ||
						data?.data?.config?.startDateTime) * 1000
				);
			}

			self.showLessonDetailForMonitorItem = true;
			self.$forceUpdate();
		},
		// 学生取消申请添加的课程
		async studentCancelNewLessonRequest(data) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			let studentCancelRequestedLesson =
				self.$functionsService.studentCancelRequestedLesson;

			let option = {
				id: data.id,
			};

			console.log("studentCancelRequestedLesson: ", option);

			// return false;

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.cancel"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			studentCancelRequestedLesson(option)
				.then(async (result) => {
					console.log("取消课程成功: ", result.data);
					// 删除 calendar 中 lesson
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.cancel"),
						type: "success",
						unix: now,
					});

					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("取消课程失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.cancel"),
						type: "error",
						unix: now,
					});
				});
		},
		// 老师处理学生申请添加的课程
		async progressStudentNewLessonRequest(data, type) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			let progressStudentNewLessonRequest =
				self.$functionsService.progressStudentNewLessonRequest;

			let option = {
				id: data?.id,
				type,
			};

			console.log("progressStudentNewLessonRequest: ", option);

			self.$bus.$emit("showFullCover", {
				text:
					type == "DECLINE"
						? self.$i18n.t("notification.loading.decline")
						: self.$i18n.t("notification.loading.confirm"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			progressStudentNewLessonRequest(option)
				.then(async (result) => {
					console.log("处理课程成功: ", result.data);
					self.$bus.$emit("hideFullCover", {
						message:
							type == "DECLINE"
								? self.$i18n.t("notification.success.decline")
								: self.$i18n.t("notification.success.confirm"),
						type: "success",
						unix: now,
					});

					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("处理课程失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message:
							type == "DECLINE"
								? self.$i18n.t("notification.failed.decline")
								: self.$i18n.t("notification.failed.confirm"),
						type: "error",
						unix: now,
					});
				});
		},
		// 取消 group lesson
		async deleteGroupLesson() {
			let self = this;
			let now = self.$moment().unix();
			let deleteGroupLesson = self.$functionsService.deleteGroupLesson;

			self.alert.show = false;

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.cancel"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			deleteGroupLesson({
				configId: self.lessonDetail.lessonScheduleConfigId,
			})
				.then(async (result) => {
					console.log("取消课程成功: ", result.data);
					// 删除 calendar 中 lesson
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.cancel"),
						type: "success",
						unix: now,
					});
				})
				.catch(async (err) => {
					console.log("取消课程失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.cancel"),
						type: "error",
						unix: now,
					});
				});
		},
		// 取消课程
		async cancelLesson(data) {
			let self = this;
			let now = self.$moment().unix();
			let config =
				self.lessonConfigsMap[self.lessonDetail.lessonScheduleConfigId];

			self.alert.show = false;
			self.showLessonPreview = false;
			// self.eventId = "";

			let cancelLesson = data
				? self.$functionsService.cancelRescheduledLesson
				: config?.lessonCategory ==
				  self.$dataModules.lessonType.category.group
				? self.$functionsService.cancelGroupLesson
				: self.eventMode == self.eventModeType.current
				? self.$functionsService.cancelLesson
				: self.$functionsService.cancelLessonsWithType;

			let option = {};

			if (data) {
				option = {
					id: data.id,
				};
			} else {
				option = {
					// current
					lessonId: self.lessonDetail.id,
					scheduleMode:
						self.eventMode == self.eventModeType.current
							? "CURRENT"
							: self.eventMode,

					// this & following / all
					scheduleConfigId: self.lessonDetail.lessonScheduleConfigId,
					selectedLessonScheduleId: self.lessonDetail.id,
					cancelType: self.eventMode || "",

					// group
					lessonScheduleId: self.lessonDetail.id,
					type: self.eventMode || "",
				};
			}

			console.log("cancel lesson: ", option);

			// return false;

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.cancel"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			cancelLesson(option)
				.then(async (result) => {
					console.log("取消课程成功: ", result.data);
					// 删除 calendar 中 lesson
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.cancel"),
						type: "success",
						unix: now,
					});

					if (data) {
						self.onClickMonitorItem();
					} else {
						self.initMonitor();
					}
				})
				.catch(async (err) => {
					console.log("取消课程失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.cancel"),
						type: "error",
						unix: now,
					});
				});
		},
		// 批量取消课程 成功
		async onCanceledMultipleSuccess(data) {
			let self = this;
			console.log("onCanceledMultipleSuccess: ", data);

			self.canceledSchedulesMap = self.$tools.equalValue(data);
			// self.showMultipleCancel = false;

			self.alert.title = "Successfully canceled!";
			self.alert.left = self.$i18n.t("general.go_back");
			self.alert.right = self.$i18n.t("general.confirm");
			self.alert.leftClass = "tk-font-color-main";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.isCancelation = true;
			self.alert.show = true;
			self.alert.onLeftTap = () => {
				self.alert.show = false;
				self.alert.isCancelation = false;
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
				self.alert.isCancelation = false;
			};

			self.$forceUpdate();
		},
		// archive 全部取消的课程
		async archiveAllCanceledLesson() {
			let self = this;
			let now = self.$moment().unix();
			let archiveAllFollowUps =
				self.$functionsService.archiveAllFollowUps;

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			let unArchivedCancellations = self.lessonCanceled?.filter(
				(item) =>
					item.status != self.$dataModules.followUp.status.archived
			);
			let ids = [];
			unArchivedCancellations?.some((item) => {
				ids.push(item.id);
			});

			console.log("archive all canceled lesson: ", ids);

			if (ids?.length == 0) {
				return false;
			}

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.archive"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			archiveAllFollowUps({
				ids: ids,
			})
				.then(async (result) => {
					console.log("archive canceled lesson 成功: ", result.data);

					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.archive"),
						type: "success",
						unix: now,
					});

					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("archive canceled lesson 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.archive"),
						type: "error",
						unix: now,
					});
				});
		},
		// archive 取消的课程
		async archiveCanceledLesson(id) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			console.log("archive canceled lesson: ", id, self.followUpMap[id]);

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.archive"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			let archiveCancellation =
				self.$functionsService.archiveCancellation;

			archiveCancellation({
				id: id,
			})
				.then(async (result) => {
					console.log("archive canceled lesson 成功: ", result.data);

					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.archive"),
						type: "success",
						unix: now,
					});

					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("archive canceled lesson 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.archive"),
						type: "error",
						unix: now,
					});
				});
		},
		// archive noshow的课程
		async archiveNoShowLesson(id) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			console.log("archive noshow lesson: ", id, self.followUpMap[id]);

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.archive"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			let archiveNoshow = self.$functionsService.archiveNoshow;

			archiveNoshow({
				id: id,
			})
				.then(async (result) => {
					console.log("archive noshow lesson 成功: ", result.data);

					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.archive"),
						type: "success",
						unix: now,
					});

					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("archive noshow lesson 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.archive"),
						type: "error",
						unix: now,
					});
				});
		},
		// 取消课程改期
		retractReschedule(data) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			console.log("retract reschedule: ", data);

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.retract"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			let retractReschedule = self.$functionsService.retractReschedule;

			retractReschedule({
				id: data.id,
			})
				.then(async (result) => {
					console.log("retract reschedule 成功: ", result.data);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.retract"),
						type: "success",
						unix: now,
					});
					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("retract reschedule 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.retract"),
						type: "error",
						unix: now,
					});
				});
		},
		// 确认课程改期
		confirmReschedule(data) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			console.log("confirm reschedule: ", data);

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.confirm"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			let confirmReschedule;

			switch (data.dataType) {
				case self.$dataModules.followUp.dataType.reschedule:
					// if (data.confirmImmediately) {
					//   confirmReschedule =
					//     self.$functionsService.confirmRescheduleDirectlly;
					// } else {
					//   confirmReschedule = self.$functionsService.confirmReschedule;
					// }

					confirmReschedule =
						self.$functionsService.confirmReschedule;
					break;
				case self.$dataModules.followUp.dataType.newLessonFromCredit:
					confirmReschedule =
						self.$functionsService.confirmNewLessonFromCredit;
					break;
			}

			confirmReschedule({
				id: data.id,
				lessonScheduleId: data.data.scheduleId,
				timeAfter: data.data.timeAfter,
				confirmImmediately: data.confirmImmediately,
			})
				.then(async (result) => {
					console.log("confirm reschedule 成功: ", result.data);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.confirm"),
						type: "success",
						unix: now,
					});
					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("confirm reschedule 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.confirm"),
						type: "error",
						unix: now,
					});
				});
		},
		// 添加 credit
		addCredit(data) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			console.log("add credit: ", data);

			// return false

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.add"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			let addCredit =
				data.dataType ==
				self.$dataModules.followUp.dataType.cancellation
					? self.$functionsService.addCreditFromCancellation
					: self.$functionsService.addCreditFromNoshow;

			addCredit({
				id: data.id,
			})
				.then(async (result) => {
					console.log("add Credit 成功: ", result.data);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.add"),
						type: "success",
						unix: now,
					});
					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("add credit 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.add"),
						type: "error",
						unix: now,
					});
				});
		},
		// 拒绝 reschedule
		declineReschedule(data) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			console.log("decline reschedule: ", data);

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.decline"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			let declineReschedule;

			switch (data.dataType) {
				case self.$dataModules.followUp.dataType.reschedule:
					declineReschedule =
						self.$functionsService.declineReschedule;
					break;
				case self.$dataModules.followUp.dataType.newLessonFromCredit:
					declineReschedule =
						self.$functionsService.declineNewLessonFromCredit;
					break;
			}

			if (declineReschedule) {
				declineReschedule({
					id: data.id,
				})
					.then(async (result) => {
						console.log("decline 成功: ", result.data);
						self.$bus.$emit("hideFullCover", {
							message: self.$i18n.t("notification.success.add"),
							type: "success",
							unix: now,
						});

						self.showLessonDetailForMonitorItem = false;
					})
					.catch(async (err) => {
						console.log("decline 失败: ", err);
						self.$bus.$emit("hideFullCover", {
							message: self.$i18n.t(
								"notification.failed.decilne"
							),
							type: "error",
							unix: now,
						});
					});
			}
		},
		// 忽略 conflict
		ignoreConflict(data) {
			let self = this;
			let now = self.$moment().unix();

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			console.log("ignore confilict: ", data);

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.update"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			self.$scheduleService.followUpAction
				.update(data.id, {
					status: self.$dataModules.followUp.status.ignored,
					updateTime: now,
				})
				.then((err) => {
					if (err) {
						console.log("ignore 失败: ", err);
						self.$bus.$emit("hideFullCover", {
							message: self.$i18n.t("notification.failed.update"),
							type: "error",
							unix: now,
						});
					} else {
						console.log("ignore 成功");
						self.$bus.$emit("hideFullCover", {
							message: self.$i18n.t(
								"notification.success.update"
							),
							type: "success",
							unix: now,
						});
					}
				});
		},
		// TODO: 付款
		paidAtLesson() {
			let self = this;
		},
		// report no-show / uddate attendance
		async reportNoShow(schedule, type) {
			let self = this;
			let now = self.$moment().unix();
			let noShowUserId = [];
			let data =
				self.$tools.equalValue(schedule) ??
				(await self.$scheduleService.lessonScheduleAction.get(
					self.getLessonScheduleIdInMonitorItem(
						self.followUpMap[self.currentFollowUpId]
					)
				));

			self.alert.show = false;
			self.showLessonPreview = false;
			self.eventId = "";

			self.$bus.$emit("showFullCover", {
				text: schedule
					? self.$i18n.t("notification.loading.report")
					: self.$i18n.t("notification.loading.update"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			if (type.value == "STUDENT_ABSENT") {
				noShowUserId.push(data.studentId);
			} else if (type.value == "INSTRUCTOR_ABSENT") {
				noShowUserId.push(data.teacherId);
			} else if (type.value == "BOTH_ABSENT") {
				noShowUserId.push(data.studentId);
				noShowUserId.push(data.teacherId);
			}

			let report = schedule
				? self.$functionsService.reportNoShow
				: self.$functionsService.updateNoShowAttended;

			let options = {
				id: self.currentFollowUpId,
				lessonId: data.id,
				noShowUserIds: noShowUserId,
				note: self.alert.content,
			};

			console.log("options: ", options);

			report(options)
				.then(async (result) => {
					console.log("report 成功: ", result.data);
					self.$bus.$emit("hideFullCover", {
						message: schedule
							? self.$i18n.t("notification.success.report")
							: self.$i18n.t("notification.success.update"),
						type: "success",
						unix: now,
					});
					self.onClickMonitorItem();
				})
				.catch(async (err) => {
					console.log("report 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: schedule
							? self.$i18n.t("notification.failed.report")
							: self.$i18n.t("notification.failed.update"),
						type: "error",
						unix: now,
					});
				});
		},
		async removeCalendarEvent(id, syncCache = false) {
			let self = this;
			let event = null;

			delete self.lessonSchedulesMap[id];

			if (
				!self.isNull(self.calendarApi()) &&
				typeof self.calendarApi()?.getEventById == "function"
			) {
				event = await self.calendarApi().getEventById(id);
				if (!self.isNull(event)) {
					if (self.eventId == id) {
						self.showLessonPreview = false;
					}
					event.remove();
				}
			}

			if (syncCache) {
				self.$tools.setCache(
					"temp_lessonSchedulesMap",
					self.lessonSchedulesMap
				);
			}
		},
		addCalendarEvent(item, syncCache = false) {
			let self = this;
			let event = null;

			if (
				!self.isNull(self.calendarApi()) &&
				!self.isNull(item?.id) &&
				typeof self.calendarApi()?.getEventById == "function"
			) {
				self.lessonSchedulesMap[item.id] = self.$tools.equalValue(item);

				event = self.calendarApi()?.getEventById(item.id);
				if (!self.$tools.isNull(event?.id)) {
					event.remove();
				}

				if (self.meetFilter(item?.extendedProps?.data)) {
					self.calendarApi().addEvent(item);
				}

				if (syncCache) {
					self.$tools.setCache(
						"temp_lessonSchedulesMap",
						self.lessonSchedulesMap
					);
				}
			}
		},
		onClickStudent(data) {
			let self = this;
			self.previewStudentId = data?.studentId || data?.userId;
			console.log("previewStudentId: ", self.previewStudentId);
			self.showStudent = true;
		},
		onUpdateStudentsForGroupLesson(data) {
			let self = this;
			let selectedStudents = data?.selectedUser ?? {};
			let now = self.$moment().unix();
			let studentIds = Object.keys(selectedStudents);
			let updateStudentsForGroupLesson =
				self.$functionsService.updateStudentsForGroupLesson;

			// return false;

			self.$bus.$emit("showFullCover", {
				text: self.$i18n.t("notification.loading.update"),
				type: "loading",
				timeout: 0,
				unix: now,
			});

			updateStudentsForGroupLesson({
				students: studentIds,
				configId: self.lessonDetail.lessonScheduleConfigId,
			})
				.then((res) => {
					console.log(
						"updateStudentsForGroupLesson 成功: ",
						res.data
					);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.success.update"),
						type: "success",
						unix: now,
					});

					self.showSelectStudents = false;
				})
				.catch((err) => {
					console.log("updateStudentsForGroupLesson 失败: ", err);
					self.$bus.$emit("hideFullCover", {
						message: self.$i18n.t("notification.failed.update"),
						type: "error",
						unix: now,
					});
				});
		},
		onClickMonitorItem(data) {
			let self = this;
			console.log(data);
			if (self.isNull(data)) {
				self.showLessonDetailForMonitorItem = false;
			} else {
				self.initLessonDetailForMonitorItem(data);
			}
		},
		async onClickShare(data) {
			let self = this;
			let now = self.$moment().unix();
			let linkCache =
				(await self.$tools.getCache("temp_lessonLinksMap")) ?? {};

			if (self.$tools.isNull(linkCache[data?.lessonScheduleConfigId])) {
				// 生成短链接

				self.$bus.$emit("showFullCover", {
					text: "Generating link...",
					type: "loading",
					timeout: 0,
					unix: now,
				});

				self.closeLessonPreview();

				self.$axios
					.post(`${url}`, {
						suffix: {
							option: "SHORT",
						},
						dynamicLinkInfo: {
							domainUriPrefix: "https://tunekey.app/link",
							// link: "https://tunekey.app/join/groupLesson/10897",
							link: `https://tunekey.app/join/groupLesson/${data.lessonScheduleConfigId}`,
							androidInfo: {
								androidPackageName: "com.spelist.tunekey",
								androidFallbackLink: "",
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
								socialTitle: "Join Group Lesson",
								socialDescription: "",
								socialImageLink: "",
							},
						},
					})
					.then(async (res) => {
						if (res?.data?.shortLink) {
							console.log("shortLink: ", res.data.shortLink);
							linkCache[data?.lessonScheduleConfigId] =
								res.data.shortLink;
							self.$tools.setCache(
								"temp_lessonLinksMap",
								linkCache
							);

							self.$bus.$emit("hideFullCover", {
								message: self.$i18n.t(
									"notification.success.share"
								),
								type: "success",
								unix: now,
							});
						}
					})
					.catch((err) => {
						console.log("生成短连接失败: ", err);
						self.$bus.$emit("hideFullCover", {
							message: self.$i18n.t("notification.failed.share"),
							type: "error",
							unix: now,
						});
					});
			}
		},
		onClickEdit(data) {
			let self = this;
			self.lessonDetail = self.$tools.equalValue(data);
			self.getSelectTime(self.lessonDetail);
			self.showEditSchedule = true;
			console.log("lessonDetail: ", self.lessonDetail);
		},
		onClickAddLocation(data) {
			let self = this;
			self.lessonDetail = self.$tools.equalValue(data);
			self.getSelectTime(self.lessonDetail);
			self.showEditSchedule = true;
			self.showLocation = true;
			console.log("lessonDetail: ", self.lessonDetail);
		},
		onClickCancel(data) {
			let self = this;
			self.eventMode = data;
			self.alert.show = true;
			self.alert.title = self.$i18n.t("calendar.cancel_lesson") + "?";
			self.alert.content = self.$i18n.t("alert").cancel_lesson({
				mode: self.eventMode,
			});
			self.alert.left = self.$i18n.t("general.cancel_anyway");
			self.alert.right = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-red";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				// if (
				//   self.lessonConfigsMap[self.lessonDetail.lessonScheduleConfigId]
				//     ?.lessonCategory == self.$dataModules.lessonType.category.group
				// ) {
				//   self.deleteGroupLesson();
				// } else {
				self.cancelLesson();
				// }
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
			};
		},
		onClickNoShow(data, type) {
			let self = this;
			self.alert.show = true;
			self.alert.title = data ? "Report No-show" : "Update No-show";
			self.alert.content = "";
			self.alert.isNoShow = true;
			self.alert.left = self.$i18n.t("general.go_back");
			self.alert.right = self.$i18n.t("general.confirm");
			self.alert.leftClass = "tk-font-color-main";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				self.alert.show = false;
				self.alert.isNoShow = false;
			};
			self.alert.onRightTap = async () => {
				await self.reportNoShow(data, type);
				self.alert.isNoShow = false;
			};
		},
		onRescheduleClick(data) {
			let self = this;

			self.getSelectTime(self.lessonDetail);
			console.log("onRescheduleClick: ", data);

			self.eventMode = data;
			self.showReschedule = true;
			self.isRescheduleAllLesson = data == self.eventModeType.all;
		},
		onClickArchive(data) {
			let self = this;
			console.log("onClickArchive: ", data);
			self.alert.title = self.$i18n.t("general.archive") + "?";
			self.alert.content = self.$i18n.t("alert.archive");
			self.alert.left = self.$i18n.t("general.archive");
			self.alert.right = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-red";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.show = true;
			self.alert.onLeftTap = () => {
				if (
					data.dataType ==
					self.$dataModules.followUp.dataType.cancellation
				) {
					self.archiveCanceledLesson(data.id);
				} else if (
					data.dataType == self.$dataModules.followUp.dataType.noshows
				) {
					self.archiveNoShowLesson(data.id);
				}
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
			};
		},
		async onClickMakeup(data) {
			let self = this;
			console.log("onClickMakeup: ", data);

			self.lessonDetail =
				data.column == self.$dataModules.followUp.column.cancelled
					? data.data?.oldSchedule ??
					  (await self.$scheduleService.lessonScheduleAction.get(
							data.data.oldScheduleId
					  ))
					: data.data?.lessonSchedule ??
					  (await self.$scheduleService.lessonScheduleAction.get(
							data.data.lessonScheduleId
					  ));

			self.currentFollowUpId = data.id;
			self.isMakeupCancelation =
				data.column == self.$dataModules.followUp.column.cancelled;
			self.isMakeupNoShow =
				data.column == self.$dataModules.followUp.column.noshows;

			self.getSelectTime(self.lessonDetail);

			self.showReschedule = true;
			self.$forceUpdate();
		},
		onClickCredit(data) {
			let self = this;
			self.alert.show = true;
			self.alert.title = "Add Credit?";
			self.alert.content = "Are you sure you want to add a credit?";
			self.alert.left = "ADD CREDIT";
			self.alert.right = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-main";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				self.addCredit(data);
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
			};
		},
		onClickRefund(data) {
			let self = this;
			console.log("onClickRefund: ", data);
			self.$notify({
				message: "接口待接入",
				type: "info",
			});
		},
		onClickRetract(data) {
			let self = this;
			self.alert.show = true;
			self.alert.title = self.$i18n.t("general.retract") + "?";
			self.alert.content = self.$i18n.t(
				"alert.retract_reschedule_lesson"
			);
			self.alert.left = self.$i18n.t("general.retract");
			self.alert.right = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-red";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				self.retractReschedule(data);
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
			};
		},
		onClickCancelLesson(data) {
			let self = this;
			self.alert.show = true;
			self.alert.title = self.$i18n.t("calendar.cancel_lesson") + "?";
			self.alert.content = self.$i18n.t("alert").cancel_lesson({
				mode: self.$dataModules.lessonCancelation.mode.current,
			});
			self.alert.left = self.$i18n.t("general.cancel");
			self.alert.right = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-red";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				self.cancelLesson(data);
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
			};
		},
		onClickStudentCancelNewLesson(data) {
			let self = this;
			self.alert.show = true;
			self.alert.title = self.$i18n.t("calendar.cancel_lesson") + "?";
			self.alert.content = self.$i18n.t("alert").cancel_lesson({
				mode: self.$dataModules.lessonCancelation.mode.current,
			});
			self.alert.left = self.$i18n.t("general.cancel");
			self.alert.right = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-red";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				self.studentCancelNewLessonRequest(data);
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
			};
		},
		async onClickChange(data) {
			let self = this;
			let now = self.$moment().unix();
			self.lessonDetail =
				data?.dataType ==
				self.$dataModules.followUp.dataType.studentLessonConfigRequests
					? {
							...data?.data?.config,
							shouldDateTime: data?.data?.config?.startDateTime,
							newLessonFromStudent: true,
					  }
					: await self.$scheduleService.lessonScheduleAction.get(
							data.data.scheduleId
					  );

			self.selectedTime = {
				isPast:
					data?.data?.timeAfter > 0
						? data?.data?.timeAfter < now
						: self.lessonDetail?.shouldDateTime < now,
				timeStr:
					data?.data?.timeAfter > 0
						? self
								.$moment(data?.data?.timeAfter * 1000)
								.format("h:mmA")
						: self
								.$moment(
									self.lessonDetail?.shouldDateTime * 1000
								)
								.format("h:mmA"),
				timestamp:
					data?.data?.timeAfter > 0
						? data?.data?.timeAfter
						: self.lessonDetail?.shouldDateTime,
				ymd:
					data?.data?.timeAfter > 0
						? self
								.$moment(data?.data?.timeAfter * 1000)
								.format("YYYY/M/D")
						: self
								.$moment(
									self.lessonDetail.shouldDateTime * 1000
								)
								.format("YYYY/M/D"),
			};

			self.isChangeReschedule =
				data?.dataType !=
				self.$dataModules.followUp.dataType.studentLessonConfigRequests;
			// self.followUpId = data.id;
			self.currentFollowUpId = data.id;
			self.showReschedule = true;
			console.log("onClickChange:", data);
			self.$forceUpdate();
		},
		async onClickReschedule(data) {
			let self = this;
			let now = self.$moment().unix();
			self.lessonDetail =
				await self.$scheduleService.lessonScheduleAction.get(
					data.data.scheduleId
				);

			self.selectedTime = {
				isPast:
					data?.data?.timeAfter > 0
						? data?.data?.timeAfter < now
						: self.lessonDetail?.shouldDateTime < now,
				timeStr:
					data?.data?.timeAfter > 0
						? self
								.$moment(data?.data?.timeAfter * 1000)
								.format("h:mmA")
						: self
								.$moment(
									self.lessonDetail?.shouldDateTime * 1000
								)
								.format("h:mmA"),
				timestamp:
					data?.data?.timeAfter > 0
						? data?.data?.timeAfter
						: self.lessonDetail?.shouldDateTime,
				ymd:
					data?.data?.timeAfter > 0
						? self
								.$moment(data?.data?.timeAfter * 1000)
								.format("YYYY/M/D")
						: self
								.$moment(
									self.lessonDetail.shouldDateTime * 1000
								)
								.format("YYYY/M/D"),
			};

			self.isChangeReschedule = true;
			// self.followUpId = data.id;
			self.currentFollowUpId = data.id;
			self.showReschedule = true;
			console.log("onClickReschedule:", data);
			self.$forceUpdate();
		},
		async onClickConfirm(data) {
			let self = this;
			console.log("onClickConfirm: ", data);
			self.alert.show = true;
			self.alert.title = self.$i18n.t("general.confirm") + "?";
			self.alert.content = !data?.confirmImmediately
				? self.$i18n.t("alert.confirm_reschedule_lesson")
				: self.$i18n.t("alert.confirm_reschedule_lesson_immediately");
			self.alert.right = self.$i18n.t("general.confirm");
			self.alert.left = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-main";
			self.alert.rightClass = "tk-font-color-white";

			self.alert.onLeftTap = () => {
				self.alert.show = false;
			};
			self.alert.onRightTap = () => {
				if (
					data?.dataType ==
					self.$dataModules.followUp.dataType
						.studentLessonConfigRequests
				) {
					self.progressStudentNewLessonRequest(data, "CONFIRM");
				} else {
					self.confirmReschedule(data);
				}
			};
		},
		async onClickDecline(data) {
			let self = this;
			console.log("onClickDecline: ", data);
			self.alert.show = true;
			self.alert.title = self.$i18n.t("general.decline") + "?";
			self.alert.content = "Are you sure you want to decline the event?";
			self.alert.left = self.$i18n.t("general.decline");
			self.alert.right = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-red";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				if (
					data?.dataType ==
					self.$dataModules.followUp.dataType
						.studentLessonConfigRequests
				) {
					self.progressStudentNewLessonRequest(data, "DECLINE");
				} else {
					self.declineReschedule(data);
				}
			};
			self.alert.onRightTap = () => {
				self.alert.show = false;
			};
		},
		async onClickIgnore(data) {
			let self = this;
			self.alert.show = true;
			self.alert.title = self.$i18n.t("general.ignore") + "?";
			self.alert.content =
				"Are you sure you want to ignore the conflict?";
			self.alert.right = self.$i18n.t("general.ignore");
			self.alert.left = self.$i18n.t("general.go_back");
			self.alert.leftClass = "tk-font-color-main";
			self.alert.rightClass = "tk-font-color-white";
			self.alert.onLeftTap = () => {
				self.alert.show = false;
			};
			self.alert.onRightTap = () => {
				self.ignoreConflict(data);
			};
		},
		getMonitorData() {
			let self = this;
			switch (self.monitorType) {
				case 0:
					return self.lessonUnconfirmed;
				// return self.$commons.mapToArray(self.lessonUnconfirmedMap, "desc", "updateTime");
				case 1:
					return self.lessonCanceled;
				// return self.$commons.mapToArray(self.lessonCanceledMap, "desc", "updateTime");
				case 2:
					return self.lessonRescheduled;
				// return self.$commons.mapToArray(self.lessonRescheduledMap, "desc", "updateTime");
				case 3:
					return self.lessonNoShows;
				// return self.$commons.mapToArray(self.lessonNoShowsMap, "desc", "updateTime");
			}
		},
		async monitorOnChanged(
			data,
			option = { isRemove: false, isChange: false }
		) {
			let self = this;

			if (data?.id) {
				self.followUpMap[data.id] = self.$tools.equalValue(data);
			}

			if (option?.isRemove || option?.isChange) {
				delete self.followUpMap[data.id];
				delete self.lessonUnconfirmedMap[data.id];
				delete self.lessonCanceledMap[data.id];
				delete self.lessonRescheduledMap[data.id];
				delete self.lessonNoShowsMap[data.id];
				self.$forceUpdate();
			}

			if (option?.isChange) {
				self.followUpMap[data.id] = self.$tools.equalValue(data);
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(data);
				let lessonSchedule =
					await self.$scheduleService.lessonScheduleAction.get(
						lessonScheduleId
					);
				self.followUpMap[data.id].lessonConfig =
					self.lessonConfigsMap[
						lessonSchedule?.lessonScheduleConfigId
					];
			}

			switch (data.column) {
				case self.$dataModules.followUp.column.unconfirmed:
					if (!option?.isRemove) {
						self.lessonUnconfirmedMap[data.id] =
							self.$tools.equalValue(self.followUpMap[data.id]);
						if (data?.data?.oldScheduleId) {
							await self.removeCalendarEvent(
								data.data.oldScheduleId,
								true
							);
						}

						self.getFollowUpUnconfirmedEvents();
					}

					if (!option?.isChange) {
						self.updateFollowUpArray(
							self.lessonUnconfirmedMap,
							"lessonUnconfirmedMap",
							"unconfirmed"
						);
					}

					break;
				case self.$dataModules.followUp.column.cancelled:
					if (!option?.isRemove) {
						self.lessonCanceledMap[data.id] =
							self.$tools.equalValue(self.followUpMap[data.id]);
						if (data.data?.id) {
							await self.removeCalendarEvent(data.id, true);
						}
					}

					if (!option?.isChange) {
						self.updateFollowUpArray(
							self.lessonCanceledMap,
							"lessonCanceledMap",
							"canceled"
						);
					}

					break;
				case self.$dataModules.followUp.column.rescheduled:
					if (!option?.isRemove) {
						console.log("非删除 rescheduled data: ", data, data.id);
						if (data?.id) {
							self.lessonRescheduledMap[data?.id] =
								self.$tools.equalValue(data);
							await self.removeCalendarEvent(
								data?.data?.newSchedule?.id,
								true
							);
							await self.addCalendarEvent(
								data?.data?.newSchedule,
								true
							);
						}
					}

					if (option?.isChange) {
						console.log(
							"非 change rescheduled data: ",
							data,
							data.id
						);
						self.updateFollowUpArray(
							self.lessonRescheduledMap,
							"lessonRescheduledMap",
							"rescheduled"
						);
					}

					break;
				case self.$dataModules.followUp.column.noshows:
					if (!option?.isRemove) {
						self.lessonNoShowsMap[data.id] = self.$tools.equalValue(
							self.followUpMap[data.id]
						);
					}

					if (!option?.isChange) {
						self.updateFollowUpArray(
							self.lessonNoShowsMap,
							"lessonNoShowsMap",
							"noShows"
						);
					}

					break;
			}

			console.log("colum: ", self.followUpMap[data.id]?.column);

			if (option?.isChange) {
				Promise.all([
					self.updateFollowUpArray(
						self.lessonUnconfirmedMap,
						"lessonUnconfirmedMap",
						"unconfirmed"
					),
					self.updateFollowUpArray(
						self.lessonCanceledMap,
						"lessonCanceledMap",
						"canceled"
					),
					self.updateFollowUpArray(
						self.lessonRescheduledMap,
						"lessonRescheduledMap",
						"rescheduled"
					),
					self.updateFollowUpArray(
						self.lessonNoShowsMap,
						"lessonNoShowsMap",
						"noShows"
					),
				]);
			}
		},
		// 初始化 monitor
		async initMonitor() {
			let self = this;
			console.log("init monitor ---");

			if (self.$tkVersion.isNew) {
				self.eventModeType = self.$dataModules.lessonCancelation.mode;
				self.lessonUnconfirmedMap = {};
				self.lessonCanceledMap = {};
				self.lessonRescheduledMap = {};
				self.lessonNoShowsMap = {};

				if (self.$commons.userIsInstructor(self.userInfo)) {
					await Promise.all([
						self.initUnconfirmed(),
						self.initRescheduled(),
						self.initCanceled(),
						self.initNoShows(),
					]);
				} else {
					await self.initPending();
				}
			}
		},
		// 更新 follow up 数组
		async updateFollowUpArray(dataMap, mapName, amountName) {
			let self = this;
			let arr = self.$commons.mapToArray(dataMap);
			// console.log(mapName, dataMap);

			self[mapName] = dataMap;

			arr.sort((a, b) => {
				return b.updateTime - a.updateTime;
			});

			self[amountName] =
				amountName == "rescheduled"
					? self.$commons
							.mapToArray(self[mapName])
							.filter(
								(item) =>
									(!item?.data?.teacherRead &&
										item.teacherId ==
											self.userInfo.userId &&
										self.userInfo?.roleIds?.indexOf(
											self.$dataModules.user.roleId
												.instructor
										) > -1) ||
									(!item?.data?.studioManagerRead &&
										self.userInfo?.roleIds?.indexOf(
											self.$dataModules.user.roleId
												.studioManager
										) > -1)
							).length
					: self.$commons
							.mapToArray(self[mapName])
							.filter(
								(item) =>
									item.status !==
										self.$dataModules.followUp.status
											.ignored &&
									item.status !==
										self.$dataModules.followUp.status
											.archived &&
									item.status !==
										self.$dataModules.followUp.status.read
							)?.length ?? 0;

			switch (mapName) {
				case "lessonUnconfirmedMap":
					self.lessonUnconfirmed = self.$tools.equalValue(arr);
					break;
				case "lessonNoShowsMap":
					self.lessonNoShows = self.$tools.equalValue(arr);
					break;
				case "lessonRescheduledMap":
					self.lessonRescheduled = self.$tools.equalValue(arr);
					break;
				case "lessonCanceledMap":
					self.lessonCanceled = self.$tools.equalValue(arr);
					break;
			}

			self.$tools.setCache("temp_" + amountName, self[amountName]);
			self.$tools.setCache("fw_up", self.followUpMap);
			self.$forceUpdate();
		},
		// 初始化 未完成的 request => student / parent
		async initPending() {
			let self = this;
			console.log("init pending request ---");

			let lessonUnconfirmedMap =
				await self.$scheduleService.lessonFollowUp({
					column: self.$dataModules.followUp.column.unconfirmed,
					online: true,
					studentIds: self.$commons.userIsStudent(self.userInfo)
						? [self.userInfo.userId]
						: self.userInfo.kids ?? [],
				});

			self.updateFollowUpArray(
				lessonUnconfirmedMap,
				"lessonUnconfirmedMap",
				"unconfirmed"
			);
		},
		// 初始化 未完成的 request => instructor
		async initUnconfirmed() {
			let self = this;

			let lessonUnconfirmedMap =
				await self.$scheduleService.lessonFollowUp({
					column: self.$dataModules.followUp.column.unconfirmed,
					online: true,
					studioId: self.$commons.instructorIsManagerInStudio(
						self.studioInfo,
						self.userInfo
					)
						? self.studioInfo?.id
						: "",
				});

			let getLessonSchedule = [];
			let lessonSchedulesMap = {};

			Object.keys(lessonUnconfirmedMap).forEach(async (key) => {
				let followUp = lessonUnconfirmedMap[key];
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(followUp);
				getLessonSchedule.push(
					self.$scheduleService.lessonScheduleAction.get(
						lessonScheduleId
					)
				);
			});

			await Promise.all(getLessonSchedule).then((results) => {
				results.forEach((res) => {
					if (res?.id) {
						lessonSchedulesMap[res?.id] = res;
					}
				});
			});

			Object.keys(lessonUnconfirmedMap).forEach((key) => {
				let followUp = lessonUnconfirmedMap[key];
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(followUp);
				lessonUnconfirmedMap[key].lessonConfig =
					self.lessonConfigsMap[
						lessonSchedulesMap[
							lessonScheduleId
						]?.lessonScheduleConfigId
					];
				lessonUnconfirmedMap[key].lessonScheduleId = lessonScheduleId;

				if (
					!lessonSchedulesMap[lessonScheduleId] &&
					followUp.dataType !=
						self.$dataModules.followUp.dataType
							.studentLessonConfigRequests
				) {
					delete lessonUnconfirmedMap[key];
				}
			});

			self.updateFollowUpArray(
				lessonUnconfirmedMap,
				"lessonUnconfirmedMap",
				"unconfirmed"
			);

			console.log("init unconfirmed ---", self.lessonUnconfirmed);
		},
		// 初始化 已经完成 cancelation 的 lesson
		async initCanceled() {
			let self = this;
			console.log("init canceled ---");
			let lessonCanceledMap = await self.$scheduleService.lessonFollowUp({
				column: self.$dataModules.followUp.column.cancelled,
				online: true,
				studioId: self.$commons.instructorIsManagerInStudio(
					self.studioInfo,
					self.userInfo
				)
					? self.studioInfo?.id
					: "",
			});

			let getLessonSchedule = [];
			let lessonSchedulesMap = {};

			Object.keys(lessonCanceledMap).forEach(async (key) => {
				let followUp = lessonCanceledMap[key];
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(followUp);
				getLessonSchedule.push(
					self.$scheduleService.lessonScheduleAction.get(
						lessonScheduleId
					)
				);
			});

			let uncancelledLessonIds = [];
			await Promise.all(getLessonSchedule).then((results) => {
				results.forEach((res) => {
					if (res?.id) {
						lessonSchedulesMap[res?.id] = {
							...res,
							cancelled: true,
						};

						if (!res?.cancelled) {
							uncancelledLessonIds.push(res?.id);
						}
					}
				});
			});

			if (uncancelledLessonIds?.length > 0) {
				console.log("uncancelledLessonIds: ", uncancelledLessonIds);
				// await Promise.all(uncancelledLessonIds.map(async id => {self.$scheduleService.lessonScheduleAction.update(id, {
				//   cancelled: true
				// })}))
			}

			Object.keys(lessonCanceledMap).forEach((key) => {
				let followUp = lessonCanceledMap[key];
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(followUp);
				lessonCanceledMap[key].lessonConfig =
					self.lessonConfigsMap[
						lessonSchedulesMap[
							lessonScheduleId
						]?.lessonScheduleConfigId
					];
				lessonCanceledMap[key].lessonScheduleId = lessonScheduleId;

				// if (!self.$tools.isNull(lessonCanceledMap[key].lessonConfig)) {
				//   console.log("lesson cancel config: ", lessonCanceledMap[key].lessonConfig)
				// }
			});

			self.updateFollowUpArray(
				lessonCanceledMap,
				"lessonCanceledMap",
				"canceled"
			);
		},
		// 初始化 已经完成 reschedule 的 lesson
		async initRescheduled(unix) {
			let self = this;
			let lessonRescheduledMap =
				await self.$scheduleService.lessonFollowUp({
					column: self.$dataModules.followUp.column.rescheduled,
					online: true,
					unix: unix,
					studioId: self.$commons.instructorIsManagerInStudio(
						self.studioInfo,
						self.userInfo
					)
						? self.studioInfo?.id
						: "",
				});

			let getLessonSchedule = [];
			let lessonSchedulesMap = {};

			Object.keys(lessonRescheduledMap).forEach(async (key) => {
				let followUp = lessonRescheduledMap[key];
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(followUp);
				getLessonSchedule.push(
					self.$scheduleService.lessonScheduleAction.get(
						lessonScheduleId
					)
				);
			});

			await Promise.all(getLessonSchedule).then((results) => {
				results.forEach((res) => {
					if (res?.id) {
						lessonSchedulesMap[res?.id] = res;
					}
				});
			});

			if (!self.$tools.isNull(lessonRescheduledMap)) {
				Object.keys(lessonRescheduledMap).forEach((key) => {
					let followUp = lessonRescheduledMap[key];
					let lessonScheduleId =
						self.getLessonScheduleIdInMonitorItem(followUp);
					lessonRescheduledMap[key].lessonConfig =
						self.lessonConfigsMap[
							lessonSchedulesMap[
								lessonScheduleId
							]?.lessonScheduleConfigId
						];
					lessonRescheduledMap[key].lessonScheduleId =
						lessonScheduleId;
				});

				self.updateFollowUpArray(
					lessonRescheduledMap,
					"lessonRescheduledMap",
					"rescheduled"
				);

				console.log("init rescheduled ---", self.lessonRescheduled);
			}
		},
		// 初始化 no-show 的 lesson
		async initNoShows() {
			let self = this;
			console.log("init noshows ---");
			let lessonNoShowsMap = await self.$scheduleService.lessonFollowUp({
				column: self.$dataModules.followUp.column.noshows,
				online: true,
				studioId: self.$commons.instructorIsManagerInStudio(
					self.studioInfo,
					self.userInfo
				)
					? self.studioInfo?.id
					: "",
			});

			let getLessonSchedule = [];
			let lessonSchedulesMap = {};

			Object.keys(lessonNoShowsMap).forEach(async (key) => {
				let followUp = lessonNoShowsMap[key];
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(followUp);
				getLessonSchedule.push(
					self.$scheduleService.lessonScheduleAction.get(
						lessonScheduleId
					)
				);
			});

			await Promise.all(getLessonSchedule).then((results) => {
				results.forEach((res) => {
					if (res?.id) {
						lessonSchedulesMap[res?.id] = res;
					}
				});
			});

			Object.keys(lessonNoShowsMap).forEach(async (key) => {
				let followUp = lessonNoShowsMap[key];
				let lessonScheduleId =
					self.getLessonScheduleIdInMonitorItem(followUp);

				lessonNoShowsMap[key].lessonConfig =
					self.lessonConfigsMap[
						lessonSchedulesMap[
							lessonScheduleId
						]?.lessonScheduleConfigId
					];
				lessonNoShowsMap[key].lessonScheduleId = lessonScheduleId;
			});

			self.updateFollowUpArray(
				lessonNoShowsMap,
				"lessonNoShowsMap",
				"noShows"
			);
		},
		// 首字母大写
		makeFirstLetterUpper(str) {
			return this.$tools.makeFirstLetterUpper(str.trim());
		},
		moment(param) {
			return this.$moment(param);
		},
		// 初始化日历属性
		initOptions() {
			let self = this;

			self.closeLessonPreview();

			self.calendarApi().destroy();

			self.calendarApi().setOption(
				"eventClassNames",
				"tk-cursor-pointer " + self.defaultView
			);
			// self.calendarApi().setOption(
			//   "eventTimeFormat",
			//   self.defaultView == self.viewType.month
			//     ? {
			//         hour: "numeric",
			//         minute: "2-digit",
			//         omitZeroMinute: true,
			//         meridiem: "narrow",
			//       }
			//     : {
			//         hour: "numeric",
			//         minute: "2-digit",
			//         // meridiem: "short",
			//       }
			// );
			self.calendarApi().setOption(
				"dayHeaderFormat",
				self.defaultView == self.viewType.month
					? { weekday: "short" }
					: {
							weekday:
								self.defaultView == self.viewType.day
									? "long"
									: "short",
							month: "numeric",
							day: "numeric",
							omitCommas: true,
					  }
			);
			self.calendarApi().setOption(
				"slotMinTime",
				self.businessHours.startTime
			);
			self.calendarApi().setOption(
				"slotMaxTime",
				self.businessHours.endTime
			);
			self.calendarApi().setOption("now", new Date());
			self.calendarApi().setOption("initialView", self.defaultView);

			self.calendarApi().setOption(
				"eventMaxStack",
				self.defaultView == self.viewType.month
					? null
					: self.defaultView == self.viewType.week
					? 1
					: 7
			);

			self.calendarApi().render();
			self.$forceUpdate();
		},
		// 日历渲染完毕触发
		viewDidMount(arg) {
			this.setCalendarHeight();
			$(".tk-daygrid-add").remove();

			let addDom =
				"" +
				"<div class='tk-text-center tk-font-color-main tk-daygrid-add tk-position-absolute tk-px-width-px24 tk-px-height-px24  tk-px-border-px2 tk-px-radius-px24 tk-cursor-pointer' style='right: 0; top: 0; display: none'>" +
				"<span class='tk-position-center tk-text-lg-bold'>+</span>" +
				"</div>";

			$("td.fc-day-future").append(addDom);
			$("td.fc-day-today").append(addDom);
		},
		// 设置日历高度
		setCalendarHeight() {
			// this.calendarApi().setOption("contentHeight", $(window).height() - 120);
			this.calendarApi().setOption(
				"contentHeight",
				$(window).height() - 100
			);
			this.calendarApi().render();
		},
		// 获取选择的时间
		getSelectTime(data, callback) {
			let self = this;
			if (data?.shouldDateTime) {
				self.selectedTime.isPast =
					data.shouldDateTime < self.$moment().unix();
				self.selectedTime.timeStr = self
					.$moment(data.shouldDateTime * 1000)
					.format("h:mmA");
				self.selectedTime.timestamp = data?.shouldDateTime;
				self.selectedTime.ymd = self
					.$moment(data.shouldDateTime * 1000)
					.format("YYYY/M/D");
			} else {
				if (!self.selectedTime.isPast) {
					if (self.$commons.userIsInstructor(self.userInfo)) {
						if (self.$tools.objIsNull(self.studentsListMap)) {
							self.$notify({
								message: "Please add a student first!",
								type: "warning",
							});
							return false;
						}
					} else {
						if (Object.keys(self.studiosMap ?? {}).length == 0) {
							self.$notify({
								message: "You have no instructor!",
								type: "warning",
							});
							return false;
						}
					}

					self.showCreateNewSchedule = true;
				}
			}

			console.log("getSelectTime: ", self.selectedTime);
		},
		// 隐藏 timeGrid 下 具体时间
		hideDetailTime() {
			let self = this;
			$("#tkDetailTime").css({
				opacity: 0,
				top: 0,
				left: 0,
				zIndex: -10,
				display: "none",
			});

			self.showDetailTime = false;
		},
		// 具体时间段上滚动时触发
		scrollOnDetailTime(ev) {
			let self = this,
				e = ev || window.event;
			let scrollTop =
				$(".fc-scroller.fc-scroller-liquid-absolute")[0].scrollTop +
				e.deltaY;

			self.hideDetailTime();
			$(".fc-scroller.fc-time-grid-container").stop().animate(
				{
					scrollTop: scrollTop,
				},
				Math.abs(e.deltaY)
			);
		},
		// 鼠标在 dayGrid 下的移动事件
		mouseMoveDayGrid() {
			let self = this;
			$(document).on("mouseover", "td.fc-day", (ev) => {
				if (self.defaultView == self.viewType.month) {
					$(".tk-daygrid-add").stop().hide();
					let parents = $(ev.target).parents();
					for (let i = 0; i < parents.length; i++) {
						if (
							parents[i].nodeName.toLowerCase() == "td" &&
							(parents.eq(i).hasClass("fc-day-today") ||
								parents.eq(i).hasClass("fc-day-future"))
						) {
							parents.eq(i).find(".tk-daygrid-add").show();
							break;
						}
					}
				} else {
					$(".tk-daygrid-add").stop().hide();
				}
			});

			$(document).on("mouseout", "td.fc-day", (ev) => {
				$(".tk-daygrid-add").stop().hide();
			});
		},
		// 鼠标在 timeGrid 下的移动事件
		mouseMoveTimeGrid() {
			let self = this;
			let hhmm,
				hr,
				min,
				top = 0,
				left = 0,
				timeStr = "";
			let downTime = 0;

			$("#tkCalendar").mousemove(async (ev) => {
				if (self.defaultView !== self.viewType.month) {
					downTime = 0;
					let e = ev || window.event;
					let target = ev.target,
						elClassName = target.className,
						elNodeName = target.nodeName;

					if (
						elClassName.indexOf("fc-timegrid-slot-lane") > -1 &&
						e.clientX <= $("#tkCalendar").width() + 270 &&
						elClassName.indexOf("fc-more-link") < 0
					) {
						let isTimeGrid = true;

						if (
							!self.isNull(target.firstElementChild) &&
							target.firstElementChild.className.indexOf(
								"fc-scroller"
							) > 0
						) {
							isTimeGrid = false;
						}

						if (isTimeGrid) {
							let width = 0,
								axisW = $(".fc-timegrid-slot-label")
									.eq(0)
									.width();
							let elRect = target.getBoundingClientRect();
							let timeElRect = document
								.getElementById("tkDetailTime")
								.getBoundingClientRect();
							let tr = target.getBoundingClientRect();
							// let tr = target.parentElement.getBoundingClientRect();
							let offsetY = e.clientY - elRect.top;
							let offsetX = e.clientX;

							let firstViewDayTime = !self.isNull(
								self.currentViewDays[0]
							)
								? self.currentViewDays[0].getTime()
								: 0;

							if (self.defaultView == self.viewType.week) {
								// week
								let baseWidth = tr.width / 7;
								// width = baseWidth - 18;
								width = baseWidth;
								top = tr.top;

								// let baseLeft = tr.left + axisW + 12;
								let baseLeft = tr.left;

								if (
									offsetX >= baseLeft &&
									offsetX <= baseLeft + baseWidth
								) {
									// left = baseLeft + 4;
									left = baseLeft;
									self.selectedTime.ymd =
										self.$commons.formatYMD(
											firstViewDayTime
										);
								} else if (
									offsetX > baseLeft + baseWidth &&
									offsetX <= baseLeft + baseWidth * 2
								) {
									// left = baseLeft + 4 * 2 + width + 8;
									left = baseLeft + width;
									self.selectedTime.ymd =
										self.$commons.formatYMD(
											firstViewDayTime
										) + "+1";
								} else if (
									offsetX > baseLeft + baseWidth * 2 &&
									offsetX <= baseLeft + baseWidth * 3
								) {
									// left = baseLeft + 4 * 3 + width * 2 + 8 * 2;
									left = baseLeft + width * 2;
									self.selectedTime.ymd =
										self.$commons.formatYMD(
											firstViewDayTime
										) + "+2";
								} else if (
									offsetX > baseLeft + baseWidth * 3 &&
									offsetX <= baseLeft + baseWidth * 4
								) {
									// left = baseLeft + 4 * 4 + width * 3 + 8 * 3;
									left = baseLeft + width * 3;
									self.selectedTime.ymd =
										self.$commons.formatYMD(
											firstViewDayTime
										) + "+3";
								} else if (
									offsetX > baseLeft + baseWidth * 4 &&
									offsetX <= baseLeft + baseWidth * 5
								) {
									// left = baseLeft + 4 * 5 + width * 4 + 8 * 4;
									left = baseLeft + width * 4;
									self.selectedTime.ymd =
										self.$commons.formatYMD(
											firstViewDayTime
										) + "+4";
								} else if (
									offsetX > baseLeft + baseWidth * 5 &&
									offsetX <= baseLeft + baseWidth * 6
								) {
									// left = baseLeft + 4 * 6 + width * 5 + 8 * 5;
									left = baseLeft + width * 5;
									self.selectedTime.ymd =
										self.$commons.formatYMD(
											firstViewDayTime
										) + "+5";
								} else if (offsetX > baseLeft + baseWidth * 6) {
									// left = baseLeft + 4 * 7 + width * 6 + 8 * 6;
									left = baseLeft + width * 6;
									self.selectedTime.ymd =
										self.$commons.formatYMD(
											firstViewDayTime
										) + "+6";
								}
							} else if (self.defaultView == self.viewType.day) {
								// day
								width = $(".fc-timegrid-slot-lane")
									.eq(0)
									.width();
								left = tr.left;
								top = tr.top;

								self.selectedTime.ymd =
									self.$commons.formatYMD(firstViewDayTime);
							}

							hhmm = target.dataset.time;
							self.showDetailTime = true;
							if (!self.isNull(hhmm)) {
								timeStr = "";
								let hhmmArr = hhmm.split(":");
								hr = parseInt(hhmmArr[0]);
								min = parseInt(hhmmArr[1]);
								let timeStrMin = "";
								let timeStrHr = "";

								if (offsetY < 0) {
									timeStrHr = min == 30 ? hr : hr - 1;

									if (parseInt(timeStrHr) == parseInt(hr)) {
										timeStrMin = "30";
									} else {
										timeStrMin = "59";
									}

									if (parseInt(timeStrHr) > 12) {
										timeStrHr = parseInt(timeStrHr) - 12;
									}
								} else {
									if (hr > 12) {
										timeStrHr = hr - 12;
									} else {
										timeStrHr = hr;
									}

									let m = min + offsetY;

									if (min == 30) {
										if (m > 59) {
											timeStrMin = 59;
										} else {
											timeStrMin = m;
										}
									} else {
										if (m < 10) {
											timeStrMin = m;
										} else if (m > 30) {
											timeStrMin = "29";
										} else {
											timeStrMin = m;
										}
									}
								}

								if (
									parseInt(timeStrMin) >= 0 &&
									parseInt(timeStrMin) < 15
								) {
									timeStrMin = "00";
								} else if (
									parseInt(timeStrMin) >= 15 &&
									parseInt(timeStrMin) < 30
								) {
									timeStrMin = "15";
									top += 15;
								} else if (
									parseInt(timeStrMin) >= 30 &&
									parseInt(timeStrMin) < 45
								) {
									timeStrMin = "30";
								} else if (
									parseInt(timeStrMin) >= 45 &&
									parseInt(timeStrMin) <= 59
								) {
									timeStrMin = "45";
									top += 15;
								}

								timeStr += timeStrHr + ":" + timeStrMin;

								if (hr > 12) {
									timeStr += "PM";
								} else if (hr == 12) {
									timeStr += "PM";
								} else {
									timeStr += "AM";
								}

								$("#tkDetailTimeStr").text(
									timeStr.toUpperCase()
								);
							}

							let isCoverEvent = await self.detailTimeCoverEvent(
								top,
								left
							);

							if (isCoverEvent) {
								self.hideDetailTime();
							} else {
								$("#tkDetailTime")
									.stop()
									.hide()
									.css({
										width: width,
										top: top,
										left: left,
										opacity: 1,
										zIndex: 2,
									})
									.stop()
									.fadeIn();
							}
						}

						self.selectedTime.timeStr = timeStr;
					} else {
						self.hideDetailTime();
					}
				}
			});

			$("#tkDetailTimeSecond").mouseover((ev) => {
				downTime++;
				updateGrid(15, 13);
			});

			async function updateGrid(minutes, dis) {
				let minResult = min + minutes;
				let hrResult = hr;

				if (minResult >= 60) {
					minResult = minResult - 60;
					hrResult = hrResult + 1;
				}

				timeStr =
					(hrResult > 12 ? hrResult - 12 : hrResult) +
					":" +
					(minResult < 10 ? "0" + minResult : minResult) +
					(hrResult < 12 ? "AM" : "PM");

				// top = top + dis;
				min = minResult;
				hr = hrResult;

				let offsetTop = dis
					? top + dis * downTime
					: top + parseInt(minutes / 15) * 17;
				let offsetLeft = left;
				let isCoverEvent = await self.detailTimeCoverEvent(
					offsetTop,
					offsetLeft
				);

				if (
					parseFloat(hrResult + "." + minResult) >=
						parseFloat(
							self.businessHours.startTime.split(":")[0] +
								"." +
								self.businessHours.startTime.split(":")[1]
						) &&
					parseFloat(hrResult + "." + minResult) <
						parseFloat(
							self.businessHours.endTime.split(":")[0] +
								"." +
								self.businessHours.endTime.split(":")[1]
						) &&
					!isCoverEvent
				) {
					$("#tkDetailTimeStr").text(timeStr.toUpperCase());
					$("#tkDetailTime")
						.stop()
						.css({
							top: offsetTop,
							left: offsetLeft,
							zIndex: 2,
						})
						.stop()
						.fadeIn();
					self.selectedTime.timeStr = timeStr;
				} else {
					self.hideDetailTime();
				}

				if (isCoverEvent) {
					self.hideDetailTime();
				}
			}
		},
		// 判断时间选择是否覆盖 event
		detailTimeCoverEvent(top, left) {
			let els = $(".fc-timegrid-event-harness");
			let isCover = false;

			for (let i = 0; i < els.length; i++) {
				let item = els.eq(i).get(0);
				let rect = item.getBoundingClientRect();
				let height = rect.height;
				let itemTop = rect.top;
				let itemLeft = rect.left;
				let topMinus = Math.abs(itemTop - top);
				let leftMinus = Math.abs(itemLeft - left);

				if (
					(topMinus <= 16 ||
						(top >= itemTop && top <= itemTop + height)) &&
					leftMinus <= 16
				) {
					isCover = true;
					break;
				}
			}

			return isCover;
		},
		// 选择时间添加课程
		onSelect(date) {
			let self = this;

			if (self.$commons.userIsInstructor(self.userInfo)) {
				// single instructor
				if (!self.$tkVersion.isNew) {
					return false;
				}

				// access
				if (!self.allowCreateLesson) {
					return false;
				}
			} else {
				if (Object.keys(self.studiosMap)?.length == 0) {
					self.$notify({
						message: "You have not in any studios yet.",
						type: "info",
					});
					return false;
				}

				if (
					self.$commons
						.mapToArray(self.lessonTypesMap)
						?.filter(
							(item) =>
								!item.deleted &&
								(
									item.visibility ==
										self.$dataModules.lessonType.visibility
											.students ||
									item.visibility !=
										self.$dataModules.lessonType.visibility
											.anyone ||
									self.$tools.isNull(item.visibility)
								)?.length == 0
						)
				) {
					self.$notify({
						message: "Your studio have no public lessons.",
						type: "info",
					});
					return false;
				}
			}

			// month
			console.log("select date:  ", date);

			if (self.$moment(date.endStr).unix() > self.$moment().unix()) {
				self.selectedTime = {
					isPast: false,
					timeStr: "",
					timestamp:
						self.defaultView == self.viewType.month
							? 0
							: self.$moment(date.start).unix(),
					ymd: self.$moment(date.startStr).format("YYYY/M/D"),
				};

				self.getSelectTime();
			}
			// }
		},
		// 清空 filter
		resetFilter() {
			this.confirmFilter({
				usersMap: {},
				studioTagsMap: {},
				studioRoomsMap: {},
				locationsMap: {},
				lessonTypesMap: {},
			});
		},
		// 确认 filter
		confirmFilter(data) {
			let self = this;

			if (!self.isNull(data.availableHours)) {
				let businessHours = this.businessHours;
				businessHours.startTime = data.availableHours.startTime;
				businessHours.endTime = data.availableHours.endTime;
				businessHours.start = data.availableHours.start;
				businessHours.end = data.availableHours.end;

				self.$tools.setCache("temp_businessHours", businessHours);
			}

			if (data.usersMap) {
				self.filterUserMap = self.$tools.equalValue(data.usersMap);
			}

			if (data.studioTagsMap) {
				self.filterTagMap = self.$tools.equalValue(data.studioTagsMap);
			}

			if (data.studioRoomsMap) {
				self.filterRoomMap = self.$tools.equalValue(
					data.studioRoomsMap
				);
			}

			if (data.locationsMap) {
				self.filterOtherLocationMap = self.$tools.equalValue(
					data.locationsMap
				);
			}

			if (data.lessonTypesMap) {
				self.filterLessonTypeMap = self.$tools.equalValue(
					data.lessonTypesMap
				);
			}

			console.log("usersMap: ", self.filterUserMap);
			console.log("studioTagsMap: ", self.filterTagMap);
			console.log("studioRoomsMap: ", self.filterRoomMap);
			console.log("locationsMap: ", self.filterOtherLocationMap);
			console.log("lessonTypesMap: ", self.filterLessonTypeMap);

			console.log("lessonSchedulesMap: ", self.lessonSchedulesMap);

			self.initTitle({
				showFullCover: true,
				isFilter: true,
				msg: self.$i18n.t("notification.loading.filter"),
			});
		},
		// 满足 filter 条件
		meetFilter(item) {
			let self = this;
			let meetLocation = true,
				meetRoom = true,
				meetLessonType = true,
				meetUser = true,
				meetTag = true;

			// location
			if (self.$tools.objIsNull(self.filterOtherLocationMap)) {
				// 全不选, 全部匹配
				meetLocation = true;
			} else {
				meetLocation =
					(self.filterOtherLocationMap["REMOTE"] &&
						item?.location?.type ==
							self.$dataModules.lessonSchedule.locationType
								.remote) ||
					(self.filterOtherLocationMap["OTHER_PLACE"] &&
						(self.$commons.locationIsOtherPlace(item?.location) ||
							self.$commons.locationIsStudioLocation(
								item?.location
							)));
			}

			// room
			if (self.$tools.objIsNull(self.filterRoomMap)) {
				// 全不选, 全部匹配
				meetRoom = true;
			} else {
				meetRoom = self.$commons
					.mapToArray(self.filterRoomMap)
					.some(
						(room) =>
							room?.id?.indexOf("__") > 1 &&
							room?.id?.split("__")[1] ==
								(item?.location?.place || item?.location?.id)
					);
			}

			// tag
			if (self.$tools.objIsNull(self.filterTagMap)) {
				// 全不选, 全部匹配
				meetTag = true;
			} else {
				let student = self.studentsListMap[item?.studentId];
				meetTag =
					student?.tags?.length > 0 &&
					student?.tags?.some((tag) =>
						tag?.tags?.some(
							(t) =>
								!self.isNull(
									self.filterTagMap[tag.category + "__" + t]
								)
						)
					);
			}

			// filterUser
			if (self.$tools.objIsNull(self.filterUserMap)) {
				// 全不选, 全部匹配
				meetUser = true;
			} else {
				meetUser = !self.isNull(
					self.filterUserMap[item?.studentId] ||
						self.filterUserMap[item?.teacherId]
				);
				// console.log(
				//   "meet user:",
				//   self.filterUserMap[item?.studentId],
				//   self.filterUserMap[item?.studentId] ||
				//     self.filterUserMap[item?.teacherId],
				//   !self.isNull(
				//     self.filterUserMap[item?.studentId] ||
				//       self.filterUserMap[item?.teacherId]
				//   )
				// );
			}

			// filterLessonType
			if (self.$tools.objIsNull(self.filterLessonTypeMap)) {
				// 全不选, 全部匹配
				meetLessonType = true;
			} else {
				meetLessonType = !self.isNull(
					self.filterLessonTypeMap[item.lessonTypeId]
				);
			}

			return (
				meetUser &&
				meetLessonType &&
				meetRoom &&
				meetLocation &&
				meetTag
			);
		},
		// 打开当前登录用户的 profile
		showProfile() {
			this.$bus.$emit("showProfile");
		},
		// 更新 color Setting
		confirmColorSetting() {
			let self = this;
		},
		// 日历 event 内容
		onEventContent(arg) {},
		// 日历 渲染 event
		async onEventRender(arg) {
			let self = this;
			let el = arg.el,
				event = arg.event,
				data = event?.extendedProps?.data,
				type = event?.extendedProps?.type;

			if (type == "GOOGLE_EVENTS") {
				// console.log(el);
				let container =
					$(el).find(".fc-event-time")?.length > 0
						? $(el).find(".fc-event-time")
						: $(el).find(".fc-event-main-frame");
				container.prepend(
					"<div class='tk-px-width-px16 tk-px-height-px16 tk-px-margin-right-px3 tk-px-radius-px16 tk-bg-color-white tk-px-margin-top-px2 tk-font-lineHeight-1 tk-layout-inline-block'><img src='/img/brand/ic_google.png' class='tk-px-width-px16 tk-px-height-px16'></div>"
				);
			}

			if (
				data?.rescheduled ||
				(!self.$tools.isNull(data?.data?.timeBefore) &&
					self.defaultView != self.viewType.month)
			) {
				// rescheduled
				// ? For 4:30pm,1/22
				// ? Was 4:30pm,1/22

				let config = data?.rescheduled
					? self.lessonConfigsMap[data?.lessonScheduleConfigId]
					: data?.config;

				let timeUnix =
					(data?.rescheduled
						? self.lessonUnconfirmed?.filter(
								(item) => item?.data?.scheduleId == data?.id
						  )[0]?.data?.timeAfter * 1
						: data?.data?.timeBefore * 1) ?? null;

				let displayTtime = self.$commons.getLessonShouldDateTime(
					{
						type: 0,
						shouldDateTime: timeUnix,
					},
					config ?? {}
				);

				let timeStr = !self.$tools.isNull(displayTtime)
					? self
							.$momentTimezone(displayTtime * 1000)
							.tz(self.$commons.getTz())
							.format("h:mmA, M/D")
					: "";

				console.log(
					"render rescheduled event: ",
					data,
					timeUnix,
					timeStr
				);

				let dom = self.$tools.isNull(timeStr)
					? `<div class='tk-font-color-black2 tk-font-lineHeight-1 tk-text-xxs'>For ? </div>`
					: `<div class='tk-font-color-black2 tk-font-lineHeight-1 tk-text-xxs'>? ${
							data?.rescheduled ? "For" : "Was"
					  } ${timeStr}</div>`;
				let container = $(el).find(".fc-event-main");
				container.append(dom);
			}
		},
		// 关闭 Lesson 详情预览
		closeLessonPreview() {
			let self = this;
			self.showLessonPreview = false;
			self.hoverOnLessonDetail = false;
		},
		async initLessonDetailForEvent(event) {
			let self = this;
			let data = self.$tools.equalValue(event.extendedProps?.data);

			if (data?.shouldDateTime) {
				console.log(
					"config data",
					self.lessonConfigsMap[data.lessonScheduleConfigId],
					new Date(
						self.lessonConfigsMap[data.lessonScheduleConfigId]
							?.startDateTime * 1000
					),
					new Date(
						self.lessonConfigsMap[data.lessonScheduleConfigId]
							?.endDate * 1000
					)
				);
				console.log("lesson ->", data, new Date(event.start));
			} else {
				console.log(
					"event or unconfirmed lesson->",
					data,
					new Date(event.start)
				);
			}

			let followUp =
				self.lessonUnconfirmed?.filter(
					(item) => item?.data?.scheduleId == data?.id
				)[0] ?? null;

			self.eventId = event.id;
			self.lessonDetail =
				data?.shouldDateTime || data?.startTime
					? data
					: {
							...self.$dataModules.lessonSchedule.default,

							config: data?.config ?? null,
							lessonTypeId: data?.config?.lessonTypeId ?? null,
							color: data?.color ?? null,

							id: event.id,
							studioId: data?.studioId,
							subStudioId: data?.subStudioId,
							teacherId: data?.data?.teacherId,
							studentId: data?.studentId,
							shouldDateTime: data?.data?.timeAfter * 1,
							timeBefore: data?.data?.timeBefore * 1,
							location: data?.data?.locationAfter,
							locationBefore: data?.data?.locationBefore,
							shouldTimeLength: data?.data?.shouldTimeLength,
							// teacherBefore: "",
							// teacherAfter: "",

							isFollowUp: true,
					  };

			if (followUp) {
				self.lessonDetail.timeAfter = followUp?.data?.timeAfter;
			}
		},
		initLessonDetailPosition(ele, jsEvent) {
			let self = this;
			$(".triangle").hide();
			let rect = ele.getBoundingClientRect();

			let x = rect.x,
				y = rect.y,
				elH = rect.height,
				elW = rect.width;

			let h = $("#tkLessonPreview").height();
			let w = $("#tkLessonPreview").width();
			let winH = $(window).height();
			let winW = $(window).width();

			// 下上右左
			let isTop = false;
			if (y + h + elH > winH) {
				// 上
				y = y - h + elH + 32;
				isTop = true;
			}

			if (
				x + elW > (winW / 3) * 2 &&
				self.defaultView != self.viewType.day
			) {
				// 左
				if (x - w - 16 < 80 && jsEvent) {
					x = x + elW / 3;
					if (!isTop) {
						$(".triangle-left.triangle-top").show();
					} else {
						$(".triangle-left.triangle-bottom").show();
					}
				} else {
					x = x - w - 16;

					if (!isTop) {
						$(".triangle-right.triangle-top").show();
					} else {
						$(".triangle-right.triangle-bottom").show();
					}
				}
			} else {
				// 右
				if (self.defaultView == self.viewType.day) {
					x = x + elW / 3;
				} else {
					x = x + elW + 16;
				}

				if (!isTop) {
					$(".triangle-left.triangle-top").show();
				} else {
					$(".triangle-left.triangle-bottom").show();
				}
			}

			$("#tkLessonPreview")
				.stop()
				.animate({
					top: y + "px",
					left: x + "px",
				});

			// setTimeout(() => {
			self.showLessonPreview = true;
			// }, 100);

			self.$forceUpdate();
		},
		// 日历 event 鼠标移入事件
		onEventMouseEnter({ event, el, jsEvent, view }) {
			let self = this;
			if ($(el).hasClass("tk-cal")) {
				$(el).addClass("tk-cal-hover");
			}
		},
		// 日历 event 鼠标移出事件
		onEventMouseLeave({ event, el, jsEvent, view }) {
			$(el).removeClass("tk-cal-hover");
		},
		// 日历 event 点击事件
		async onEventClick({ event, el, jsEvent, view }) {
			let self = this;

			let evt = self.$tools.equalValue(event);
			let ele = $(el).get(0);
			let id = event?.extendedProps?.data?.id;

			if (
				self.showLessonPreview &&
				id == self.lessonDetail?.id &&
				!self.$tools.isNull(id)
			) {
				self.closeLessonPreview();
			} else {
				console.log(evt, ele, jsEvent);

				await self.initLessonDetailForEvent(evt);
				await self.initLessonDetailPosition(
					ele,
					!self.$tools.isNull(evt?.extendedProps?.type)
						? jsEvent
						: false
				);

				setTimeout(() => {
					self.initLessonDetailPosition(
						ele,
						!self.$tools.isNull(evt?.extendedProps?.type)
							? jsEvent
							: false
					);
				}, 500);
			}
		},
		// 判空
		isNull(obj) {
			return this.$tools.isNull(obj);
		},
		objIsNull(obj) {
			return this.$tools.objIsNull(obj);
		},
		async getStudioEvents(map) {
			let self = this;
			// return false

			let colorPreference =
				self.userCalendarColorPreference?.items?.filter(
					(item) =>
						item.category ==
						self.$dataModules.userCalendarColorPreference.category
							.studioEvents
				)[0];
			let colorsMap = {};

			if (
				colorPreference?.isSelected &&
				colorPreference?.colorCodes?.length > 0
			) {
				colorsMap = self.$commons.arrayToMap(
					colorPreference?.colorCodes,
					"ref"
				);
			}

			if (map) {
				self.studioEventsMap = self.$tools.equalValue(map);
			} else if (Object.keys(self.studioEventsMap)?.length == 0) {
				self.studioEventsMap = await self.$studioService.studioEvents();
			}

			let eventsMap = {};
			Object.keys(self.studioEventsMap).forEach((key) => {
				let item = self.studioEventsMap[key];

				let classNamesBasic = [
					"tk-text-xs-bold",
					"tk-text-left",
					"tk-cal-all-day",
				];

				let displayStartTime = item.startTime;
				let displayEndTime =
					item.endTime > 0
						? self
								.$moment(item.endTime * 1000)
								.add(1, "days")
								.startOf("date")
								.unix()
						: self
								.$moment()
								.add(1000, "years")
								.endOf("date")
								.unix();

				let eventItem = {
					id: item.id,
					title: item.title, // title
					classNames: classNamesBasic,
					start: displayStartTime * 1000,
					end: displayEndTime * 1000,
					allDay: true,
					display: "block",
					backgroundColor: `#${
						colorsMap[item.id]
							? colorsMap[item.id]?.block
							: item.color || "71d9c2"
					}`,
					borderColor: `#${
						colorsMap[item.id]
							? colorsMap[item.id]?.block
							: item.color || "71d9c2"
					}`,
					extendedProps: {
						data: {
							...item,
							color: colorsMap[item.id]
								? colorsMap[item.id]?.block
								: item.color || "71d9c2",
						},
						type: "STUDIO_EVENTS",
					},
				};

				let event = self.calendarApi()?.getEventById(key);
				if (event?.id) {
					event.remove();
				}

				if (self.studioEventsMap[eventItem?.id]) {
					if (!self.hasFilter) {
						self.calendarApi().addEvent(eventItem);
					}
					eventsMap[key] = eventItem;
				}
			});
			console.log("studioEventsMap: ", self.studioEventsMap);
			self.$tools.setCache("so_es", self.studioEventsMap);

			return eventsMap;
		},
		async getGoogleEvents(map, showLoading = false) {
			let self = this;
			let now = self.$moment().unix();
			// return false;

			if (showLoading) {
				self.$bus.$emit("showFullCover", {
					text: "Syncing...",
					type: "loading",
					timeout: 0,
					unix: now,
				});
			}

			await self.removeGoogleEvents();

			if (
				self.$tools.isNull(
					self.googleCalendarSyncRequest?.syncFromGoogleCalendars
				) ||
				self.googleCalendarSyncRequest?.syncFromGoogleCalendars
					?.length < 1
			) {
				if (showLoading) {
					self.$bus.$emit("hideFullCover", {
						type: "success",
						unix: now,
					});
				}
				return false;
			}

			if (
				self.$tools.isNull(self.googleAccessTokenCalendar.access_token)
			) {
				self.googleAccessTokenCalendar =
					(await self.$userService.googleAccessTokenCalendarAction.get(
						self.userInfo?.userId
					)) ?? {};
			}

			if (
				!self.$tools.isNull(
					self.googleAccessTokenCalendar.refresh_token
				) &&
				self.googleAccessTokenCalendar?.expiry_date <=
					new Date().getTime()
			) {
				await self.getGoogleAccessToken();
			}

			let activeGoogleCalendars =
				self.googleCalendarSyncRequest?.syncFromGoogleCalendars?.filter(
					(item) =>
						item?.status ==
						self.$dataModules.googleCalendarSyncRequest
							.syncFromGoogleCalendarStatus.active
				) ?? [];
			let activeGoogleCalendarsMap = self.$commons.arrayToMap(
				activeGoogleCalendars,
				"calendarId"
			);

			console.log(
				"get googe event -- ",
				activeGoogleCalendars?.length == 0,
				self.$tools.isNull(self.googleAccessTokenCalendar?.access_token)
			);

			if (
				activeGoogleCalendars?.length == 0 ||
				self.$tools.isNull(self.googleAccessTokenCalendar?.access_token)
			) {
				if (showLoading) {
					self.$bus.$emit("hideFullCover", {
						type: "success",
						unix: now,
					});
				}
				return false;
			}

			console.log("get googe event -- ✅");

			let eventsMap = {};
			if (map) {
				self.googleEventsMap = self.$tools.equalValue(map);
			} else {
				let googleEventsMap = {};
				let fetchGoogleCalendarEvents =
					self.$functionsService.fetchGoogleCalendarEvents;

				/**
				 * @property {string} userId
				 * @property {string} timeMax
				 * @property {string} timeMin
				 * @property {FetchGoogleCalendarEventsResponseItem[]} data
				 */

				/**
				 * @typedef {Object} FetchGoogleCalendarEventsResponseItem
				 * @property {string} calendarId
				 * @property {Schema$Event[]} events
				 */

				let timeMinMoment = self
					.$momentTimezone(self.calendarApi().view.activeStart)
					.tz(self.$commons.getTz());
				let timeMaxMoment = self
					.$momentTimezone(self.calendarApi().view.activeEnd)
					.tz(self.$commons.getTz());

				let res = await fetchGoogleCalendarEvents({
					timeMin: timeMinMoment.format(),
					timeMax: timeMaxMoment.format(),
				});

				let eventsArray = res?.data?.data?.data;
				console.log("fetchGoogleCalendarEvents: ", eventsArray);

				eventsArray?.some((item) => {
					if (activeGoogleCalendarsMap[item.calendarId]) {
						activeGoogleCalendarsMap[item.calendarId].events =
							item.events;
					}
				});

				Object.keys(activeGoogleCalendarsMap)?.forEach((key) => {
					let calendar = activeGoogleCalendarsMap[key];
					let backgroundColor =
						calendar?.calendarData?.backgroundColor;
					let timeZone = calendar?.calendarData?.timeZone;

					if (calendar.events?.length > 0) {
						calendar.events.some((event) => {
							if (event?.status != "cancelled") {
								let data = {
									title: event.summary,
									calendarId: key,
									eventId: event.id,
									creator:
										event?.creator?.displayName ??
										event?.creator?.email,
									description: event.description ?? "",
									location: event.location ?? "",
									color: !self.$tools.isNull(event?.colorId)
										? self.colorsMap[event.colorId].line
										: backgroundColor,
									timeZone: timeZone || self.$commons.getTz(),
									allDay: !self.$tools.isNull(
										event?.start?.date
									),
									originData: event,
								};

								let startTime = 0;
								let endTime = 0;

								if (!self.$tools.isNull(event?.start?.date)) {
									// day event
									startTime = self.$momentTimezone
										.tz(
											`${event.start.date} 00:00`,
											data.timeZone
										)
										.unix();
									endTime = self.$momentTimezone
										.tz(
											`${event.end.date} 00:00`,
											data.timeZone
										)
										.unix();
								} else if (
									!self.$tools.isNull(event?.start?.dateTime)
								) {
									// time event
									startTime = self.$momentTimezone
										.tz(
											event?.start?.dateTime,
											data.timeZone
										)
										.unix();
									endTime = self.$momentTimezone
										.tz(event?.end?.dateTime, data.timeZone)
										.unix();
								}

								if (event?.recurrence?.length > 0 && false) {
									// repeat
									// DTSTART;TZID=America/Denver:20181101T190000;\n

									let startDTSTART = `DTSTART;TZID=${
										data.timeZone
									}:${self
										.$momentTimezone(startTime * 1000)
										.utc()
										.format("YYYYMMDDTHHmmss")}\n`;

									let localStartRRule = RRule.fromString(
										startDTSTART +
											event?.recurrence.join("\n")
									);

									// console.log(
									//   "localStartRRule - ",
									//   startDTSTART + event?.recurrence.join("\n"),
									//   localStartRRule
									// );

									let byDayStr = event?.recurrence
										.join("\n")
										?.split("RRULE:")[1]
										?.split("BYDAY=")[1]
										?.split(";")[0];
									let pos = byDayStr?.substring(
										0,
										byDayStr.length - 2
									);
									let setpos = self.$tools.isNull(pos)
										? null
										: pos;
									let startByweekdays =
										localStartRRule?.origOptions?.byweekday;
									let startWkst =
										localStartRRule?.origOptions?.wkst;

									let startOption = {
										...localStartRRule?.origOptions,
									};

									if (setpos) {
										startOption.bysetpos = [setpos];
									}

									if (startByweekdays) {
										startByweekdays?.some((item, index) => {
											startByweekdays[index] =
												self.$commons.getUTCRRuleWeekday(
													item?.weekday + 1 > 6
														? 0
														: item?.weekday + 1,
													startTime
												);
										});

										startOption.byweekday = startByweekdays;
									}

									if (startWkst) {
										startWkst =
											self.$commons.getUTCRRuleWeekday(
												startWkst?.weekday + 1 > 6
													? 0
													: startWkst?.weekday + 1,
												startTime
											);

										startOption.wkst = startWkst;
									}

									let startRRule = new RRule(startOption);

									// console.log("google event start - ", startRRule, startOption);

									let startTimeArr = startRRule.between(
										self.$commons.datetime(
											timeMinMoment.year(),
											timeMinMoment.month(),
											timeMinMoment.date(),
											timeMinMoment.hour(),
											timeMinMoment.minute()
										),
										self.$commons.datetime(
											timeMaxMoment.year(),
											timeMaxMoment.month(),
											timeMaxMoment.date(),
											timeMaxMoment.hour(),
											timeMaxMoment.minute()
										),
										true
									);

									startTimeArr.some((item, index) => {
										let dataItem = {
											...data,
											startTime: self
												.$moment(item)
												.unix(),
											endTime: self
												.$moment(item)
												.add(
													endTime - startTime,
													"seconds"
												)
												.unix(),
										};
										dataItem.id = `${dataItem.eventId}:${dataItem.startTime}`;

										googleEventsMap[dataItem.id] = dataItem;
									});

									// console.log(event);
									// console.log(startTimeArr);
								} else {
									// single

									data.startTime = startTime;
									data.endTime = endTime;
									data.id = `${data.eventId}:${data.startTime}`;

									googleEventsMap[data.id] = data;

									// console.log(
									//   "google event start -  ",
									//   event.summary,
									//   self.$moment(startTime * 1000).format("YYYY-MM-DD hh:mmA")
									// );
									// console.log(
									//   "google event end - ",
									//   self.$moment(endTime * 1000).format("YYYY-MM-DD hh:mmA")
									// );
									// console.log(event);
								}
							}
						});
					}
				});

				// console.log("googleEventsMap: ", googleEventsMap);

				Object.keys(self.googleEventsMap).forEach((key) => {
					let event = self.calendarApi()?.getEventById(key);
					if (event?.id) {
						event.remove();
					}
				});

				self.googleEventsMap = googleEventsMap;

				Object.keys(self.googleEventsMap).forEach((key) => {
					let item = self.googleEventsMap[key];

					let classNamesBasic = [
						"tk-text-xs-bold",
						"tk-text-left",
						"tk-cal-all-day",
						"tk-cal-google",
					];

					// let data = {
					//   title: event.summary,
					//   calendarId: key,
					//   eventId: event.id,
					//   creator: event?.creator?.displayName ?? event?.creator?.email,
					//   description: event.description ?? "",
					//   location: event.location ?? "",
					//   color: !self.$tools.isNull(event?.colorId)
					//     ? self.colorsMap[event.colorId].line
					//     : backgroundColor,
					//   timeZone: timeZone || self.$commons.getTz(),
					//   originData: event,
					// };

					let eventItem = {
						id: item.id,
						title: item.title, // title
						classNames: classNamesBasic,
						start: item.startTime * 1000,
						end: item.endTime * 1000,
						allDay: item.allDay,
						display: "block",
						backgroundColor: item.color,
						borderColor: item.color,
						extendedProps: {
							data: item,
							type: "GOOGLE_EVENTS",
						},
					};

					if (self.googleEventsMap[eventItem?.id]) {
						if (!self.hasFilter) {
							self.calendarApi().addEvent(eventItem);
						}
						eventsMap[key] = eventItem;
					}
				});

				self.$tools.setCache("ge_es", self.googleEventsMap);
			}

			if (showLoading) {
				self.$bus.$emit("hideFullCover", {
					type: "success",
					unix: now,
				});
			}

			return eventsMap;
		},
		async removeGoogleEvents() {
			let self = this;

			Object.keys(self.googleEventsMap ?? {}).forEach((key) => {
				let event = self.calendarApi()?.getEventById(key);
				if (event?.id) {
					event.remove();
				}
			});

			self.$forceUpdate();
		},
		async getFollowUpUnconfirmedEvents(map) {
			let self = this;
			let now = self.$moment().unix();

			if (!self.$commons.userIsInstructor(self.userInfo)) {
				return false;
			}

			Object.keys(self.lessonUnconfirmeEventsMap).forEach((key) => {
				let event = self.calendarApi()?.getEventById(key);
				if (event?.id) {
					event.remove();
				}
			});

			for (let key in self.lessonUnconfirmedMap) {
				let followUpItem = self.lessonUnconfirmedMap[key];
				let scheduleId = followUpItem?.data?.scheduleId;
				let timeAfter = followUpItem?.data?.timeAfter * 1;
				let classNamesBasic = ["tk-text-xs-bold", "tk-cal"];

				console.log("unconfirmed follow up: ", followUpItem);

				if (
					timeAfter * 1000 >= self.startTimestamp &&
					timeAfter * 1000 <= self.endTimestamp
				) {
					let item =
						await self.$scheduleService.lessonScheduleAction.get(
							scheduleId
						);

					if (item?.id) {
						let colorData = self.getLessonColor(item);
						let bgColor = colorData.bgColor;
						let borderColor = colorData.borderColor;

						let config =
							self.lessonConfigsMap[item?.lessonScheduleConfigId];
						if (item.shouldTimeLength <= 30) {
							classNamesBasic.push("tk-time-30");
						}

						let specificClassName = [];

						if (!self.isNull(config)) {
							let displayTime =
								self.$commons.getLessonShouldDateTime(
									{
										...item,
										shouldDateTime: timeAfter,
									},
									config
								);

							if (displayTime < now) {
								classNamesBasic.push("fc-event-past");
							} else {
								classNamesBasic.push("fc-event-future");
							}

							// reschedule 但未确认
							specificClassName.push("tk-cal-unconfirmed-after");

							let idArr = item.id.split(":");

							let eventItem = {
								id: `${idArr[0]}:${idArr[1]}:${timeAfter}`,
								title: self.$tools.isNull(item.studentId)
									? self.$commons
											.mapToArray(
												self.lessonConfigsMap[
													item.lessonScheduleConfigId
												]?.groupLessonStudents ?? {}
											)
											.filter(
												(i) =>
													(i.status ==
														self.$dataModules
															.lessonScheduleConfig
															.groupLessonStudentsStatus
															.active &&
														i.registrationTimestamp <=
															item.shouldDateTime) ||
													(i.status ==
														self.$dataModules
															.lessonScheduleConfig
															.groupLessonStudentsStatus
															.quit &&
														i.registrationTimestamp <=
															item.shouldDateTime &&
														i.quitTimestamp >
															item.shouldDateTime)
											)?.length + " students"
									: self.studentsListMap[item.studentId]
											?.name ?? "", // name
								classNames:
									classNamesBasic.concat(specificClassName),
								start: displayTime * 1000,
								end:
									(displayTime + item.shouldTimeLength * 60) *
									1000,
								display: "block",
								backgroundColor: `#${bgColor}`,
								borderColor: `#${borderColor}`,
								extendedProps: {
									data: {
										...followUpItem,
										color: bgColor,
										config,
										// color: borderColor
									},
								},
							};

							// console.log(eventItem);

							if (
								config.lessonCategory ==
									self.$dataModules.lessonType.category
										.group &&
								eventItem.id.split(":")[1] != config.id
							) {
								continue;
							}

							if (!self.$tools.isNull(eventItem?.id)) {
								let event = self
									.calendarApi()
									?.getEventById(eventItem?.id);
								console.log("unconfirmed event: ", event);
								if (event?.id) {
									event.remove();
								}

								if (!self.hasFilter) {
									self.calendarApi().addEvent(eventItem);
								}
								console.log(
									"add unconfirmed event: ",
									eventItem
								);
							}
						}
					}
				}
			}
		},
		getLessonColor(item) {
			let self = this;
			let bgColor = "d7f2eb";
			let borderColor = "71d9c2";
			let config = self.lessonConfigsMap[item?.lessonScheduleConfigId];

			let bgColorsMap = self.bgColorsMap;
			let borderColorsMap = self.borderColorsMap;

			if (
				// self.$tools.isNull(item?.location?.remoteLink) &&
				self.$tools.isNull(item?.location?.id) &&
				self.$tools.isNull(item?.location?.place) &&
				item?.location?.type != "REMOTE" &&
				self.$tools.isNull(config?.rrule)
			) {
				item.location = config?.location;
			}

			if (
				self.$tools.isNull(item?.location?.remoteLink) &&
				self.$tools.isNull(item?.location?.id) &&
				self.$tools.isNull(item?.location?.place) &&
				!self.$tools.isNull(config?.rrule)
			) {
				item.location = config?.location ?? {};
			}

			let hasLocation =
				!self.$tools.isNull(item?.location?.remoteLink) ||
				!self.$tools.isNull(item?.location?.place) ||
				!self.$tools.isNull(item?.location?.name) ||
				!self.$tools.isNull(item?.location?.title) ||
				!self.$tools.isNull(item?.location?.id);

			if (hasLocation) {
				let address = self.addressBooksMap[item?.location?.id];
				let studioRoom =
					self.studioRoomsMap[
						item?.location?.id || item?.location?.place
					];

				if (
					item?.location?.type ==
					self.$dataModules.lessonSchedule.locationType.studioRoom
				) {
					let sameNameAddress =
						self.teacherInfo?.addressBooks?.filter(
							(addr) =>
								!addr.isDelete &&
								addr?.title == studioRoom?.name
						)[0] ?? null;
					if (
						studioRoom?.isDeleted &&
						!self.$tools.isNull(sameNameAddress)
					) {
						item.location = sameNameAddress;
					}
				}

				if (
					item?.location?.type ==
					self.$dataModules.lessonSchedule.locationType.otherPlace
				) {
					let sameNameStudioRoom =
						self.$commons
							.mapToArray(self.studioRoomsMap)
							?.filter(
								(room) =>
									!room.isDeleted &&
									room?.name == (item?.title || item?.name)
							)[0] ?? null;

					if (
						address?.isDelete &&
						!self.$tools.isNull(sameNameStudioRoom)
					) {
						item.location = {
							id: sameNameStudioRoom?.id,
							place: sameNameStudioRoom?.id,
							type: self.$dataModules.lessonSchedule.locationType
								.studioRoom,
							title: sameNameStudioRoom?.name,
							name: sameNameStudioRoom?.name,
						};
					}
				}
			}

			let studentTags = !self.$tools.isNull(item?.studentId)
				? self.studentsListMap[item?.studentId]?.tags
				: [];
			let blockColorTag =
				studentTags?.filter(
					(item) =>
						self.colorPreferenceMap?.[`studentTag-${item.category}`]
							?.selectedStyle == "block"
				)[0] ?? null;
			let lineColorTag =
				studentTags?.filter(
					(item) =>
						self.colorPreferenceMap?.[`studentTag-${item.category}`]
							?.selectedStyle == "line"
				)[0] ?? null;

			bgColor =
				bgColorsMap?.[item?.location?.id]?.block ||
				bgColorsMap?.[item?.location?.place]?.block ||
				bgColorsMap?.[
					self.onlineLinksMap?.[item?.location?.remoteLink]?.id
				]?.block ||
				bgColorsMap?.[item?.lessonTypeId]?.block ||
				(!self.$commons.instructorIsManagerInStudio(
					self.studioInfo,
					self.userInfo
				) && Object.keys(self.teachersMap)?.length > 1
					? bgColorsMap?.[item?.teacherId]?.block
					: "") ||
				(!self.$tools.isNull(blockColorTag) &&
				blockColorTag?.tags?.length > 0
					? bgColorsMap?.[blockColorTag?.tags[0]]?.block
					: "") ||
				bgColor;

			borderColor =
				borderColorsMap?.[item?.location?.id]?.line ||
				borderColorsMap?.[item?.location?.place]?.line ||
				borderColorsMap?.[
					self.onlineLinksMap?.[item?.location?.remoteLink]?.id
				]?.line ||
				borderColorsMap?.[item?.lessonTypeId]?.line ||
				(!self.$commons.instructorIsManagerInStudio(
					self.studioInfo,
					self.userInfo
				) && Object.keys(self.teachersMap)?.length > 1
					? borderColorsMap?.[item?.teacherId]?.line
					: "") ||
				(!self.$tools.isNull(lineColorTag) &&
				lineColorTag?.tags?.length > 0
					? borderColorsMap?.[lineColorTag?.tags[0]]?.line
					: "") ||
				borderColor;

			return {
				bgColor,
				borderColor,
			};
		},
		// 获取时间范围内的 Lesson
		async getLessons(timestamp, events = {}, clearAll = false) {
			let self = this;
			let eventsMap = {};
			let studioEventsMap = {};
			let unconfirmedEventsMap = {};
			let googleEventsMap = {};
			let lessonSchedulesMap = {};
			let startMoment = self
				.$moment(self.calendarApi()?.view.activeStart)
				.startOf("date");
			let endMoment = self
				.$moment(self.calendarApi()?.view.activeEnd)
				.endOf("date");

			console.log("get Lessons");

			if (
				self.defaultView == self.viewType.month ||
				self.hasFilter ||
				clearAll
			) {
				console.log("month -- ");

				self.calendarApi().setOption("events", []);
				self.calendarApi().render();

				let events = (await self.calendarApi().getEvents()) ?? [];
				events.forEach((item) => {
					item.remove();
				});
			}

			if (self.$commons.userIsInstructor(self.userInfo)) {
				if (events?.readStudioEvents) {
					studioEventsMap =
						(await self.getStudioEvents(
							self.studioEventsMap ?? {}
						)) || {};
				} else {
					studioEventsMap = (await self.getStudioEvents()) || {};
				}
				unconfirmedEventsMap =
					(await self.getFollowUpUnconfirmedEvents(
						self.lessonUnconfirmedMap ?? {}
					)) || {};

				console.log("get studio events: ", studioEventsMap);
				console.log("get unconfirmed events: ", unconfirmedEventsMap);
			}

			if (events?.readGoogleEvents) {
				googleEventsMap =
					(await self.getGoogleEvents(self.googleEventsMap ?? {})) ||
					{};
			} else {
				googleEventsMap = (await self.getGoogleEvents()) || {};
			}

			console.log("get google events: ", googleEventsMap);

			if (timestamp) {
				let lessonSchedules = await self.getLessonsByConfig(timestamp);

				if (self.defaultView != self.viewType.month) {
					console.log("清除原有课程");
					Object.keys(self.lessonSchedulesMap).forEach((key) => {
						let item = self.lessonSchedulesMap[key];

						if (
							item?.extendedProps?.data?.shouldDateTime >=
								startMoment.unix() &&
							item?.extendedProps?.data?.shouldDateTime <=
								endMoment.unix()
						) {
							self.removeCalendarEvent(key);
						}
					});
				}

				console.log("渲染新get课程");
				lessonSchedules.forEach((item) => {
					if (
						item?.extendedProps?.data?.shouldDateTime >=
							startMoment.unix() &&
						item?.extendedProps?.data?.shouldDateTime <=
							endMoment.unix()
					) {
						lessonSchedulesMap[item.id] = item;
						if (self.defaultView != self.viewType.month) {
							self.addCalendarEvent(item);
						}
					}
				});

				self.$tools.setCache(
					"temp_lessonSchedulesMap",
					self.lessonSchedulesMap
				);

				if (self.defaultView == self.viewType.month) {
					eventsMap = {
						...studioEventsMap,
						...googleEventsMap,
						...unconfirmedEventsMap,
						...lessonSchedulesMap,
					};

					console.log(
						"刷新events: ",
						Object.keys(eventsMap ?? {})?.length
					);

					let lessons = self.$commons
						.mapToArray(lessonSchedulesMap)
						?.filter((item) =>
							self.meetFilter(item?.extendedProps?.data)
						);

					self.calendarApi().setOption("events", lessons);
					self.calendarApi().render();
				} else {
					console.log("刷新课程: ", lessonSchedules.length);
				}

				self.$forceUpdate();
			} else {
				// filter
				let lessonSchedules =
					self.$commons.mapToArray(self.lessonSchedulesMap) ?? [];
				console.log("lessonSchedulesMap: ", self.lessonSchedulesMap);

				lessonSchedules?.some((item) => {
					if (self.meetFilter(item?.extendedProps?.data)) {
						self.calendarApi().addEvent(item);
					}
				});
			}
		},
		// 根据 config 获取 lesson
		async getLessonsByConfig(timestamp, config) {
			return new Promise(async (resolve, reject) => {
				let self = this;
				let now = self.$moment().unix();

				self.$bus.$emit("showFullCover", {
					message: self.$i18n.t("notification.loading.load_lesson"),
					type: "loading",
					timeout: 0,
					unix: now,
				});

				console.log(
					"getLessonsByConfig: ",
					self.$moment(timestamp).format("YYYY/M/D")
				);

				let schedules =
					await this.$scheduleService.calculateScheduleByConfig({
						timestamp: timestamp,
						startTime: self
							.$moment(self.calendarApi()?.view.activeStart)
							.startOf("date")
							.unix(),
						endTime: self
							.$moment(self.calendarApi()?.view.activeEnd)
							.endOf("date")
							.unix(),
						config: config,
						studioId: self.studioInfo?.id ?? null,
						studentId: self.studioInfo?.id
							? null
							: self.$commons.userIsParent(self.userInfo)
							? self.userInfo?.kids ?? []
							: self.userInfo?.userId,
					});

				if (config) {
					console.log("schedules under config: ", schedules);
				} else {
					console.log("all configs schedule: ", schedules);
				}

				// test teacher
				// self.userInfo = await self.$userService.userAction.get(
				//   "KAa51Aua2IQxGc6meJgyb0Gt7432"
				// );
				// self.teacherInfo = await self.$teacherService.teacherInfoAction.get(
				//   "KAa51Aua2IQxGc6meJgyb0Gt7432"
				// );
				// self.teachersMap["KAa51Aua2IQxGc6meJgyb0Gt7432"] = self.teacherInfo;
				// self.studioInfo = await self.$userService.studioAction.get(
				//   "492301995080679424"
				// );
				// self.lessonTypesMap =
				//   await self.$studioService.lessonTypeAction.getByTeacherId(
				//     "492301995080679424"
				//   );
				// let lessonConfigs =
				//   await self.$scheduleService.lessonScheduleConfigAction.getByTeacherId(
				//     "KAa51Aua2IQxGc6meJgyb0Gt7432",
				//     "492301995080679424"
				//   );
				// self.lessonConfigsMap = self.$commons.arrayToMap(lessonConfigs, "id");
				// self.studentsListMap = self.$commons.userIsOldVersion(self.userInfo)
				//   ? await self.$studentService.studentListAction.getByUserIds({
				//       teacherId: "KAa51Aua2IQxGc6meJgyb0Gt7432",
				//     })
				//   : await self.$studentService.studentListAction.getByUserIds({
				//       studioId: "492301995080679424",
				//     });
				// let schedules =
				//   await this.$scheduleService.calculateOtherUserScheduleByConfig({
				//     timestamp: timestamp,
				//     config: config,
				//     studioId: "492301995080679424",
				//     teacherId: "KAa51Aua2IQxGc6meJgyb0Gt7432",
				//     period: "weeks",
				//     startTime: self.$moment("2023/09/05 00:00").unix(),
				//     endTime: self.$moment("2023/09/06 23:59").unix(),
				//   });
				// console.log("schedules: ", schedules);

				// test student
				// self.userInfo = await self.$userService.userAction.get(
				//   "KmpdX4790eXe2wburTrNoktnKG73"
				// );
				// self.lessonConfigsMap =
				//   await self.$scheduleService.lessonScheduleConfigAction.getByStudentIdOnly(
				//     { studentId: "KmpdX4790eXe2wburTrNoktnKG73" }
				//   );
				// self.lessonTypesMap =
				//   await self.$studioService.lessonTypeAction.getByTeacherId(
				//     "IXMtbePgHPWkXEBtjJU64SnGPGm1"
				//   );
				// self.teachersMap["IXMtbePgHPWkXEBtjJU64SnGPGm1"] =
				//   await self.$teacherService.userInfo("IXMtbePgHPWkXEBtjJU64SnGPGm1");
				// self.teachersInfoMap["IXMtbePgHPWkXEBtjJU64SnGPGm1"] =
				//   await self.$teacherService.teacherInfo(
				//     "IXMtbePgHPWkXEBtjJU64SnGPGm1"
				//   );
				// self.studiosMap["606922829836849152"] =
				//   await self.$userService.studioAction.get("606922829836849152");
				// studioRoomsMap = {}
				// let schedules =
				//   await this.$scheduleService.calculateOtherUserScheduleByConfig({
				//     timestamp: timestamp,
				//     config: config,
				//     studentId: "KmpdX4790eXe2wburTrNoktnKG73",
				//     teacherId: "IXMtbePgHPWkXEBtjJU64SnGPGm1",
				//     studioId: "606922829836849152",
				//   });
				// console.log("schedules: ", schedules);

				let getInitEventItem = [];

				for (let id in schedules) {
					let item = schedules[id];
					if (
						(self.$commons.userIsInstructor(self.userInfo) &&
							(item.teacherId == self.userInfo?.userId ||
								item.studioId == self.studioInfo?.id)) ||
						(self.$commons.userIsParent(self.userInfo) &&
							self.userInfo?.kids?.indexOf(item.studentId) >
								-1) ||
						(self.$commons.userIsParent(self.userInfo) &&
							self.userInfo?.kids?.filter(
								(kid) =>
									self.lessonConfigsMap[
										item.lessonScheduleConfigId
									]?.groupLessonStudents[kid]?.status ==
									self.$dataModules.lessonScheduleConfig
										.groupLessonStudentsStatus.active
							) &&
							self.lessonConfigsMap[item.lessonScheduleConfigId]
								?.lessonCategory ==
								self.$dataModules.lessonType.category.group) ||
						(self.$commons.userIsStudent(self.userInfo) &&
							item.studentId == self.userInfo?.userId) ||
						(self.$commons.userIsStudent(self.userInfo) &&
							self.lessonConfigsMap[item.lessonScheduleConfigId]
								?.lessonCategory ==
								self.$dataModules.lessonType.category.group &&
							self.lessonConfigsMap[item.lessonScheduleConfigId]
								?.groupLessonStudents[self.userInfo?.userId]
								?.status ==
								self.$dataModules.lessonScheduleConfig
									.groupLessonStudentsStatus.active)
					) {
						if (
							self.lessonConfigsMap[item.lessonScheduleConfigId]
								?.endType == 1 &&
							item?.shouldDateTime >
								self.lessonConfigsMap[
									item.lessonScheduleConfigId
								]?.endDate
						) {
							console.log(
								"排除 endType == 1: ",
								self.lessonConfigsMap[
									item.lessonScheduleConfigId
								]
							);
							continue;
						} else {
							getInitEventItem.push(
								self.initEventItem(schedules[id])
							);
						}
					}
				}

				let lessonSchedules = await Promise.all(getInitEventItem);

				console.log("lessonSchedules event item: ", lessonSchedules);

				self.$bus.$emit("hideFullCover", {
					type: "success",
					unix: now,
				});

				resolve(lessonSchedules);
			}).catch((err) => {
				reject(err);
			});
		},
		// 初始化 Lesson evnet item
		async initEventItem(data) {
			let self = this;
			let classNamesBasic = ["tk-text-xs-bold", "tk-cal"];
			let now = self.$moment().unix();
			let eventItem = null;
			let item = self.$tools.equalValue(data);
			let config = self.lessonConfigsMap[item?.lessonScheduleConfigId];
			let colorData = self.getLessonColor(item);
			let bgColor = colorData.bgColor;
			let borderColor = colorData.borderColor;

			// console.log(" initEventItem -=-=-=-=-=-=-=-=-=-=-=- ");

			if (
				(config?.repeatType !=
					self.$dataModules.lessonScheduleConfig.repeatType.none &&
					config?.endType ==
						self.$dataModules.lessonScheduleConfig.endType
							.endAtSomeday &&
					item.shouldDateTime >= config?.endDate) ||
				// config?.delete ||
				self.$tools.isNull(config?.id)
			) {
				console.log("排除 end => config: ", data, config);
				return null;
			}

			if (item.shouldTimeLength <= 30) {
				classNamesBasic.push("tk-time-30");
			}

			// 纠正 shouldDateTime
			if (item.id.split(":")?.length >= 2) {
				item.shouldDateTime = parseInt(item.id.split(":")[2]);
			}

			let specificClassName = [];

			if (!self.isNull(config)) {
				let displayTime = self.$commons.getLessonShouldDateTime(
					item,
					config
				);

				if (displayTime < now) {
					classNamesBasic.push("fc-event-past");
				} else {
					classNamesBasic.push("fc-event-future");
				}

				// reschedule 但未确认
				if (item.rescheduled && self.isNull(item.rescheduleId)) {
					specificClassName.push("tk-cal-unconfirmed");
					borderColor = "fa897b";
					bgColor = "f2e2dd";
				}

				if (
					(!item.rescheduled ||
						(item.rescheduled && self.isNull(item.rescheduleId))) &&
					!item.cancelled
				) {
					eventItem = {
						id: item.id,
						title:
							" " +
							(self.$commons.userIsInstructor(self.userInfo)
								? self.$tools.isNull(item.studentId)
									? self.$commons
											.mapToArray(
												self.lessonConfigsMap[
													item.lessonScheduleConfigId
												]?.groupLessonStudents ?? {}
											)
											.filter(
												(i) =>
													(i.status ==
														self.$dataModules
															.lessonScheduleConfig
															.groupLessonStudentsStatus
															.active &&
														i.registrationTimestamp <=
															item.shouldDateTime) ||
													(i.status ==
														self.$dataModules
															.lessonScheduleConfig
															.groupLessonStudentsStatus
															.quit &&
														i.registrationTimestamp <=
															item.shouldDateTime &&
														i.quitTimestamp >
															item.shouldDateTime)
											)?.length + " students"
									: self.studentsListMap[item.studentId]
											?.name ?? ""
								: self.$commons.userIsStudent(self.userInfo)
								? self.lessonTypesMap[item.lessonTypeId]
										?.name ?? ""
								: self.formatKidsInLesson(item).name), // name
						classNames: classNamesBasic.concat(specificClassName),
						start: displayTime * 1000,
						end:
							displayTime * 1000 +
							item.shouldTimeLength * 60 * 1000,
						display: "block",
						backgroundColor: `#${bgColor}`,
						borderColor: `#${borderColor}`,
						extendedProps: {
							data: {
								...item,
								color: bgColor,
								// color: borderColor
							},
						},
					};

					if (
						config.lessonCategory ==
							self.$dataModules.lessonType.category.group &&
						eventItem.id.split(":")[1] != config.id
					) {
						console.log("排除 category: ", config, eventItem);
						eventItem = null;
					}
				} else {
					// console.log("rescheduled & canceled: ", item);
				}
			}

			// if (eventItem) {
			//   console.log(
			//     "initEventItem ----- : ",
			//     self.$moment(eventItem?.start).format("M/D/YYYY h:mmA"),
			//     eventItem.id
			//   );
			// } else {
			//   console.log(
			//     "eventItem = null: ",
			//     self.$moment(data?.shouldDateTime * 1000).format("M/D/YYYY h:mmA"),
			//     data,
			//     config
			//   );
			// }
			return eventItem;
		},
		getActiveGroupLessonStudents(groupLessonStudentsMap) {
			let self = this;
			let data = self.$tools.equalValue(groupLessonStudentsMap) ?? {};
			Object.keys(groupLessonStudentsMap).forEach((key) => {
				let item = groupLessonStudentsMap[key];
				if (
					item.status ==
					self.$dataModules.lessonScheduleConfig
						.groupLessonStudentsStatus.quit
				) {
					delete data[key];
				}
			});
			return data;
		},
		formatKidsInLesson(lessonData) {
			let self = this;
			let config =
				self.lessonConfigsMap[lessonData.lessonScheduleConfigId];
			let result = {
				name: "",
				studentId: "",
				array: [],
				email: "",
			};

			if (
				config?.lessonCategory ==
					self.$dataModules.lessonType.category.single ||
				self.$tools.isNull(config?.lessonCategory)
			) {
				// single
				result.name =
					self.kidsUserInfoMap[lessonData?.studentId]?.name ?? "";
				result.studentId = lessonData?.studentId;
				result.email =
					self.kidsUserInfoMap[lessonData?.studentId]?.email ?? "";
			} else if (
				config?.lessonCategory ==
				self.$dataModules.lessonType.category.group
			) {
				// group
				let names = [];
				let studentIds = [];

				Object.keys(config?.groupLessonStudents).forEach((key) => {
					if (self.kidsUserInfoMap[key]) {
						names.push(self.kidsUserInfoMap[key]?.name);
						studentIds.push(key);
					}
				});

				if (names?.length > 1) {
					result.name = `${names.length} kids`;
					result.array = names;
				} else {
					result.name = names[0];
					result.studentId = studentIds[0];
					result.email = self.kidsUserInfoMap[result.studentId].email;
				}
			}

			return result;
		},
		// 初始化 日历标题
		async initTitle(option) {
			let self = this;
			let now = self.$moment().unix();

			if (option?.showFullCover) {
				self.$bus.$emit("showFullCover", {
					message: option?.msg
						? option?.msg
						: self.$i18n.t("notification.loading.load_lesson"),
					type: "loading",
					timeout: 0,
					unix: now,
				});
			}

			await self.initOptions();

			let currentStartTimestamp = new Date(
					self.calendarApi().view.currentStart
				).getTime(),
				currentEndTimestamp = new Date(
					self.calendarApi().view.currentEnd
				).getTime(),
				currentFirstYMD = self
					.$moment(currentStartTimestamp)
					.format("YYYY/M/D"),
				currentEndYMD = self
					.$moment(currentEndTimestamp)
					.subtract(1, "days")
					.format("YYYY/M/D");

			let startTimestamp =
				self.$moment(currentStartTimestamp).startOf("date").unix() *
				1000;
			let endTimestamp =
				self.$moment(currentEndTimestamp).endOf("date").unix() * 1000;

			// console.log("calendar api: ", self.calendarApi());
			console.log("start YMD: ", currentFirstYMD);
			console.log("end YMD: ", currentEndYMD);

			self.currentViewDays = [];
			self.hideDetailTime();

			if (option?.cache) {
				await self.reRenderEvent(self.lessonSchedulesMap, true);
			} else {
				if (!self.isNull(self.calendarApi())) {
					if (!option?.isFilter) {
						// toggle
						console.log("defaultView: ", self.defaultView);
						if (
							self.defaultView == self.viewType.month ||
							option?.viewType
						) {
							self.startTimestamp = startTimestamp;
							self.endTimestamp = endTimestamp;
							await self.getLessons(startTimestamp, {}, true);
						} else {
							if (option?.isRefresh) {
								console.log("refresh");
								self.calendarApi().setOption("events: ", []);
								self.calendarApi().render();
								self.$forceUpdate();
								await self.getLessons(startTimestamp);
							} else {
								console.log("no refresh");
								if (startTimestamp < self.startTimestamp) {
									console.log("获取 小于 开始时间");
									self.startTimestamp = startTimestamp;
									await self.getLessons(startTimestamp);
								} else if (endTimestamp > self.endTimestamp) {
									console.log("获取 大于 结束时间");
									self.endTimestamp = endTimestamp;
									await self.getLessons(endTimestamp);
								} else {
									console.log("在时间范围内，不获取");
									await self.getGoogleEvents();
								}
							}
						}
					} else {
						// self.getLessons();
						self.getLessons(self.startTimestamp);
					}
				}
			}

			self.showToday = !(
				now * 1000 >= startTimestamp && now * 1000 <= endTimestamp
			);

			self.title = self.calendarApi().view.title;
			self.currentViewDays.push(self.calendarApi().view.currentStart);
			self.currentViewDays.push(self.calendarApi().view.currentEnd);
			// console.log("currentViewDays: ", self.currentViewDays);

			if (option?.showFullCover) {
				self.$bus.$emit("hideFullCover", {
					type: "success",
					unix: now,
				});
			}

			// all day slot
			if (self.defaultView == self.viewType.month) {
				self.calendarApi().setOption("allDaySlot", false);
			} else {
				if (
					self.$commons.userIsInstructor(self.userInfo) ||
					Object.keys(self.studioEventsMap).length > 0
				) {
					let startUnix = self
						.$moment(self.calendarApi()?.view?.activeStart)
						.startOf("date")
						.unix();
					let endUnix = self
						.$moment(self.calendarApi()?.view?.activeEnd)
						.endOf("date")
						.unix();
					let showAllDaySlot = false;

					Object.keys(self.studioEventsMap).forEach((key) => {
						let item = self.studioEventsMap[key];
						if (
							(item.startTime >= startUnix &&
								item.startTime < endUnix) ||
							(item.endTime > startUnix &&
								item.endTime <= endUnix) ||
							item.endTime == 0
						) {
							showAllDaySlot = true;
						}
					});

					self.calendarApi().setOption("allDaySlot", showAllDaySlot);
					console.log("allDaySlot: ", showAllDaySlot);
				}
			}
			self.calendarApi().render();
			self.$tools.setCache("temp_view", self.defaultView);

			self.calendarReady = true;
			self.$forceUpdate();
		},
		// 日历 api
		calendarApi() {
			if (!this.isNull(this.calendar())) {
				return this.calendar();
			} else {
				return false;
			}
		},
		// 日历 组件
		calendar() {
			return this.fullCalendar || this.$refs.fullCalendar?.getApi();
		},
		// 日历切换视图
		async changeView(viewType) {
			let self = this;

			self.showMonitoring = false;
			self.monitorType = -1;
			self.showLessonDetailForMonitorItem = false;
			self.defaultView = viewType;
			self.calendarApi().changeView(viewType);
			self.initTitle({
				viewType,
			});
		},
		// 下一个日历视图
		async next() {
			await this.calendarApi().next();
			this.initTitle();
			this.hideDetailTime();
		},
		// 上一个日历视图
		async prev() {
			await this.calendarApi().prev();
			this.initTitle();
			this.hideDetailTime();
		},
		// 日历回到今天
		today() {
			let self = this;
			if (self.showToday) {
				self.calendarApi().today();
				self.initTitle();
			}
		},
	},
};
</script>
<style lang="scss">
@import "~@fullcalendar/common/main.css";
@import "~@fullcalendar/daygrid/main.css";
@import "~@fullcalendar/timegrid/main.css";

.calendar td,
.calendar th {
	border-color: #eff7f5 !important;
	border-width: 0.25rem !important;
	position: relative;
}

.triangle-right {
	width: 0;
	height: 0;
	border-left: 0.75rem solid white;
	border-right: none;
	border-top: 0.5rem solid transparent;
	border-bottom: 0.5rem solid transparent;
	right: -0.75rem;
	position: absolute;
	display: none;
	filter: drop-shadow(4px 2px 2px rgba(0, 0, 0, 0.2));
}
.triangle-left {
	width: 0;
	height: 0;
	border-right: 0.75rem solid white;
	border-left: none;
	border-top: 0.5rem solid transparent;
	border-bottom: 0.5rem solid transparent;
	left: -0.75rem;
	position: absolute;
	display: none;
	filter: drop-shadow(-4px 2px 2px rgba(0, 0, 0, 0.2));
}
.triangle-top {
	top: 0.25rem;
}
.triangle-bottom {
	bottom: 2.75rem;
}
</style>
