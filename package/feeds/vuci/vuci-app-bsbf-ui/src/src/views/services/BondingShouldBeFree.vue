<template>
  <iframe
    ref="iframeRef"
    src="/bsbf-client-web/?theme=light"
    title="BondingShouldBeFree"
    :style="{ width: '100%', minHeight: iframeHeight }"
    @load="updateHeight"
  />
</template>

<script setup>
import { ref } from 'vue'

/* Create a null iframeRef, which will be populated by the iframe DOM node ref
 * when the iframe DOM node is mounted.
 */
const iframeRef = ref(null)
/* Start the minimum height from 1000px. */
const iframeHeight = ref('1000px')

let resizeObserver = null

function syncHeight() {
  const root = iframeRef.value?.contentDocument?.documentElement
  if (!root) return
  const h = root.scrollHeight
  if (h > 0) iframeHeight.value = `${h}px`
}

async function updateHeight() {
  resizeObserver?.disconnect()
  resizeObserver = null

  const doc = iframeRef.value?.contentDocument
  if (!doc?.documentElement) return

  syncHeight()
  resizeObserver = new ResizeObserver(syncHeight)
  resizeObserver.observe(doc.documentElement)
}
</script>
