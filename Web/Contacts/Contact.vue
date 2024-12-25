<template>
  <div>
    <div class="tk-g-root-container tk-layout-flex-row">
      <div class="tk-layout-flex-1 tk-layout-flex-row tk-layout-full-height">
        <div class="tk-layout-page-left-with-index tk-layout-full-height">
          <contact-list
            @preview="preview"
            @hidePreview="showPreview = false"
            @onClickAdd="
              currentRole = $event;
              showCreate = true;
            "
          ></contact-list>
        </div>

        <div
          class="tk-layout-page-right tk-layout-full-height tk-scrollbar tk-overflow-y"
        >
          <template v-if="showPreview">
            <teacher-profile
              v-if="
                $commons.userIsInstructor(previewData) ||
                $commons.userIsInstructor(previewData.userInfo)
              "
              :userId="previewData.userId"
            ></teacher-profile>

            <parent-profile
              v-if="$commons.userIsParent(previewData)"
              :userId="previewData.userId"
              :data="previewData"
            ></parent-profile>

            <parent-profile
              v-if="$commons.userIsParent(previewData)"
              :userId="previewData.userId"
              :data="previewData"
            ></parent-profile>

            <student-profile
              v-if="$commons.userIsStudent(previewData)"
              :userId="previewData.studentId || previewData.userId"
              :data="previewData"
              @onClickDelete="onClickDelete"
              @onClickArchive="onClickArchive"
            ></student-profile>
          </template>

          <div class="tk-position-relative tk-layout-full" v-else>
            <img
              class="tk-position-center"
              src="/img/icons/tk/img_teachers.png"
              style="width: 80%"
            />
          </div>
        </div>
      </div>

      <!-- 右侧工具栏 -->
      <tool-bar :bars="funcBars" class="tk-right-tool-bar"></tool-bar>
    </div>

    <!-- new contact -->
    <new-user
      class="tk-popup-outer"
      v-if="showCreate || showEdit"
      :title="formatUserPopupTitle()"
      :button="
        showCreate
          ? $t('teacher.send_invite').toUpperCase()
          : $t('general.save').toUpperCase()
      "
      :data="showCreate ? null : { ...previewData }"
      :type="showCreate ? 'add' : 'edit'"
      :roleId="currentRole"
      @close="
        showCreate = false;
        showEdit = false;
      "
      @onSuccess="onSuccess"
    ></new-user>

    <!-- alert -->
    <alert
      :title="alert.title"
      :content="alert.content"
      :left="alert.left"
      :right="alert.right"
      :leftClass="alert.leftClass"
      :rightClass="alert.rightClass"
      v-if="alert.show"
      @close="closeAlert()"
      @onLeftTapped="alert.onLeftTap"
      @onRightTapped="alert.onRightTap"
    ></alert>
  </div>
</template>

