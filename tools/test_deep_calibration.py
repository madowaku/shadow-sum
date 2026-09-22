"""Optical equivalence, enumeration, deduplication and FOG regression tests."""
import copy
from itertools import combinations
import random
import unittest

from deep_calibration_model import LIGHTS, KINDS, Profile, StateIndex, code, rays, world_key
from generate_deep_calibration import close_target
from validate_grant20_v03 import shadow as reference_shadow
from validate_grant36_draft import normalized_world, pack, validate_stage


class DeepCalibrationTests(unittest.TestCase):
    def test_every_atomic_ray_against_existing_reference(self):
        for count in range(1, 5):
            for lamps in combinations(LIGHTS, count):
                for shutter in (None, 0, 1, 2, 3, 4):
                    for kind in KINDS:
                        for pos in range(25):
                            actual, _ = rays([(pos, kind)], lamps, shutter)
                            self.assertEqual(tuple(actual), reference_shadow([(pos, kind)], lamps, shutter))

    def test_packed_four_object_addition_has_no_carries(self):
        rng = random.Random(20260922)
        for _ in range(500):
            objects = [(p, rng.choice(KINDS)) for p in rng.sample(range(25), 4)]
            lights = rng.sample(LIGHTS, rng.randrange(1, 5))
            shutter = rng.choice((None, 0, 1, 2, 3, 4))
            packed = sum(pack(reference_shadow([obj], lights, shutter)) for obj in objects)
            self.assertEqual(packed, pack(reference_shadow(objects, lights, shutter)))

    def test_reverse_index_covers_unlabelled_legal_worlds(self):
        profile = Profile('test', 'two', 2, 0, 0, 2, True)
        index = StateIndex(profile)
        self.assertEqual(len(index.shadows), 300 * 6 * 5)
        seen, reference = set(), {}
        for world_id in range(profile.states):
            world = index.world(world_id)
            positions = tuple(o['cell'] for o in world['objects'])
            key = (positions, tuple(world['lights']), world['shutter'])
            self.assertNotIn(key, seen)
            seen.add(key)
            objects = [(ord(name[0])-65 + (int(name[1])-1)*5, 'normal') for name in positions]
            wanted = reference_shadow(objects, world['lights'], world['shutter'])
            self.assertEqual(tuple(index.shadows[world_id]), wanted)
            reference.setdefault(wanted, []).append(world_id)
        self.assertEqual(set(map(int, index.unique_ids)), {ids[0] for ids in reference.values() if len(ids) == 1})

    def test_translation_and_mirror_include_lamps_and_shutter(self):
        a = {'objects': [{'cell': 'B2', 'type': 'normal'}, {'cell': 'D3', 'type': 'plate_v'}],
             'lights': ['TOP', 'LEFT'], 'shutter': 1}
        b = {'objects': [{'cell': 'D2', 'type': 'normal'}, {'cell': 'B3', 'type': 'plate_v'}],
             'lights': ['TOP', 'RIGHT'], 'shutter': 3}
        moved = {'objects': [{'cell': 'A3', 'type': 'normal'}, {'cell': 'C4', 'type': 'plate_v'}],
                 'lights': ['TOP', 'LEFT'], 'shutter': 0}
        for canonical in (world_key, normalized_world):
            self.assertEqual(canonical(a), canonical(b))
            self.assertEqual(canonical(a), canonical(moved))
            wrong_lamp = copy.deepcopy(b)
            wrong_lamp['lights'] = ['TOP', 'LEFT']
            self.assertNotEqual(canonical(a), canonical(wrong_lamp))
            wrong_shutter = copy.deepcopy(b)
            wrong_shutter['shutter'] = 2
            self.assertNotEqual(canonical(a), canonical(wrong_shutter))

    def test_near_target_dedup_crosses_full_fog_buckets(self):
        profile = Profile('full', 'two', 1, 1, 0, 2).record()
        a = {'profile': profile, 'complete_shadow': [0] * 25, 'visible_mask': [True] * 25}
        b = copy.deepcopy(a)
        b['profile']['name'] = 'fog'
        b['profile']['bucket'] = 'fog'
        b['visible_mask'][0] = False
        b['complete_shadow'][3] = 1
        self.assertTrue(close_target(a, [b]))

    def fixture(self):
        values = list(reference_shadow([(12, 'normal')], LIGHTS, None))
        fog = ['A1', 'A2', 'C4']  # C4 is really 1, not zero.
        return {'id': 'TEST', 'posts': 1, 'normal_posts': 1, 'tall_posts': 0, 'plate_posts': 0,
                'review_only': True, 'solution': ['C3'], 'solution_post_types': {'C3': 'normal'},
                'installed_lights': list(LIGHTS), 'solution_complete_shadow': values,
                'observations': [{'id': 'A', 'active_lights': list(LIGHTS),
                                  'target': {code(c): v for c, v in enumerate(values) if code(c) not in fog}}],
                'expected_states': 25, 'fog_cells': fog}

    def test_fog_is_unknown_and_not_zero(self):
        stage = self.fixture()
        self.assertEqual(validate_stage(stage)['solution_count'], 1)
        stage.pop('fog_cells')
        stage['observations'][0]['target'].update({'A1': 0, 'A2': 0, 'C4': 0})
        with self.assertRaisesRegex(ValueError, 'violates visible'):
            validate_stage(stage)

    def test_validator_rejects_count_and_metadata_corruption(self):
        stage = self.fixture()
        stage['expected_states'] = 24
        with self.assertRaisesRegex(ValueError, 'enumerated 25'):
            validate_stage(stage)
        stage = self.fixture()
        stage['solution'] = ['D3']
        stage['solution_post_types'] = {'D3': 'normal'}
        with self.assertRaisesRegex(ValueError, 'shadow metadata mismatch'):
            validate_stage(stage)

    def test_validator_rejects_ambiguous_visible_target(self):
        stage = self.fixture()
        stage.pop('fog_cells')
        stage['solution'] = ['C5']
        stage['solution_post_types'] = {'C5': 'normal'}
        stage['solution_complete_shadow'] = [0] * 25
        stage['observations'] = [{'id': 'A', 'active_lights': ['TOP'], 'target': {code(c): 0 for c in range(25)}}]
        with self.assertRaisesRegex(ValueError, 'got 5'):
            validate_stage(stage)


if __name__ == '__main__':
    unittest.main()
