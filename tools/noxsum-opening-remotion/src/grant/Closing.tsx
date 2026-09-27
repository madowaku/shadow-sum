import {Img, Interactive, staticFile} from "remotion";
import {NoxsumTitle} from "../components/NoxsumTitle";
import {Stage} from "./Design";

export const Closing: React.FC = () => <Stage>
  <Img src={staticFile("nox/nox_sit.webp")} style={{position: "absolute", left: 1230, top: 180, width: 570, height: 680, objectFit: "contain", opacity: 0.93}} />
  <Interactive.Div name="Closing logo" style={{position: "absolute", left: 48, top: 190, width: 1050, height: 260}}><NoxsumTitle layout="landscape" /></Interactive.Div>
  <Interactive.Div name="Closing invitation" style={{position: "absolute", left: 96, top: 482, fontFamily: "Grant Display", fontSize: 69, color: "#f0eadf", lineHeight: 1.2}}>Read what remains.</Interactive.Div>
  <Interactive.Div name="Prototype details" style={{position: "absolute", left: 100, top: 650, fontSize: 31, color: "#c5d3d6", lineHeight: 1.8}}>Playable browser prototype<br />36 records · English / Japanese</Interactive.Div>
  <Interactive.Div name="Development status" style={{position: "absolute", left: 100, top: 830, fontSize: 22, letterSpacing: 3, color: "#cbb685"}}>IN ACTIVE DEVELOPMENT</Interactive.Div>
  <Interactive.Div name="Credits" style={{position: "absolute", left: 96, top: 966, fontSize: 18, color: "#8a9ba1", lineHeight: 1.6}}>Draknek New Voices Puzzle Grant · 2026<br />Music: “Logical Thinking” by Phalene / OpenTracks</Interactive.Div>
</Stage>;
