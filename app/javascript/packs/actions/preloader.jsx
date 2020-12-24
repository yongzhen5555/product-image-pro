import { PRELOADER_TOGGLE } from '../helper/types'

export const togglePreloader = data => ({
  type: PRELOADER_TOGGLE,
  payload: data
})
