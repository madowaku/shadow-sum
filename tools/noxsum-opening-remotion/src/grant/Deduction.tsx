import {Video} from "@remotion/media";
import {Interactive, Sequence, staticFile} from "remotion";
import {Footnote, GameplayFrame, Heading, Label, Stage} from "./Design";

export const Deduction: React.FC = () => <Stage>
  <Label>03 / DEDUCE</Label>
  <Sequence durationInFrames={210} name="Build plausible answer"><Heading>A convincing<br />wrong answer.</Heading><Interactive.Div name="Initial clue" style={{position: "absolute", left: 96, top: 465, width: 850, color: "#b8c9cc", fontSize: 32}}>Three traces. One seemingly perfect match.</Interactive.Div></Sequence>
  <Sequence from={210} durationInFrames={195} name="Find contradiction"><Heading>Every shadow fits.<br />Except one.</Heading><Interactive.Div name="Contradiction" style={{position: "absolute", left: 96, top: 465, width: 850, color: "#d4be91", fontSize: 32}}>All marked squares agree. But D5 should be clear.</Interactive.Div></Sequence>
  <Sequence from={405} durationInFrames={180} name="Rethink the placement"><Heading>Read the<br />empty squares.</Heading><Interactive.Div name="Revision" style={{position: "absolute", left: 96, top: 465, width: 850, color: "#b8c9cc", fontSize: 32}}>Move the trace. Test the whole record.</Interactive.Div></Sequence>
  <Sequence from={585} durationInFrames={195} name="Aha"><Heading>Absence<br />is evidence.</Heading><Interactive.Div name="Deduction payoff" style={{position: "absolute", left: 96, top: 465, width: 850, color: "#d4be91", fontSize: 32}}>Now every square agrees — including the empty ones.</Interactive.Div></Sequence>
  <Interactive.Div name="Enlarged evidence plates" style={{position: "absolute", left: 96, top: 552, width: 731, height: 393, overflow: "hidden", borderRadius: 4, boxShadow: "0 16px 60px #0006"}}>
    <Video name="Synchronized GR03 close-up" src={staticFile("grant/gameplay.mp4")} trimBefore={630} durationInFrames={780} muted style={{position: "absolute", width: 1512, height: 1890, left: -390.6, top: -212.1}} />
    <Sequence from={210} durationInFrames={375} name="Highlight D5 evidence">
      <Interactive.Div name="Recorded D5 must be empty" style={{position: "absolute", left: 206, top: 317, width: 59, height: 59, border: "4px solid #f1d190", borderRadius: 7, boxShadow: "0 0 18px #efbc5d66"}} />
      <Interactive.Div name="Extra reconstruction shadow" style={{position: "absolute", left: 592, top: 317, width: 59, height: 59, border: "4px solid #f1d190", borderRadius: 7, boxShadow: "0 0 18px #efbc5d66"}} />
    </Sequence>
  </Interactive.Div>
  <Footnote>RECORD 03 · MATCH THE SHADOWS AND THE GAPS</Footnote>
  <GameplayFrame><Video name="GR03 full deduction" src={staticFile("grant/gameplay.mp4")} trimBefore={630} durationInFrames={780} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
</Stage>;
