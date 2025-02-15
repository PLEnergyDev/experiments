
main:     file format elf64-x86-64


Disassembly of section .init:

<_init>:
	endbr64
	sub    $0x8,%rsp
	mov    0x2fd9(%rip),%rax        # <__gmon_start__@Base>
	test   %rax,%rax
	je     <_init+0x16>
	call   *%rax
	add    $0x8,%rsp
	ret

Disassembly of section .plt:

<.plt>:
	push   0x2f72(%rip)        # <_GLOBAL_OFFSET_TABLE_+0x8>
	bnd jmp *0x2f73(%rip)        # <_GLOBAL_OFFSET_TABLE_+0x10>
	nopl   (%rax)
	endbr64
	push   $0x0
	bnd jmp <_init+0x20>
	nop
	endbr64
	push   $0x1
	bnd jmp <_init+0x20>
	nop
	endbr64
	push   $0x2
	bnd jmp <_init+0x20>
	nop
	endbr64
	push   $0x3
	bnd jmp <_init+0x20>
	nop
	endbr64
	push   $0x4
	bnd jmp <_init+0x20>
	nop
	endbr64
	push   $0x5
	bnd jmp <_init+0x20>
	nop

Disassembly of section .plt.got:

<__cxa_finalize@plt>:
	endbr64
	bnd jmp *0x2f5d(%rip)        # <__cxa_finalize@GLIBC_2.2.5>
	nopl   0x0(%rax,%rax,1)

Disassembly of section .plt.sec:

<free@plt>:
	endbr64
	bnd jmp *0x2efd(%rip)        # <free@GLIBC_2.2.5>
	nopl   0x0(%rax,%rax,1)

<stop_rapl@plt>:
	endbr64
	bnd jmp *0x2ef5(%rip)        # <stop_rapl@Base>
	nopl   0x0(%rax,%rax,1)

<start_rapl@plt>:
	endbr64
	bnd jmp *0x2eed(%rip)        # <start_rapl@Base>
	nopl   0x0(%rax,%rax,1)

<strtol@plt>:
	endbr64
	bnd jmp *0x2ee5(%rip)        # <strtol@GLIBC_2.2.5>
	nopl   0x0(%rax,%rax,1)

<malloc@plt>:
	endbr64
	bnd jmp *0x2edd(%rip)        # <malloc@GLIBC_2.2.5>
	nopl   0x0(%rax,%rax,1)

<__printf_chk@plt>:
	endbr64
	bnd jmp *0x2ed5(%rip)        # <__printf_chk@GLIBC_2.3.4>
	nopl   0x0(%rax,%rax,1)

Disassembly of section .text:

<main>:
	endbr64
	push   %r14
	mov    $0xa,%edx
	push   %r13
	push   %r12
	push   %rbp
	push   %rbx
	mov    %rsi,%rbx
	mov    0x8(%rsi),%rdi
	xor    %esi,%esi
	call   <strtol@plt>
	mov    0x10(%rbx),%rdi
	xor    %esi,%esi
	mov    $0xa,%edx
	mov    %rax,%r13
	mov    %eax,%r14d
	call   <strtol@plt>
	mov    0x18(%rbx),%rdi
	xor    %esi,%esi
	mov    $0xa,%edx
	mov    %eax,%r12d
	call   <strtol@plt>
	test   %r13d,%r13d
	jle    <main+0x7d>
	mov    %eax,%ebp
	xor    %r13d,%r13d
	xor    %eax,%eax
	call   <start_rapl@plt>
	mov    $0x3e8,%ebx
	xchg   %ax,%ax
	mov    %ebp,%esi
	mov    %r12d,%edi
	call   <run_benchmark>
	dec    %ebx
	jne    <main+0x60>
	xor    %eax,%eax
	inc    %r13d
	call   <stop_rapl@plt>
	cmp    %r14d,%r13d
	jne    <main+0x52>
	pop    %rbx
	pop    %rbp
	pop    %r12
	pop    %r13
	xor    %eax,%eax
	pop    %r14
	ret
	nopl   0x0(%rax,%rax,1)

<_start>:
	endbr64
	xor    %ebp,%ebp
	mov    %rdx,%r9
	pop    %rsi
	mov    %rsp,%rdx
	and    $0xfffffffffffffff0,%rsp
	push   %rax
	push   %rsp
	xor    %r8d,%r8d
	xor    %ecx,%ecx
	lea    -0xaf(%rip),%rdi        # <main>
	call   *0x2e23(%rip)        # <__libc_start_main@GLIBC_2.34>
	hlt
	cs nopw 0x0(%rax,%rax,1)

<deregister_tm_clones>:
	lea    0x2e49(%rip),%rdi        # <__TMC_END__>
	lea    0x2e42(%rip),%rax        # <__TMC_END__>
	cmp    %rdi,%rax
	je     <deregister_tm_clones+0x28>
	mov    0x2e06(%rip),%rax        # <_ITM_deregisterTMCloneTable@Base>
	test   %rax,%rax
	je     <deregister_tm_clones+0x28>
	jmp    *%rax
	nopl   0x0(%rax)
	ret
	nopl   0x0(%rax)

