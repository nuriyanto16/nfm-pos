<template>
  <div>
    <header class="app-header">
      <button class="back-btn" @click="goBack">←</button>
      <span class="header-title">Riwayat Pesanan</span>
    </header>

    <div class="history-page">
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Memuat riwayat...</p>
      </div>

      <div v-else-if="orders.length === 0" class="empty-state">
        <div class="empty-icon">📜</div>
        <p class="empty-text">Belum ada riwayat pesanan</p>
        <button class="btn-outline" @click="goBack" style="margin-top: 20px;">Mulai Pesan</button>
      </div>

      <div v-else class="order-list">
        <div v-for="order in orders" :key="order.id" class="order-card" @click="viewStatus(order.id)">
          <div class="order-card-header">
            <span class="order-date">{{ formatDate(order.created_at) }}</span>
            <span :class="['order-status-badge', order.status.toLowerCase()]">{{ order.status }}</span>
          </div>
          <div class="order-card-body">
            <div class="branch-name">{{ order.branch?.name || 'Cabang' }}</div>
            <div class="order-items-summary">
              {{ order.items?.length || 0 }} Menu • {{ formatPrice(order.total_amount) }}
            </div>
          </div>
          <div class="order-card-footer">
            <span class="view-detail">Lihat Detail ❯</span>
          </div>
        </div>
      </div>
    </div>
    
    <div style="height: 80px;"></div>
    <BottomNav :companyCode="props.companyCode || 'NFM001'" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api.js'
import BottomNav from '../components/BottomNav.vue'

const props = defineProps({ companyCode: String })
const router = useRouter()
const orders = ref([])
const loading = ref(true)

onMounted(async () => {
  const token = localStorage.getItem('customer_token')
  if (!token) {
    router.push({ name: 'BranchSelect', params: { companyCode: props.companyCode || 'NFM001' } })
    return
  }

  try {
    const data = await api.getOrderHistory(token)
    orders.value = data || []
  } catch (e) {
    console.error('Failed to fetch history', e)
  } finally {
    loading.value = false
  }
})

function goBack() {
  router.back()
}

function viewStatus(orderId) {
  router.push({ name: 'OrderStatus', params: { orderId } })
}

function formatDate(dateStr) {
  const date = new Date(dateStr)
  return date.toLocaleDateString('id-ID', { 
    day: 'numeric', 
    month: 'short', 
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function formatPrice(price) {
  return 'Rp' + (price || 0).toLocaleString('id-ID')
}
</script>

<style scoped>
.history-page { padding: 16px; }
.order-list { display: flex; flex-direction: column; gap: 12px; }
.order-card {
  background: var(--surface);
  border: 1px solid var(--border-light);
  border-radius: var(--radius);
  padding: 16px;
  cursor: pointer;
  transition: var(--transition);
}
.order-card:hover { border-color: var(--primary); transform: translateY(-2px); box-shadow: var(--shadow-md); }
.order-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}
.order-date { font-size: 0.75rem; color: var(--text-secondary); }
.order-status-badge {
  font-size: 0.7rem;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: var(--radius-full);
  text-transform: uppercase;
}
.order-status-badge.pending { background: #fff8e1; color: #f59e0b; }
.order-status-badge.proses { background: #e3f2fd; color: #3b82f6; }
.order-status-badge.selesai { background: var(--success-bg); color: var(--success); }
.order-status-badge.batal { background: var(--danger-bg); color: var(--danger); }

.branch-name { font-weight: 700; font-size: 0.95rem; margin-bottom: 4px; }
.order-items-summary { font-size: 0.85rem; color: var(--text-secondary); }

.order-card-footer {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px dashed var(--border-light);
  text-align: right;
}
.view-detail { font-size: 0.8rem; color: var(--primary); font-weight: 600; }
</style>
