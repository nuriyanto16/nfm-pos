<template>
  <div class="auth-page">
    <header class="app-header">
      <button class="back-btn" @click="goBack">←</button>
      <span class="header-title">Masuk Customer</span>
    </header>

    <div class="container" style="padding-top: 40px;">
      <div style="text-align: center; margin-bottom: 30px;">
        <h2 style="font-size: 1.5rem; font-weight: 800;">Selamat Datang!</h2>
        <p style="color: var(--text-secondary); font-size: 0.9rem;">Masuk untuk melihat riwayat pesanan Anda</p>
      </div>

      <div class="form-group">
        <label class="form-label">Username</label>
        <input v-model="form.username" class="form-input" placeholder="Masukkan username" />
      </div>

      <div class="form-group">
        <label class="form-label">Password</label>
        <input v-model="form.password" type="password" class="form-input" placeholder="Masukkan password" />
      </div>

      <button class="btn-primary" @click="handleLogin" :disabled="loading || !form.username || !form.password" style="margin-top: 10px;">
        <span v-if="loading" class="spinner" style="width:20px;height:20px;border-width:2px;"></span>
        <span v-else>Masuk</span>
      </button>

      <div style="text-align: center; margin-top: 24px; font-size: 0.9rem;">
        <span style="color: var(--text-secondary);">Belum punya akun? </span>
        <router-link :to="{ name: 'Register', params: { companyCode } }" style="color: var(--primary); font-weight: 600;">Daftar Sekarang</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, inject } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api.js'

const props = defineProps({ companyCode: String })
const router = useRouter()
const showToast = inject('showToast')

const form = ref({
  username: '',
  password: '',
})

const loading = ref(false)

function goBack() {
  router.push(`/${props.companyCode}`)
}

async function handleLogin() {
  loading.value = true
  try {
    const res = await api.login(form.value)
    localStorage.setItem('customer_token', res.token)
    localStorage.setItem('customer_user', JSON.stringify(res.user))
    showToast('Login berhasil!', 'success')
    router.push(`/${props.companyCode}`)
  } catch (e) {
    showToast(e.message || 'Login gagal', 'error')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  background: var(--surface);
}
</style>
