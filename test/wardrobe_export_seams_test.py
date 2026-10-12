"""Export repairs must close only tiny missing faces without reshaping vertices."""
import sys, unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from wardrobe_export_seams import repair_indices

class ExportSeamsTest(unittest.TestCase):
    points=[(0.,0.,0.),(.0007,0.,0.),(0.,.0007,0.),(0.,0.,.0007)]
    closed=[0,2,1,0,1,3,1,2,3,2,0,3]

    def test_closed_shell_is_unchanged(self):
        indices,report=repair_indices(self.points,self.closed)
        self.assertEqual(indices,self.closed)
        self.assertEqual(report,{'added_triangles':0,'removed_internal_faces':0})

    def test_missing_triangle_is_closed_with_consistent_winding(self):
        indices,report=repair_indices(self.points,self.closed[3:])
        self.assertEqual(report['added_triangles'],1)
        self.assertEqual(indices[:9],self.closed[3:])
        # Auditing the result a second time must make no additional repairs.
        self.assertEqual(repair_indices(self.points,indices)[0],indices)

    def test_large_opening_is_not_silently_capped(self):
        points=[tuple(x*100 for x in p) for p in self.points]
        with self.assertRaises(ValueError):repair_indices(points,self.closed[3:])

    def test_opposite_internal_duplicate_faces_are_removed(self):
        points=self.points+[(.0002,.0002,.0002)]
        indices,report=repair_indices(points,self.closed+[0,1,4,0,4,1])
        self.assertEqual(report['removed_internal_faces'],2)
        self.assertEqual(indices,self.closed)

if __name__=='__main__':unittest.main()
