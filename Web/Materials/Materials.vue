<template>
  <div class="tk-g-root-container tk-layout-flex-row">
    <materials
      class="tk-layout-full tk-layout-flex-1"
      style="width: calc(100% - 100px)"
    ></materials>

    <!-- 右侧工具栏 -->
    <tool-bar :bars="funcBars" class="tk-right-tool-bar"></tool-bar>
  </div>
</template>

<script>
export default {
  data() {
    return {
      funcBars: [],
      userInfo: {},
    };
  },
  components: {
    ToolBar: () => import("@/tkViews/components/layout/RightToolbar.vue"),
    Materials: () => import("@/tkViews/Pages/Materials.vue"),
  },
  async created() {
    let self = this;
    self.userInfo = await self.$userService.userInfo();
    self.initFuncBars();
  },
  async mounted() {
    let self = this;
  },
  methods: {
    initFuncBars() {
      let self = this;
      let add = [
        {
          icon: "fa-solid fa-folder-plus",
          text: "Create new folder",
          onItemClick() {
            self.$bus.$emit("onClickNewFolder");
          },
        },
        {
          icon: "fa-solid fa-cloud-arrow-up",
          text: "Upload file",
          onItemClick() {
            self.$bus.$emit("onClickUploadFile");
          },
        },
        {
          icon: "fa-solid fa-link",
          text: "Add shared link",
          onItemClick() {
            self.$bus.$emit("onClickSharedLink");
          },
        },
      ];
      let group = [
        {
          icon: "fa-solid fa-calendar-day",
          text: "Group by day",
          onItemClick() {
            self.$bus.$emit("onClickGroupMaterial", "DAY");
          },
        },
        {
          icon: "fa-solid fa-calendar-week",
          text: "Group by week",
          onItemClick() {
            self.$bus.$emit("onClickGroupMaterial", "WEEK");
          },
        },
        {
          icon: "fa-solid fa-calendar-days",
          text: "Group by month",
          onItemClick() {
            self.$bus.$emit("onClickGroupMaterial", "MONTH");
          },
        },
        {
          icon: "fa-solid fa-folder",
          text: "Group by file type",
          onItemClick() {
            self.$bus.$emit("onClickGroupMaterial", "FILE_TYPE");
          },
        },
        {
          icon: "fa-solid fa-folder-minus",
          text: "Cancel grouping",
          onItemClick() {
            self.$bus.$emit("onClickGroupMaterial", "CANCEL");
          },
        },
      ];

      let funcBars = [
        {
          label: self.$i18n.t("general.add"),
          icon: "fa-solid fa-plus",
          list: add,
          key: 0,
          onClick() {},
        },
        {
          label: "Grouping",
          icon: "fa-solid fa-layer-group",
          list: group,
          key: 1,
          onClick() {},
        },
        // {
        //   label: self.$i18n.t("general.download"),
        //   icon: "fa-solid fa-cloud-arrow-down",
        //   onClick() {
        //   },
        // },
        // {
        //   label: self.$i18n.t("general.rename"),
        //   icon: "fa-solid fa-pen-to-square",
        //   onClick() {
        //   },
        // },
        // {
        //   label: self.$i18n.t("general.move"),
        //   icon: "fa-solid fa-up-down-left-right",
        //   onClick() {
        //   },
        // },
        // {
        //   label: self.$i18n.t("general.share"),
        //   icon: "fa-solid fa-share",
        //   onClick() {
        //   },
        // },
        // {
        //   label: self.$i18n.t("general.delete"),
        //   icon: "fa-solid fa-trash",
        //   onClick() {
        //   },
        // },
      ];

      // if (self.$commons.userIsInstructor(self.userInfo)) {
      //   funcBars.push({
      //     label: "Filter by student",
      //     icon: "fa-solid fa-user",
      //     onClick() {
      //       self.$bus.$emit("onClickFilterStudent");
      //     },
      //   });
      // }

      self.funcBars = !self.$commons.userIsParent(self.userInfo)
        ? [
            ...funcBars,
            {
              label: "Refresh",
              icon: "fa-solid fa-rotate-right",
              onClick() {
                self.$bus.$emit("onClearCacheAndRefreshMaterial");
              },
            },
          ]
        : [];
    },
  },
};
</script>

<style></style>
