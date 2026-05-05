<script setup lang="ts">
import { ref, watch, onUnmounted } from 'vue'

const props = defineProps<{
  originalImage: string | null
  processedImage: string | null
  isProcessing: boolean
  bgType: 'transparent' | 'color' | 'image'
  bgColor: string
  bgImage: string | null
  removeBgToggle: boolean
}>()

const emit = defineEmits<{
  (e: 'reset'): void
  (e: 'export'): void
  (e: 'error', message: string): void
  (e: 'update:bgType', value: 'transparent' | 'color' | 'image'): void
  (e: 'update:bgColor', value: string): void
  (e: 'update:bgImage', value: string | null): void
  (e: 'update:removeBgToggle', value: boolean): void
}>()

const onColorPick = (color: string) => {
  emit('update:bgType', 'color')
  emit('update:bgColor', color)
}

const onImageUpload = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    const file = target.files[0]
    if (file) {
      if (!file.type.startsWith('image/')) {
        emit('error', 'Invalid format. Please select an image file.')
        return
      }
      if (props.bgImage && props.bgImage.startsWith('blob:')) {
        URL.revokeObjectURL(props.bgImage)
      }
      emit('update:bgType', 'image')
      emit('update:bgImage', URL.createObjectURL(file))
    }
  }
}

const zoomLevel = ref(100)
const zoomIn = () => { if (zoomLevel.value < 500) zoomLevel.value += 10 }
const zoomOut = () => { if (zoomLevel.value > 10) zoomLevel.value -= 10 }

const imgDimensions = ref({ width: 0, height: 0 })
const previewUrl = ref<string | null>(null)

const generatePreview = async () => {
  const mainSrc = (props.removeBgToggle ? props.processedImage : props.originalImage)
  if (!mainSrc || !imgDimensions.value.width) return

  const canvas = document.createElement('canvas')
  canvas.width = imgDimensions.value.width
  canvas.height = imgDimensions.value.height
  const ctx = canvas.getContext('2d')
  if (!ctx) return

  if (props.removeBgToggle) {
    if (props.bgType === 'color') {
      ctx.fillStyle = props.bgColor
      ctx.fillRect(0, 0, canvas.width, canvas.height)
    } else if (props.bgType === 'image' && props.bgImage) {
      const bgImg = new Image()
      bgImg.src = props.bgImage
      await new Promise(r => bgImg.onload = r)
      const sRatio = bgImg.width / bgImg.height
      const cRatio = canvas.width / canvas.height
      let sx, sy, sWidth, sHeight
      if (sRatio > cRatio) {
        sHeight = bgImg.height; sWidth = bgImg.height * cRatio
        sy = 0; sx = (bgImg.width - sWidth) / 2
      } else {
        sWidth = bgImg.width; sHeight = bgImg.width / cRatio
        sx = 0; sy = (bgImg.height - sHeight) / 2
      }
      ctx.drawImage(bgImg, sx, sy, sWidth, sHeight, 0, 0, canvas.width, canvas.height)
    }
  } else {
    ctx.fillStyle = '#ffffff'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
  }

  const mainImg = new Image()
  mainImg.src = mainSrc
  await new Promise(r => mainImg.onload = r)
  ctx.drawImage(mainImg, 0, 0, canvas.width, canvas.height)

  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  canvas.toBlob((blob) => {
    if (blob) previewUrl.value = URL.createObjectURL(blob)
  }, 'image/png')
}

const onImageLoad = (e: Event) => {
  const img = e.target as HTMLImageElement
  const firstLoad = imgDimensions.value.width === 0
  imgDimensions.value = { width: img.naturalWidth, height: img.naturalHeight }
  img.style.opacity = '1'
  if (firstLoad) generatePreview()
}

watch([() => props.bgType, () => props.bgColor, () => props.bgImage, () => props.removeBgToggle, () => props.processedImage], () => {
  generatePreview()
})

onUnmounted(() => {
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
})

const handleWheel = (e: WheelEvent) => {
  if (e.ctrlKey) {
    e.preventDefault()
    if (e.deltaY < 0) zoomIn()
    else zoomOut()
  }
}
</script>

