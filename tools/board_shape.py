"""Placement-domain validation shared by offline solvers; never shadow math."""
def enabled_cells(stage):
    if 'boardShape' not in stage:
        return tuple(range(25))
    shape = stage['boardShape']
    assert isinstance(shape, dict), 'boardShape must be an object'
    assert shape.get('type') == 'mask', 'boardShape.type must be mask'
    for key in ('width', 'height'):
        assert type(shape.get(key)) in (int, float) and shape[key] == 5, f'boardShape.{key} must be 5'
    rows = shape.get('mask')
    assert isinstance(rows, list) and len(rows) == 5, 'mask must contain five rows'
    assert all(isinstance(row, str) and len(row) == 5 for row in rows), 'mask rows must be five-character strings'
    assert all(c in '01' for row in rows for c in row), 'mask accepts only 0 and 1'
    cells = tuple(i for i in range(25) if rows[i // 5][i % 5] == '1')
    assert cells, 'mask must enable at least one socket'
    assert stage['posts'] <= len(cells), 'Post count exceeds enabled socket count'
    return cells
