import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/:companyCode',
    name: 'BranchSelect',
    component: () => import('./views/BranchSelectView.vue'),
    props: true,
  },
  {
    path: '/:companyCode/login',
    name: 'Login',
    component: () => import('./views/LoginView.vue'),
    props: true,
  },
  {
    path: '/:companyCode/register',
    name: 'Register',
    component: () => import('./views/RegisterView.vue'),
    props: true,
  },
  {
    path: '/:companyCode/:branchId',
    name: 'Menu',
    component: () => import('./views/MenuView.vue'),
    props: true,
  },
  {
    path: '/:companyCode/:branchId/checkout',
    name: 'Checkout',
    component: () => import('./views/CheckoutView.vue'),
    props: true,
  },
  {
    path: '/order/:orderId/status',
    name: 'OrderStatus',
    component: () => import('./views/OrderStatusView.vue'),
    props: true,
  },
  {
    path: '/:companyCode/history',
    name: 'OrderHistory',
    component: () => import('./views/OrderHistoryView.vue'),
    props: true,
  },
  {
    path: '/',
    redirect: '/NFM001',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0 }
  },
})

export default router
