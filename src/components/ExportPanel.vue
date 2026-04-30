<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'

const props = defineProps<{
    processedImage: string | null
    originalImage: string | null
    bgType: 'transparent' | 'color' | 'image'
    bgColor: string
    bgImage: string | null
    removeBgToggle: boolean
}>()

const emit = defineEmits<{
    (e: 'back'): void
    (e: 'reset'): void
}>()

const quality = ref(100)
const format = ref<'PNG' | 'JPG' | 'WEBP'>('PNG')
const width = ref(1000)
const height = ref(1000)
const estimatedSize = ref("Calculating...")
const previewUrl = ref<string | null>(null)

const zoomLevel = ref(100)
const zoomIn = () => { if (zoomLevel.value < 500) zoomLevel.value += 10 }
const zoomOut = () => { if (zoomLevel.value > 10) zoomLevel.value -= 10 }

const imgDimensions = ref({ width: 0, height: 0 })
const onImageLoad = (e: Event) => {
    const img = e.target as HTMLImageElement
    imgDimensions.value = { width: img.naturalWidth, height: img.naturalHeight }
}

const handleWheel = (e: WheelEvent) => {
  if (e.ctrlKey) {
    e.preventDefault()
    if (e.deltaY < 0) zoomIn()
    else zoomOut()
  }
}

