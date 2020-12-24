import { combineReducers } from 'redux'
import { connectRouter } from 'connected-react-router'
import preloader from './preloader'
import product from './product'
import toast from './toast'

const rootReducer = (history) => combineReducers({
  preloader,
  product,
  toast,
  router: connectRouter(history)
})

export default rootReducer
