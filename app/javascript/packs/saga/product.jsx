import regeneratorRuntime from 'regenerator-runtime'
import { put, takeLatest, call } from 'redux-saga/effects'
import request from '../helper/request'
import getMsgText from '../helper/toast_messages'
import getErrorMessage from '../helper/error_messages'

import {
    LOAD_PRODUCTS, PRODUCTS_TOGGLE, TOAST_TOGGLE
} from '../helper/types'

function errorHandler(error) {
    return {
      type: TOAST_TOGGLE,
      payload: {
        isOpen: true,
        error: true,
        message: getErrorMessage(error),
      }
    }
}

function* loadProducts({data}) {
    let res
    try {
      res = yield call(
        request.get,
        '/products',
        { params: data }
      )
    } catch (error) {
      yield put(errorHandler(error))
    } finally {
      if (res) {
        yield put({
          type: PRODUCTS_TOGGLE,
          payload: {
            ...res.data
          }
        })
        data.cb && data.cb(res.data)
      }
    }
}

export function* product() {
    yield takeLatest(LOAD_PRODUCTS, loadProducts)
}