import {Img, Interactive, interpolate, staticFile, useCurrentFrame} from "remotion";
import {Layout} from "../types";

export const WindowLight: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <Interactive.Div
      name="Window Light"
      style={{
        position: "absolute",
        left: layout === "portrait" ? "13%" : "31%",
        top: layout === "portrait" ? "17%" : "10%",
        width: layout === "portrait" ? "74%" : "38%",
        height: layout === "portrait" ? "52%" : "67%",
        border: "1px solid rgba(217,193,155,.12)",
        overflow: "hidden",
        borderTopLeftRadius: "50% 23%",
        borderTopRightRadius: "50% 23%",
        background: "linear-gradient(160deg, rgba(193,204,217,.13), rgba(134,151,171,.035) 54%, rgba(11,14,22,0) 82%)",
        boxShadow: "0 0 65px rgba(177,183,201,.055), inset 0 0 30px rgba(10,13,21,.7)",
        opacity: interpolate(frame, [0, 8, 140, 153, 190], [0.12, 0.18, 0.18, 0.8, 0.46], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
      }}
    >
      <Img
        src={staticFile("room/window_city.webp")}
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
          objectFit: "cover",
          opacity: interpolate(frame, [141, 153, 190], [0, 0.36, 0.20], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      />
      <div style={{position: "absolute", top: 0, bottom: 0, left: "50%", width: 1, background: "rgba(212,207,194,.12)"}} />
      <div style={{position: "absolute", top: "49%", left: 0, right: 0, height: 1, background: "rgba(212,207,194,.12)"}} />
    </Interactive.Div>
  );
};

