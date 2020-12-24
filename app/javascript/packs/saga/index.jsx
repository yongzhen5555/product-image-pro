// import regeneratorRuntime from 'regenerator-runtime'
import { all } from 'redux-saga/effects'
import { product } from './product'

export default function* rootSaga() {
  yield all([
    product()
  ])
}
