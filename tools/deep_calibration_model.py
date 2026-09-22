"""Generator-only state index. The independent validator does not import this file."""
from __future__ import annotations

from dataclasses import asdict, dataclass
from itertools import combinations, product
from math import comb

import numpy as np


LIGHTS = ("TOP", "LEFT", "RIGHT", "BOTTOM")
VECTORS = ((0, 1), (1, 0), (-1, 0), (0, -1))
KINDS = ("normal", "tall", "plate_v", "plate_h")
ALL_CELLS = (1 << 25) - 1


def code(index):
    return chr(65 + int(index) % 5) + str(int(index) // 5 + 1)


def cell(name):
    return (int(name[1:]) - 1) * 5 + ord(name[0]) - 65


@dataclass(frozen=True)
class Profile:
    name: str
    bucket: str
    normal: int
    tall: int
    plate: int
    light_count: int = 0  # 0 means the supplied fixed lights.
    shutter: bool = False
    fixed_lights: tuple = LIGHTS

    @property
    def families(self):
        return (["HEIGHT"] if self.tall else []) + (["PLATE"] if self.plate else []) + (
            ["LIGHT"] if self.light_count else []) + (["SHUTTER"] if self.shutter else [])

    @property
    def configurations(self):
        lamps = list(combinations(LIGHTS, self.light_count)) if self.light_count else [self.fixed_lights]
        return [(lights, shutter) for lights in lamps for shutter in (range(5) if self.shutter else [None])]

    @property
    def states(self):
        return (comb(25, self.normal) * comb(25 - self.normal, self.tall)
                * comb(25 - self.normal - self.tall, self.plate) * 2 ** self.plate
                * len(self.configurations))

    def record(self):
        result = asdict(self)
        result["fixed_lights"] = list(self.fixed_lights)
        result["families"] = self.families
        result["expected_states"] = self.states
        return result


def profiles():
    return [
        Profile("two_height_light", "two", 2, 1, 0, 2),
        Profile("two_plate_light", "two", 2, 0, 1, 3),
        Profile("two_shutter_light", "two", 3, 0, 0, 3, True),
        Profile("two_height_plate", "two", 1, 1, 1, fixed_lights=LIGHTS[:3]),
        Profile("two_height_shutter", "two", 2, 1, 0, shutter=True),
        Profile("two_plate_shutter", "two", 2, 0, 1, shutter=True),
        Profile("three_height_light_shutter", "three", 2, 1, 0, 3, True),
        Profile("three_height_plate_light", "three", 1, 1, 1, 3),
        Profile("three_height_plate_shutter", "three", 1, 1, 1, shutter=True),
        Profile("three_plate_light_shutter", "three", 2, 0, 1, 3, True),
        Profile("fog_height_light", "fog", 2, 1, 0, 2),
        Profile("fog_plate_shutter", "fog", 2, 0, 1, shutter=True),
        Profile("fog_height_plate_light", "fog", 1, 1, 1, 3),
        Profile("fog_height_light_shutter", "fog", 2, 1, 0, 3, True),
        Profile("dense_height_plate_light", "dense", 2, 1, 1, 3),
        Profile("dense_height_plate_shutter", "dense", 2, 1, 1, shutter=True),
        Profile("finale", "finale", 2, 1, 1, 3, True),
    ]


def rays(objects, lights, shutter):
    """Return shadow plus physical evidence, with the runtime's ray conventions."""
    shadow = [0] * 25
    far, absence, offboard, attempts = set(), set(), 0, 0
    footprints = []
    blocked = 0
    for pos, kind in objects:
        footprint = set()
        x, y = pos % 5, pos // 5
        for light in lights:
            dx, dy = VECTORS[LIGHTS.index(light)]
            if light == "TOP" and x == shutter:
                if kind != "plate_v":
                    blocked += 1
                continue
            if (kind == "plate_v" and light in ("TOP", "BOTTOM")) or (
                kind == "plate_h" and light in ("LEFT", "RIGHT")
            ):
                tx, ty = x + dx, y + dy
                if 0 <= tx < 5 and 0 <= ty < 5:
                    absence.add(ty * 5 + tx)
                continue
            for distance in range(1, 3 if kind == "tall" else 2):
                attempts += 1
                tx, ty = x + dx * distance, y + dy * distance
                if 0 <= tx < 5 and 0 <= ty < 5:
                    target = ty * 5 + tx
                    shadow[target] += 1
                    footprint.add(target)
                    if distance == 2:
                        far.add(target)
                else:
                    offboard += 1
        footprints.append(footprint)
    edges = sum(bool(a & b) for a, b in combinations(footprints, 2))
    return shadow, dict(far=far, absence=absence, offboard=offboard, attempts=attempts,
                        interaction_edges=edges, footprints=footprints, blocked=blocked)


def world_key(world):
    """Conservative near-duplicate key: translations AND left/right reflections.

    Ignores fog/profile, preserves material/orientation, lamps and relative shutter.
    Translation equivalence is deliberately stricter than optical equivalence at edges.
    """
    keys = []
    for mirror in (False, True):
        objects = [(4 - cell(o["cell"]) % 5 if mirror else cell(o["cell"]) % 5,
                    cell(o["cell"]) // 5, o["type"]) for o in world["objects"]]
        min_x = min(x for x, _, _ in objects)
        min_y = min(y for _, y, _ in objects)
        lamps = sorted(({"LEFT": "RIGHT", "RIGHT": "LEFT"}.get(v, v) if mirror else v)
                       for v in world["lights"])
        shutter = world["shutter"]
        if shutter is not None:
            shutter = (4 - shutter if mirror else shutter) - min_x
        keys.append((tuple(sorted((x - min_x, y - min_y, k) for x, y, k in objects)),
                     tuple(lamps), -99 if shutter is None else shutter))
    return min(keys)


class StateIndex:
    """One enumeration per profile; a signature reverse index and compact world IDs."""

    def __init__(self, profile):
        self.profile = profile
        rows = []
        for normals in combinations(range(25), profile.normal):
            remaining = [p for p in range(25) if p not in normals]
            for talls in combinations(remaining, profile.tall):
                rest = [p for p in remaining if p not in talls]
                for plates in combinations(rest, profile.plate):
                    for orientations in product((2, 3), repeat=profile.plate):
                        rows.append((*normals, *(25 + p for p in talls),
                                     *(25 * k + p for p, k in zip(plates, orientations))))
        self.placements = np.asarray(rows, dtype=np.uint8)
        self.placement_count = len(rows)
        del rows
        self.configs = profile.configurations
        self.shadows = np.empty((profile.states, 25), dtype=np.uint8)
        for config, (lights, shutter) in enumerate(self.configs):
            atoms = np.asarray([rays([(p, kind)], lights, shutter)[0]
                                for kind in KINDS for p in range(25)], dtype=np.uint8)
            target = self.shadows[config * self.placement_count:(config + 1) * self.placement_count]
            target[:] = 0
            for slot in range(self.placements.shape[1]):
                target += atoms[self.placements[:, slot]]
        signatures = self.shadows.view(np.dtype((np.void, 25))).ravel()
        _, first, counts = np.unique(signatures, return_index=True, return_counts=True)
        self.unique_ids = first[counts == 1]
        self.signature_count = len(counts)
        self.full_unique_count = len(self.unique_ids)

    def world(self, world_id):
        config, placement = divmod(int(world_id), self.placement_count)
        lights, shutter = self.configs[config]
        return {"objects": [{"cell": code(int(value) % 25), "type": KINDS[int(value) // 25]}
                            for value in self.placements[placement]],
                "lights": list(lights), "shutter": shutter}

    def difference_masks(self, shadow):
        masks = np.zeros(len(self.shadows), dtype=np.uint32)
        for c in range(25):
            masks |= (self.shadows[:, c] != shadow[c]).astype(np.uint32) << c
        return masks

    def settings(self, ids):
        return ids // self.placement_count

    def family_values(self, ids, family):
        ids = np.asarray(ids, dtype=np.int64)
        if family in ("LIGHT", "SHUTTER"):
            configs = np.unique(self.settings(ids))
            return {tuple(self.configs[c][0]) if family == "LIGHT" else self.configs[c][1]
                    for c in configs}
        # Assigned typed positions; normal copies are indistinguishable.
        placements = self.placements[np.unique(ids % self.placement_count)]
        if family == "ORIENTATION":
            return {tuple(row // 25) for row in placements[:, -self.profile.plate:]}
        start = self.profile.normal
        return {tuple(row) for row in placements[:, start:start + self.profile.tall]}


def mask_for(cells):
    return sum(1 << int(c) for c in set(cells))


def greedy_witness(masks, visible):
    """Greedy smallest surviving partition; stable row-major ties. Not a minimum."""
    survivors = np.arange(len(masks), dtype=np.int64)
    trace = []
    remaining = list(visible)
    while len(survivors) > 1:
        local = masks[survivors]
        counts = [(int(np.count_nonzero((local & (1 << c)) == 0)), c) for c in remaining]
        count, chosen = min(counts)
        if count == len(survivors):
            raise ValueError("Evidence is not unique")
        survivors = survivors[(local & (1 << chosen)) == 0]
        trace.append((chosen, len(survivors), survivors))
        remaining.remove(chosen)
    return trace
