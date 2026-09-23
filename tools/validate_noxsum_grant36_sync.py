"""Guard the NOXSUM product against drift from the final Grant36 v0.5 campaign."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from validate_grant20_v03 import legal_positions
from validate_grant36_v05 import enumerate_stages

ROOT = Path(__file__).resolve().parents[1]
CAMPAIGN = ROOT / "data/grant36_v0_5.json"
SOURCE_SEMANTIC_SHA256 = "77aa04b701dbbeaf34ac57d65817ee35168dfff44dbbdacf8a37dfb328fb8f59"
REPLACEMENTS = {
    "GR24": "SHAPE OF THE SILENCE",
    "GR25": "THE LONG WAY THROUGH",
    "GR28": "PLATE IN THE GAP",
    "GR29": "VEILED SOCKETS",
    "GR32": "THE LAST OPEN AXIS",
    "GR34": "FOUR CAUSES AGREE",
    "GR35": "DENSE BOARD SYNTHESIS",
    "GR36": "THE SHAPED FINALE",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def main() -> None:
    stages = json.loads(CAMPAIGN.read_text(encoding="utf-8"))
    require(isinstance(stages, list) and len(stages) == 36, "product campaign must have exactly 36 stages")
    ids = [stage["id"] for stage in stages]
    require(ids == [f"GR{number:02d}" for number in range(1, 37)], "campaign must be GR01..GR36 in order")
    require(len(set(ids)) == 36 and "BS01" not in ids, "bonus/review stage entered product campaign")

    semantic_json = json.dumps(stages, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    digest = hashlib.sha256(semantic_json.encode("utf-8")).hexdigest()
    require(digest == SOURCE_SEMANTIC_SHA256, "campaign differs from final v0.5 source semantics")

    home = (ROOT / "src/home_screen.gd").read_text(encoding="utf-8")
    router = (ROOT / "src/campaign_main.gd").read_text(encoding="utf-8")
    runtime = (ROOT / "src/experiment_main.gd").read_text(encoding="utf-8")
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    require('const STAGE_DATA := "res://data/grant36_v0_5.json"' in home, "HOME points at old stage data")
    require('const PROGRESS_PATH := "user://shadow_sum_grant36_v0_5.json"' in home, "HOME points at old progress")
    require('parsed.get("campaign", "") == "grant36-v05"' in home, "HOME campaign progress check drifted")
    require('var selected: String = "grant36-v05"' in router, "normal router default is not Grant36 v0.5")
    require('"grant36-v05"' in router and 'campaign.grant36_v05 = true' in router, "Grant36 route missing")
    require('campaign.set("requested_stage_index", requested_stage_index)' in router, "stage-select forwarding missing")
    require('data_path = "res://data/grant36_v0_5.json"' in runtime, "gameplay points at old stage data")
    require('progress_path = "user://shadow_sum_grant36_v0_5.json"' in runtime, "gameplay points at old progress")
    require('campaign_id = "grant36-v05"' in runtime, "gameplay campaign identity drifted")
    require('run/main_scene="res://scenes/home.tscn"' in project, "fresh launch no longer opens HOME")
    require('config/name="NOXSUM"' in project, "product identity changed")

    by_id = {stage["id"]: stage for stage in stages}
    for stage_id, title in REPLACEMENTS.items():
        stage = by_id[stage_id]
        require(stage["title"] == title and "boardShape" in stage, f"{stage_id}: final replacement missing")
        require(not stage.get("free_light_selection") and not stage.get("movable_shutter"),
                f"{stage_id}: old light/shutter variant present")
    sentinel = by_id["GR28"]
    require(sentinel["normal_posts"] == 2 and sentinel["plate_posts"] == 1 and sentinel["tall_posts"] == 0,
            "GR28 typed inventory drifted")
    require(sentinel["boardShape"]["mask"] == ["10101", "11111", "00100", "11111", "10101"],
            "GR28 mask drifted")
    require(sentinel["observations"][0]["active_lights"] == ["TOP", "LEFT", "RIGHT", "BOTTOM"],
            "GR28 must use four fixed lights")

    for stage in stages:
        positions = legal_positions(stage)
        require(positions and len(positions) <= 25, f"{stage['id']}: invalid board mask")
    counts, _ = enumerate_stages(stages)
    require(all(counts[stage_id] == 1 for stage_id in ids), "campaign is not independently exact-unique")
    print(f"NOXSUM final sync: 36/36 exact-unique; source semantic SHA256 {digest}")


if __name__ == "__main__":
    main()
