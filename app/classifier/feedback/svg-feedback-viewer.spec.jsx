/* eslint
  func-names: 0,
  import/no-extraneous-dependencies: ['error', { 'devDependencies': true }]
  no-underscore-dangle: 0,
  prefer-arrow-callback: 0,
  'react/jsx-boolean-value': ['error', 'always']
*/

import React from 'react';
import assert from 'assert';
import { shallow } from 'enzyme';
import { FeedbackViewer, __RewireAPI__ as RewireAPI } from './svg-feedback-viewer';

class FeedbackPoint extends React.Component {
  render() {
    return <circle />;
  }
}

RewireAPI.__Rewire__('FeedbackPoint', FeedbackPoint);

const FEEDBACK = [
  { x: '10', y: '10' },
  { x: '20', y: '20' }
];

describe('<FeedbackViewer />', function () {
  it('should return null if not passed any feedback', function () {
    const wrapper = shallow(<FeedbackViewer feedback={[]} />);
    assert.strictEqual(wrapper.type(), null);
  });

  it('should return the correct element and class', function () {
    const wrapper = shallow(<FeedbackViewer feedback={FEEDBACK} />);
    assert.strictEqual(wrapper.type(), 'g');
    assert(wrapper.hasClass('feedback-points'));
  });

  it('should return a FeedbackPoint for each feedback item', function () {
    const wrapper = shallow(<FeedbackViewer feedback={FEEDBACK} />);
    assert.strictEqual(wrapper.find('FeedbackPoint').length, 2);
  });
});
