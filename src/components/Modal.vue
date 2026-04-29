<script setup lang="ts">
defineProps<{
  show: boolean
  title: string
  message: string
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()
</script>

<template>
  <Transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div v-if="show" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" @click.self="emit('close')">
      <div class="bg-surface w-full max-w-md rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-300">
        <div class="p-6">
          <div class="w-12 h-12 rounded-full bg-error-container text-error flex items-center justify-center mb-4">
            <span class="material-symbols-outlined text-2xl">warning</span>
          </div>
          <h3 class="text-xl font-bold text-on-surface mb-2">{{ title }}</h3>
          <p class="text-on-surface-variant leading-relaxed">{{ message }}</p>
        </div>
        <div class="bg-surface-container-low p-4 flex justify-end">
          <button 
            @click="emit('close')"
            class="px-6 py-2 bg-primary text-on-primary font-bold rounded-xl hover:brightness-110 active:scale-95 transition-all"
          >
            Got it
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>
