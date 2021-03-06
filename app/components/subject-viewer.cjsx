React = require 'react'
`import FavoritesButton from '../collections/favorites-button';`
Dialog = require 'modal-form/dialog'
{Markdown} = require 'markdownz'
classnames = require 'classnames'
getSubjectLocation = require '../lib/get-subject-location'
FlagSubjectButton = require './flag-subject-button'
SignInPrompt = require '../partials/sign-in-prompt'
`import FrameViewer from './frame-viewer';`
`import CollectionsManagerIcon from '../collections/manager-icon';`
`import getSubjectLocations from '../lib/get-subject-locations';`

NOOP = Function.prototype

subjectTypes = (subject) ->
  allTypes = []
  (subject?.locations ? []).forEach (location) ->
    Object.keys(location).forEach (typeAndFormat) ->
      type = typeAndFormat.split('/')[0]
      unless type in allTypes
        allTypes.push type
  # this line seems to be required, but that shouldn't be the case
  return allTypes

subjectHasMixedLocationTypes = (subject) ->
  allTypes = subjectTypes subject
  allTypes.length > 1

subjectIsLikelyAudioPlusImage = (subject) ->
  if parseInt(subject?.metadata?.image_with_audio?, 0) > 0
    true
  else
    allTypes = subjectTypes subject
    allTypes.length == 2 and allTypes.includes('audio') and allTypes.includes('image')

CONTAINER_STYLE = display: 'flex', flexWrap: 'wrap', position: 'relative'

