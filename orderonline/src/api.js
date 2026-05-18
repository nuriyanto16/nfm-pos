const BASE_URL = import.meta.env.VITE_API_URL || '/api'

async function request(method, endpoint, body = null) {
  const options = {
    method,
    headers: { 'Content-Type': 'application/json' },
  }
  if (body) {
    options.body = JSON.stringify(body)
  }

  const res = await fetch(`${BASE_URL}${endpoint}`, options)
  const data = await res.json()
  
  if (!res.ok) {
    throw new Error(data.error || 'Terjadi kesalahan')
  }
  return data
}

export const api = {
  getCompanyInfo(code) {
    return request('GET', `/public/company/${code}`)
  },

  getBranches(companyCode) {
    return request('GET', `/public/company/${companyCode}/branches`)
  },

  getMenuByBranch(branchId) {
    return request('GET', `/public/menu/${branchId}`)
  },

  createOrder(orderData, token = null) {
    const headers = { 'Content-Type': 'application/json' }
    if (token) headers['Authorization'] = `Bearer ${token}`
    
    return fetch(`${BASE_URL}${token ? '/public/authenticated-orders' : '/public/orders'}`, {
      method: 'POST',
      headers,
      body: JSON.stringify(orderData)
    }).then(res => res.json().then(data => {
      if (!res.ok) throw new Error(data.error || 'Gagal membuat pesanan')
      return data
    }))
  },

  getOrderStatus(orderId) {
    return request('GET', `/public/orders/${orderId}/status`)
  },

  register(userData) {
    return request('POST', '/public/register', userData)
  },

  login(credentials) {
    return request('POST', '/public/login', credentials)
  },

  getOrderHistory(token) {
    return fetch(`${BASE_URL}/public/orders/history`, {
      headers: { 'Authorization': `Bearer ${token}` }
    }).then(res => res.json())
  },

  getMe(token) {
    return fetch(`${BASE_URL}/public/me`, {
      headers: { 'Authorization': `Bearer ${token}` }
    }).then(res => res.json())
  },
  
  getPromos(companyId) {
    return request('GET', `/public/promos?company_id=${companyId}`)
  }
}

export default api
