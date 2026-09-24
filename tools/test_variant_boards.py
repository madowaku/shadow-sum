import json
import unittest
from copy import deepcopy
from board_shape import enabled_cells
from analyze_stages import explain
from validate_stages import coord_to_index, shadow_for, validate_stage
from validate_variant_boards import DATA

class VariantBoardTests(unittest.TestCase):
    def setUp(self):
        self.stages = json.loads(DATA.read_text(encoding='utf-8'))

    def test_default_is_full_board(self):
        self.assertEqual(enabled_cells({'posts': 3}), tuple(range(25)))

    def test_all_shapes_and_unique_expected_solutions(self):
        expected = [['C1','B3','C5'], ['E2','A3','C3','D4'], ['A2','C2','D3','C4'], ['A2','C4','D4','A5'], ['A1','C1','E1','B5'], ['D2','C4','E4','B5']]
        for stage, count, solution in zip(self.stages, [9,15,13,16,16,19], expected):
            with self.subTest(stage=stage['title']):
                self.assertEqual(len(enabled_cells(stage)),count)
                answers = validate_stage(stage)
                self.assertEqual(len(answers),1)
                self.assertEqual(set(answers[0]), {coord_to_index(c) for c in solution})
                self.assertEqual(set(explain(stage)['filled']),set(solution))
                self.assertEqual(explain(stage)['undecided'],0)

    def test_hollow_shadows_still_reach_disabled_cells(self):
        stage = self.stages[4]
        shadow = shadow_for([coord_to_index(c) for c in stage['solution']])
        self.assertNotIn(coord_to_index('C2'),enabled_cells(stage))
        self.assertEqual(shadow[1][2],1)

    def test_malformed_shapes_rejected(self):
        cases = [None, [], {}, {'type':'wall'}]
        base = self.stages[0]['boardShape']
        for field, value in [('width',4),('width','5'),('width',True),('height',6),('mask',None),('mask',['11111']*4),('mask',['1111']*5),('mask',['11x11']*5),('mask',[11111]*5),('mask',['00000']*5)]:
            shape = deepcopy(base);shape[field]=value;cases.append(shape)
        for shape in cases:
            with self.subTest(shape=shape):
                stage=deepcopy(self.stages[0]);stage['boardShape']=shape
                with self.assertRaises(AssertionError):enabled_cells(stage)
        stage=deepcopy(self.stages[0]);stage['posts']=10
        with self.assertRaises(AssertionError):enabled_cells(stage)

    def test_disabled_authored_solution_rejected(self):
        stage=deepcopy(self.stages[0]);stage['solution'][0]='A1'
        with self.assertRaisesRegex(AssertionError,'disabled'):validate_stage(stage)

    def test_mask_is_essential_to_uniqueness(self):
        stage=deepcopy(self.stages[0]);del stage['boardShape']
        with self.assertRaisesRegex(AssertionError,'found 2'):validate_stage(stage)

    def test_shape_name_has_no_logic(self):
        stage=deepcopy(self.stages[0]);stage['title']='An arbitrary experimental plate'
        self.assertEqual(validate_stage(stage),validate_stage(self.stages[0]))

if __name__ == '__main__':
    unittest.main()
