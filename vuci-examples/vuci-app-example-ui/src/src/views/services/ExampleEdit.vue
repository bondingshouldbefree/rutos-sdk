<template>
  <vuci-form v-slot="{ uciData }" config="example" editing>
    <vuci-named-section
      v-slot="{ s }"
      :title="$t('Example configuration: %s').format(section.id)"
      :uci-data="uciData"
      :endpoints="[{ endpoint: 'example_c/config' }]"
      :name="section.id"
      data-key="example"
    >
      <vuci-form-item-switch :uci-section="s" :label="$t('Bool')" name="bool" />
      <vuci-form-item-input
        :uci-section="s"
        :label="$t('Text')"
        name="text"
        maxlength="100"
        minlength="5"
      />
      <vuci-form-item-select
        :uci-section="s"
        :label="$t('Select')"
        name="select"
        :options="selectOptions"
      />
      <vuci-form-item-select
        :uci-section="s"
        name="multi_select"
        :label="$t('Select Multiple')"
        :placeholder="$t('Any')"
        :options="selectOptions"
        maxlength="64"
        multiple
        allow-create
        rules="defaulttype"
      />
    </vuci-named-section>
  </vuci-form>
</template>

<script>
export default {
  props: {
    section: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectOptions: [
        ["first", this.$t("Example 1")],
        ["second", this.$t("Example 2")],
      ],
    };
  },
};
</script>
