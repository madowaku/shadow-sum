import {loadFont} from "@remotion/fonts";
import {Audio} from "@remotion/media";
import {TransitionSeries} from "@remotion/transitions";
import {AbsoluteFill, interpolate, staticFile, useCurrentFrame} from "remotion";
import {Closing} from "./Closing";
import {Core} from "./Core";
import {Deduction} from "./Deduction";
import {Depth} from "./Depth";
import {Room} from "./Design";
import {Hook} from "./Hook";
import {Light} from "./Light";
import {Poses} from "./Poses";

loadFont({family: "Grant Sans", url: staticFile("fonts/Manrope.ttf"), weight: "200 800"});
loadFont({family: "Grant Display", url: staticFile("fonts/CormorantGaramond.ttf"), weight: "300 700"});

export const NoxsumGrant: React.FC = () => {
  const frame = useCurrentFrame();
  return <AbsoluteFill style={{backgroundColor: "#07121b", fontFamily: "Grant Sans", overflow: "hidden"}}>
    <Room />
    <TransitionSeries name="Grant application · English · 90 seconds">
      <TransitionSeries.Sequence durationInFrames={240} name="The mystery"><Hook /></TransitionSeries.Sequence>
      <TransitionSeries.Sequence durationInFrames={420} name="The core mechanic"><Core /></TransitionSeries.Sequence>
      <TransitionSeries.Sequence durationInFrames={780} name="GR03 · Absence is evidence"><Deduction /></TransitionSeries.Sequence>
      <TransitionSeries.Sequence durationInFrames={360} name="The poses"><Poses /></TransitionSeries.Sequence>
      <TransitionSeries.Sequence durationInFrames={240} name="Sleep and light"><Light /></TransitionSeries.Sequence>
      <TransitionSeries.Sequence durationInFrames={420} name="The deeper puzzles"><Depth /></TransitionSeries.Sequence>
      <TransitionSeries.Sequence durationInFrames={240} name="The prototype"><Closing /></TransitionSeries.Sequence>
    </TransitionSeries>
    <Audio name="Quiet puzzle soundtrack" src={staticFile("grant/logical-thinking.mp3")} volume={(f) => interpolate(f, [0, 60, 2580, 2699], [0, 0.28, 0.28, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"})} />
    <AbsoluteFill style={{backgroundColor: "#07121b", opacity: interpolate(frame, [0, 18, 2670, 2699], [1, 0, 0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}), pointerEvents: "none"}} />
  </AbsoluteFill>;
};