<template>
  <!-- editor-root: explicit height so the centering div always has a real pixel height -->
  <div class="editor-root" @wheel="handleWheel">

    <!-- Processing Overlay -->
    <Transition enter-active-class="transition-opacity duration-300" leave-active-class="transition-opacity duration-300" enter-from-class="opacity-0" leave-to-class="opacity-0">
      <div v-if="isProcessing" class="fixed inset-0 z-[100] bg-white/60 backdrop-blur-sm flex flex-col items-center justify-center">
        <div class="w-12 h-12 border-4 border-primary border-t-transparent animate-spin rounded-full"></div>
        <p class="text-primary mt-6 text-sm font-bold tracking-widest uppercase">Analyzing Image</p>
      </div>
    </Transition>

    <!-- Centering canvas: fills the root's definite height, centers content -->
    <div class="editor-canvas">

      <!-- Image + Toolbar stacked group -->
      <div class="editor-content">

        <!-- Image Preview -->
        <div
          v-if="(removeBgToggle && processedImage) || (!removeBgToggle && originalImage)"
          class="preview-wrapper transition-all duration-500 ease-in-out shadow-2xl rounded-xl overflow-hidden"
          :class="[
            !previewUrl && bgType === 'transparent' && removeBgToggle ? 'checkerboard-inner' : '',
            !removeBgToggle ? 'bg-white shadow-none' : ''
          ]"
          :style="[
            !previewUrl && removeBgToggle && bgType === 'color' ? { backgroundColor: bgColor } : {},
            !previewUrl && removeBgToggle && bgType === 'image' && bgImage
              ? { backgroundImage: `url(${bgImage})`, backgroundSize: 'cover', backgroundPosition: 'center' }
              : {},
            { transform: `scale(${zoomLevel / 100})`, transformOrigin: 'center' }
          ]"
        >
          <img
            :src="previewUrl || (removeBgToggle ? processedImage! : originalImage!)"
            class="preview-img block select-none pointer-events-none transition-opacity duration-300"
            @load="onImageLoad"
            style="opacity: 0"
          />
        </div>

        <!-- Toolbar -->
        <div class="toolbar-wrap">
          <div class="toolbar-inner">

            <!-- Remove BG Toggle -->
            <button
              @click="emit('update:removeBgToggle', !removeBgToggle)"
              class="px-3 md:px-4 py-2 md:py-2.5 flex items-center gap-2 text-sm font-bold rounded-xl transition-all active:scale-95 shrink-0"
              :class="removeBgToggle ? 'bg-primary text-on-primary shadow-lg' : 'hover:bg-surface-container-high text-on-surface-variant'"
            >
              <span class="material-symbols-outlined text-[20px]" :style="removeBgToggle ? 'font-variation-settings: \'FILL\' 1' : ''">
                {{ removeBgToggle ? 'settings_backup_restore' : 'content_cut' }}
              </span>
              <span class="hidden md:inline">{{ removeBgToggle ? 'Restore Original' : 'Remove Background' }}</span>
            </button>

            <div class="toolbar-divider"></div>

            <!-- Background Type -->
            <div class="flex items-center gap-1 md:gap-2 p-1 bg-surface-container-low rounded-xl shrink-0">
              <!-- Transparent -->
              <button
                @click="emit('update:bgType', 'transparent')"
                class="w-8 h-8 md:w-9 md:h-9 rounded-lg flex items-center justify-center transition-all active:scale-90"
                :class="bgType === 'transparent' ? 'bg-surface shadow-sm ring-1 ring-primary/20' : 'hover:bg-surface/50'"
              >
                <span class="material-symbols-outlined text-[18px] md:text-[20px]">not_interested</span>
              </button>

              <!-- Color Picker -->
              <div class="relative w-8 h-8 md:w-9 md:h-9 rounded-lg overflow-hidden group active:scale-90 transition-transform"
                :class="bgType === 'color' ? 'ring-2 ring-primary ring-offset-2' : ''">
                <input type="color" :value="bgType === 'color' ? bgColor : '#ffffff'"
                  @input="e => onColorPick((e.target as HTMLInputElement).value)"
                  class="absolute inset-0 opacity-0 cursor-pointer w-full h-full p-0 z-10" />
                <div class="w-full h-full shadow-inner border border-outline-variant/20"
                  :style="{ backgroundColor: bgType === 'color' ? bgColor : '#ffffff' }">
                  <div class="w-full h-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/10">
                    <span class="material-symbols-outlined text-white text-[14px] md:text-[16px]">palette</span>
                  </div>
                </div>
              </div>

              <!-- BG Image Upload -->
              <label class="w-8 h-8 md:w-9 md:h-9 rounded-lg flex items-center justify-center cursor-pointer transition-all active:scale-90"
                :class="bgType === 'image' ? 'bg-surface shadow-sm ring-1 ring-primary/20' : 'hover:bg-surface/50'">
                <span class="material-symbols-outlined text-[18px] md:text-[20px]">image</span>
                <input type="file" class="hidden" accept="image/*" @change="onImageUpload" />
              </label>
            </div>

            <div class="toolbar-divider"></div>

            <!-- Zoom Controls -->
            <div class="flex items-center gap-0.5 md:gap-1 bg-surface-container-low p-1 rounded-xl shrink-0">
              <button @click="zoomOut" class="w-7 h-7 md:w-8 md:h-8 flex items-center justify-center hover:bg-surface rounded-lg transition-colors">
                <span class="material-symbols-outlined text-[16px] md:text-[18px]">remove</span>
              </button>
              <span class="text-[10px] md:text-xs font-bold w-10 md:w-12 text-center text-primary">{{ zoomLevel }}%</span>
              <button @click="zoomIn" class="w-7 h-7 md:w-8 md:h-8 flex items-center justify-center hover:bg-surface rounded-lg transition-colors">
                <span class="material-symbols-outlined text-[16px] md:text-[18px]">add</span>
              </button>
            </div>

            <div class="toolbar-divider"></div>

            <!-- Export -->
            <button @click="emit('export')"
              class="px-4 md:px-6 py-2 md:py-2.5 bg-primary text-on-secondary rounded-xl text-sm font-bold shadow-lg hover:brightness-110 active:scale-95 transition-all flex items-center gap-2 shrink-0">
              <span class="hidden md:inline">Export</span>
              <span class="material-symbols-outlined text-[18px]">download</span>
            </button>

          </div>
        </div>
      </div>
    </div>

    <!-- Reset Button (top-left, absolute) -->
    <div class="absolute top-4 left-4 md:top-6 md:left-6 z-40">
      <button @click="emit('reset')"
        class="w-8 h-8 md:w-10 md:h-10 rounded-full bg-surface shadow-lg flex items-center justify-center hover:bg-error hover:text-on-error transition-all group active:scale-90">
        <span class="material-symbols-outlined text-[18px] md:text-[20px] transition-transform group-hover:rotate-90">close</span>
      </button>
    </div>

  </div>
