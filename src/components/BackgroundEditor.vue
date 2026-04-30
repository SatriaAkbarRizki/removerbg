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

    // Draw Background
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
                sHeight = bgImg.height
                sWidth = bgImg.height * cRatio
                sy = 0
                sx = (bgImg.width - sWidth) / 2
            } else {
                sWidth = bgImg.width
                sHeight = bgImg.width / cRatio
                sx = 0
                sy = (bgImg.height - sHeight) / 2
            }
            ctx.drawImage(bgImg, sx, sy, sWidth, sHeight, 0, 0, canvas.width, canvas.height)
        }
    } else {
        ctx.fillStyle = '#ffffff'
        ctx.fillRect(0, 0, canvas.width, canvas.height)
    }

    // Draw Main Image
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
  <div class="flex-1 flex flex-col w-full h-full bg-white overflow-hidden relative" @wheel="handleWheel"> 
    
    <!-- Central Canvas Area -->
    <section class="flex-1 relative overflow-hidden flex flex-col h-full bg-white">
        <!-- Loader Overlays -->
        <Transition enter-active-class="transition-opacity duration-300" leave-active-class="transition-opacity duration-300" enter-from-class="opacity-0" leave-to-class="opacity-0">
            <div v-if="isProcessing" class="fixed inset-0 z-[100] bg-white/60 backdrop-blur-sm flex flex-col items-center justify-center">
                <div class="w-12 h-12 border-4 border-primary border-t-transparent animate-spin rounded-full"></div>
                <p class="text-primary mt-6 text-sm font-bold tracking-widest uppercase">Analyzing Image</p>
            </div>
        </Transition>

        <!-- Canvas Area -->
        <div class="flex-1 relative flex items-center justify-center p-4 md:p-8 h-full w-full bg-white">
            
            <!-- Image Preview Wrapper (Centered in entire area) -->
            <div 
                v-if="(removeBgToggle && processedImage) || (!removeBgToggle && originalImage)"
                class="relative flex items-center justify-center transition-all duration-500 ease-in-out shadow-2xl rounded-xl overflow-hidden"
                :class="[
                    !previewUrl && bgType === 'transparent' && removeBgToggle ? 'checkerboard-inner' : '',
                    !removeBgToggle ? 'bg-white shadow-none' : ''
                ]"
                :style="[
                    !previewUrl && removeBgToggle && bgType === 'color' ? { backgroundColor: bgColor } : {},
                    !previewUrl && removeBgToggle && bgType === 'image' && bgImage ? { backgroundImage: `url(${bgImage})`, backgroundSize: 'cover', backgroundPosition: 'center' } : {},
                    { transform: `scale(${zoomLevel / 100})`, transformOrigin: 'center' },
                    { 
                        width: '100%',
                        maxWidth: imgDimensions.width ? `min(100%, ${imgDimensions.width}px)` : '900px',
                        maxHeight: 'calc(100vh - 200px)',
                        aspectRatio: imgDimensions.width ? `${imgDimensions.width} / ${imgDimensions.height}` : 'auto'
                    }
                ]"
            >
                <img 
                    :src="previewUrl || (removeBgToggle ? processedImage! : originalImage!)" 
                    class="block w-full h-full object-contain select-none pointer-events-none transition-opacity duration-300"
                    @load="onImageLoad"
                    style="opacity: 0"
                />
            </div>

            <!-- Floating Tool Bar (Positioned at bottom but absolute) -->
            <div class="absolute bottom-6 md:bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-4 z-40 w-[95%] sm:w-fit">
                <div class="bg-surface/90 backdrop-blur-md border border-outline-variant/50 p-1.5 md:p-2 flex items-center justify-center gap-1 md:gap-2 shadow-xl rounded-2xl w-full sm:w-auto overflow-x-auto no-scrollbar">
                    
                    <!-- Remove BG Toggle -->
                    <button 
                        @click="emit('update:removeBgToggle', !removeBgToggle)"
                        class="px-3 md:px-4 py-2 md:py-2.5 flex items-center gap-2 text-sm font-bold rounded-xl transition-all active:scale-95 shrink-0"
                        :class="removeBgToggle ? 'bg-primary text-on-primary shadow-lg' : 'hover:bg-surface-container-high text-on-surface-variant'"
                    >
                        <span class="material-symbols-outlined text-[20px]" :style="removeBgToggle ? 'font-variation-settings: \'FILL\' 1' : ''">{{ removeBgToggle ? 'settings_backup_restore' : 'content_cut' }}</span>
                        <span class="hidden md:inline">{{ removeBgToggle ? 'Restore Original' : 'Remove Background' }}</span>
                    </button>

                    <div class="w-[1px] h-8 bg-outline-variant/30 mx-0.5 md:mx-1 shrink-0"></div>

                    <!-- Background Selection -->
                    <div class="flex items-center gap-1 md:gap-2 p-1 bg-surface-container-low rounded-xl shrink-0">
                        <button 
                            @click="emit('update:bgType', 'transparent')"
                            v-tooltip="'Transparent'"
                            class="w-8 h-8 md:w-9 md:h-9 rounded-lg flex items-center justify-center transition-all active:scale-90"
                            :class="bgType === 'transparent' ? 'bg-surface shadow-sm ring-1 ring-primary/20' : 'hover:bg-surface/50'"
                        >
                            <span class="material-symbols-outlined text-[18px] md:text-[20px]">not_interested</span>
                        </button>

                        <!-- Color Picker Wrapper -->
                        <div class="relative w-8 h-8 md:w-9 md:h-9 rounded-lg overflow-hidden group active:scale-90 transition-transform" :class="bgType === 'color' ? 'ring-2 ring-primary ring-offset-2' : ''">
                            <input type="color" :value="bgType==='color'?bgColor:'#ffffff'" @input="e => onColorPick((e.target as HTMLInputElement).value)" class="absolute inset-0 opacity-0 cursor-pointer w-full h-full p-0 z-10" />
                            <div class="w-full h-full shadow-inner border border-outline-variant/20" :style="{ backgroundColor: bgType === 'color' ? bgColor : '#ffffff' }">
                                <div class="w-full h-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/10">
                                    <span class="material-symbols-outlined text-white text-[14px] md:text-[16px]">palette</span>
                                </div>
                            </div>
                        </div>

                        <!-- Image Upload -->
                        <label class="w-8 h-8 md:w-9 md:h-9 rounded-lg flex items-center justify-center cursor-pointer transition-all active:scale-90" :class="bgType==='image' ? 'bg-surface shadow-sm ring-1 ring-primary/20' : 'hover:bg-surface/50'">
                            <span class="material-symbols-outlined text-[18px] md:text-[20px]">image</span>
                            <input type="file" class="hidden" accept="image/*" @change="onImageUpload" />
                        </label>
                    </div>

                    <div class="w-[1px] h-8 bg-outline-variant/30 mx-0.5 md:mx-1 shrink-0"></div>

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

                    <div class="w-[1px] h-8 bg-outline-variant/30 mx-0.5 md:mx-1 shrink-0"></div>

                    <!-- Export Action -->
                    <button @click="emit('export')" class="px-4 md:px-6 py-2 md:py-2.5 bg-primary text-on-secondary rounded-xl text-sm font-bold shadow-lg hover:brightness-110 active:scale-95 transition-all flex items-center gap-2 shrink-0">
                        <span class="hidden md:inline">Export</span>
                        <span class="material-symbols-outlined text-[18px]">download</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- Top Left Actions (Reset) -->
        <div class="absolute top-4 left-4 md:top-6 md:left-6 z-40">
            <button @click="emit('reset')" class="w-8 h-8 md:w-10 md:h-10 rounded-full bg-surface shadow-lg flex items-center justify-center hover:bg-error hover:text-on-error transition-all group active:scale-90">
                <span class="material-symbols-outlined text-[18px] md:text-[20px] transition-transform group-hover:rotate-90">close</span>
            </button>
        </div>
    </section>
  </div>
</template>

<style scoped>
</style>
