import {Interactive, interpolate, useCurrentFrame} from "remotion";
import {NoxLayer} from "../components/NoxLayer";
import {ShadowLayer} from "../components/ShadowLayer";
import {Layout} from "../types";

export const WalkScene: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <>
      <Interactive.Div
        name="Walk Shadow"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "28%" : "39%",
          top: layout === "portrait" ? "71%" : "76%",
          width: layout === "portrait" ? "52%" : "23%",
          height: "8%",
          opacity: interpolate(frame, [0, 15, 43, 53], [0, 0.60, 0.60, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          translate: interpolate(frame, [18, 36], ["-55px 0px", "55px 0px"], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: 1,
        }}
      ><ShadowLayer direction="west" /></Interactive.Div>
      <Interactive.Div
        name="NOX Walk"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "3%" : "37%",
          top: layout === "portrait" ? "48%" : "44%",
          width: layout === "portrait" ? "92%" : "27%",
          aspectRatio: "1 / 1",
          opacity: interpolate(frame, [0, 15, 34, 43], [0, 1, 1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          translate: interpolate(frame, [16, 21, 26, 30, 33], ["-55px 0px", "-27px -2px", "3px 0px", "30px -2px", "55px 0px"], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: 1,
        }}
      ><NoxLayer pose="walk" /></Interactive.Div>
    </>
  );
};




