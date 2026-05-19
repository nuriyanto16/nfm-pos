<template>
  <div>
    <header class="app-header">
      <button class="back-btn" @click="goBack">←</button>
      <span class="header-title">Checkout</span>
    </header>

    <div class="checkout-page">
      <!-- Order Items Summary -->
      <div class="checkout-summary">
        <h3 style="font-size: 0.9rem; margin-bottom: 12px; font-weight: 700;">Ringkasan Pesanan</h3>
        <div v-for="item in cartItems" :key="item.menuId" class="checkout-summary-row">
          <span>{{ item.name }} × {{ item.quantity }}</span>
          <span style="font-weight: 600;">{{ formatPrice(item.price * item.quantity) }}</span>
        </div>
        <div class="checkout-summary-row total">
          <span>Total</span>
          <span>{{ formatPrice(cartSubtotal) }}</span>
        </div>
      </div>

      <!-- Customer Info -->
      <div class="form-group">
        <label class="form-label">Nama Pemesan *</label>
        <input v-model="form.customer_name" class="form-input" placeholder="Nama lengkap" id="checkout-name" />
      </div>

      <div class="form-group">
        <label class="form-label">No. WhatsApp / Telepon</label>
        <input v-model="form.customer_phone" class="form-input" placeholder="08xxxxxxxx" id="checkout-phone" type="tel" />
      </div>

      <div class="form-group">
        <label class="form-label">Metode Pengambilan</label>
        <select v-model="form.delivery_method" class="form-select" id="checkout-delivery">
          <option value="Pickup">Ambil di Tempat (Pickup)</option>
          <option value="Dine In">Makan di Tempat (Dine In)</option>
          <option value="Delivery">Kirim ke Alamat (Delivery)</option>
        </select>
      </div>

      <div v-if="form.delivery_method === 'Delivery'" class="form-group">
        <label class="form-label">Pilih Kurir Pengiriman *</label>
        <select v-model="form.courier" class="form-select" id="checkout-courier">
          <option value="Gojek">Gojek (Instant/Sameday) - Rp15.000</option>
          <option value="Grab">Grab (Instant/Sameday) - Rp15.000</option>
          <option value="Shopee Express">Shopee Express - Rp12.000</option>
          <option value="Lalamove">Lalamove - Rp18.000</option>
          <option value="Kurir Toko">Kurir Toko - Rp10.000</option>
        </select>
      </div>

      <div v-if="form.delivery_method === 'Delivery'" class="form-group">
        <label class="form-label">Alamat Pengiriman *</label>
        <textarea v-model="form.shipping_address" class="form-textarea" placeholder="Alamat lengkap pengiriman..." id="checkout-address"></textarea>
      </div>

      <div class="form-group">
        <label class="form-label">Metode Pembayaran</label>
        <select v-model="form.payment_method" class="form-select" id="checkout-payment">
          <option value="Tunai">Tunai / Bayar di Kasir</option>
          <option value="Transfer Bank">Transfer Bank</option>
          <option value="QRIS">QRIS</option>
        </select>
      </div>

      <div class="form-group">
        <label class="form-label">Catatan</label>
        <textarea v-model="form.notes" class="form-textarea" placeholder="Catatan tambahan..." id="checkout-notes"></textarea>
      </div>

      <!-- Promo Section -->
      <div class="promo-section" v-if="availablePromos.length">
        <h3 style="font-size: 0.9rem; margin-bottom: 8px; font-weight: 700;">Gunakan Promo</h3>
        <select v-model="form.promo_id" class="form-select" @change="calculateDiscount">
          <option :value="null">Pilih Promo (Jika ada)</option>
          <option v-for="promo in availablePromos" :key="promo.id" :value="promo.id">
            {{ promo.name }} ({{ promo.type === 'percentage' ? promo.value + '%' : formatPrice(promo.value) }})
          </option>
        </select>
        <div v-if="discountAmount > 0" class="promo-applied">
          Hemat {{ formatPrice(discountAmount) }}! 🎉
        </div>
      </div>

      <!-- Point Redemption Section -->
      <div class="points-section" v-if="customerUser && customerUser.customer && customerUser.customer.loyalty_points > 0">
        <div class="points-header">
            <span style="font-size: 0.85rem; font-weight: 600;">⭐ Tukar Poin</span>
            <span style="font-size: 0.75rem; color: var(--text-secondary);">Tersedia: {{ customerUser.customer.loyalty_points }} koin</span>
        </div>
        <div class="points-toggle">
            <span style="font-size: 0.8rem; color: var(--text-secondary);">Tukarkan {{ maxUsablePoints }} koin untuk hemat {{ formatPrice(maxUsablePoints) }}</span>
            <label class="switch">
                <input type="checkbox" v-model="form.use_points">
                <span class="slider round"></span>
            </label>
        </div>
      </div>

      <!-- Fees Summary -->
      <div class="checkout-summary" style="margin-top: 20px;">
        <div class="checkout-summary-row">
            <span>Subtotal</span>
            <span>{{ formatPrice(cartSubtotal) }}</span>
        </div>
        <div v-if="form.delivery_method === 'Delivery'" class="checkout-summary-row">
          <span>Ongkos Kirim</span>
          <span>{{ formatPrice(shippingFee) }}</span>
        </div>
        <div v-if="discountAmount > 0" class="checkout-summary-row" style="color: var(--success);">
          <span>Promo ({{ selectedPromo?.name }})</span>
          <span>- {{ formatPrice(discountAmount) }}</span>
        </div>
        <div v-if="personalDiscountAmount > 0" class="checkout-summary-row" style="color: var(--success);">
          <span>Promo Personal</span>
          <span>- {{ formatPrice(personalDiscountAmount) }}</span>
        </div>
        <div v-if="pointsDiscount > 0" class="checkout-summary-row" style="color: var(--success);">
          <span>Tukar Koin ({{ maxUsablePoints }} koin)</span>
          <span>- {{ formatPrice(pointsDiscount) }}</span>
        </div>
        <div class="checkout-summary-row total" style="border-top: 2px solid #eee; margin-top: 10px; padding-top: 10px;">
          <span>Total Pembayaran</span>
          <span>{{ formatPrice(finalTotal) }}</span>
        </div>
      </div>

      <button class="btn-primary" @click="submitOrder" :disabled="submitting || !form.customer_name">
        <span v-if="submitting" class="spinner" style="width:20px;height:20px;border-width:2px;"></span>
        <span v-else>🛒 Pesan Sekarang</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, inject, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api.js'
