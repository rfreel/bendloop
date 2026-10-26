.option norvc
.option norelax
.section .text
.globl synth4_eval
.type synth4_eval,@function
# LP64: a0 = u32 prefix tokens, a1 = count, a2 = input, a3 = 63*u64 scratch.
# Returns a0 = output, a1 = 0; invalid token/shape/domain returns a0=0,a1=2.
# Caller supplies aligned, mapped, disjoint buffers and a valid return address.
synth4_eval:
  beqz a1, invalid
  li t0, 63
  bltu t0, a1, invalid
  li t0, 16
  bgeu a2, t0, invalid
  slli t1, a1, 2
  add t1, a0, t1
  mv t2, a3
  li t3, 0
  mv t4, a1
loop:
  addi t1, t1, -4
  lwu t0, 0(t1)
  beqz t0, input
  li t5, 17
  bltu t0, t5, constant
  beq t0, t5, negate
  li t5, 20
  bltu t5, t0, invalid
  li t5, 2
  bltu t3, t5, invalid
  addi t2, t2, -8
  ld t5, 0(t2)
  ld t6, -8(t2)
  li a0, 18
  beq t0, a0, conjunction
  li a0, 19
  beq t0, a0, disjunction
  xor t5, t5, t6
  j binary_done
conjunction:
  and t5, t5, t6
  j binary_done
disjunction:
  or t5, t5, t6
binary_done:
  sd t5, -8(t2)
  addi t3, t3, -1
  j next
negate:
  beqz t3, invalid
  ld t5, -8(t2)
  xori t5, t5, 15
  sd t5, -8(t2)
  j next
constant:
  addi t5, t0, -1
  j push
input:
  mv t5, a2
push:
  sd t5, 0(t2)
  addi t2, t2, 8
  addi t3, t3, 1
next:
  addi t4, t4, -1
  bnez t4, loop
  li t0, 1
  bne t3, t0, invalid
  ld a0, 0(a3)
  li a1, 0
  ret
invalid:
  li a0, 0
  li a1, 2
  ret
.size synth4_eval, .-synth4_eval
