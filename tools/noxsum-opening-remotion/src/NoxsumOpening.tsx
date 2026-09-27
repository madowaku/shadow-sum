import {AbsoluteFill, Sequence} from "remotion";
import {OpeningProps} from "./types";
import {DarknessScene} from "./scenes/DarknessScene";
import {SitScene} from "./scenes/SitScene";
import {StandScene} from "./scenes/StandScene";
import {WalkScene} from "./scenes/WalkScene";
import {WindowScene} from "./scenes/WindowScene";
import {ShadowSumScene} from "./scenes/ShadowSumScene";
import {TitleScene} from "./scenes/TitleScene";

export const NoxsumOpening: React.FC<OpeningProps> = ({layout}) => (
  <AbsoluteFill style={{overflow: "hidden", backgroundColor: "#0b0d12"}}>
    <Sequence durationInFrames={210} name="Darkness / Room">
      <DarknessScene layout={layout} />
    </Sequence>
    <Sequence from={9} durationInFrames={60} name="Sit / Shadow 01">
      <SitScene layout={layout} />
    </Sequence>
    <Sequence from={53} durationInFrames={60} name="Stand / Shadow 02">
      <StandScene layout={layout} />
    </Sequence>
    <Sequence from={97} durationInFrames={54} name="Walk / Shadow 03">
      <WalkScene layout={layout} />
    </Sequence>
    <Sequence from={141} durationInFrames={69} name="Window / Final Vanish">
      <WindowScene layout={layout} />
    </Sequence>
    <Sequence from={180} durationInFrames={30} name="Shadow Sum">
      <ShadowSumScene layout={layout} />
    </Sequence>
    <Sequence from={191} durationInFrames={19} name="Title / Hold">
      <TitleScene layout={layout} />
    </Sequence>
  </AbsoluteFill>
);


