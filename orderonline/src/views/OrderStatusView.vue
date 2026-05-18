<template>
  <div>
    <header class="app-header">
      <span class="header-title">Status Pesanan</span>
    </header>

    <div v-if="loading" class="loading-container">
      <div class="spinner"></div>
      <span style="color: var(--text-secondary); font-size: 0.85rem;">Memuat status...</span>
    </div>

    <div v-else-if="error" class="empty-state">
      <div class="empty-icon">😕</div>
      <div class="empty-text">{{ error }}</div>
    </div>

    <div v-else class="status-page">
      <!-- Status Icon -->
      <div :class="['status-icon', statusClass]">
        {{ statusEmoji }}
      </div>
      <h1 class="status-title">{{ statusLabel }}</h1>
      <p class="status-subtitle">Pesanan #{{ order.order_id }} • {{ order.customer_name }}</p>

      <!-- Timeline -->
      <div class="status-timeline">
        <div :class="['timeline-step', stepClass(0)]">
          <div class="timeline-dot">📝</div>
          <div class="timeline-text">
            <div class="timeline-label">Pesanan Diterima</div>
            <div class="timeline-desc">Menunggu konfirmasi dari toko</div>
          </div>
        </div>
        <div :class="['timeline-step', stepClass(1)]">
          <div class="timeline-dot">👨‍🍳</div>
          <div class="timeline-text">
            <div class="timeline-label">Sedang Diproses</div>
            <div class="timeline-desc">Pesanan sedang disiapkan</div>
          </div>
        </div>
        <div :class="['timeline-step', stepClass(2)]">
          <div class="timeline-dot">✅</div>
          <div class="timeline-text">
            <div class="timeline-label">Siap Diambil</div>
            <div class="timeline-desc">Pesanan siap untuk diambil</div>
          </div>
        </div>
        <div :class="['timeline-step', stepClass(3)]">
          <div class="timeline-dot">🎉</div>
          <div class="timeline-text">
            <div class="timeline-label">Selesai</div>
            <div class="timeline-desc">Pesanan telah selesai</div>
          </div>
        </div>
      </div>

      <!-- Order Details -->
      <div class="checkout-summary" style="text-align: left;">
        <h3 style="font-size: 0.9rem; margin-bottom: 12px; font-weight: 700;">Detail Pesanan</h3>
        <div v-for="item in order.items" :key="item.name" class="checkout-summary-row">
          <span>{{ item.name }} × {{ item.quantity }}</span>
          <span style="font-weight: 600;">{{ formatPrice(item.subtotal) }}</span>
        </div>
        <div class="checkout-summary-row total">
          <span>Total</span>
          <span>{{ formatPrice(order.total_amount) }}</span>
        </div>
      </div>

      <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 16px;">
        {{ order.branch_name }} • {{ order.delivery_method }}
      </p>

      <button v-if="canRefresh" class="btn-outline" @click="fetchStatus" style="margin-top: 20px;">
        🔄 Refresh Status
      </button>
    </div>
    
    <div style="height: 80px;"></div>
    <BottomNav :companyCode="order.company_code || 'NFM001'" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, inject } from 'vue'
import api from '../api.js'
import { applyTheme } from '../utils/theme.js'
import BottomNav from '../components/BottomNav.vue'

const props = defineProps({ orderId: String })
const showToast = inject('showToast')

const loading = ref(true)
const error = ref('')
const order = ref({})
let pollInterval = null

const statusMap = {
  'Pending': { step: 0, emoji: '⏳', label: 'Menunggu Konfirmasi', class: 'pending' },
  'Proses': { step: 1, emoji: '👨‍🍳', label: 'Sedang Diproses', class: 'process' },
  'Siap': { step: 2, emoji: '✅', label: 'Siap Diambil', class: 'ready' },
  'Selesai': { step: 3, emoji: '🎉', label: 'Pesanan Selesai', class: 'done' },
  'Batal': { step: -1, emoji: '❌', label: 'Pesanan Dibatalkan', class: 'pending' },
}

const currentStep = computed(() => statusMap[order.value.status]?.step ?? 0)
const statusEmoji = computed(() => statusMap[order.value.status]?.emoji ?? '⏳')
const statusLabel = computed(() => statusMap[order.value.status]?.label ?? order.value.status)
const statusClass = computed(() => statusMap[order.value.status]?.class ?? 'pending')
const canRefresh = computed(() => !['Selesai', 'Batal'].includes(order.value.status))

function stepClass(step) {
  if (step < currentStep.value) return 'completed'
  if (step === currentStep.value) return 'active'
  return ''
}

function formatPrice(price) {
  return 'Rp' + (price || 0).toLocaleString('id-ID')
}

async function fetchStatus() {
  try {
    const data = await api.getOrderStatus(props.orderId)
    order.value = data
    document.title = `Pesanan #${data.order_id} - ${statusLabel.value}`
    if (['Selesai', 'Batal'].includes(data.status) && pollInterval) {
      clearInterval(pollInterval)
    }
  } catch (e) {
    error.value = e.message || 'Gagal memuat status'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchStatus()
  pollInterval = setInterval(fetchStatus, 10000) // Poll every 10s
})

onUnmounted(() => {
  if (pollInterval) clearInterval(pollInterval)
})
</script>
