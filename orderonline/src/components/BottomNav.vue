<template>
  <nav class="bottom-nav">
    <router-link :to="{ name: 'BranchSelect', params: { companyCode } }" class="nav-item">
      <span class="nav-icon">🏠</span>
      <span class="nav-label">Beranda</span>
    </router-link>
    <router-link :to="{ name: 'OrderHistory', params: { companyCode } }" class="nav-item">
      <span class="nav-icon">📜</span>
      <span class="nav-label">Riwayat</span>
    </router-link>
    <div class="nav-item promo-item" @click="showPromoModal = true">
      <div class="promo-badge" v-if="promoCount > 0">{{ promoCount }}</div>
      <span class="nav-icon">🎟️</span>
      <span class="nav-label">Voucher</span>
    </div>
  </nav>

  <!-- Promo Modal -->
  <div v-if="showPromoModal" class="promo-modal-overlay" @click="showPromoModal = false">
    <div class="promo-modal" @click.stop>
      <div class="promo-modal-header">
        <h3>Voucher & Promo Seru 🎁</h3>
        <button class="close-btn" @click="showPromoModal = false">×</button>
      </div>
      <div class="promo-modal-body">
        <div v-if="loading" class="loading-state">Memuat promo...</div>
        <div v-else-if="promos.length === 0" class="empty-state">
          <p>Belum ada promo aktif saat ini.</p>
        </div>
        <div v-else class="promo-list">
          <div v-for="promo in promos" :key="promo.id" class="promo-item-card">
            <div class="promo-icon">🎫</div>
            <div class="promo-info">
              <div class="promo-name">{{ promo.name }}</div>
              <div class="promo-desc">{{ promo.description }}</div>
              <div class="promo-valid">Hingga {{ formatDate(promo.end_date) }}</div>
            </div>
          </div>
        </div>
      </div>
      <div class="promo-modal-footer">
        <button class="btn-primary" @click="showPromoModal = false">Oke, Mengerti!</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api.js'

const props = defineProps({ companyCode: String })
const showPromoModal = ref(false)
const promos = ref([])
const promoCount = ref(0)
const loading = ref(true)

onMounted(async () => {
  try {
    // We need companyId to get promos. We'll fetch it from branchSelect data or similar.
    // For simplicity, let's assume we can get it from the branch list or a separate call.
    const companyData = await api.getBranches(props.companyCode)
    const companyId = companyData.company.id
    const data = await api.getPromos(companyId)
    promos.value = data || []
    promoCount.value = promos.value.length
  } catch (e) {
    console.error('Failed to load promos in bottom nav', e)
  } finally {
    loading.value = false
  }
})

function formatDate(dateStr) {
  const date = new Date(dateStr)
  return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>

<style scoped>
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  max-width: var(--max-width);
  height: 60px;
  background: var(--surface);
  display: flex;
  justify-content: space-around;
  align-items: center;
  border-top: 1px solid var(--border-light);
  box-shadow: 0 -2px 10px rgba(0,0,0,0.05);
  z-index: 500;
}
.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 0.75rem;
  font-weight: 500;
  cursor: pointer;
  transition: var(--transition);
  position: relative;
}
.nav-item:hover, .nav-item.router-link-active { color: var(--primary); }
.nav-icon { font-size: 1.2rem; }

.promo-badge {
  position: absolute;
  top: -5px;
  right: -5px;
  background: var(--danger);
  color: #fff;
  font-size: 0.65rem;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
}

/* Modal Styles */
.promo-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  z-index: 1000;
}
.promo-modal {
  width: 100%;
  max-width: var(--max-width);
  background: var(--surface);
  border-radius: 20px 20px 0 0;
  padding: 20px;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  animation: slideUp 0.3s ease-out;
}
@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

.promo-modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.promo-modal-header h3 { font-size: 1.1rem; font-weight: 700; }
.close-btn { font-size: 1.5rem; color: var(--text-secondary); }

.promo-modal-body { flex: 1; overflow-y: auto; }
.promo-list { display: flex; flex-direction: column; gap: 12px; }
.promo-item-card {
  background: var(--bg);
  border-radius: var(--radius);
  padding: 14px;
  display: flex;
  gap: 12px;
  border-left: 4px solid var(--primary);
}
.promo-icon { font-size: 1.5rem; }
.promo-name { font-weight: 700; font-size: 0.9rem; margin-bottom: 2px; }
.promo-desc { font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 4px; }
.promo-valid { font-size: 0.7rem; color: var(--text-muted); font-style: italic; }

.promo-modal-footer { margin-top: 20px; }
</style>