const getCanvasBlob = async (): Promise<Blob | null> => {
    if (!props.processedImage && !props.originalImage) return null
    if (width.value <= 0 || height.value <= 0) return null

    const canvas = document.createElement('canvas')
    canvas.width = Number(width.value)
    canvas.height = Number(height.value)
    const ctx = canvas.getContext('2d')
    if (!ctx) return null
    
    if (props.bgType === 'color' || format.value === 'JPG') {
        ctx.fillStyle = props.bgType === 'color' ? props.bgColor : '#ffffff'
        ctx.fillRect(0, 0, canvas.width, canvas.height)
    }

    if (props.bgType === 'image' && props.bgImage) {
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

    const mainImg = new Image()
    mainImg.src = (props.removeBgToggle ? props.processedImage : props.originalImage) || ''
    await new Promise(r => mainImg.onload = r)
    
    const ratio = Math.min(canvas.width / mainImg.width, canvas.height / mainImg.height)
    const newWidth = mainImg.width * ratio
    const newHeight = mainImg.height * ratio
    const dx = (canvas.width - newWidth) / 2
    const dy = (canvas.height - newHeight) / 2
    
    ctx.drawImage(mainImg, 0, 0, mainImg.width, mainImg.height, dx, dy, newWidth, newHeight)

    const mimeType = format.value === 'JPG' ? 'image/jpeg' : format.value === 'WEBP' ? 'image/webp' : 'image/png'
    const q = format.value === 'PNG' ? undefined : quality.value / 100

    return new Promise((resolve) => {
        canvas.toBlob((blob) => resolve(blob), mimeType, q)
    })
}

const updateEstimatedSize = async () => {
    const blob = await getCanvasBlob()
    if (blob) {
        const mb = blob.size / (1024 * 1024)
        estimatedSize.value = mb < 0.1 ? (blob.size / 1024).toFixed(1) + " KB" : mb.toFixed(1) + " MB"
        if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
        previewUrl.value = URL.createObjectURL(blob)
    } else {
        estimatedSize.value = "N/A"
    }
}

let debounceTimer: any
watch([quality, format, width, height], () => {
    estimatedSize.value = "Calculating..."
    clearTimeout(debounceTimer)
    debounceTimer = setTimeout(updateEstimatedSize, 500)
})

onMounted(async () => {
    if (props.originalImage) {
        const img = new Image()
        img.src = props.originalImage
        await new Promise(r => img.onload = r)
        width.value = img.width
        height.value = img.height
    }
    updateEstimatedSize()
})

onUnmounted(() => {
    if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
})

const downloadImage = async () => {
    const blob = await getCanvasBlob()
    if (!blob) return
    const link = document.createElement('a')
    const documentUrl = URL.createObjectURL(blob)
    link.href = documentUrl
    link.download = `remover_export_${Date.now()}.${format.value.toLowerCase()}`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    setTimeout(() => URL.revokeObjectURL(documentUrl), 100)
}
</script>

<template>
  <div class="bg-white text-on-surface min-h-screen flex flex-col antialiased w-full h-full relative z-[100]" @wheel="handleWheel">
    <header class="w-full border-b border-outline-variant/30 h-16 flex items-center px-4 md:px-8 shrink-0 bg-surface/80 backdrop-blur-md">
        <button @click="emit('back')" class="flex items-center gap-2 text-on-surface-variant hover:text-primary transition-colors text-sm font-bold active:scale-95">
            <span class="material-symbols-outlined text-[20px]">arrow_back</span>
            <span>Back to Editor</span>
        </button>
    </header>

    <main class="flex-1 w-full flex flex-col md:flex-row md:h-[calc(100vh-64px)] overflow-y-auto md:overflow-hidden">
        
        <!-- Left: Image Preview -->
        <section class="w-full md:flex-1 border-b md:border-b-0 md:border-r border-outline-variant/30 flex flex-col bg-surface-container-low shrink-0 md:shrink">
            <div class="px-6 md:px-8 py-3 md:py-4 border-b border-outline-variant/30 flex items-center justify-between bg-surface shrink-0">
                <h2 class="text-[10px] md:text-xs font-bold uppercase tracking-widest flex items-center gap-2 opacity-60">Export Preview</h2>
                <div class="flex items-center gap-3 md:gap-4 bg-surface-container-high px-2.5 py-1 md:px-3 md:py-1.5 rounded-full">
                    <button @click="zoomOut" class="text-on-surface-variant hover:text-primary active:scale-90 transition-all"><span class="material-symbols-outlined text-[16px] md:text-[18px]">remove</span></button>
                    <span class="text-[10px] md:text-xs font-bold w-10 md:w-12 text-center">{{ zoomLevel }}%</span>
                    <button @click="zoomIn" class="text-on-surface-variant hover:text-primary active:scale-90 transition-all"><span class="material-symbols-outlined text-[16px] md:text-[18px]">add</span></button>
                </div>
            </div>

            <div class="flex-1 flex items-center justify-center p-4 md:p-8 bg-white min-h-[300px] md:min-h-0">
                <div 
                    v-if="previewUrl || processedImage || originalImage"
                    class="relative flex items-center justify-center transition-all duration-500 ease-in-out shadow-2xl rounded-xl overflow-hidden"
                    :class="[
                        !previewUrl && bgType === 'transparent' && removeBgToggle ? 'checkerboard-inner' : '',
                        !previewUrl && !removeBgToggle ? 'bg-white shadow-none' : ''
                    ]"
                    :style="[
                        !previewUrl && removeBgToggle && bgType === 'color' ? { backgroundColor: bgColor } : {},
                        !previewUrl && removeBgToggle && bgType === 'image' && bgImage ? { backgroundImage: `url(${bgImage})`, backgroundSize: 'cover', backgroundPosition: 'center' } : {},
                        { transform: `scale(${zoomLevel / 100})`, transformOrigin: 'center' },
                        {
                            width: '100%',
                            maxWidth: imgDimensions.width ? `min(100%, ${imgDimensions.width}px)` : '800px',
                            maxHeight: 'calc(100vh - 300px)',
                            aspectRatio: imgDimensions.width ? `${imgDimensions.width} / ${imgDimensions.height}` : 'auto'
                        }
                    ]"
                >
                    <img 
                        :src="previewUrl || (removeBgToggle ? processedImage! : originalImage!)" 
                        class="block w-full h-full object-contain select-none transition-opacity duration-300"
                        @load="onImageLoad"
                    />
                </div>
            </div>
        </section>

        <!-- Right: Export Settings -->
        <aside class="w-full md:w-[400px] bg-surface p-6 md:p-10 flex flex-col gap-8 md:gap-10 shrink-0 md:h-full overflow-y-auto shadow-[-10px_0_30px_rgba(0,0,0,0.02)]">
            <div>
                <h1 class="text-xl md:text-2xl font-black tracking-tight mb-2">Export Settings</h1>
                <p class="text-xs md:text-sm text-on-surface-variant leading-relaxed">Configure your final output format and quality.</p>
            </div>

            <!-- Format -->
            <div class="flex flex-col gap-3 md:gap-4">
                <span class="text-[10px] md:text-xs font-bold uppercase tracking-widest opacity-50">File Format</span>
                <div class="grid grid-cols-3 gap-2 p-1.5 bg-surface-container-high rounded-2xl">
                    <button v-for="f in ['PNG', 'JPG', 'WEBP']" :key="f" @click="format = f as any" 
                        :class="format === f ? 'bg-surface text-primary shadow-sm' : 'text-on-surface-variant hover:bg-surface/50'"
                        class="px-2 py-2.5 md:py-3 text-[10px] md:text-xs font-bold rounded-xl transition-all active:scale-95">
                        {{ f }}
                    </button>
                </div>
            </div>

            <!-- Quality -->
            <div class="flex flex-col gap-3 md:gap-4">
                <div class="items-center justify-between flex">
                    <span class="text-[10px] md:text-xs font-bold uppercase tracking-widest opacity-50">Quality</span>
                    <span class="text-sm font-black text-primary">{{ quality }}%</span>
                </div>
                <input v-model="quality" :disabled="format==='PNG'" class="w-full accent-primary cursor-pointer disabled:opacity-20" max="100" min="1" type="range" />
            </div>

            <!-- Dimensions -->
            <div class="flex flex-col gap-3 md:gap-4">
                <span class="text-[10px] md:text-xs font-bold uppercase tracking-widest opacity-50">Dimensions</span>
                <div class="grid grid-cols-[1fr,auto,1fr] items-center gap-2 md:gap-3">
                    <div class="relative group">
                        <input v-model="width" class="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl px-3 md:px-4 py-2.5 md:py-3 text-xs md:text-sm font-bold focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all" type="number" />
                        <span class="absolute right-2 md:right-3 top-1/2 -translate-y-1/2 text-[8px] md:text-[10px] font-bold opacity-30 group-focus-within:opacity-100">PX</span>
                    </div>
                    <span class="text-outline-variant font-bold">×</span>
                    <div class="relative group">
                        <input v-model="height" class="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl px-3 md:px-4 py-2.5 md:py-3 text-xs md:text-sm font-bold focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all" type="number" />
                        <span class="absolute right-2 md:right-3 top-1/2 -translate-y-1/2 text-[8px] md:text-[10px] font-bold opacity-30 group-focus-within:opacity-100">PX</span>
                    </div>
                </div>
            </div>

            <div class="md:mt-auto pt-6 md:pt-10 border-t border-outline-variant/30 flex flex-col gap-6 md:gap-8">
                <div class="flex items-center justify-between p-3 md:p-4 bg-primary-container/30 rounded-2xl border border-primary-container">
                    <div class="flex items-center gap-2 md:gap-3 text-primary">
                        <span class="material-symbols-outlined text-[18px] md:text-[20px]">info</span>
                        <span class="text-[10px] md:text-xs font-bold uppercase tracking-widest">Estimated Size</span>
                    </div>
                    <span class="text-xs md:text-sm font-black text-primary">{{ estimatedSize }}</span>
                </div>
                
                <div class="flex flex-col gap-3">
                    <button @click="emit('reset')" class="w-full bg-surface-container-high text-on-surface-variant text-[10px] md:text-sm font-bold uppercase tracking-[0.1em] py-3.5 md:py-4 rounded-full hover:bg-surface-container-highest transition-all flex items-center justify-center gap-2 md:gap-3 active:scale-95">
                        <span class="material-symbols-outlined text-[20px]">add_photo_alternate</span>
                        Upload New Image
                    </button>
                    
                    <button @click="downloadImage" class="w-full bg-primary text-on-primary text-[10px] md:text-sm font-bold uppercase tracking-[0.1em] py-4 md:py-5 rounded-full hover:shadow-xl hover:-translate-y-0.5 active:translate-y-0 transition-all shadow-lg flex items-center justify-center gap-2 md:gap-3">
                        <span class="material-symbols-outlined text-[20px]">download</span>
                        Download Image
                    </button>
                </div>
            </div>
        </aside>
    </main>
  </div>
</template>

<style scoped>
</style>