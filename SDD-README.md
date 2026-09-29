# SimCamCard SDD Week 1 Package

This package is designed to be merged into:

`~/codework/SimCamCard/`

## Installation

From Terminal:

```bash
cd ~/codework/SimCamCard
unzip -o /path/to/SimCamCard-SDD-Week1.zip
```

Or unzip it in Finder and copy the package contents into the project root.

Expected result:

```text
SimCamCard/
├── assignment/              # keep your existing instructor files
├── spec.md
├── spec/
├── evidence/
├── dataset/
├── ai/
├── SimCamCard.xcodeproj
├── SimCamCard/
├── SimCamCardTests/
└── SimCamCardUITests/
```

## Do not move the package into `assignment/`

`assignment/` is the immutable instructor source.

The files in this package are your derived SDD artifacts.

## Next actions

1. Fill TODO values in `spec/reference-environment.md`.
2. Keep current screenshot names unchanged.
3. Complete the remaining observation gaps in `spec/reference-tests.md`:
   - T18 persistence;
   - successful T19 export;
   - remaining T20 exception cases;
   - group/tag deletion.
4. Expand dataset from 3 cards to approximately 30–50.
5. Freeze Week 1.
6. Commit the SDD baseline before Week 2 implementation.
