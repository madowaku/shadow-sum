import {Interactive, interpolate, useCurrentFrame} from "remotion";
import {BoardGhost} from "../components/BoardGhost";
import {Layout} from "../types";

export const ShadowSumScene: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <>
      <BoardGhost layout={layout} />
      <Interactive.Div
        name="N / North Shadow"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "41%" : "45%",
          top: layout === "portrait" ? "43%" : "29%",
          width: layout === "portrait" ? "18%" : "10%",
          height: layout === "portrait" ? "20%" : "15%",
          clipPath: "polygon(22% 0, 78% 0, 100% 100%, 0 100%)",
          backgroundColor: "#060b12",
          filter: layout === "portrait" ? "blur(3px)" : "blur(4px)",
          opacity: interpolate(frame, [0, 2], [0.08, 0.25], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      />
      <Interactive.Div
        name="W / West Shadow"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "20%" : "40%",
          top: layout === "portrait" ? "53.5%" : "41%",
          width: layout === "portrait" ? "37%" : "12%",
          height: layout === "portrait" ? "8%" : "9%",
          clipPath: "polygon(0 0, 100% 18%, 100% 82%, 0 100%)",
          backgroundColor: "#060b12",
          filter: layout === "portrait" ? "blur(3px)" : "blur(4px)",
          opacity: interpolate(frame, [2, 5], [0, 0.25], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      />
      <Interactive.Div
        name="E / East Shadow"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "43%" : "48%",
          top: layout === "portrait" ? "53.5%" : "41%",
          width: layout === "portrait" ? "37%" : "12%",
          height: layout === "portrait" ? "8%" : "9%",
          clipPath: "polygon(0 18%, 100% 0, 100% 100%, 0 82%)",
          backgroundColor: "#060b12",
          filter: layout === "portrait" ? "blur(3px)" : "blur(4px)",
          opacity: interpolate(frame, [5, 10], [0, 0.25], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      />
    </>
  );
};