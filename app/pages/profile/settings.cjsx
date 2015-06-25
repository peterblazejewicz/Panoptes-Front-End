React = require 'react'
ChangeListener = require '../../components/change-listener'
auth = require '../../api/auth'
PromiseRenderer = require '../../components/promise-renderer'
counterpart = require 'counterpart'
Translate = require 'react-translate-component'
AccountInformation = require './account-information'
CustomizeProfile = require './customize-profile'
{Link, RouteHandler} = require 'react-router'

counterpart.registerTranslations 'en',
  userSettingsPage:
    header: "Settings"
    nav:
      accountInformation: "Account Information"
      customizeProfile: "Customize Profile"

UserSettingsPage = React.createClass
  displayName: 'UserSettingsPage'

  getInitialState: ->
    activeTab: "account-information"

  render: ->
    <section className="user-profile-content">
      <div className="secondary-page settings-page">
        <h2><Translate content="userSettingsPage.header" /></h2>
        <div className="settings-content">
          <aside className="secondary-page-side-bar settings-side-bar">
            <nav>
              <Link to="settings-account-information"
                type="button"
                className="secret-button settings-button" >
                <Translate content="userSettingsPage.nav.accountInformation" />
              </Link>
              <Link to="settings-customize-profile"
                type="button"
                className="secret-button settings-button" >
                <Translate content="userSettingsPage.nav.customizeProfile" />
              </Link>
            </nav>
          </aside>
          <section className="settings-tab-content">
            <RouteHandler user={@props.user} />
          </section>
        </div>
      </div>
    </section>

module.exports = React.createClass
  displayName: 'UserSettingsPageWrapper'

  render: ->
    <ChangeListener target={auth} handler={=>
      <PromiseRenderer promise={auth.checkCurrent()} then={(user) =>
        if user?
          <ChangeListener target={user} handler={=>
            <UserSettingsPage user={user} />
          } />
        else
          <div className="content-container">
            <p>You’re not signed in.</p>
          </div>
      } />
    } />