import {Interactive, interpolate, useCurrentFrame} from "remotion";
import {Layout} from "../types";

export const BoardGhost: React.FC<{layout: Layout}> = ({layout}) => {
  const frame = useCurrentFrame();
  return (
    <Interactive.Div
      name="Board Ghost"
      style={{
        position: "absolute",
        left: layout === "portrait" ? "17%" : "40%",
        top: layout === "portrait" ? "42%" : "28%",
        width: layout === "portrait" ? "66%" : "20%",
        aspectRatio: "1 / 1",
        display: "grid",
        gridTemplateColumns: "repeat(5, 1fr)",
        gridTemplateRows: "repeat(5, 1fr)",
        border: "1px solid rgba(235,231,216,.9)",
        opacity: interpolate(frame, [0, 3, 10, 29], [0.12, 0.22, 0.22, 0.22], {extrapolateLeft: "clamp", extrapolateRight: "clamp"}),
      }}
    >
      {Array.from({length: 25}, (_, index) => (
        <div
          key={index}
          style={{
            borderRight: index % 5 < 4 ? "1px solid rgba(235,231,216,.9)" : undefined,
            borderBottom: index < 20 ? "1px solid rgba(235,231,216,.9)" : undefined,
          }}
        />
      ))}
    </Interactive.Div>
  );
};