<register_tm_clones>:
	lea    0x2e19(%rip),%rdi        # <__TMC_END__>
	lea    0x2e12(%rip),%rsi        # <__TMC_END__>
	sub    %rdi,%rsi
	mov    %rsi,%rax
	shr    $0x3f,%rsi
	sar    $0x3,%rax
	add    %rax,%rsi
	sar    $1,%rsi
	je     <register_tm_clones+0x38>
	mov    0x2dd5(%rip),%rax        # <_ITM_registerTMCloneTable@Base>
	test   %rax,%rax
	je     <register_tm_clones+0x38>
	jmp    *%rax
	nopw   0x0(%rax,%rax,1)
	ret
	nopl   0x0(%rax)

<__do_global_dtors_aux>:
	endbr64
	cmpb   $0x0,0x2dd5(%rip)        # <__TMC_END__>
	jne    <__do_global_dtors_aux+0x38>
	push   %rbp
	cmpq   $0x0,0x2db2(%rip)        # <__cxa_finalize@GLIBC_2.2.5>
	mov    %rsp,%rbp
	je     <__do_global_dtors_aux+0x27>
	mov    0x2db6(%rip),%rdi        # <__dso_handle>
	call   <__cxa_finalize@plt>
	call   <deregister_tm_clones>
	movb   $0x1,0x2dad(%rip)        # <__TMC_END__>
	pop    %rbp
	ret
	nopl   (%rax)
	ret
	nopl   0x0(%rax)

<frame_dummy>:
	endbr64
	jmp    <register_tm_clones>
	nopl   0x0(%rax)

