import {Img, staticFile} from "remotion";

export const NoxLayer: React.FC<{pose: "sit" | "stand" | "walk" | "window"}> = ({pose}) => (
  <Img
    src={staticFile("nox/nox_" + pose + ".webp")}
    style={{width: "100%", height: "100%", objectFit: "contain"}}
  />
);


