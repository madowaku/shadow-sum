import unittest
from copy import deepcopy
from analyze_stages import constraints, explain, propagate
from validate_stages import shadow_for, validate_stage

class StageAnalysisTests(unittest.TestCase):
    def fixture(self):
        return dict(id=1,posts=1,clues=shadow_for([12]),solution=['C3'])

    def test_unique_and_trace(self):
        s=self.fixture(); validate_stage(s)
        self.assertEqual(explain(s)['filled'],['C3'])
        self.assertEqual(explain(s)['undecided'],0)

    def test_ambiguous_not_declared_unique(self):
        s=self.fixture();s['clues']=[[-1]*5 for _ in range(5)]
        with self.assertRaises(AssertionError):validate_stage(s)
        self.assertEqual(explain(s)['undecided'],25)

    def test_duplicate_solution(self):
        s=self.fixture();s.update(posts=2,solution=['C3','C3'])
        with self.assertRaises(AssertionError):validate_stage(s)

    def test_bad_authored_solution(self):
        s=self.fixture();s['solution']=['A1']
        with self.assertRaises(AssertionError):validate_stage(s)

    def test_malformed_clue(self):
        s=self.fixture();s['clues'][0][0]=True
        with self.assertRaises(AssertionError):validate_stage(s)

    def test_empty_is_different_from_unknown(self):
        _,empty,_,conflict=propagate([(3,0,'clear')])
        self.assertEqual(empty,3);self.assertIsNone(conflict)
        filled,empty,_,conflict=propagate([])
        self.assertEqual(filled|empty,0);self.assertIsNone(conflict)

    def test_subset_and_inconsistent_difference(self):
        filled,empty,_,conflict=propagate([(3,1,'pair'),(7,1,'triple')],subsets=True)
        self.assertEqual(empty,4);self.assertEqual(filled,0);self.assertIsNone(conflict)
        self.assertIsNotNone(propagate([(3,1,'pair'),(3,2,'same')],subsets=True)[3])

if __name__=='__main__':unittest.main()