<script>
import { Dropdown, DropdownItem, DropdownMenu } from "element-ui";
export default {
  components: {
    [Dropdown.name]: Dropdown,
    [DropdownItem.name]: DropdownItem,
    [DropdownMenu.name]: DropdownMenu,
    ContactList: () => import("@/tkViews/Contact/ContactList"),
    CreateStudent: () => import("./components/Modal/CreateStudent.vue"),
    NewUser: () => import("./components/Modal/NewUser.vue"),
    toolBar: () => import("@/tkViews/components/layout/RightToolbar.vue"),
    TeacherProfile: () => import("@/tkViews/Pages/TeacherProfile.vue"),
    ParentProfile: () => import("@/tkViews/Pages/ParentProfile.vue"),
    StudentProfile: () => import("@/tkViews/Pages/StudentProfile.vue"),
    Alert: () => import("@/tkViews/components/Modal/Alert"),
  },
  data() {
    return {
      showPreview: false,
      showCreate: false,
      showEdit: false,

      currentRole: "",

      previewData: {},
      studioInfo: {},
      userInfo: {},

      funcBars: [],
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
      },
    };
  },
  async created() {
    let self = this;
    await self.initBasicData();
  },
  mounted() {
    let self = this;
  },
  watch: {},
  methods: {
    closeAlert() {
      this.alert.show = false;
    },
    async initBasicData() {
      let self = this;

      self.userInfo = await self.$userService.userInfo();
      self.studioInfo = await self.$userService.studioInfo();

      self.initFuncBars();
    },
    formatUserPopupTitle() {
      let self = this;
      let title = "";

      switch (self.currentRole) {
        case self.$dataModules.user.roleId.student:
          title = self.showCreate ? "Add Student" : "Edit Student";
          break;
        case self.$dataModules.user.roleId.parent:
          title = self.showCreate ? "Add Parent" : "Edit Parent";
          break;
        case self.$dataModules.user.roleId.instructor:
          title = self.showCreate ? "Add Instructor" : "Edit Instructor";
          break;
      }

      return title;
    },
    async onClickDelete() {
      let self = this;
      self.alert.show = true;
      self.alert.title = self.$i18n.t("general.delete") + "?";
      self.alert.content = self.$i18n.t("alert").delete_student({
        name: self.previewData?.name,
      });
      self.alert.left = self.$i18n.t("general.delete");
      self.alert.right = self.$i18n.t("general.go_back");
      self.alert.leftClass = "tk-font-color-red";
      self.alert.rightClass = "tk-font-color-white";
      self.alert.onLeftTap = () => {
        self.deleteStudent();
      };
      self.alert.onRightTap = () => {
        self.alert.show = false;
      };
    },
    async onClickArchive() {
      let self = this;
      self.alert.show = true;
      self.alert.title = self.$i18n.t("general.archive") + "?";
      self.alert.content = self.$i18n.t("alert").archive_student({
        name: self.previewData?.name,
      });
      self.alert.left = self.$i18n.t("general.archive");
      self.alert.right = self.$i18n.t("general.go_back");
      self.alert.leftClass = "tk-font-color-red";
      self.alert.rightClass = "tk-font-color-white";
      self.alert.onLeftTap = () => {
        self.archiveStudent();
      };
      self.alert.onRightTap = () => {
        self.alert.show = false;
      };
    },
    // 删除 archived 学生
    deleteStudent() {
      let self = this;
      let removeStudent = self.$functionsService.removeStudent;
      let now = self.$moment().unix();

      self.$bus.$emit("showFullCover", {
        text: self.$i18n.t("notification.loading.delete"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      removeStudent({
        studentId: self.previewData?.studentId || self.previewData?.userId,
        studioId: self.studioInfo.id,
      })
        .then((result) => {
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.success.delete"),
            type: "success",
            unix: now,
          });
          self.showPreview = false;
          self.alert.show = false;
        })
        .catch((err) => {
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.failed.delete"),
            type: "error",
            unix: now,
          });

          console.log("Delete archived student failed: ", err);
          self.alert.show = false;
        });
    },
    // archive 学生
    archiveStudent() {
      let self = this;
      let archiveStudents = self.$functionsService.archiveStudents;
      let now = self.$moment().unix();

      self.$bus.$emit("showFullCover", {
        text: self.$i18n.t("notification.loading.archive"),
        type: "loading",
        timeout: 0,
        unix: now,
      });

      archiveStudents({
        studentIds: [self.previewData?.studentId || self.previewData?.userId],
        studioId: self.studioInfo.id,
      })
        .then((result) => {
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.success.archive"),
            type: "success",
            unix: now,
          });
          self.showPreview = false;
          self.alert.show = false;
        })
        .catch((err) => {
          self.$bus.$emit("hideFullCover", {
            message: self.$i18n.t("notification.failed.archive"),
            type: "error",
            unix: now,
          });

          console.log("Delete archived student failed: ", err);
          self.alert.show = false;
        });
    },
    async onSuccess(data) {
      let self = this;
      self.showCreate = false;
      self.showEdit = false;
    },
    initFuncBars() {
      let self = this;
      let preview = self.previewData;
      let funcBars = [];
      if (preview.userId) {
        let active = Boolean(preview.active || preview?.userInfo?.active);
        console.log("active: ", active);

        if (!active) {
          funcBars.push({
            label: self.$i18n.t("general.edit"),
            icon: "fas fa-edit",
            onClick() {
              self.showEdit = true;
            },
          });
        }

        funcBars.push({
          label: self.$i18n.t("general.delete"),
          icon: "fas fa-trash",
          onClick() {
            self.onClickDelete();
          },
        });
      } else {
        funcBars = [];
      }
      // TODO:
      // self.funcBars = funcBars;
      self.funcBars = [];
    },
    showProfile() {
      this.$bus.$emit("showProfile");
    },
    isNull(obj) {
      return this.$tools.isNull(obj);
    },
    objIsNull(obj) {
      return this.$tools.objIsNull(obj);
    },
    async preview(data) {
      console.log("preview: ", data);
      let self = this;
      self.showPreview = true;
      self.previewData = data;
      self.initFuncBars();
    },
    async onClickDelete() {
      let self = this;
      self.alert.show = true;
      self.alert.title = self.$i18n.t("general.delete") + "?";
      self.alert.content = self.$i18n.t("alert").delete_teacher({
        name: self.previewData?.userInfo?.name,
      });
      self.alert.left = self.$i18n.t("general.delete");
      self.alert.right = self.$i18n.t("general.go_back");
      self.alert.leftClass = "tk-font-color-red";
      self.alert.rightClass = "tk-font-color-white";
      self.alert.onLeftTap = () => {
        self.deleteTeacher();
      };
      self.alert.onRightTap = () => {
        self.alert.show = false;
      };
    },
    // TODO: 删除老师
    deleteTeacher() {
      let self = this;
      self.alert.show = false;
    },
  },
};
</script>
