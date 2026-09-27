import {Video} from "@remotion/media";
import {Interactive, staticFile} from "remotion";
import {Copy, Footnote, GameplayFrame, Heading, Label, Stage} from "./Design";

export const Light: React.FC = () => <Stage>
  <Label>05 / QUESTION THE LIGHT</Label>
  <Heading>Even a nap<br />changes the clues.</Heading>
  <Copy>SLEEP blocks light from above.<br />Slide it along the rail to reshape the evidence.</Copy>
  <Interactive.Div name="Light blocking explanation" style={{position: "absolute", left: 98, top: 749, width: 780, paddingLeft: 26, borderLeft: "2px solid #c1a56c", color: "#d4be91", fontSize: 29, lineHeight: 1.55}}>The same placement.<br />A different set of shadows.</Interactive.Div>
  <Footnote>ACTUAL GAMEPLAY · RECORD 08</Footnote>
  <GameplayFrame><Video name="GR08 sleep rail" src={staticFile("grant/gameplay.mp4")} trimBefore={1950} durationInFrames={240} volume={0.6} style={{position: "absolute", width: 1008, height: 1260, left: -126, top: -98}} /></GameplayFrame>
</Stage>;
