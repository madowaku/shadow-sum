import {Interactive, interpolate, useCurrentFrame} from "remotion";
import {NoxLayer} from "../components/NoxLayer";
import {ShadowLayer} from "../components/ShadowLayer";
import {Layout} from "../types";

export const SitScene: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <>
      <Interactive.Div
        name="Sit Shadow"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "27%" : "39%",
          top: layout === "portrait" ? "68%" : "72%",
          width: layout === "portrait" ? "49%" : "22%",
          height: "12%",
          opacity: interpolate(frame, [0, 15, 43, 59], [0, 0.65, 0.65, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: 1,
        }}
      ><ShadowLayer direction="west" /></Interactive.Div>
      <Interactive.Div
        name="NOX Sit"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "8%" : "36%",
          top: layout === "portrait" ? "43%" : "40%",
          width: layout === "portrait" ? "83%" : "28%",
          aspectRatio: "1 / 1",
          opacity: interpolate(frame, [0, 15, 26, 35], [0, 1, 1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: interpolate(frame, [0, 15, 20, 25], [0.985, 1, 1.003, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      ><NoxLayer pose="sit" /></Interactive.Div>
    </>
  );
};




