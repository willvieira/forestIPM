import Lake
open Lake DSL

package "ForestIPM" where
  name := "ForestIPM"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4"

lean_lib «ForestIPM» where
  srcDir := "lean"
  roots  := #[`ForestIPM]