</template>

<style scoped>
/*
 * Root: explicit height using the known navbar height (4rem = 64px).
 * This guarantees the centering div always has a real pixel height
 * without relying on any nested flex height chain.
 */
.editor-root {
  position: relative;
  width: 100%;
  height: calc(100vh - 4rem);
  overflow: hidden;
  background: white;
}

/*
 * Canvas: fills the root's known height, perfectly centers its child.
 */
.editor-canvas {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

@media (min-width: 768px) {
  .editor-canvas { padding: 2rem; }
}

/*
 * Content group: image stacked above toolbar, centered horizontally.
 */
.editor-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  /* constrain to viewport so nothing overflows on narrow screens */
  max-width: calc(100vw - 2rem);
  width: 100%;
}

@media (min-width: 768px) {
  .editor-content { gap: 1.5rem; max-width: calc(100vw - 4rem); }
}

/*
 * Preview wrapper: inline so it hugs the image naturally.
 */
.preview-wrapper {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

/*
 * Image: natural size, capped to viewport, min size so tiny images stay visible.
 */
.preview-img {
  display: block;
  width: auto;
  height: auto;
  max-width: min(90vw, 900px);
  /* leave space for toolbar + gaps + padding */
  max-height: calc(100vh - 200px);
  /* smaller min on mobile so tiny images don't push toolbar off screen */
  min-width: 120px;
  min-height: 120px;
  object-fit: contain;
}

@media (min-width: 640px) {
  .preview-img { min-width: 200px; min-height: 200px; max-height: calc(100vh - 260px); }
}

/* Toolbar */
.toolbar-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  z-index: 40;
  width: 95%;
}

@media (min-width: 640px) {
  .toolbar-wrap { width: auto; }
}

.toolbar-inner {
  /* plain values — no undefined CSS custom properties */
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(0, 0, 0, 0.1);
  padding: 0.375rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  box-shadow: 0 10px 40px -8px rgb(0 0 0 / 0.2);
  border-radius: 1rem;
  width: 100%;
  overflow-x: auto;
  scrollbar-width: none;
  /* don't shrink — scroll instead */
  flex-shrink: 0;
}

@media (min-width: 640px) {
  .toolbar-inner { width: auto; gap: 0.5rem; padding: 0.5rem; }
}

.toolbar-inner::-webkit-scrollbar { display: none; }

.toolbar-divider {
  width: 1px;
  height: 2rem;
  background: rgba(0, 0, 0, 0.12);
  flex-shrink: 0;
  margin: 0 0.125rem;
}

@media (min-width: 768px) {
  .toolbar-divider { margin: 0 0.25rem; }
}
</style>
