/*
Mini Cloud Log Analyzer - Variante A (Mejorado)
Cuenta códigos HTTP:
- 2xx (éxitos)
- 4xx (cliente)
- 5xx (servidor)
Incluye total de códigos procesados
*/

.equ SYS_read,   63
.equ SYS_write,  64
.equ SYS_exit,   93
.equ STDIN_FD,    0
.equ STDOUT_FD,   1

.section .bss
    .align 4
buffer:     .skip 4096
num_buf:    .skip 32

.section .data
msg_titulo: .asciz "=== Mini Cloud Log Analyzer ===\n"
msg_sep:    .asciz "------------------------------\n"
msg_total:  .asciz "Total de codigos: "
msg_2xx:    .asciz "Exitos 2xx: "
msg_4xx:    .asciz "Errores 4xx: "
msg_5xx:    .asciz "Errores 5xx: "
msg_nl:     .asciz "\n"

.section .text
.global _start

_start:
    // Contadores
    mov x19, #0      // 2xx
    mov x20, #0      // 4xx
    mov x21, #0      // 5xx
    mov x24, #0      // TOTAL

    // Parser
    mov x22, #0      // numero_actual
    mov x23, #0      // tiene_digitos

leer:
    mov x0, #STDIN_FD
    adrp x1, buffer
    add x1, x1, :lo12:buffer
    mov x2, #4096
    mov x8, #SYS_read
    svc #0

    cmp x0, #0
    beq fin_lectura
    blt salir

    mov x25, #0
    mov x26, x0

loop:
    cmp x25, x26
    b.ge leer

    adrp x1, buffer
    add x1, x1, :lo12:buffer
    ldrb w27, [x1, x25]
    add x25, x25, #1

    cmp w27, #10
    b.eq fin_num

    cmp w27, #'0'
    b.lt loop
    cmp w27, #'9'
    b.gt loop

    mov x28, #10
    mul x22, x22, x28
    sub w27, w27, #'0'
    uxtw x27, w27
    add x22, x22, x27
    mov x23, #1
    b loop

fin_num:
    cbz x23, reset

    add x24, x24, #1
    mov x0, x22
    bl clasificar

reset:
    mov x22, #0
    mov x23, #0
    b loop

fin_lectura:
    cbz x23, imprimir
    add x24, x24, #1
    mov x0, x22
    bl clasificar

imprimir:
    adrp x0, msg_titulo
    add x0, x0, :lo12:msg_titulo
    bl print_str

    adrp x0, msg_sep
    add x0, x0, :lo12:msg_sep
    bl print_str

    adrp x0, msg_total
    add x0, x0, :lo12:msg_total
    bl print_str
    mov x0, x24
    bl print_num
    bl newline

    adrp x0, msg_2xx
    add x0, x0, :lo12:msg_2xx
    bl print_str
    mov x0, x19
    bl print_num
    bl newline

    adrp x0, msg_4xx
    add x0, x0, :lo12:msg_4xx
    bl print_str
    mov x0, x20
    bl print_num
    bl newline

    adrp x0, msg_5xx
    add x0, x0, :lo12:msg_5xx
    bl print_str
    mov x0, x21
    bl print_num
    bl newline

salir:
    mov x0, #0
    mov x8, #SYS_exit
    svc #0

// -------------------------

clasificar:
    cmp x0, #200
    b.lt fin_c
    cmp x0, #299
    b.le ok

    cmp x0, #400
    b.lt fin_c
    cmp x0, #499
    b.le cliente

    cmp x0, #500
    b.lt fin_c
    cmp x0, #599
    b.le servidor

    b fin_c

ok:
    add x19, x19, #1
    b fin_c

cliente:
    add x20, x20, #1
    b fin_c

servidor:
    add x21, x21, #1

fin_c:
    ret

// -------------------------

print_str:
    mov x9, x0
    mov x10, #0
len:
    ldrb w11, [x9, x10]
    cbz w11, done
    add x10, x10, #1
    b len
done:
    mov x1, x9
    mov x2, x10
    mov x0, #STDOUT_FD
    mov x8, #SYS_write
    svc #0
    ret

newline:
    adrp x0, msg_nl
    add x0, x0, :lo12:msg_nl
    bl print_str
    ret

// -------------------------

print_num:
    cbnz x0, conv

    adrp x1, num_buf
    add x1, x1, :lo12:num_buf
    mov w2, #'0'
    strb w2, [x1]

    mov x0, #STDOUT_FD
    mov x2, #1
    mov x8, #SYS_write
    svc #0
    ret

conv:
    adrp x12, num_buf
    add x12, x12, :lo12:num_buf
    add x12, x12, #31

    mov x14, #10
    mov x15, #0

loop2:
    udiv x16, x0, x14
    msub x17, x16, x14, x0
    add x17, x17, #'0'

    sub x12, x12, #1
    strb w17, [x12]
    add x15, x15, #1

    mov x0, x16
    cbnz x0, loop2

    mov x1, x12
    mov x2, x15
    mov x0, #STDOUT_FD
    mov x8, #SYS_write
    svc #0
    ret
