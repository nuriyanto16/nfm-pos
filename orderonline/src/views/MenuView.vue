<template>
  <div>
    <!-- Header -->
    <header class="app-header">
      <button class="back-btn" @click="goBack">←</button>
      <span class="header-title">{{ branch.name || 'Menu' }}</span>
      <div class="header-right">
        <button class="back-btn" @click="showSearch = !showSearch">🔍</button>
      </div>
    </header>

    <!-- Closed Banner -->
    <div v-if="!branch.is_open && !loading" class="closed-banner">
      ⚠️ Toko sedang tutup ({{ branch.open_time }} - {{ branch.close_time }})
    </div>

    <!-- Search -->
    <div v-if="showSearch" class="search-bar">
      <div class="search-input-wrap">
        <span class="search-icon">🔍</span>
        <input v-model="searchQuery" class="search-input" placeholder="Cari menu..." ref="searchInput" />
      </div>
    </div>

    <!-- Category Tabs -->
    <div v-if="categories.length" class="category-tabs" ref="tabsRef">
      <button
        v-for="cat in categories"
        :key="cat.id"
        :class="['category-tab', { active: activeCategory === cat.id }]"
        @click="scrollToCategory(cat.id)"
      >
        {{ cat.name }}
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading-container">
      <div class="spinner"></div>
      <span style="color: var(--text-secondary); font-size: 0.85rem;">Memuat menu...</span>
    </div>

    <!-- Menu Sections -->
    <template v-else>
      <div v-for="cat in filteredCategories" :key="cat.id" :ref="el => setCatRef(cat.id, el)" class="menu-section">
        <h2 class="menu-section-title">{{ cat.name }}</h2>
        <div v-for="item in cat.items" :key="item.id" class="menu-item">
          <img
            v-if="item.image_url"
            :src="getImageUrl(item.image_url)"
            :alt="item.name"
            class="menu-item-image"
            loading="lazy"
          />
          <div v-else class="menu-item-image placeholder">🍽️</div>
          <div class="menu-item-info">
            <div class="menu-item-name">{{ item.name }}</div>
            <div v-if="item.description" class="menu-item-desc">{{ item.description }}</div>
            <div class="menu-item-price">{{ formatPrice(item.price) }}</div>
          </div>
          <div class="menu-item-actions">
            <div v-if="getItemQty(item.id) > 0" class="qty-control">
              <button class="qty-btn" @click="decrementItem(item)">−</button>
              <span class="qty-value">{{ getItemQty(item.id) }}</span>
              <button class="qty-btn" @click="addToCart(item)">+</button>
            </div>
            <button v-else class="add-btn" @click="addToCart(item)" :disabled="!branch.is_open">+</button>
          </div>
        </div>
      </div>

      <div v-if="filteredCategories.length === 0" class="empty-state">
        <div class="empty-icon">🍽️</div>
        <div class="empty-text">Menu tidak ditemukan</div>
      </div>
    </template>

    <!-- Cart Bar -->
    <div v-if="itemCount > 0" class="cart-bar" @click="openCartDrawer">
      <div class="cart-bar-inner">
        <div class="cart-bar-left">
          <span class="cart-badge">{{ itemCount }}</span>
          <span class="cart-bar-text">Keranjang</span>
        </div>
        <span class="cart-bar-total">{{ formatPrice(subtotal) }}</span>
      </div>
    </div>

    <!-- Cart Drawer Overlay -->
    <div v-if="cartOpen" :class="['cart-overlay', { active: cartOpen }]" @click="cartOpen = false"></div>

    <!-- Cart Drawer -->
    <div :class="['cart-drawer', { active: cartOpen }]">
      <div class="cart-drawer-header">
        <h3>🛒 Keranjang</h3>
        <button class="cart-drawer-close" @click="cartOpen = false">✕</button>
      </div>
      <div class="cart-drawer-body">
        <div v-for="item in cartItems" :key="item.menuId" class="cart-item">
          <img v-if="item.imageUrl" :src="getImageUrl(item.imageUrl)" class="cart-item-img" />
          <div v-else class="cart-item-img" style="display:flex;align-items:center;justify-content:center;font-size:1.4rem;">🍽️</div>
          <div class="cart-item-info">
            <div class="cart-item-name">{{ item.name }}</div>
            <div class="cart-item-price">{{ formatPrice(item.price) }} × {{ item.quantity }}</div>
            <div class="cart-item-remove" @click="removeFromCart(item.menuId)">Hapus</div>
          </div>
          <div class="qty-control">
            <button class="qty-btn" @click="updateQty(item.menuId, item.quantity - 1)">−</button>
            <span class="qty-value">{{ item.quantity }}</span>
            <button class="qty-btn" @click="updateQty(item.menuId, item.quantity + 1)">+</button>
          </div>
        </div>
      </div>
      <div class="cart-drawer-footer">
        <div class="cart-summary">
          <span class="label">Subtotal</span>
          <span class="value">{{ formatPrice(subtotal) }}</span>
        </div>
        <button class="btn-primary" @click="goToCheckout">Checkout</button>
      </div>
    </div>

    <!-- Spacer for cart bar -->
    <div v-if="itemCount > 0" style="height: 80px;"></div>
    <div v-else style="height: 80px;"></div>
    <BottomNav :companyCode="companyCode" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, inject } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api.js'
