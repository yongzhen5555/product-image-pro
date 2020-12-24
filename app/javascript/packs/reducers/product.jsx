import {
    PRODUCTS_TOGGLE
  } from '../helper/types'

const initialState = {
    products: [],
}

export default (state = initialState, action) => {
    const { type, payload } = action
    if (type === PRODUCTS_TOGGLE) {
        return {
            ...state,
            products: JSON.parse(JSON.stringify(payload.products)),
        }
    }

    return state
}
