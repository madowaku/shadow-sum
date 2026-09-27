import {Img, Interactive, interpolate, staticFile, useCurrentFrame} from "remotion";
import {NoxsumTitle} from "../components/NoxsumTitle";
import {Stage} from "./Design";

export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  return <Stage>
    <Interactive.Div name="Moonlit window" style={{position: "absolute", left: 1030, top: 60, width: 820, height: 960, overflow: "hidden", opacity: 0.8, borderBottom: "2px solid #a6997355"}}>
      <Img src={staticFile("room/window_city.webp")} style={{width: 820, height: 960, objectFit: "cover", scale: interpolate(frame, [0, 240], [1, 1.035])}} />
      <Interactive.Div name="Window vignette" style={{position: "absolute", inset: 0, background: "linear-gradient(90deg, #07121b 0%, transparent 25%), linear-gradient(0deg, #07121b 0%, transparent 60%)"}} />
      <Img src={staticFile("nox/nox_window.webp")} style={{position: "absolute", left: 105, top: 380, width: 660, opacity: interpolate(frame, [0, 25, 110, 172], [0, 1, 1, 0], {extrapolateRight: "clamp"})}} />
    </Interactive.Div>
    <Interactive.Div name="Game title" style={{position: "absolute", left: 48, top: 185, width: 980, height: 290}}><NoxsumTitle layout="landscape" /></Interactive.Div>
    <Interactive.Div name="Opening premise" style={{position: "absolute", left: 96, top: 487, width: 875, fontFamily: "Grant Display", fontSize: 76, lineHeight: 1.14, color: "#eee7db", opacity: interpolate(frame, [18, 44], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"})}}>NOX is gone.<br />The shadows remember.</Interactive.Div>
    <Interactive.Div name="Genre" style={{position: "absolute", left: 99, top: 749, fontSize: 24, letterSpacing: 4, color: "#b6cbd0", opacity: interpolate(frame, [85, 110], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"})}}>A QUIET LOGIC MYSTERY</Interactive.Div>
    <Interactive.Div name="Application label" style={{position: "absolute", left: 96, top: 970, fontSize: 18, letterSpacing: 3, color: "#81949c"}}>DRAKNEK NEW VOICES PUZZLE GRANT · 2026</Interactive.Div>
  </Stage>;
};
