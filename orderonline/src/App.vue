<template>
  <div id="online-order-app">
    <router-view />
    <div v-if="toast.show" :class="['toast', toast.type, { show: toast.show }]">{{ toast.message }}</div>
  </div>
</template>

<script setup>
import { reactive, provide } from 'vue'

const toast = reactive({ show: false, message: '', type: 'success' })

function showToast(message, type = 'success') {
  toast.message = message
  toast.type = type
  toast.show = true
  setTimeout(() => { toast.show = false }, 3000)
}

provide('showToast', showToast)
</script>
