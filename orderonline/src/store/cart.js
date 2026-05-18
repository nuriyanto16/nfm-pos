import { reactive, computed } from 'vue'

const state = reactive({
  items: [],
  branchId: null,
  branchName: '',
  companyCode: '',
})

export function useCart() {
  const itemCount = computed(() => {
    return state.items.reduce((sum, item) => sum + item.quantity, 0)
  })

  const subtotal = computed(() => {
    return state.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  })

  function addItem(menu) {
    const existing = state.items.find(i => i.menuId === menu.id)
    if (existing) {
      existing.quantity++
    } else {
      state.items.push({
        menuId: menu.id,
        name: menu.name,
        price: menu.price,
        imageUrl: menu.image_url,
        quantity: 1,
        notes: '',
      })
    }
  }

  function removeItem(menuId) {
    const idx = state.items.findIndex(i => i.menuId === menuId)
    if (idx !== -1) {
      state.items.splice(idx, 1)
    }
  }

  function updateQuantity(menuId, qty) {
    const item = state.items.find(i => i.menuId === menuId)
    if (item) {
      if (qty <= 0) {
        removeItem(menuId)
      } else {
        item.quantity = qty
      }
    }
  }

  function updateNotes(menuId, notes) {
    const item = state.items.find(i => i.menuId === menuId)
    if (item) {
      item.notes = notes
    }
  }

  function clearCart() {
    state.items.splice(0, state.items.length)
  }

  function setBranch(id, name, companyCode) {
    state.branchId = id
    state.branchName = name
    state.companyCode = companyCode
  }

  function getItemQuantity(menuId) {
    const item = state.items.find(i => i.menuId === menuId)
    return item ? item.quantity : 0
  }

  return {
    state,
    items: computed(() => state.items),
    itemCount,
    subtotal,
    addItem,
    removeItem,
    updateQuantity,
    updateNotes,
    clearCart,
    setBranch,
    getItemQuantity,
  }
}
