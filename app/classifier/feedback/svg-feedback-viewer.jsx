import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import FeedbackPoint from './feedback-point';

class FeedbackViewer extends React.Component {
  constructor(props) {
    super(props);
    this.renderFeedbackPoints = this.renderFeedbackPoints.bind(this);
  }

  shouldComponentUpdate(nextProps) {
    return nextProps.feedback.length !== this.props.feedback.length;
  }

  render() {
    const { feedback } = this.props;
    return (feedback.length) ? this.renderFeedbackPoints(feedback) : null;
  }

  renderFeedbackPoints(feedback) {
    return (
      <g className="feedback-points">
        {feedback.map(point => <FeedbackPoint point={point} key={`feedback-point-${point.x}-${point.y}`} />)}
      </g>
    );
  }
}

const mapStateToProps = (state) => ({
  feedback: state.feedback.filter(item => item.target === 'classifier'),
});

FeedbackViewer.propTypes = {
  feedback: PropTypes.arrayOf(PropTypes.shape({
    x: PropTypes.string,
    y: PropTypes.string,
  }))
};

export default connect(mapStateToProps)(FeedbackViewer);
export { FeedbackViewer };