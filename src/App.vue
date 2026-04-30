<script setup lang="ts">
import { ref } from 'vue'
import Dropzone from './components/Dropzone.vue'
import BackgroundEditor from './components/BackgroundEditor.vue'
import ExportPanel from './components/ExportPanel.vue'
import Modal from './components/Modal.vue'

type ViewState = 'home' | 'editor' | 'export'

const currentView = ref<ViewState>('home')
const originalImage = ref<string | null>(null)
const processedImage = ref<string | null>(null)
const isProcessing = ref(false)

// Background State
const bgType = ref<'transparent' | 'color' | 'image'>('transparent')
const bgColor = ref<string>('#ffffff')
const bgImage = ref<string | null>(null)
const removeBgToggle = ref(true)

// Modal State
const showModal = ref(false)
const modalTitle = ref('')
const modalMessage = ref('')

const showError = (message: string, title = 'Upload Error') => {
  modalTitle.value = title
  modalMessage.value = message
  showModal.value = true
}

const cleanup = () => {
  if (originalImage.value) {
    if (originalImage.value.startsWith('blob:')) URL.revokeObjectURL(originalImage.value)
  }
  if (processedImage.value) {
    if (processedImage.value.startsWith('blob:')) URL.revokeObjectURL(processedImage.value)
  }
  if (bgImage.value) {
    if (bgImage.value.startsWith('blob:')) URL.revokeObjectURL(bgImage.value)
  }
}

const navigateTo = (view: ViewState) => {
  currentView.value = view
}

const processImage = async (file: File) => {
  cleanup()
  originalImage.value = URL.createObjectURL(file)
  isProcessing.value = true
  processedImage.value = null
  bgType.value = 'transparent'
  bgColor.value = '#ffffff'
  bgImage.value = null
  removeBgToggle.value = true
  navigateTo('editor')

  try {
    const formData = new FormData()
    formData.append('file', file)

    const response = await fetch('http://localhost:5000/api/remove', {
      method: 'POST',
      body: formData,
    })

    if (!response.ok) {
      let errorDetail = response.statusText
      try {
        const errJson = await response.json()
        errorDetail = errJson.detail || errorDetail
      } catch (e) {
        /* ignore parse error */
      }
      throw new Error(errorDetail)
    }

    const imageBlob = await response.blob()
    const url = URL.createObjectURL(imageBlob)
    processedImage.value = url
  } catch (error: any) {
    console.error('Error removing background:', error)
    reset() // Navigate back home if processing fails
    showError(
      error.message ||
        'Failed to remove background. Ensure the Python backend is running on port 5000.',
      'Processing Error',
    )
  } finally {
    isProcessing.value = false
  }
}

const reset = () => {
  cleanup()
  originalImage.value = null
  processedImage.value = null
  isProcessing.value = false
  navigateTo('home')
}
</script>

