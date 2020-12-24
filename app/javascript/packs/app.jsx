import React, { Component } from 'react'

import { Switch, Route } from 'react-router-dom'
import { ConnectedRouter } from 'connected-react-router'
import routes from './routes'
import Toaster from './components/shared/toaster'
const App = ({ history }) => {
  return (
    <ConnectedRouter history={history}>
      <Switch>
        {routes.map((route) => (
          <Route
            key={route.url}
            path={route.url}
            exact={route.exact}
            component={route.component}
          />
        ))}
      </Switch>
      <Toaster/>
    </ConnectedRouter>
  )
}

export default App
