React = require 'react'
Draggable = require '../../lib/draggable'

RADIUS = 4
OVERSHOOT = 4

module.exports = React.createClass
  displayName: 'DragHandle'

  render: ->
    matrix = @props.getScreenCurrentTransformationMatrix()
    className = "drag-handle"
    if @props.className?
      className += " #{@props.className}"
    styleProps =
      fill: 'currentColor'
      stroke: 'transparent'
      strokeWidth: OVERSHOOT
      transform: """
        translate(#{@props.x}, #{@props.y})
        matrix( #{1/matrix.a} 0 0 #{1/matrix.d} 0 0)
      """
    <Draggable onStart={@props.onStart} onDrag={@props.onDrag} onEnd={@props.onEnd} >
      <circle className={className} r={RADIUS} {...styleProps} style={@props.style} />
    </Draggable>
