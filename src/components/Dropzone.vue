<script setup lang="ts">
import { ref } from 'vue'

const emit = defineEmits<{
  (e: 'file-selected', file: File): void
  (e: 'error', message: string): void
}>()

const isDragging = ref(false)

const onDragOver = (e: DragEvent) => {
  e.preventDefault()
  isDragging.value = true
}

const onDragLeave = () => {
  isDragging.value = false
}

const onDrop = (e: DragEvent) => {
  e.preventDefault()
  isDragging.value = false
  if (e.dataTransfer?.files && e.dataTransfer.files.length > 0) {
    const file = e.dataTransfer.files[0]
    if (file) {
      if (!file.type.startsWith('image/')) {
          emit('error', "Invalid file type. Please upload a valid image file (JPG, PNG, WEBP).")
          return
      }
      emit('file-selected', file)
    }
  }
}

const onFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    const file = target.files[0]
    if (file) {
      if (!file.type.startsWith('image/')) {
          emit('error', "Invalid file type. Please upload a valid image file (JPG, PNG, WEBP).")
          return
      }
      emit('file-selected', file)
    }
  }
}
</script>

<template>
  <div class="w-full">
    <label 
        @dragover="onDragOver"
        @dragleave="onDragLeave"
        @drop="onDrop"
        class="group border-2 border-dashed border-outline-variant hover:border-primary bg-surface-container-lowest hover:bg-surface-container-low rounded-2xl cursor-pointer p-8 md:p-24 flex flex-col items-center justify-center relative transition-all duration-300 ease-in-out overflow-hidden"
        :class="isDragging ? 'border-primary bg-surface-container-low scale-[0.98]' : ''">
        
        <input type="file" accept="image/*" class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10" @change="onFileChange" />
            
        <div class="absolute inset-0 bg-gradient-to-br from-primary-fixed/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"></div>

        <div class="w-16 h-16 md:w-20 md:h-20 rounded-full bg-primary text-white flex items-center justify-center mb-6 shadow-sm transition-transform duration-300 group-hover:scale-110">
            <span class="material-symbols-outlined text-3xl md:text-4xl" style="font-variation-settings: 'FILL' 1;">cloud_upload</span>
        </div>
        
        <h3 class="text-lg md:text-2xl font-bold text-on-surface mb-2 text-center">Drag and drop an image</h3>
        <p class="text-on-surface-variant text-xs md:text-sm mb-8 text-center px-4">or click to browse from your computer</p>
        
        <button class="bg-primary hover:bg-surface-tint text-on-primary font-semibold py-2.5 px-8 md:py-3 md:px-10 rounded-full shadow-md transition-all active:scale-95 flex items-center gap-2 pointer-events-none text-sm md:text-base">
            Upload Image
        </button>
        
        <p class="text-[10px] md:text-xs font-bold text-on-surface-variant mt-6 uppercase tracking-widest text-center px-4">Supports JPG, PNG, WEBP up to 10MB</p>
    </label>
  </div>
</template>
