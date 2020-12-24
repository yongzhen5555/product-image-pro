import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import { AppProvider, Frame } from '@shopify/polaris'
import { store, history } from './store'
import App from './app'

if( document.readyState !== 'loading' ) {
  myInitCode();
} else {
  document.addEventListener('DOMContentLoaded', function () {
    myInitCode();
  });
}

function myInitCode() {
  ReactDOM.render(
    <Provider store={store}>
      <AppProvider>
        <Frame>
          <App history={history} />
        </Frame>
      </AppProvider>
    </Provider>,
    document.body.appendChild(document.createElement('div')),
  )
}

