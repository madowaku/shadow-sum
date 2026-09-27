import {Interactive, interpolate, useCurrentFrame} from "remotion";
import {NoxLayer} from "../components/NoxLayer";
import {ShadowLayer} from "../components/ShadowLayer";
import {Layout} from "../types";

export const WindowScene: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <>
      <Interactive.Div
        name="Window Room Detail"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "9%" : "29%",
          top: layout === "portrait" ? "16%" : "10%",
          width: layout === "portrait" ? "82%" : "42%",
          height: layout === "portrait" ? "58%" : "68%",
          borderBottom: "8px solid rgba(151,132,112,.25)",
          boxShadow: "0 5px 10px rgba(3,5,9,.45)",
          opacity: interpolate(frame, [0, 10, 48, 59], [0, 0.72, 0.72, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
        }}
      />
      <Interactive.Div
        name="Window Shadow"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "40%" : "48%",
          top: layout === "portrait" ? "68%" : "72%",
          width: layout === "portrait" ? "47%" : "21%",
          height: "12%",
          opacity: interpolate(frame, [0, 10, 38, 49, 59], [0, 0.66, 0.66, 0.08, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: 1,
        }}
      >
        {frame >= 38 && frame < 59 ? (
          <div style={{position: "absolute", inset: 0, filter: "blur(4px)"}}>
            <div
              style={{
                position: "absolute",
                left: "4%",
                top: "22%",
                width: "92%",
                height: "56%",
                background: "linear-gradient(105deg, transparent 0%, rgba(2,6,13,.78) 18%, rgba(2,6,13,.9) 70%, transparent 100%)",
                clipPath: "polygon(0 28%, 100% 0, 86% 100%, 13% 78%)",
              }}
            />
            <div
              style={{
                position: "absolute",
                left: "27%",
                top: "8%",
                width: "7%",
                height: "82%",
                transform: "rotate(-12deg)",
                backgroundColor: "rgba(2,6,13,.72)",
              }}
            />
            <div
              style={{
                position: "absolute",
                left: "66%",
                top: "12%",
                width: "6%",
                height: "76%",
                transform: "rotate(-12deg)",
                backgroundColor: "rgba(2,6,13,.72)",
              }}
            />
          </div>
        ) : (
          <ShadowLayer direction="window" />
        )}
      </Interactive.Div>
      <Interactive.Div
        name="NOX Window"
        style={{
          position: "absolute",
          left: layout === "portrait" ? "28%" : "44%",
          top: layout === "portrait" ? "42%" : "36%",
          width: layout === "portrait" ? "71%" : "24%",
          aspectRatio: "1 / 1",
          opacity: interpolate(frame, [0, 10, 25, 38], [0, 1, 1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
          scale: 1,
        }}
      ><NoxLayer pose="window" /></Interactive.Div>
    </>
  );
};