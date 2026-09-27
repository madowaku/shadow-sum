import {Video} from "@remotion/media";
import {Interactive, Sequence, staticFile} from "remotion";
import {Copy, Footnote, GameplayFrame, Heading, Label, Stage} from "./Design";

export const Depth: React.FC = () => <Stage>
  <Label>06 / GO DEEPER</Label>
  <Sequence durationInFrames={210} name="Shaped boards">
    <Heading>Fewer places.<br />Sharper deductions.</Heading>
    <Copy>Shaped boards narrow the possibilities.</Copy>
    <Interactive.Div name="Board insight" style={{position: "absolute", left: 98, top: 735, width: 790, color: "#d4be91", fontSize: 31, lineHeight: 1.55}}>A missing position changes<br />what the shadows can mean.</Interactive.Div>
    <Footnote>ACTUAL GAMEPLAY · RECORD 24</Footnote>
    <GameplayFrame><Video name="GR24 shaped board" src={staticFile("grant/gameplay.mp4")} trimBefore={2280} durationInFrames={210} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
  </Sequence>
  <Sequence from={210} durationInFrames={210} name="Combined rules">
    <Heading>Simple rules.<br />Layers of logic.</Heading>
    <Copy>Combine poses, light and board shapes.<br />Find the arrangement that explains it all.</Copy>
    <Interactive.Div name="Thinking pace" style={{position: "absolute", left: 98, top: 754, width: 790, color: "#d4be91", fontSize: 31}}>No timer. Time to think.</Interactive.Div>
    <Footnote>ACTUAL GAMEPLAY · RECORD 36</Footnote>
    <GameplayFrame><Video name="GR36 combined rules" src={staticFile("grant/gameplay.mp4")} trimBefore={2580} durationInFrames={210} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
  </Sequence>
</Stage>;
