import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # If it's Math.Core, we handle it specially
    if filepath.endswith('Math/Core.idr'):
        # 0 SparseMaxel : Type -> public export \n record SparseMaxel where \n   constructor MkSparseMaxel \n   maxelMap : Multiset (Geometry, Amplitude)
        content = re.sub(
            r'0 SparseMaxel : Type\nSparseMaxel = Multiset \(Geometry, Amplitude\)',
            r'public export\nrecord SparseMaxel where\n  constructor MkSparseMaxel\n  maxelMap : Multiset (Geometry, Amplitude)',
            content
        )
        # Fix emptySparseMaxel
        content = re.sub(
            r'emptySparseMaxel = ZeroM',
            r'emptySparseMaxel = MkSparseMaxel ZeroM',
            content
        )
        # Fix singletonSparseMaxel
        content = re.sub(
            r'singletonSparseMaxel geom amp = fromList \[\(\(geom, amp\), 1\)\]',
            r'singletonSparseMaxel geom amp = MkSparseMaxel (fromList [((geom, amp), 1)])',
            content
        )
        # Fix superposeStates
        content = re.sub(
            r'superposeStates = addMultiset',
            r'superposeStates (MkSparseMaxel m1) (MkSparseMaxel m2) = MkSparseMaxel (addMultiset m1 m2)',
            content
        )
        # Fix stateLag
        content = re.sub(
            r'stateLag = multiplicityAll',
            r'stateLag (MkSparseMaxel m) = multiplicityAll m',
            content
        )
        # Fix restrictToPixel
        content = re.sub(
            r'restrictToPixel geom pip =\n  fromList \(filter \(\\(\(g, _\), _\) => g == geom\) \(multisetToList pip\)\)',
            r'restrictToPixel geom (MkSparseMaxel pip) =\n  MkSparseMaxel (fromList (filter (\((g, _), _) => g == geom) (multisetToList pip)))',
            content
        )
        # Fix isSynchronised
        content = re.sub(
            r'isSynchronised sub pip =',
            r'isSynchronised sub (MkSparseMaxel pip) =',
            content
        )

    else:
        # In other files, SparseMaxel is passed as an argument.
        # We need to see if they destruct it or just pass it around.
        # It's better to just manually inspect or do basic replacements.
        pass

    with open(filepath, 'w') as f:
        f.write(content)

process_file('/var/home/justin/Projects/Linear-Physi../idris2-Universe/src/Math/Core.idr')
