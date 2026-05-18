<template>
  <div class="auth-page">
    <header class="app-header">
      <button class="back-btn" @click="goBack">←</button>
      <span class="header-title">Daftar Customer</span>
    </header>

    <div class="container" style="padding: 30px 16px;">
      <div style="text-align: center; margin-bottom: 30px;">
        <h2 style="font-size: 1.5rem; font-weight: 800;">Buat Akun Baru</h2>
        <p style="color: var(--text-secondary); font-size: 0.9rem;">Daftar untuk kemudahan memesan makanan</p>
      </div>

      <div class="form-group">
        <label class="form-label">Nama Lengkap *</label>
        <input v-model="form.full_name" class="form-input" placeholder="Nama lengkap Anda" />
      </div>

      <div class="form-group">
        <label class="form-label">Username *</label>
        <input v-model="form.username" class="form-input" placeholder="Pilih username" />
      </div>

      <div class="form-group">
        <label class="form-label">Password *</label>
        <input v-model="form.password" type="password" class="form-input" placeholder="Minimal 6 karakter" />
      </div>

      <div class="form-group">
        <label class="form-label">No. WhatsApp</label>
        <input v-model="form.phone" class="form-input" placeholder="08xxxxxxxx" />
      </div>

      <div class="form-group">
        <label class="form-label">Alamat Lengkap</label>
        <textarea v-model="form.address" class="form-textarea" placeholder="Alamat untuk pengiriman"></textarea>
      </div>

      <button class="btn-primary" @click="handleRegister" :disabled="loading || !form.username || !form.password || !form.full_name" style="margin-top: 10px;">
        <span v-if="loading" class="spinner" style="width:20px;height:20px;border-width:2px;"></span>
        <span v-else>Daftar Sekarang</span>
      </button>

      <div style="text-align: center; margin-top: 24px; font-size: 0.9rem; padding-bottom: 40px;">
        <span style="color: var(--text-secondary);">Sudah punya akun? </span>
        <router-link :to="{ name: 'Login', params: { companyCode } }" style="color: var(--primary); font-weight: 600;">Masuk</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, inject, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api.js'

const props = defineProps({ companyCode: String })
const router = useRouter()
const showToast = inject('showToast')

const form = ref({
  company_id: 0,
  username: '',
  password: '',
  full_name: '',
  phone: '',
  address: '',
})

const loading = ref(false)

onMounted(async () => {
    try {
        const company = await api.getCompanyInfo(props.companyCode)
        form.value.company_id = company.id
    } catch (e) {
        showToast('Gagal memuat info perusahaan', 'error')
    }
})

function goBack() {
  router.push(`/${props.companyCode}/login`)
}

async function handleRegister() {
  loading.value = true
  try {
    await api.register(form.value)
    showToast('Registrasi berhasil! Silakan login.', 'success')
    router.push(`/${props.companyCode}/login`)
  } catch (e) {
    showToast(e.message || 'Registrasi gagal', 'error')
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
