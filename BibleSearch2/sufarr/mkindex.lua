require "sufarr"
assert (loadfile "./indexer.lua") ()

mkindex ("../kjv.pidx", "../kjv.idx",
         "../kjv.txt")
