<template>
  <div>
    <div class="tk-g-root-container tk-layout-flex-row">
      <div class="tk-layout-flex-1 tk-layout-flex-column tk-layout-full-height">
        <!-- title -->
        <div class="tk-page-title tk-px-margin-bottom-px16">
          {{ $t("nav.message") }}
        </div>

        <!-- content -->
        <div class="tk-layout-flex-1 tk-layout-flex-row tk-overflow-y">
          <!-- left -->
          <div
            class="tk-layout-page-left tk-layout-full-height tk-layout-flex-column tk-overflow-y"
          >
            <card-loading v-if="loadingConversation"></card-loading>
            <template v-else>
              <!-- search -->
              <div class="tk-layout-full-width">
                <!-- :button="[
                  {
                    text: $t('general.add'),
                    icon: 'fas fa-plus',
                    emit: 'onClickAdd',
                  },
                ]" -->
                <search-bar-with-button
                  @onInput="onInputSearch"
                  @onClickAdd="onClickAdd"
                  @onClear="search = ''"
                ></search-bar-with-button>
              </div>

              <!-- list -->
              <div class="tk-layout-flex-1 tk-overflow-y tk-scrollbar">
                <template v-for="item in conversations">
                  <left-part-list-item-with-pic
                    :key="item.id"
                    :class="[
                      currentConversationId == item.id
                        ? 'tk-border-color-main tk-px-border-px2'
                        : 'tk-border-bottom-color-gray-200',
                    ]"
                    @onClick="openConversation(item)"
                    :userId="
                      !$commons.userIsInstructor(userInfo) &&
                      !$tools.isNull(studioInfo[item.id])
                        ? ''
                        : getConversationOpposite(item).userId
                    "
                    :studioId="
                      !$commons.userIsInstructor(userInfo) &&
                      !$tools.isNull(studioInfo[item.id])
                        ? item.id
                        : ''
                    "
                    :name="getConversationOpposite(item).name"
                    :isLogo="item.id == item.creatorId"
                    :title="getConversationTitle(item)"
                    :unread="
                      currentConversationId == item.id
                        ? 0
                        : getConversationUnread(item)
                    "
                    :pinTop="
                      Boolean(item.isPinTop) ||
                      (item.id == studioInfo.id &&
                        item.id == userInfo.userId) ||
                      !$tools.isNull(studioInfo[item.id])
                    "
                    :icon="
                      studioInfo.id == item.id
                        ? 'fa-solid fa-users tk-font-color-main tk-text-lg'
                        : ''
                    "
                    iconBg="tk-bg-color-white"
                    v-if="
                      ($tools.isNull(search) ||
                        getConversationTitle(item)
                          .toUpperCase()
                          .indexOf(search.toUpperCase()) > -1) &&
                      (!$tools.isNull(item.latestMessageId) ||
                        item.id == studioInfo.id ||
                        item.id == userInfo.userId)
                    "
                  >
                    <!-- last msg -->
                    <div
                      v-if="!$tools.isNull(item.latestMessageId)"
                      class="tk-layout-flex-row tk-layout-flex-vertical-center"
                    >
                      <div class="tk-layout-flex-1 tk-text-overflow">
                        <template
                          v-if="
                            item.latestMessage &&
                            item.latestMessage.type ==
                              $conversationService.type.messageType.text
                          "
                          >{{
                            $commons.formatMsg(item.latestMessage).text
                          }}</template
                        >
                        <template v-else>{{
                          $commons.formatMsg(item.latestMessage).outerStr
                        }}</template>
                      </div>
                      <div
                        class="tk-text-sm tk-px-margin-left-px16"
                        v-if="item.latestMessageTimestamp > 0"
                      >
                        {{
                          $commons.formatTimeDiffForNow(
                            item.latestMessageTimestamp,
                            "MMM D"
                          )
                        }}
                      </div>
                    </div>
                  </left-part-list-item-with-pic>
                </template>
              </div>
            </template>
          </div>

          <!-- right -->
          <div
            class="tk-layout-page-right tk-layout-full-height tk-scrollbar tk-overflow-y"
          >
            <conversation
              class="tk-layout-full"
              :data="conversationsMap[currentConversationId]"
              :id="currentConversationId"
              :title="
                getConversationTitle(
                  conversationsMap[currentConversationId],
                  true
                )
              "
              v-if="!$tools.isNull(currentConversationId)"
            ></conversation>

            <div class="tk-position-relative tk-layout-full" v-else>
              <img
                class="tk-position-center"
                src="/img/icons/tk/img_chat.png"
                style="width: 64%; max-width: 375px"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧工具栏 -->
      <tool-bar :bars="funcBars" class="tk-right-tool-bar"></tool-bar>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      loadingConversation: true,
      loadingMessage: true,
      enableListener: false,

      userInfo: {},
      studioInfo: {},
      studentsListMap: {},
      teachersMap: {},
      teacherInfosMap: {},
      kidsMap: {},
      parentsMap: {},
      conversationsMap: {},
      conversations: [],
      currentConversationId: "",
      search: "",

      funcBars: [],
    };
  },
  components: {
    ToolBar: () => import("@/tkViews/components/layout/RightToolbar.vue"),
    SearchBarWithButton: () =>
      import("@/tkViews/components/layout/SearchBarWithButton.vue"),
    CardLoading: () => import("@/tkViews/components/layout/CardLoading.vue"),
    LeftPartListItemWithPic: () =>
      import("@/tkViews/components/layout/Item/LeftPartListItemWithPic.vue"),
    Conversation: () => import("@/tkViews/Pages/Conversation.vue"),
  },
  async created() {
    let self = this;
    self.initBasicData();

    // self.test(1678752000);
  },
  async mounted() {
    let self = this;

    // conversation
    self.$bus.$on("onAddConversation", async (data) => {
      if (self.enableListener && self.$tools.isNull(data.targetId)) {
        console.log("----- new conversation: ", data);
        self.conversationOnChanged(data);
      }
    });
    self.$bus.$on("onChangeConversation", async (data) => {
      if (
        self.enableListener &&
        self.$tools.isNull(data.targetId) &&
        !self.conversationsMap[data?.id]
      ) {
        console.log("----- conversation changed: ", data);
        self.conversationOnChanged(data);
      }
    });
    self.$bus.$on("onRemoveConversation", async (data) => {
      if (self.enableListener && self.$tools.isNull(data.targetId)) {
        console.log("----- delete conversation: ", data);
        delete self.conversationsMap[data.id];
        self.$forceUpdate();
      }
    });

    // enable listener
    self.enableListener = true;
  },
  watch: {
    currentConversationId(newVal, oldVal) {
      let self = this;
      if (!self.$tools.isNull(newVal)) {
        self.clearConversationUnread();
      }
    },
  },
  methods: {
    async test(timestamp) {
      const utcDate = new Date(timestamp);
      const localDate = new Date(
        timestamp + new Date().getTimezoneOffset() * 60 * 1000
      );

      const utcWeekday = utcDate.getUTCDay();
      const localWeekday = localDate.getDay();

      let diff = utcWeekday - localWeekday;
      console.log(`UTC weekday diff: ${diff}`);
    },
    async initBasicData() {
      let self = this;

      self.userInfo = await self.$userService.userInfo();

      if (self.$commons.userIsInstructor(self.userInfo)) {
        self.studioInfo = await self.$userService.studioInfo();
        self.studentsListMap = await self.$studioService.studentsList();
        self.teachersMap = await self.$studioService.teacherUserInfo();
      } else {
        self.studioInfo = await self.$studentService.studioInfos();
        console.log("studioInfo: ", self.studioInfo);
        self.teachersMap = await self.$studentService.teacherUserInfos();
        self.teacherInfosMap = await self.$studentService.teacherInfos();
        self.kidsMap = self.$commons.userIsParent(self.userInfo)
          ? await self.$userService.userKids()
          : {};
        self.parentsMap = self.$commons.userIsStudent(self.userInfo)
          ? await self.$userService.userParents()
          : {};
      }

      self.conversationsMap = await self.$conversationService.conversation();

      let getSupportCenterCreator = [];
      Object.keys(self.conversationsMap).forEach((key) => {
        let data = self.conversationsMap[key];
        if (
          data.creatorId == data.id &&
          data.creatorId != self.userInfo?.userId
        ) {
          console.log("support center: ", data);
          getSupportCenterCreator.push(
            self.$userService.userAction.get(data.creatorId)
          );
        }
      });

      if (getSupportCenterCreator?.length > 0) {
        console.log("getSupportCenterCreator: ", getSupportCenterCreator);
        await Promise.all(getSupportCenterCreator).then((res) => {
          res.forEach((item) => {
            if (self.conversationsMap[item?.userId]) {
              self.conversationsMap[item.userId].creatorName = item?.name;
            }
          });
        });
      }
      self.conversations = await self.getConversationList();

      if (
        self.$commons.userIsInstructor(self.userInfo) &&
        !self.conversationsMap[self.studioInfo?.id] &&
        self.$commons.instructorIsManagerInStudio(
          self.studioInfo,
          self.userInfo
        )
      ) {
        // 没有 announcement 会话
        console.log("没有 announcement -> 创建");
        await self.createAnnouncement();
      }

      self.loadingConversation = false;
    },
    createAnnouncement() {
      let self = this;
      let now = new Date().getTime() / 1000;
      let conversation = self.$dataModules.conversation.default;
      conversation.id = self.studioInfo.id;
      conversation.title = "Community";
      conversation.type = self.$dataModules.conversation.type.group;
      conversation.creatorId = self.userInfo.userId;
      conversation.createTime = now;
      conversation.updateTime = now;
      conversation.speechMode =
        self.$dataModules.conversation.speechMode.onlyCreator;

      conversation.userMap = {};
      conversation.users = [];

      conversation.userMap[self.userInfo?.userId] = true;
      conversation.users.push({
        conversationId: self.studioInfo.id,
        userId: self.userInfo.userId,
        nickname: self.userInfo.name,
        unreadMessageCount: 0,
      });

      Object.keys(self.studentsListMap).forEach((key) => {
        let user = self.studentsListMap[key];
        conversation.userMap[user.studentId] = true;
        conversation.users.push({
          conversationId: self.studioInfo.id,
          userId: user.studentId,
          nickname: user.name,
          unreadMessageCount: 0,
        });
      });

      Object.keys(self.teachersMap).forEach((key) => {
        let user = self.teachersMap[key];
        if (user.userId != self.userInfo?.userId) {
          conversation.userMap[user.studentId] = true;
          conversation.users.push({
            conversationId: self.studioInfo.id,
            userId: user.studentId,
            nickname: user.name,
            unreadMessageCount: 0,
          });
        }
      });

      self.$conversationService.conversationAction.create(
        conversation.id,
        conversation,
        (err) => {
          if (!err) {
            console.log("create announcement");
          }
        }
      );
    },
    clearConversationUnread() {
      let self = this;
      self.conversationsMap[self.currentConversationId].users.some((item) => {
        if (item.userId == self.userInfo?.userId) {
          item.unreadMessageCount = 0;
        }
      });
    },
    async conversationOnChanged(data) {
      let self = this;
      self.conversationsMap[data.id] = data;

      if (data.id == data.creatorId && self.userInfo.userId !== data.id) {
        let user = await self.$userService.userAction.get(data.creatorId);
        data.creatorName = user.name;
      }

      self.conversations = await self.getConversationList();
      self.$forceUpdate();
    },
    getConversationList() {
      let self = this;

      let arr = self.$commons.mapToArray(
        self.conversationsMap,
        "desc",
        "latestMessageTimestamp"
      );

      // let arr = self.$commons.mapToArray(self.conversationsMap);

      // 排序: top、latestMessageTimestamp
      arr = arr.sort((a, b) => {
        if (a?.id == self.studioInfo?.id) {
          return -1;
        } else if (b?.id == self.studioInfo?.id) {
          return 1;
        } else if (
          (a?.isPinTop && b?.isPinTop) ||
          (!a?.isPinTop && !b?.isPinTop)
        ) {
          return b.latestMessageTimestamp - a.latestMessageTimestamp;
        } else if (a?.isPinTop && !b?.isPinTop) {
          return -1;
        } else if (!a?.isPinTop && b?.isPinTop) {
          return 1;
        }
        return 0;
      });

      for (let i = 0; i < arr.length; i++) {
        let item = arr[i];
        if (item.isRemoved || !self.$tools.isNull(item.targetId)) {
          arr.splice(i, 1);
          i--;
        }
      }

      console.log("conversation: ", arr);

      return arr;
    },
    getConversationTitle(data) {
      let self = this;
      let title = data?.title ?? "";

      if (data?.id == self.studioInfo?.id || self.studioInfo[data?.id]) {
        // announcement
        if (self.studioInfo[data?.id]) {
          title = "Announcement";
        } else {
          title =
            "Announcement (" +
            (data?.users?.length ?? 0) +
            " students / parents)";
        }
      } else if (data?.id == self.userInfo?.userId) {
        // support center
        title = "Support Center";
      } else {
        // user
        title = self.getConversationOpposite(data)?.name ?? "";
      }

      return title;
    },
    getConversationOpposite(data) {
      let self = this;
      let oppositeUser = {};
      let title = data.title;

      if (
        data?.id != self.studioInfo?.id &&
        data?.id != self.userInfo?.userId
      ) {
        // if (data?.id == data?.creatorId) {
        //   // support center
        //   data?.users?.some((item) => {
        //     if (item.userId == data?.id) {
        //       oppositeUser = item;
        //       return true;
        //     }
        //   });
        // } else {
        //   data?.users?.some((item) => {
        //     if (item.userId != self.userInfo?.userId) {
        //       oppositeUser = item;
        //       return true;
        //     }
        //   });
        // }
        if (data.type == self.$dataModules.conversation.type.private) {
          // 单聊

          data?.users?.some((item) => {
            if (item.userId != self.userInfo?.userId) {
              oppositeUser = item;
              title = item.nickname;
              return true;
            }
          });
        } else {
          // 群聊
          if (!self.$tools.isNull(data?.creatorName)) {
            title = data.creatorName;
          }
        }
      }

      return {
        name: (title || data.title) ?? "",
        userId: oppositeUser?.userId ?? "",
      };
    },
    getConversationUnread(data) {
      let self = this;
      let unread =
        data?.users?.filter((item) => item.userId == self.userInfo?.userId)[0]
          ?.unreadMessageCount ?? 0;
      return unread;
    },
    openConversation(data) {
      let self = this;
      self.currentConversationId = data.id;

      console.log("open: ", data);

      // 读取消息
    },
    onInputSearch(cont) {
      let self = this;
      self.search = cont;
    },
    onClickAdd() {
      let self = this;
    },
  },
};
</script>

<style></style>
