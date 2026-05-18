<template>
  <div>
    <!-- Header -->
    <header class="app-header">
      <span class="header-title">🍽️ Order Online</span>
      <div class="header-right">
        <template v-if="customerUser">
          <button class="btn-outline" @click="toggleMenu" style="padding: 6px 12px; font-size: 0.75rem;">
            👤 {{ customerUser.full_name.split(' ')[0] }}
          </button>
        </template>
        <template v-else>
          <router-link :to="{ name: 'Login', params: { companyCode } }" class="btn-outline" style="padding: 6px 12px; font-size: 0.75rem;">
            Masuk
          </router-link>
        </template>
      </div>
    </header>

    <!-- Simple User Menu Dropdown (Optional) -->
    <div v-if="showMenu" class="user-menu" @click="showMenu = false">
        <div class="user-menu-content" @click.stop>
            <div class="user-info-section" v-if="customerUser && customerUser.Customer">
                <div style="font-size: 0.75rem; color: var(--text-secondary);">Poin Kamu:</div>
                <div style="font-size: 1.1rem; font-weight: 700; color: var(--primary);">⭐ {{ customerUser.Customer.loyalty_points || 0 }}</div>
            </div>
            <div class="user-menu-item" @click="goToHistory">Riwayat Pesanan</div>
            <div class="user-menu-item" @click="handleLogout" style="color: var(--danger);">Keluar</div>
        </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading-container">
      <div class="spinner"></div>
      <span style="color: var(--text-secondary); font-size: 0.85rem;">Memuat outlet...</span>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="empty-state">
      <div class="empty-icon">😕</div>
      <div class="empty-text">{{ error }}</div>
    </div>

    <template v-else>
      <!-- Company Banner -->
      <div class="company-banner">
        <div class="company-logo">
          <img v-if="company.logo_url" :src="getFullUrl(company.logo_url)" :alt="company.name" style="width:100%;height:100%;object-fit:cover;border-radius: inherit;" />
          <span v-else>🏪</span>
        </div>
        <div>
          <div class="company-name">{{ company.name }}</div>
          <div class="company-branches">{{ branches.length }} outlet tersedia</div>
        </div>
      </div>

      <!-- Search -->
      <div class="search-bar">
        <div class="search-input-wrap">
          <span class="search-icon">🔍</span>
          <input v-model="search" class="search-input" placeholder="Cari outlet..." />
        </div>
      </div>

      <!-- Branch List -->
      <div v-if="filteredBranches.length" class="branch-list">
        <div
          v-for="branch in filteredBranches"
          :key="branch.id"
          class="branch-card"
          @click="selectBranch(branch)"
        >
          <div class="branch-icon">🏠</div>
          <div class="branch-info">
            <div class="branch-name">{{ branch.name }}</div>
            <div class="branch-address">{{ branch.address || 'Alamat belum tersedia' }}</div>
            <div :class="['branch-status', branch.is_open ? 'open' : 'closed']">
              <span class="dot"></span>
              {{ branch.is_open ? 'Buka' : 'Tutup' }}
              <span style="font-weight:400; margin-left: 4px;">{{ branch.open_time }} - {{ branch.close_time }}</span>
            </div>
          </div>
          <div class="branch-arrow">›</div>
        </div>
      </div>

      <div v-else class="empty-state">
        <div class="empty-icon">🔍</div>
        <div class="empty-text">Outlet tidak ditemukan</div>
      </div>
    </template>
    <div style="height: 80px;"></div>
    <BottomNav :companyCode="companyCode" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api.js'
import { applyTheme } from '../utils/theme.js'
import { getFullUrl } from '../utils/url.js'
import BottomNav from '../components/BottomNav.vue'

const props = defineProps({ companyCode: String })
const router = useRouter()

const loading = ref(true)
const error = ref('')
const company = ref({})
const branches = ref([])
const search = ref('')
const customerUser = ref(null)
const showMenu = ref(false)

function toggleMenu() {
    showMenu.value = !showMenu.value
}

function handleLogout() {
    localStorage.removeItem('customer_token')
    localStorage.removeItem('customer_user')
    customerUser.value = null
    showMenu.value = false
    window.location.reload()
}

function goToHistory() {
    router.push({ name: 'OrderHistory', params: { companyCode: props.companyCode } })
    showMenu.value = false
}

const filteredBranches = computed(() => {
  if (!search.value) return branches.value
  const q = search.value.toLowerCase()
  return branches.value.filter(b =>
    b.name.toLowerCase().includes(q) || (b.address || '').toLowerCase().includes(q)
  )
})

function selectBranch(branch) {
  router.push({ name: 'Menu', params: { companyCode: props.companyCode, branchId: branch.id } })
}

onMounted(async () => {
  try {
    const data = await api.getBranches(props.companyCode)
    company.value = data.company
    branches.value = data.branches || []
    document.title = `${data.company.name} - Order Online`
    
    if (data.company.theme) {
      applyTheme(data.company.theme)
    }
    
    const token = localStorage.getItem('customer_token')
    if (token) {
        const userData = await api.getMe(token)
        customerUser.value = userData
        localStorage.setItem('customer_user', JSON.stringify(userData))
    }
  } catch (e) {
    error.value = e.message || 'Gagal memuat data'
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.user-menu {
    position: fixed;
    inset: 0;
    z-index: 500;
}
.user-menu-content {
    position: absolute;
    top: 60px;
    right: 16px;
    background: var(--surface);
    border-radius: var(--radius);
    box-shadow: var(--shadow-lg);
    border: 1px solid var(--border-light);
    width: 180px;
    overflow: hidden;
    animation: slideDown 0.2s ease-out;
}
@keyframes slideDown {
    from { transform: translateY(-10px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
}
.user-menu-item {
    padding: 12px 16px;
    font-size: 0.85rem;
    font-weight: 500;
    cursor: pointer;
    transition: var(--transition);
}
.user-info-section {
    padding: 16px;
    background: var(--bg);
    border-bottom: 1px solid var(--border-light);
}
.user-menu-item:hover {
    background: var(--bg);
}
.user-menu-item:not(:last-child) {
    border-bottom: 1px solid var(--border-light);
}
</style>
