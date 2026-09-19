#!/usr/bin/env python3
"""Editorial regression gates. These metrics do not claim human solve times."""
import json
from pathlib import Path
from analyze_stages import ALL, code, constraints, explain, metrics, propagate
from validate_stages import coord_to_index, shadow_for

ROOT = Path(__file__).resolve().parents[1]

def validate():
    stages=json.loads((ROOT/'data/stages_v0_1.json').read_text())
    hints=json.loads((ROOT/'data/whispers_v0_1.json').read_text())
    assert len(stages)==18
    assert set(hints)=={str(i) for i in range(1,19) if i!=4}
    seen=set()
    for s in stages:
        n=s['id']; m=metrics(s)
        assert m['undecided']==0, f'{n}: requires deeper reasoning than the taught tools'
        assert set(explain(s)['filled'])==set(s['solution']), f'{n}: trace disagrees with solution'
        if n<=9:
            assert m['direct_fixed']==25
        elif n in (10,11,12,15):
            assert m['direct_fixed']<25 and m['subset_fixed']==25
        else:
            assert m['direct_posts']>=1 and m['direct_fixed']>=9
            assert m['assumptions']==1 and m['longest_contradiction']<=3
        if n<=3: assert m['hidden']==0
        if n==4:
            assert s['posts']==2 and m['hidden']==4
            shadow=shadow_for([coord_to_index(c) for c in s['solution']])
            fog=[i for i in range(25) if s['clues'][i//5][i%5]<0]
            assert shadow[fog[0]//5][fog[0]%5]>0, 'First unknown must actually hide a shadow'
            assert any(shadow[i//5][i%5]==0 for i in fog), 'Fog must not imply a positive value either'
        signature=json.dumps([s['posts'],s['clues']])
        mirror=json.dumps([s['posts'],[row[::-1] for row in s['clues']]])
        assert signature not in seen and mirror not in seen, 'Mirrored duplicate puzzle'
        seen.add(signature)
        if n==4: continue
        assert len(hints[str(n)])==3
        for index,hint in enumerate(hints[str(n)],1):
            assert hint['id']==f'{n:03}-{index}' and hint['access']=='free'
            assert len(hint['text'])<=58
            for event in hint.get('targets',[])+hint.get('sequence',[]):
                cell=coord_to_index(event['cell'])
                assert event['surface'] in ('clue','socket')
                assert event['effect'] in ('pulse','assume_empty','contradiction')
                if event['surface']=='clue':
                    assert s['clues'][cell//5][cell%5]>=0, f'{n}: hint points at an unobserved clue'
                if event['effect']=='assume_empty':
                    filled,empty,_,conflict=propagate(constraints(s),subsets=True)
                    assert conflict is None and not (filled|empty)&(1<<cell), 'Hypothesis already decided'
                    _,_,_,conflict=propagate(constraints(s),filled,empty|(1<<cell),True)
                    assert conflict is not None, 'Authored hypothesis has no bounded contradiction'
        print(f"PASS {n:03} {s['title']}: reasoning and authored hints")
    assert metrics(stages[9])['direct_posts']==2
    assert metrics(stages[10])['direct_posts']==2
    print('Grant18 editorial gates passed; independent human playtesting remains required.')

if __name__=='__main__': validate()