import { useCart } from '../store/cart.js'
import { applyTheme } from '../utils/theme.js'

const props = defineProps({ companyCode: String, branchId: String })
const router = useRouter()
const showToast = inject('showToast')

const { items: cartItems, subtotal: cartSubtotal, state: cartState, clearCart } = useCart()

const customerUser = ref(null)
const availablePromos = ref([])
const selectedPromo = ref(null)
const discountAmount = ref(0)
const submitting = ref(false)
const form = ref({
  customer_name: '',
  customer_phone: '',
  delivery_method: 'Pickup',
  courier: 'Gojek',
  payment_method: 'Tunai',
  shipping_address: '',
  notes: '',
  promo_id: null,
  use_points: false,
})

const personalDiscountAmount = computed(() => {
  if (!customerUser.value || !customerUser.value.customer) return 0
  const cust = customerUser.value.customer
  if (!cust.personal_promo_type || !cust.personal_promo_value) return 0
  
  if (cust.personal_promo_type === 'percentage') {
    return cartSubtotal.value * (cust.personal_promo_value / 100)
  } else if (cust.personal_promo_type === 'flat') {
    return cust.personal_promo_value
  }
  return 0
})

const maxUsablePoints = computed(() => {
    if (!customerUser.value || !customerUser.value.customer) return 0
    const points = customerUser.value.customer.loyalty_points || 0
    const totalAfterPromo = cartSubtotal.value - discountAmount.value - personalDiscountAmount.value
    return Math.min(points, Math.max(0, totalAfterPromo))
})

const pointsDiscount = computed(() => {
    return form.value.use_points ? maxUsablePoints.value : 0
})

const finalTotal = computed(() => {
    return cartSubtotal.value + shippingFee.value - discountAmount.value - personalDiscountAmount.value - pointsDiscount.value
})

onMounted(async () => {
  // Restore user info from local storage first
  const userStr = localStorage.getItem('customer_user')
  if (userStr) {
    const user = JSON.parse(userStr)
    customerUser.value = user
    form.value.customer_name = user.full_name
    form.value.customer_phone = user.phone
    form.value.shipping_address = user.address || ''
  }

  // Fetch company info for theme and promos
  try {
    const token = localStorage.getItem('customer_token')
    if (token) {
        const userData = await api.getMe(token)
        customerUser.value = userData
        localStorage.setItem('customer_user', JSON.stringify(userData))
    }

    const branchesData = await api.getBranches(props.companyCode)
    if (branchesData.company.theme) {
      applyTheme(branchesData.company.theme)
    }
    
    const promosData = await api.getPromos(branchesData.company.id)
    if (customerUser.value && customerUser.value.customer && customerUser.value.customer.is_global_promo_enabled === false) {
      availablePromos.value = []
    } else {
      availablePromos.value = promosData || []
    }
  } catch (e) {
    console.error('Failed to load company info or promos', e)
  }
})

