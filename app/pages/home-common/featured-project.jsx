import React from 'react';
import {Link} from 'react-router'

export default class FeaturedProject extends React.Component {
  render() {
    return (
      <section className="home-featured">
        <h1>Featured Projects</h1>
        <div className="home-featured-images">
          <img src="./assets/featured-projects/featured-project-20170328-stargazing-live.jpg" />
        </div>
        <h2>Stargazing Live</h2>
        <p>The Zooniverse has teamed up with BBC Stargazing Live and the SkyMapper Telescope team to bring you Planet 9. Join us in our quest to discover our Solar System's elusive 9th planet!</p>
        <Link to="/projects/skymap/planet-9" className="alternate-button">March 28: Planet Nine</Link>
      </section>
    );
  }
}