module.exports = React.createClass
  displayName: 'SubjectViewer'

  contextTypes:
    geordi: React.PropTypes.object

  signInAttentionTimeout: NaN

  getDefaultProps: ->
    subject: null
    isFavorite: false
    user: null
    playFrameDuration: 667
    playIterations: 3
    onFrameChange: NOOP
    onLoad: NOOP
    defaultStyle: true
    project: null
    linkToFullImage: false
    frameWrapper: null
    allowFlipbook: true
    allowSeparateFrames: false
    metadataPrefixes: ['#', '!']
    metadataFilters: ['#', '!']
    workflow: null

  getInitialState: ->
    loading: true
    playing: false
    frame: @getInitialFrame()
    frameDimensions: {}
    inFlipbookMode: @props.allowFlipbook
    promptingToSignIn: false

  getInitialFrame: ->
    {frame, allowFlipbook, subject} = @props
    default_frame = parseInt(subject.metadata?.default_frame, 10)
    initialFrame = 0
    if frame?
      initialFrame = frame
    else if allowFlipbook and typeof default_frame is 'number' and !isNaN(default_frame) and default_frame > 0 and default_frame <= subject.locations.length
      initialFrame = default_frame - 1
    initialFrame

  componentWillReceiveProps: (nextProps) ->
    unless nextProps.subject is @props.subject
      clearTimeout @signInAttentionTimeout
      @setState
        playing: false
        loading: true
        frame: 0

  componentDidUpdate: (prevProps) ->
    if @props.subject isnt prevProps.subject
      # turn off the slideshow player and reset any counters
      @setPlaying false
      @setState frame: @getInitialFrame()

  logSubjClick: (logType) ->
    @context.geordi?.logEvent
      type: logType

  render: ->
    rootClasses = classnames('subject-viewer', {
      'default-root-style': @props.defaultStyle
      'subject-viewer--flipbook': @state.inFlipbookMode
      "subject-viewer--layout-#{@props.workflow?.configuration?.multi_image_layout}": @props.workflow?.configuration?.multi_image_layout
    })

    isIE = 'ActiveXObject' of window
    if isIE
      rootStyle = flex: '1 1 auto'

    mainDisplay = ''
    {type, format, src} = getSubjectLocation @props.subject, @state.frame
    subjectLocations = getSubjectLocations @props.subject
    if subjectIsLikelyAudioPlusImage @props.subject
          mainDisplay = @renderFrame @state.frame, {subjectLocations : subjectLocations, isAudioPlusImage : true}
    else if @state.inFlipbookMode
      mainDisplay = @renderFrame @state.frame
    else
      mainDisplay = @props.subject.locations.map (frame, index) =>
        @renderFrame index, {key: "frame-#{index}"}
    tools = switch type
      when 'image'
        if not @state.inFlipbookMode or @props.subject?.locations.length < 2 or subjectHasMixedLocationTypes @props.subject
          if @props.workflow?.configuration.enable_switching_flipbook_and_separate
            <button className="secret-button" aria-label="Toggle flipbook mode" title="Toggle flipbook mode" onClick={@toggleInFlipbookMode}>
              <i className={"fa fa-fw " + if @state.inFlipbookMode then "fa-th-large" else "fa-film"}></i>
            </button>
        else
          <span className="tools">
            {if @props.workflow?.configuration.enable_switching_flipbook_and_separate
              <button className="secret-button" aria-label="Toggle flipbook mode" title="Toggle flipbook mode" onClick={@toggleInFlipbookMode}>
                <i className={"fa fa-fw " + if @state.inFlipbookMode then "fa-th-large" else "fa-film"}></i>
              </button>}

            {if not @state.inFlipbookMode or @props.subject?.locations.length < 2 or subjectHasMixedLocationTypes @props.subject
              null
            else
              <span className="subject-frame-play-controls">
                {if @state.playing
                  <button aria-label="Pause" title="Pause" type="button" className="secret-button subject-tools__play" onClick={@setPlaying.bind this, false}>
                    <i className="fa fa-pause fa-lg fa-fw"></i>
                  </button>
                else
                  <button aria-label="Play" title="Play" type="button" className="secret-button subject-tools__play" onClick={@setPlaying.bind this, true}>
                    <i className="fa fa-play fa-lg fa-fw"></i>
                  </button>}
              </span>}
          </span>

    <div className={rootClasses} style={rootStyle}>
      {if type is 'image'
        @hiddenPreloadedImages()}
      <div className="subject-container" style={CONTAINER_STYLE} >
        {mainDisplay}
        {@props.children}
      </div>

      <div className="subject-tools">
        <span>{tools}</span>
        {if @props.subject?.locations.length >= 2 and not subjectIsLikelyAudioPlusImage(@props.subject) and @state.inFlipbookMode
          <span>
            <span className="subject-frame-pips">
              {for i in [0...@props.subject?.locations.length ? 0]
                <label key={i} className="button subject-frame-pip #{if i is @state.frame then 'active' else ''}" ><input type="radio" name="frame" value={i} onChange={@handleFrameChange.bind this, i} />{i + 1}</label>}
            </span>
        </span>}
        <span>
          {if @props.workflow?.configuration?.invert_subject
            <button type="button" className="secret-button" aria-label="Invert image" title="Invert image" onClick={@toggleModification.bind this, 'invert'}>
              <i className="fa fa-adjust "></i>
            </button>}{' '}
          {if @props.workflow?.configuration?.enable_subject_flags
            <span>
              <FlagSubjectButton className="secret-button" classification={@props.classification} />{' '}
            </span>}
          {if @props.subject?.metadata?
            <span>
              <button type="button" className="secret-button" aria-label="Metadata" title="Metadata" onClick={@showMetadata}>
                <i className="fa fa-info-circle fa-fw"></i>
              </button>{' '}
            </span>}
          {if @props.project? and @props.subject?
            if  @props.user?
              <span>
                {unless @props.workflow?.configuration?.disable_favorites
                  <span>
                    <FavoritesButton className="secret-button" project={@props.project} subject={@props.subject} user={@props.user} isFavorite={@props.isFavorite} />{' '}
                  </span>}
                <CollectionsManagerIcon className="secret-button" project={@props.project} subject={@props.subject} user={@props.user} />
              </span>
            else
              <span>
                <button type="button" className="secret-button #{if @state.loading then 'get-attention'}" onClick={=> @setState promptingToSignIn: true}>
                  <small>You should sign in!</small>
                </button>
                {if @state.promptingToSignIn
                  <Dialog>
                    <SignInPrompt onChoose={=> @setState promptingToSignIn: false}>
                      <p>Sign in to help us make the most out of your hard work.</p>
                    </SignInPrompt>
                  </Dialog>}
              </span>}
          {if type is 'image' and @props.linkToFullImage
            <a className="button" onClick={@logSubjClick.bind this, "subject-image"} href={src} aria-label="Subject Image" title="Subject Image" target="zooImage">
              <i className="fa fa-photo" />
            </a>}
        </span>
      </div>
    </div>

  handleFrameLoad: ->
    @props.onLoad? arguments...
    @signInAttentionTimeout = setTimeout (=> @setState loading: false), 3000

  renderFrame: (frame, props = {}) ->
    <FrameViewer {...@props} {...props} frame={frame} modification={@state?.modification} onLoad={@handleFrameLoad} />

  hiddenPreloadedImages: ->
    # Render this to ensure that all a subject's location images are cached and ready to display.
    <div style={
      bottom: 0
      height: 1
      opacity: 0.1
      overflow: 'hidden'
      position: 'fixed'
      right: 0
      width: 1
    }>
      {for i in [0...@props.subject.locations.length]
        {src} = getSubjectLocation @props.subject, i
        <img key={i} src={src} />}
    </div>

  toggleInFlipbookMode: () ->
    @setInFlipbookMode not @state.inFlipbookMode

  toggleModification: (type) ->
    mods = @state?.modification
    if !mods
      mods = {}
    if mods[type] is undefined
      mods[type] = true
    else
      mods[type] = not mods[type]
    @setState modification: mods

  setInFlipbookMode: (inFlipbookMode) ->
    @setState {inFlipbookMode}

  setPlaying: (playing) ->
    @setState {playing}
    totalFrames = @props.subject.locations.length
    flips = totalFrames * @props.playIterations
    infiniteLoop = @props.playIterations is ''
    counter = 0

    flip = =>
      if @state.playing is on and (counter < flips or infiniteLoop is on)
        counter++
        @handleFrameChange (@state.frame + 1) %% totalFrames
        setTimeout flip, @props.playFrameDuration
        if counter is flips and infiniteLoop is off
          @setPlaying false
      else @setPlaying false

    if playing is on
      setTimeout flip, 0

  handleFrameChange: (frame) ->
    @setState {frame}
    @props.onFrameChange frame

  showMetadata: ->
    @logSubjClick "metadata"
    # TODO: Sticky popup.
    Dialog.alert <div className="content-container">
      <header className="form-label" style={textAlign: 'center'}>Subject metadata</header>
      <hr />
      <table className="standard-table">
        <tbody>
          {for key, value of @props.subject?.metadata when key.charAt(0) not in @props.metadataFilters and key[...2] isnt '//'
            <tr key={key}>
              <th>{key.replace(///^(#{@props.metadataPrefixes.join('|')})///, '')}</th>
              <Markdown tag="td" content={value} inline />
            </tr>}
        </tbody>
      </table>
    </div>, closeButton: true
