import {AbsoluteFill, Interactive, interpolate, useCurrentFrame} from "remotion";
import {WindowLight} from "../components/WindowLight";
import {Layout} from "../types";

export const DarknessScene: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill name="Darkness" style={{backgroundColor: "#0b0d12"}}>
      <Interactive.Div
        name="Room Atmosphere"
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at 50% 53%, rgba(78,91,109,.22), transparent 60%), linear-gradient(180deg, #0b0d12 0%, #141a24 58%, #1b1c20 76%, #0b0d12 100%)",
          opacity: interpolate(frame, [0, 8], [0.30, 0.45], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      />
      <WindowLight layout={layout} />
      <Interactive.Div
        name="Floor Light"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "8%" : "24%",
          width: layout === "portrait" ? "84%" : "52%",
          top: layout === "portrait" ? "70%" : "73%",
          height: "15%",
          background: "radial-gradient(ellipse at center, rgba(188,190,192,.43), rgba(115,123,136,.16) 48%, transparent 74%)",
          opacity: interpolate(frame, [0, 8, 141, 155], [0.18, 0.52, 0.52, 0.76], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      />
    </AbsoluteFill>
  );
};



