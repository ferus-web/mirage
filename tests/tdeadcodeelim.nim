import mirage/[atom, ir/gen]
import std/unittest

var generator = newCodeGenerator()
generator.opts.deadCodeElimination = true

suite "dead code eliminator":
  test "basic unused value":
    generator.enter("main")
    generator.write(
      name = "totally_useful_value",
      atom = integer 1337
    )
    generator.exit("main")

    # Pass 1: this should weed out "totally_useful_value" from the stack
    generator.compute()

    # Pass 2: generate IR
    let mir = generator.generateIR()

    for warn in mir.warnings:
      assert warn.kind != wkUnused, "Unused warning raised even when dead code elimination is on: \"" & warn.message & "\"\n" & mir.source
  
  # FIXME: this logic doesn't work yet even though it should!
  #[ 
  test "reference to value that would otherwise be unused":
    generator = newCodeGenerator()
    generator.opts.deadCodeElimination = false 

    generator.enter("main")
    generator.write(
      name = "not_at_all_worthless",
      atom = str "SPAAAAAAAAAAAAAAAAAACE"
    )
    generator.write(
      name = "iminspace",
      atom = generator.reference("not_at_all_worthless")
    )
    generator.exit("main")

    generator.compute()

    let mir = generator.generateIR()

    for warn in mir.warnings:
      assert warn.kind != wkUnused, "Unused warning raised even when there is a reference to not_at_all_worthless: \"" & warn.message & "\"\n" & mir.source ]#

  test "should warn when dead code elim is off and there is an unused write":
    generator = newCodeGenerator()
    generator.opts.deadCodeElimination = false

    generator.enter("main")
    generator.write(
      name = "insert_petty_joke_here",
      atom = str "Oglo, I thoroughly dislike you. Seek help. You schizo."
    )
    generator.exit("main")

    generator.compute()

    let mir = generator.generateIR()

    var unusedWarn = false

    for warn in mir.warnings:
      if warn.kind == wkUnused:
        unusedWarn = true
        break
    
    assert unusedWarn == true, "No unused warning was raised even when there is an unused write.\n" & mir.source
