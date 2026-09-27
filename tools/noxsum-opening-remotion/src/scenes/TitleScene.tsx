import {NoxsumTitle} from "../components/NoxsumTitle";
import {Layout} from "../types";

export const TitleScene: React.FC<{layout: Layout}> = ({layout}) => (
  <NoxsumTitle layout={layout} />
);


