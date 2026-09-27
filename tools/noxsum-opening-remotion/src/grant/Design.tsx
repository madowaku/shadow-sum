import {AbsoluteFill, Img, Interactive, interpolate, staticFile, useCurrentFrame} from "remotion";
import type {PropsWithChildren} from "react";

export const Room: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: "#07121b"}}>
    <Img src={staticFile("room/window_city.webp")} style={{position: "absolute", width: 1920, height: 1080, objectFit: "cover", opacity: 0.15}} />
    <AbsoluteFill style={{background: "linear-gradient(90deg, #07121bf2 0%, #07121bd9 48%, #07121b55 100%)"}} />
    <Interactive.Div name="Archive rule" style={{position: "absolute", left: 96, top: 82, width: 96, height: 2, backgroundColor: "#bda36d"}} />
  </AbsoluteFill>
);

export const Stage: React.FC<PropsWithChildren> = ({children}) => {
  const frame = useCurrentFrame();
  return <AbsoluteFill style={{opacity: interpolate(frame, [0, 12], [0, 1], {extrapolateRight: "clamp"})}}>{children}</AbsoluteFill>;
};

/** A crop of the real portrait game. Video child retains its authored timing. */
export const GameplayFrame: React.FC<PropsWithChildren> = ({children}) => (
  <Interactive.Div name="Actual gameplay" style={{position: "absolute", left: 1068, top: 68, width: 756, height: 928, overflow: "hidden", border: "1px solid #8b805a66", borderRadius: 4, boxShadow: "0 24px 90px #0008", backgroundColor: "#09131c"}}>
    {children}
  </Interactive.Div>
);

export const Label: React.FC<PropsWithChildren> = ({children}) => <Interactive.Div name="Scene label" style={{position: "absolute", left: 96, top: 116, fontSize: 22, fontWeight: 600, letterSpacing: 5, color: "#cab384"}}>{children}</Interactive.Div>;

export const Heading: React.FC<PropsWithChildren> = ({children}) => <Interactive.Div name="English headline" style={{position: "absolute", left: 90, top: 199, width: 900, fontFamily: "Grant Display", fontSize: 112, fontWeight: 500, lineHeight: 0.98, letterSpacing: -2, color: "#f0eadf"}}>{children}</Interactive.Div>;

export const Copy: React.FC<PropsWithChildren> = ({children}) => <Interactive.Div name="English explanation" style={{position: "absolute", left: 96, top: 482, width: 835, fontSize: 33, lineHeight: 1.55, fontWeight: 450, color: "#b8c9cc"}}>{children}</Interactive.Div>;

export const Footnote: React.FC<PropsWithChildren> = ({children}) => <Interactive.Div name="Footnote" style={{position: "absolute", left: 96, top: 968, fontSize: 19, letterSpacing: 2, color: "#8e9ea4"}}>{children}</Interactive.Div>;
