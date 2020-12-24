import { PRELOADER_TOGGLE } from '../helper/types'

const initialState = {
  show: true,
  actionName: ''
}

export default (state = initialState, action) => {
  if (action.type === PRELOADER_TOGGLE) {
    if (
      state.actionName === action.payload.actionName &&
      action.payload.show === false
    ) {
      return {
        ...state,
        show: action.payload.show,
        actionName: action.payload.actionName
      }
    } else if (action.payload.show === true) {
      return {
        ...state,
        show: action.payload.show,
        actionName: action.payload.actionName
      }
    }
  }

  return state
}