import { useCart } from '../store/cart.js'
import { applyTheme } from '../utils/theme.js'
import BottomNav from '../components/BottomNav.vue'

const props = defineProps({ companyCode: String, branchId: String })
const router = useRouter()
const showToast = inject('showToast')

const { items: cartItems, itemCount, subtotal, addItem, removeItem, updateQuantity, getItemQuantity, setBranch } = useCart()

const loading = ref(true)
const branch = ref({})
const categories = ref([])
const searchQuery = ref('')
const showSearch = ref(false)
const activeCategory = ref(null)
const cartOpen = ref(false)
const catRefs = {}
const tabsRef = ref(null)

const filteredCategories = computed(() => {
  if (!searchQuery.value) return categories.value
  const q = searchQuery.value.toLowerCase()
  return categories.value
    .map(cat => ({
      ...cat,
      items: cat.items.filter(i => i.name.toLowerCase().includes(q) || (i.description || '').toLowerCase().includes(q)),
    }))
    .filter(cat => cat.items.length > 0)
})

function setCatRef(id, el) { if (el) catRefs[id] = el }

function scrollToCategory(catId) {
  activeCategory.value = catId
  const el = catRefs[catId]
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

function formatPrice(price) {
  return 'Rp' + (price || 0).toLocaleString('id-ID')
}

import { getFullUrl } from '../utils/url.js'

function getImageUrl(url) {
  return getFullUrl(url)
}

function getItemQty(menuId) { return getItemQuantity(menuId) }

function addToCart(item) {
  if (!branch.value.is_open) {
    showToast('Toko sedang tutup', 'error')
    return
  }
  addItem(item)
}
function decrementItem(item) { updateQuantity(item.id, getItemQuantity(item.id) - 1) }
function removeFromCart(menuId) { removeItem(menuId) }
function updateQty(menuId, qty) { updateQuantity(menuId, qty) }
function openCartDrawer() { cartOpen.value = true }

function goBack() { router.push({ name: 'BranchSelect', params: { companyCode: props.companyCode } }) }

function goToCheckout() {
  cartOpen.value = false
  router.push({ name: 'Checkout', params: { companyCode: props.companyCode, branchId: props.branchId } })
}

onMounted(async () => {
  try {
    const data = await api.getMenuByBranch(props.branchId)
    branch.value = data.branch
    categories.value = data.categories || []
    setBranch(data.branch.id, data.branch.name, props.companyCode)
    
    // Fetch company info for theme
    try {
        const branchesData = await api.getBranches(props.companyCode)
        if (branchesData.company.theme) {
            applyTheme(branchesData.company.theme)
        }
    } catch (e) {
        console.error('Failed to load theme', e)
    }

    if (categories.value.length > 0) {
      activeCategory.value = categories.value[0].id
    }
    document.title = `${data.branch.name} - Menu`
  } catch (e) {
    showToast(e.message || 'Gagal memuat menu', 'error')
  } finally {
    loading.value = false
  }
})
</script>