<run_benchmark>:
	endbr64
	push   %r13
	mov    %edi,%eax
	imul   %esi,%eax
	lea    0x10(%rsp),%r13
	and    $0xffffffffffffffe0,%rsp
	push   -0x8(%r13)
	push   %rbp
	mov    %rsp,%rbp
	push   %r15
	mov    %edi,%r15d
	push   %r14
	movslq %eax,%r14
	shl    $0x3,%r14
	push   %r13
	push   %r12
	push   %rbx
	mov    %esi,%ebx
	sub    $0x28,%rsp
	mov    %edi,-0x34(%rbp)
	mov    %r14,%rdi
	mov    %eax,-0x48(%rbp)
	call   <malloc@plt>
	mov    %r14,%rdi
	mov    %rax,%r13
	call   <malloc@plt>
	mov    %r14,%rdi
	mov    %rax,%r12
	call   <malloc@plt>
	mov    %rax,-0x50(%rbp)
	test   %r15d,%r15d
	jle    <run_benchmark+0x27b>
	test   %ebx,%ebx
	jle    <run_benchmark+0x27b>
	movslq %ebx,%rax
	mov    %rax,-0x40(%rbp)
	lea    0x0(,%rax,8),%r15
	lea    -0x1(%rbx),%eax
	mov    %eax,-0x38(%rbp)
	mov    %ebx,%eax
	shr    $0x3,%eax
	lea    -0x1(%rax),%r8d
	mov    %ebx,%eax
	and    $0xfffffff8,%eax
	mov    %eax,-0x44(%rbp)
	inc    %r8
	vmovdqa 0xd01(%rip),%xmm6        # <_IO_stdin_used+0x20>
	vmovdqa 0xd19(%rip),%ymm4        # <_IO_stdin_used+0x40>
	vxorps %xmm5,%xmm5,%xmm5
	mov    %r13,%rcx
	mov    %r12,%rdx
	shl    $0x6,%r8
	xor    %r14d,%r14d
	xor    %r11d,%r11d
	xor    %edi,%edi
	nopl   (%rax)
	cmpl   $0x6,-0x38(%rbp)
	jbe    <run_benchmark+0x2cd>
	vmovd  %edi,%xmm3
	vmovdqa 0xcca(%rip),%ymm1        # <_IO_stdin_used+0x20>
	vpbroadcastd %xmm3,%ymm3
	xor    %eax,%eax
	nopl   (%rax)
	vmovdqa %ymm1,%ymm0
	vpaddd %ymm0,%ymm3,%ymm0
	vcvtdq2pd %xmm0,%ymm2
	vextracti128 $0x1,%ymm0,%xmm0
	vcvtdq2pd %xmm0,%ymm0
	vmovupd %ymm2,(%rcx,%rax,1)
	vmovupd %ymm0,0x20(%rcx,%rax,1)
	vmovupd %ymm2,(%rdx,%rax,1)
	vmovupd %ymm0,0x20(%rdx,%rax,1)
	add    $0x40,%rax
	vpaddd %ymm4,%ymm1,%ymm1
	cmp    %r8,%rax
	jne    <run_benchmark+0xe0>
	mov    -0x44(%rbp),%esi
	mov    %esi,%eax
	cmp    %ebx,%eax
	je     <run_benchmark+0x1ea>
	mov    %ebx,%r9d
	sub    %eax,%r9d
	lea    -0x1(%r9),%r10d
	cmp    $0x2,%r10d
	jbe    <run_benchmark+0x18d>
	vmovd  %esi,%xmm3
	vpshufd $0x0,%xmm3,%xmm0
	vmovd  %edi,%xmm3
	vpshufd $0x0,%xmm3,%xmm1
	add    %r14,%rax
	vpaddd %xmm6,%xmm0,%xmm0
	shl    $0x3,%rax
	vpaddd %xmm1,%xmm0,%xmm0
	lea    0x0(%r13,%rax,1),%r10
	vcvtdq2pd %xmm0,%xmm1
	add    %r12,%rax
	vpshufd $0xee,%xmm0,%xmm0
	vcvtdq2pd %xmm0,%xmm0
	vmovupd %xmm1,(%rax)
	vmovupd %xmm0,0x10(%rax)
	mov    %r9d,%eax
	and    $0xfffffffc,%eax
	vmovupd %xmm1,(%r10)
	vmovupd %xmm0,0x10(%r10)
	add    %eax,%esi
	cmp    %eax,%r9d
	je     <run_benchmark+0x1ea>
	lea    (%rdi,%rsi,1),%r9d
	vcvtsi2sd %r9d,%xmm5,%xmm0
	lea    (%r11,%rsi,1),%eax
	cltq
	vmovsd %xmm0,0x0(%r13,%rax,8)
	vmovsd %xmm0,(%r12,%rax,8)
	lea    0x1(%rsi),%eax
	cmp    %eax,%ebx
	jle    <run_benchmark+0x1ea>
	lea    (%r11,%rax,1),%r9d
	add    %edi,%eax
	vcvtsi2sd %eax,%xmm5,%xmm0
	movslq %r9d,%r9
	add    $0x2,%esi
	vmovsd %xmm0,0x0(%r13,%r9,8)
	vmovsd %xmm0,(%r12,%r9,8)
	cmp    %esi,%ebx
	jle    <run_benchmark+0x1ea>
	lea    (%r11,%rsi,1),%eax
	add    %edi,%esi
	vcvtsi2sd %esi,%xmm5,%xmm0
	cltq
	vmovsd %xmm0,0x0(%r13,%rax,8)
	vmovsd %xmm0,(%r12,%rax,8)
	inc    %edi
	add    %r15,%rcx
	add    %r15,%rdx
	add    %ebx,%r11d
	add    -0x40(%rbp),%r14
	cmp    %edi,-0x34(%rbp)
	jne    <run_benchmark+0xc0>
	mov    -0x40(%rbp),%rcx
	mov    %ebx,%ebx
	mov    -0x50(%rbp),%r10
	mov    -0x34(%rbp),%r14d
	shl    $0x3,%rcx
	mov    %r13,%r9
	lea    0x0(%r13,%rbx,8),%rsi
	xor    %r11d,%r11d
	vxorpd %xmm1,%xmm1,%xmm1
	nopl   0x0(%rax,%rax,1)
	mov    %r12,%r8
	xor    %edi,%edi
	nopl   (%rax)
	mov    %r8,%rdx
	mov    %r9,%rax
	vmovsd %xmm1,%xmm1,%xmm0
	nopw   0x0(%rax,%rax,1)
	vmovsd (%rax),%xmm7
	add    $0x8,%rax
	vfmadd231sd (%rdx),%xmm7,%xmm0
	add    %rcx,%rdx
	cmp    %rsi,%rax
	jne    <run_benchmark+0x240>
	vmovsd %xmm0,(%r10,%rdi,8)
	inc    %rdi
	add    $0x8,%r8
	cmp    %rbx,%rdi
	jne    <run_benchmark+0x230>
	inc    %r11d
	add    %rcx,%r10
	add    %rcx,%r9
	add    %rcx,%rsi
	cmp    %r11d,%r14d
	jne    <run_benchmark+0x228>
	vzeroupper
	mov    -0x48(%rbp),%eax
	mov    -0x50(%rbp),%rbx
	dec    %eax
	cltq
	vmovsd (%rbx,%rax,8),%xmm0
	lea    0xaf2(%rip),%rsi        # <_IO_stdin_used+0x4>
	mov    $0x1,%edi
	mov    $0x1,%eax
	call   <__printf_chk@plt>
	mov    %r13,%rdi
	call   <free@plt>
	mov    %r12,%rdi
	call   <free@plt>
	add    $0x28,%rsp
	mov    %rbx,%rdi
	pop    %rbx
	pop    %r12
	pop    %r13
	pop    %r14
	pop    %r15
	pop    %rbp
	lea    -0x10(%r13),%rsp
	pop    %r13
	jmp    <free@plt>
	xor    %eax,%eax
	xor    %esi,%esi
	jmp    <run_benchmark+0x126>

Disassembly of section .fini:

<_fini>:
	endbr64
	sub    $0x8,%rsp
	add    $0x8,%rsp
	ret