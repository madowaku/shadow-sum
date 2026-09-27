import "./index.css";
import {Composition} from "remotion";
import {NoxsumOpening} from "./NoxsumOpening";
import {NoxsumGrant} from "./grant/NoxsumGrant";

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="NoxsumGrantEN"
      component={NoxsumGrant}
      durationInFrames={2700}
      fps={30}
      width={1920}
      height={1080}
    />
    <Composition
      id="NoxsumOpeningPortrait"
      component={NoxsumOpening}
      durationInFrames={210}
      fps={30}
      // eslint-disable-next-line @remotion/even-dimensions -- storyboard master is exactly 405px wide
      width={405}
      height={900}
      defaultProps={{layout: "portrait"}}
    />
    <Composition
      id="NoxsumOpeningLandscape"
      component={NoxsumOpening}
      durationInFrames={210}
      fps={30}
      width={1600}
      height={900}
      defaultProps={{layout: "landscape"}}
    />
  </>
);




