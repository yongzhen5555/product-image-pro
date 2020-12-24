import {
    LOAD_PRODUCTS
  } from '../helper/types'
  
  export const loadProducts = data => ({
    type: LOAD_PRODUCTS,
    data: data
  })