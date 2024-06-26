# Mirage - the **M**odest **I**ntermediate **R**epresent**A**tion **GE**nerator
Mirage is a (soon) bytecode emitter and interpreter designed to make it easier to write interpreted languages in Nim. \
It is made for the Bali JavaScript engine that will be used for Ferus. \
A lot of the bytecode instructions are shamelessly ripped off from Lua :^) \

It returns an `IR` object that has all the warnings generated by the IR generator alongside the IR source itself.

# What it can do
- Interpret bytecode
- Proper exception tracing
- Rudimentarily analyze "hot" code paths

Mirage is ~2800 LoC and does most of the bytecode generation and interpretation work already. We're probably never going to get as fast/efficient as LLVM which has millions of hours of manpower and research applied to it with millions of LoC. \
It has plenty of bytecodes (there's too many to list here!) and can do most things you want. \
There's also some work going on to implement a fully functioning JIT compiler without any external libraries, in pure Nim!

# What it'll do
- JIT compile the bytecode whenever necessary

# What it won't do, for now atleast.
- Be a real competitor to LLVM's JIT runtime
- Do the other things needed to write a programming language interpreter (tokenizer, parser, semantic rule applier, etc.)

# Why not add a semantic rule applier?
1. A lot of languages have very bizzare allowances on what they allow the programmer to do (take JavaScript's detached-from-reality "type" system for example)
2. I'm lazy