<template>
  <div
    class="flex flex-col min-h-screen bg-background text-on-surface font-sans antialiased selection:bg-primary selection:text-on-primary"
  >
    <!-- TOP NAV BAR -->
    <header
      v-if="currentView !== 'export'"
      class="fixed top-0 w-full z-50 border-b border-outline-variant/30 bg-surface/80 backdrop-blur-md h-16 px-4 md:px-12 flex justify-between items-center"
    >
      <div class="flex items-center gap-8">
        <a class="text-xl font-black tracking-tight cursor-pointer text-primary" @click="reset"
          >removerBG </a
        >
      </div>
      <div class="flex items-center gap-6 text-sm font-medium">
        <a
          href="https://github.com/SatriaAkbarRizki/removerbg"
          target="_blank"
          class="flex items-center gap-2 hover:opacity-70 transition-opacity"
        >
          <span>Source</span>
        </a>
      </div>
    </header>

    <!-- Main Content -->
    <div class="flex-grow flex flex-col pt-16">
      <Transition
        mode="out-in"
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0 translate-y-4"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition duration-200 ease-in"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 -translate-y-4"
      >
        <main
          v-if="currentView === 'home'"
          :key="'home'"
          class="flex-grow w-full max-w-5xl mx-auto px-6 md:px-8 py-10 md:py-20 flex flex-col items-center"
        >
          <div class="w-full text-center mb-10 md:mb-16">
            <h1 class="text-3xl md:text-6xl font-bold tracking-tight text-primary mb-6">
              Background Removal Without Lose Quality
            </h1>
            <p class="text-on-surface-variant text-lg max-w-2xl mx-auto leading-relaxed">
              Upload your image and let our AI isolate your subject perfectly. Local, fast, and
              high-precision processing.
            </p>
          </div>

          <div class="w-full max-w-3xl mb-24">
            <Dropzone @file-selected="processImage" @error="(m) => showError(m)" />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-8 w-full">
            <div
              class="bg-surface-container-lowest p-8 rounded-2xl border border-outline-variant shadow-sm flex flex-col items-center text-center group hover:shadow-md transition-shadow"
            >
              <div
                class="w-14 h-14 rounded-2xl bg-primary text-on-primary flex items-center justify-center mb-6 shadow-lg group-hover:scale-110 transition-transform"
              >
                <span class="material-symbols-outlined text-3xl">high_quality</span>
              </div>
              <h3 class="text-xl font-bold mb-3 text-primary">High Quality</h3>
              <p class="text-sm text-on-surface-variant leading-relaxed">
                Full resolution output with crisp, professionally refined edges.
              </p>
            </div>
            <div
              class="bg-surface-container-lowest p-8 rounded-2xl border border-outline-variant shadow-sm flex flex-col items-center text-center group hover:shadow-md transition-shadow"
            >
              <div
                class="w-14 h-14 rounded-2xl bg-primary text-on-primary flex items-center justify-center mb-6 shadow-lg group-hover:scale-110 transition-transform"
              >
                <span class="material-symbols-outlined text-3xl">palette</span>
              </div>
              <h3 class="text-xl font-bold mb-3 text-primary">Creative Control</h3>
              <p class="text-sm text-on-surface-variant leading-relaxed">
                Change colors or images instantly to create the perfect scene.
              </p>
            </div>
            <div
              class="bg-surface-container-lowest p-8 rounded-2xl border border-outline-variant shadow-sm flex flex-col items-center text-center group hover:shadow-md transition-shadow"
            >
              <div
                class="w-14 h-14 rounded-2xl bg-primary text-on-primary flex items-center justify-center mb-6 shadow-lg group-hover:scale-110 transition-transform"
              >
                <span class="material-symbols-outlined text-3xl">lock</span>
              </div>
              <h3 class="text-xl font-bold mb-3 text-primary">Privacy First</h3>
              <p class="text-sm text-on-surface-variant leading-relaxed">
                Your images stay on your vps. We process everything locally.
              </p>
            </div>
          </div>
        </main>

        <main
          v-else-if="currentView === 'editor'"
          :key="'editor'"
          class="flex-1 flex w-full h-[calc(100vh-64px)] overflow-hidden bg-white"
        >
          <BackgroundEditor
            :original-image="originalImage"
            :processed-image="processedImage"
            :is-processing="isProcessing"
            v-model:bgType="bgType"
            v-model:bgColor="bgColor"
            v-model:bgImage="bgImage"
            v-model:removeBgToggle="removeBgToggle"
            @reset="reset"
            @export="navigateTo('export')"
            @error="(m) => showError(m)"
          />
        </main>

        <main
          v-else-if="currentView === 'export'"
          :key="'export'"
          class="flex-1 flex w-full h-full overflow-hidden absolute inset-0 z-[60] bg-white"
        >
          <ExportPanel
            :processed-image="processedImage"
            :original-image="originalImage"
            :bg-type="bgType"
            :bg-color="bgColor"
            :bg-image="bgImage"
            :remove-bg-toggle="removeBgToggle"
            @back="navigateTo('editor')"
            @reset="reset"
          />
        </main>
      </Transition>
    </div>

    <!-- Modal -->
    <Modal
      :show="showModal"
      :title="modalTitle"
      :message="modalMessage"
      @close="showModal = false"
    />

    <!-- Subtle Footer Credit -->
    <footer v-if="currentView === 'home'" class="w-full py-8 text-center text-on-surface-variant/50 text-[10px]">
      <p>
        Image Editing Icon by Cosmin Negoita on 
        <a href="https://icon-icons.com/authors/701-cosmin-negoita" target="_blank" class="hover:underline">Icon-Icons.com</a>
      </p>
    </footer>
  </div>
</template>
