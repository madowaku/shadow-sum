export const ShadowLayer: React.FC<{direction: "west" | "east" | "north" | "window"}> = ({direction}) => {
  const rotation = direction === "west" ? -18 : direction === "east" ? 19 : direction === "north" ? 0 : -8;
  return (
    <div style={{width: "100%", height: "100%", position: "relative", rotate: rotation + "deg", filter: "blur(4px)"}}>
      <div style={{position: "absolute", left: "19%", right: "19%", top: "9%", bottom: "8%", borderRadius: "48% 52% 45% 49%", background: "rgba(2, 6, 13, .88)"}} />
      <div style={{position: "absolute", left: "4%", width: "92%", height: "39%", bottom: 0, borderRadius: "50%", background: "rgba(2, 6, 13, .72)"}} />
    </div>
  );
};


