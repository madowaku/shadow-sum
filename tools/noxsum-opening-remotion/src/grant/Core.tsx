import {Video} from "@remotion/media";
import {Img, Interactive, Sequence, staticFile} from "remotion";
import {Copy, Footnote, GameplayFrame, Heading, Label, Stage} from "./Design";

export const Core: React.FC = () => <Stage>
  <Sequence durationInFrames={210} name="Place a trace">
    <Label>01 / RECONSTRUCT</Label>
    <Heading>Where<br />was NOX?</Heading>
    <Copy>Place a trace of the cat.<br />Match the recorded shadows.</Copy>
    <Interactive.Div name="SIT portrait" style={{position: "absolute", left: 580, top: 680, width: 300, height: 270}}><Img src={staticFile("nox/nox_sit.webp")} style={{width: "100%", height: "100%", objectFit: "contain"}} /></Interactive.Div>
    <Footnote>ACTUAL GAMEPLAY · RECORD 01</Footnote>
    <GameplayFrame><Video name="GR01 placement" src={staticFile("grant/gameplay.mp4")} trimBefore={30} durationInFrames={210} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
  </Sequence>
  <Sequence from={210} durationInFrames={210} name="Overlapping moments">
    <Label>02 / CONNECT</Label>
    <Heading>One cat.<br />Several moments.</Heading>
    <Copy>Each trace is a different moment.<br />Overlapping shadows add up.</Copy>
    <Interactive.Div name="Overlap key" style={{position: "absolute", left: 100, top: 726, display: "flex", alignItems: "center", gap: 34, fontSize: 42, color: "#cbb785"}}><div style={{width: 90, height: 90, borderRadius: 9, backgroundColor: "#a4adaf"}} />+<div style={{width: 90, height: 90, borderRadius: 9, backgroundColor: "#a4adaf"}} />=<div style={{width: 90, height: 90, borderRadius: 9, backgroundColor: "#6c787c"}} /></Interactive.Div>
    <Footnote>ACTUAL GAMEPLAY · RECORD 02</Footnote>
    <GameplayFrame><Video name="GR02 overlap" src={staticFile("grant/gameplay.mp4")} trimBefore={315} durationInFrames={210} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
  </Sequence>
</Stage>;