function calculateDiscount() {
  if (!form.value.promo_id) {
    selectedPromo.value = null
    discountAmount.value = 0
    return
  }

  const promo = availablePromos.value.find(p => p.id === form.value.promo_id)
  selectedPromo.value = promo

  if (!promo) {
    discountAmount.value = 0
    return
  }

  if (cartSubtotal.value < promo.min_order) {
    showToast(`Minimal belanja ${formatPrice(promo.min_order)} untuk promo ini`, 'error')
    form.value.promo_id = null
    selectedPromo.value = null
    discountAmount.value = 0
    return
  }

  let disc = 0
  if (promo.type === 'percentage') {
    disc = cartSubtotal.value * (promo.value / 100)
    if (promo.max_discount > 0 && disc > promo.max_discount) {
      disc = promo.max_discount
    }
  } else {
    disc = promo.value
  }
  discountAmount.value = disc
}

const shippingFee = computed(() => {
  if (form.value.delivery_method !== 'Delivery') return 0
  switch (form.value.courier) {
    case 'Gojek': return 15000
    case 'Grab': return 15000
    case 'Shopee Express': return 12000
    case 'Lalamove': return 18000
    case 'Kurir Toko': return 10000
    default: return 10000
  }
})

function formatPrice(price) {
  return 'Rp' + (price || 0).toLocaleString('id-ID')
}

function goBack() {
  router.push({ name: 'Menu', params: { companyCode: props.companyCode, branchId: props.branchId } })
}

async function submitOrder() {
  if (!form.value.customer_name) {
    showToast('Nama pemesan wajib diisi', 'error')
    return
  }
  if (cartItems.value.length === 0) {
    showToast('Keranjang kosong', 'error')
    return
  }

  submitting.value = true
  try {
    const orderData = {
      branch_id: parseInt(props.branchId),
      customer_name: form.value.customer_name,
      customer_phone: form.value.customer_phone,
      delivery_method: form.value.delivery_method === 'Delivery'
        ? `Delivery (${form.value.courier})`
        : form.value.delivery_method,
      payment_method: form.value.payment_method,
      shipping_address: form.value.shipping_address,
      shipping_fee: shippingFee.value,
      promo_id: form.value.promo_id,
      use_points: form.value.use_points,
      notes: form.value.notes,
      items: cartItems.value.map(item => ({
        menu_id: item.menuId,
        quantity: item.quantity,
        notes: item.notes || '',
      })),
    }

    const token = localStorage.getItem('customer_token')
    const result = await api.createOrder(orderData, token)
    clearCart()
    showToast(result.message || 'Pesanan berhasil!', 'success')
    router.push({ name: 'OrderStatus', params: { orderId: result.order_id } })
  } catch (e) {
    showToast(e.message || 'Gagal membuat pesanan', 'error')
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.promo-section {
    background: var(--surface);
    padding: 16px;
    border-radius: var(--radius);
    margin-top: 20px;
    border: 1px dashed var(--primary);
}
.promo-applied {
    margin-top: 8px;
    font-size: 0.8rem;
    color: var(--success);
    font-weight: 600;
}

.points-section {
    background: var(--surface);
    padding: 16px;
    border-radius: var(--radius);
    margin-top: 12px;
    border: 1px solid var(--border);
}
.points-header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 12px;
    padding-bottom: 8px;
    border-bottom: 1px dashed var(--border);
}
.points-toggle {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

/* Switch Styles */
.switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
}
.switch input { opacity: 0; width: 0; height: 0; }
.slider {
  position: absolute;
  cursor: pointer;
  inset: 0;
  background-color: #ccc;
  transition: .4s;
}
.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: .4s;
}
input:checked + .slider { background-color: var(--primary); }
input:focus + .slider { box-shadow: 0 0 1px var(--primary); }
input:checked + .slider:before { transform: translateX(20px); }
.slider.round { border-radius: 34px; }
.slider.round:before { border-radius: 50%; }
</style>
