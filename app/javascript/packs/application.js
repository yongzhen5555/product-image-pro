// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

// require("@rails/ujs").start()
// require("turbolinks").start()
// require("@rails/activestorage").start()
// require("channels")


// // Uncomment to copy all static images under ../images to the output folder and reference
// // them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// // or the `imagePath` JavaScript helper below.
// //
// // const images = require.context('../images', true)
// // const imagePath = (name) => images(name, true)
// require("shopify_app")
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

