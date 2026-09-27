import {Interactive, interpolate, useCurrentFrame} from "remotion";
import {Layout} from "../types";

export const NoxsumTitle: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <Interactive.Div
      name="NOXSUM Title"
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: layout === "portrait" ? "14.5%" : "12%",
        display: "flex",
        alignItems: "baseline",
        justifyContent: "center",
        fontFamily: "'NOXSUM Display', Georgia, serif",
        fontSize: layout === "portrait" ? 82 : 150,
        fontWeight: 500,
        letterSpacing: 0,
        lineHeight: 1,
        color: "#e7e1d8",
        textShadow: "0 2px 5px rgba(3,6,12,.9)",
        opacity: interpolate(frame, [0, 13], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        translate: interpolate(frame, [0, 13], ["0px 4px", "0px 0px"], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        scale: interpolate(frame, [0, 13], [0.99, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
      }}
    >
      <span>NO</span>
      <svg aria-label="X" viewBox="0 0 56 72" style={{width: ".56em", height: ".72em", alignSelf: "center", overflow: "visible"}}>
        <path d="M1 4 L11 4 L55 68 L45 68 Z" fill="#e7e1d8" />
        <path d="M45 4 L55 4 L11 68 L1 68 Z" fill="#e7e1d8" />
        <path d="M3 4 L9 4 L53 68 L47 68 Z" fill="rgba(12,22,33,.52)" />
        <path d="M47 4 L53 4 L9 68 L3 68 Z" fill="rgba(12,22,33,.52)" />
        <path d="M28 30 L34 36 L28 42 L22 36 Z" fill="rgba(7,15,24,.64)" />
      </svg>
      <span>SUM</span>
    </Interactive.Div>
  );
};



