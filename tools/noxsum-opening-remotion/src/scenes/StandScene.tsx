import {Interactive, interpolate, useCurrentFrame} from "remotion";
import {NoxLayer} from "../components/NoxLayer";
import {ShadowLayer} from "../components/ShadowLayer";
import {Layout} from "../types";

export const StandScene: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <>
      <Interactive.Div
        name="Stand Shadow"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "45%" : "48%",
          top: layout === "portrait" ? "69%" : "73%",
          width: layout === "portrait" ? "41%" : "20%",
          height: "11%",
          opacity: interpolate(frame, [0, 15, 43, 59], [0, 0.65, 0.65, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: 1,
        }}
      ><ShadowLayer direction="east" /></Interactive.Div>
      <Interactive.Div
        name="NOX Stand"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "29%" : "45%",
          top: layout === "portrait" ? "43%" : "40%",
          width: layout === "portrait" ? "72%" : "27%",
          aspectRatio: "1 / 1",
          opacity: interpolate(frame, [0, 15, 26, 35], [0, 1, 1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: 1,
        }}
      ><NoxLayer pose="stand" /></Interactive.Div>
    </>
  );
};





