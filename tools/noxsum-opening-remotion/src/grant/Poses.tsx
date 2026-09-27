import {Video} from "@remotion/media";
import {Img, Interactive, Sequence, staticFile} from "remotion";
import {Copy, Footnote, GameplayFrame, Heading, Label, Stage} from "./Design";

export const Poses: React.FC = () => <Stage>
  <Label>04 / FOLLOW THE RULES</Label>
  <Sequence durationInFrames={180} name="STAND reaches farther">
    <Heading>A different pose.<br />A different shadow.</Heading>
    <Copy>STAND reaches farther.</Copy>
    <Interactive.Div name="STAND portrait" style={{position: "absolute", left: 570, top: 590, width: 310, height: 355}}><Img src={staticFile("nox/nox_stand.webp")} style={{width: "100%", height: "100%", objectFit: "contain"}} /></Interactive.Div>
    <Footnote>ACTUAL GAMEPLAY · RECORD 09</Footnote>
    <GameplayFrame><Video name="GR09 height" src={staticFile("grant/gameplay.mp4")} trimBefore={1470} durationInFrames={180} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
  </Sequence>
  <Sequence from={180} durationInFrames={180} name="WALK changes direction">
    <Heading>Turn the pose.<br />Turn the shadow.</Heading>
    <Copy>WALK changes the direction of its trace.</Copy>
    <Interactive.Div name="WALK portrait" style={{position: "absolute", left: 385, top: 640, width: 500, height: 285}}><Img src={staticFile("nox/nox_walk.webp")} style={{width: "100%", height: "100%", objectFit: "contain"}} /></Interactive.Div>
    <Footnote>ACTUAL GAMEPLAY · RECORD 11</Footnote>
    <GameplayFrame><Video name="GR11 rotation" src={staticFile("grant/gameplay.mp4")} trimBefore={1710} durationInFrames={180} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
  </Sequence>
</Stage>;
