/*
   The Computer Language Benchmarks Game
   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

   contributed by Piotr Tarsa
   modified for JVM compatibility by Claude
*/

import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class program {
    static {
        System.loadLibrary("rapl_interface");
        System.loadLibrary("pcre2-8");
    }

    // PCRE2 constants
    private static final int PCRE2_JIT_COMPLETE = 0x00000001;
    private static final int PCRE2_SUBSTITUTE_GLOBAL = 0x00000100;
    private static final int PCRE2_NO_UTF_CHECK = 0x40000000;
    private static final int PCRE2_ERROR_NOMATCH = -1;

    // PCRE2 function handles
    private static MethodHandle pcre2_compile_8;
    private static MethodHandle pcre2_jit_compile_8;
    private static MethodHandle pcre2_match_data_create_8;
    private static MethodHandle pcre2_get_ovector_pointer_8;
    private static MethodHandle pcre2_jit_match_8;
    private static MethodHandle pcre2_get_error_message_8;
    private static MethodHandle pcre2_substitute_8;
    private static MethodHandle pcre2_code_free_8;
    private static MethodHandle pcre2_match_data_free_8;
    private static MemorySegment NULL;

    // Input data
    private static byte[] rawInput;
    
    public static void main(String[] args) throws Throwable {
        // Read input once
        rawInput = System.in.readAllBytes();
        
        SymbolLookup lookup = SymbolLookup.loaderLookup();
        Linker linker = Linker.nativeLinker();

        // Load RAPL interface functions
        MethodHandle start_rapl = linker.downcallHandle(
                lookup.find("start_rapl").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT)
        );

        MethodHandle stop_rapl = linker.downcallHandle(
                lookup.find("stop_rapl").get(),
                FunctionDescriptor.ofVoid()
        );

        // Load PCRE2 functions
        initializePcre2Functions(lookup, linker);

        // Run benchmark with energy measurement
        while ((int) start_rapl.invokeExact() > 0) {
            run_benchmark();
            stop_rapl.invokeExact();
            
            // Force garbage collection between iterations
            System.gc();
        }
    }

    private static void initializePcre2Functions(SymbolLookup lookup, Linker linker) {
        NULL = MemorySegment.NULL;

        pcre2_compile_8 = linker.downcallHandle(
                lookup.find("pcre2_compile_8").get(),
                FunctionDescriptor.of(ValueLayout.ADDRESS, 
                        ValueLayout.ADDRESS, ValueLayout.JAVA_LONG, ValueLayout.JAVA_INT,
                        ValueLayout.ADDRESS, ValueLayout.ADDRESS, ValueLayout.ADDRESS)
        );

        pcre2_jit_compile_8 = linker.downcallHandle(
                lookup.find("pcre2_jit_compile_8").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT, 
                        ValueLayout.ADDRESS, ValueLayout.JAVA_INT)
        );

        pcre2_match_data_create_8 = linker.downcallHandle(
                lookup.find("pcre2_match_data_create_8").get(),
                FunctionDescriptor.of(ValueLayout.ADDRESS, 
                        ValueLayout.JAVA_INT, ValueLayout.ADDRESS)
        );

        pcre2_get_ovector_pointer_8 = linker.downcallHandle(
                lookup.find("pcre2_get_ovector_pointer_8").get(),
                FunctionDescriptor.of(ValueLayout.ADDRESS, 
                        ValueLayout.ADDRESS)
        );

        pcre2_jit_match_8 = linker.downcallHandle(
                lookup.find("pcre2_jit_match_8").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT, 
                        ValueLayout.ADDRESS, ValueLayout.ADDRESS, ValueLayout.JAVA_LONG,
                        ValueLayout.JAVA_LONG, ValueLayout.JAVA_INT, ValueLayout.ADDRESS, 
                        ValueLayout.ADDRESS)
        );

        pcre2_get_error_message_8 = linker.downcallHandle(
                lookup.find("pcre2_get_error_message_8").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT, 
                        ValueLayout.JAVA_INT, ValueLayout.ADDRESS, ValueLayout.JAVA_INT)
        );

        pcre2_substitute_8 = linker.downcallHandle(
                lookup.find("pcre2_substitute_8").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT, 
                        ValueLayout.ADDRESS, ValueLayout.ADDRESS, ValueLayout.JAVA_LONG,
                        ValueLayout.JAVA_LONG, ValueLayout.JAVA_INT, ValueLayout.ADDRESS,
                        ValueLayout.ADDRESS, ValueLayout.ADDRESS, ValueLayout.JAVA_LONG,
                        ValueLayout.ADDRESS, ValueLayout.ADDRESS)
        );
        
        pcre2_code_free_8 = linker.downcallHandle(
                lookup.find("pcre2_code_free_8").get(),
                FunctionDescriptor.ofVoid(ValueLayout.ADDRESS)
        );
        
        pcre2_match_data_free_8 = linker.downcallHandle(
                lookup.find("pcre2_match_data_free_8").get(),
                FunctionDescriptor.ofVoid(ValueLayout.ADDRESS)
        );
    }

    private static void run_benchmark() throws Throwable {
        final int initialLength = rawInput.length;
        
        // Create a shared arena that can be accessed from multiple threads
        try (Arena arena = Arena.ofShared()) {
            // Process the input sequence
            final var sequence = arena.allocate(initialLength);
            final int sequenceLength;
            
            var rawInputBuffer = arena.allocateFrom(ValueLayout.JAVA_BYTE, rawInput);
            var initialPattern = compilePattern(">.*\\n|\\n");
            try {
                sequenceLength = substitute(initialPattern, rawInputBuffer, initialLength,
                        NULL, sequence, initialLength, "");
            } finally {
                freePattern(initialPattern);
            }

            // Create executor service for parallel tasks
            ExecutorService executorService = 
                Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
            
            // Process the magic regex substitutions
            Future<Integer> magicRegExpsCount = executorService.submit(() -> {
                final Map<String, String> iub = new LinkedHashMap<>();
                iub.put("tHa[Nt]", "<4>");
                iub.put("aND|caN|Ha[DS]|WaS", "<3>");
                iub.put("a[NSt]|BY", "<2>");
                iub.put("<[^>]*>", "|");
                iub.put("\\|[^|][^|]*\\|", "-");

                try (Arena subArena = Arena.ofShared()) {
                    var currentLength = sequenceLength;
                    var bufLength = currentLength * 3 / 2;
                    var buf1 = subArena.allocate(bufLength);
                    var buf2 = subArena.allocate(bufLength);
                    MemorySegment.copy(sequence, 0, buf1, 0, sequenceLength);
                    var flip = false;

                    for (Entry<String, String> entry : iub.entrySet()) {
                        var pattern = entry.getKey();
                        var replacement = entry.getValue();

                        var patternCompiled = compilePattern(pattern);
                        try {
                            currentLength = substitute(patternCompiled,
                                    flip ? buf2 : buf1, currentLength,
                                    NULL,
                                    flip ? buf1 : buf2, bufLength,
                                    replacement);
                            flip = !flip;
                        } finally {
                            freePattern(patternCompiled);
                        }
                    }
                    return currentLength;
                } catch (Throwable t) {
                    throw new RuntimeException(t);
                }
            });

            var variants = Arrays.asList("agggtaaa|tttaccct",
                    "[cgt]gggtaaa|tttaccc[acg]",
                    "a[act]ggtaaa|tttacc[agt]t",
                    "ag[act]gtaaa|tttac[agt]ct",
                    "agg[act]taaa|ttta[agt]cct",
                    "aggg[acg]aaa|ttt[cgt]ccct",
                    "agggt[cgt]aa|tt[acg]accct",
                    "agggta[cgt]a|t[acg]taccct",
                    "agggtaa[cgt]|[acg]ttaccct");

            var tasks = variants.stream().map(variant -> (Callable<String>) () -> {
                try {
                    var variantPattern = compilePattern(variant);
                    var oVectorSize = 100;
                    MemorySegment matchData = (MemorySegment) pcre2_match_data_create_8.invoke(oVectorSize, NULL);
                    try {
                        MemorySegment oVectorPtr = ((MemorySegment) pcre2_get_ovector_pointer_8.invoke(matchData))
                                .reinterpret(16 * oVectorSize);
                        
                        oVectorPtr.setAtIndex(ValueLayout.JAVA_LONG, 1, 0);
                        long count = 0;
                        var result = 1;
                        while ((result = (int) pcre2_jit_match_8.invoke(variantPattern,
                                sequence, sequenceLength,
                                oVectorPtr.getAtIndex(ValueLayout.JAVA_LONG, 2L * result - 1), 0,
                                matchData, NULL)) > 0) count += result;
                                
                        if (result != PCRE2_ERROR_NOMATCH) {
                            showPcre2ErrorIfAny("jit match", result);
                        }
                        return variant + " " + count;
                    } finally {
                        freeMatchData(matchData);
                        freePattern(variantPattern);
                    }
                } catch (Throwable t) {
                    throw new RuntimeException(t);
                }
            }).toList();

            for (var result : executorService.invokeAll(tasks)) {
                System.out.println(result.get());
            }

            System.out.println();
            System.out.println(initialLength);
            System.out.println(sequenceLength);
            System.out.println(magicRegExpsCount.get());
            
            executorService.shutdown();
        }
    }

    private static void freePattern(MemorySegment pattern) throws Throwable {
        if (pattern != null && !pattern.equals(NULL)) {
            pcre2_code_free_8.invoke(pattern);
        }
    }
    
    private static void freeMatchData(MemorySegment matchData) throws Throwable {
        if (matchData != null && !matchData.equals(NULL)) {
            pcre2_match_data_free_8.invoke(matchData);
        }
    }

    private static int substitute(
            MemorySegment compiledPattern,
            MemorySegment inputBuffer, int inputLength,
            MemorySegment matchContext,
            MemorySegment outputBuffer, int outputBufferLength,
            String replacement) throws Throwable {
        try (Arena arena = Arena.ofConfined()) {
            var replacementBytes =
                    replacement.getBytes(StandardCharsets.US_ASCII);
            var replacementBuffer = arena.allocateFrom(
                    ValueLayout.JAVA_BYTE, replacementBytes);
            var outputLengthHolder = arena.allocate(ValueLayout.JAVA_LONG);
            outputLengthHolder.setAtIndex(ValueLayout.JAVA_LONG, 0, outputBufferLength);
            var options = PCRE2_SUBSTITUTE_GLOBAL | PCRE2_NO_UTF_CHECK;
            
            var substitutionResult = (int) pcre2_substitute_8.invoke(
                    compiledPattern,
                    inputBuffer, inputLength,
                    0, options, NULL,
                    matchContext,
                    replacementBuffer, replacementBytes.length,
                    outputBuffer, outputLengthHolder);
                    
            showPcre2ErrorIfAny("substitutionResult", substitutionResult);
            return substitutionResult < 0 ?
                    0 : outputLengthHolder.getAtIndex(ValueLayout.JAVA_INT, 0);
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
    }

    private static MemorySegment compilePattern(String pattern) throws Throwable {
        try (Arena arena = Arena.ofConfined()) {
            var patternBytes = pattern.getBytes(StandardCharsets.US_ASCII);
            var patternLength = patternBytes.length;
            var bufPattern = arena.allocateFrom(ValueLayout.JAVA_BYTE, patternBytes);
            var bufErrorCode = arena.allocate(ValueLayout.JAVA_LONG);
            var bufErrorOffset = arena.allocate(ValueLayout.JAVA_LONG);
            
            var compiledPattern = (MemorySegment) pcre2_compile_8.invoke(
                    bufPattern, patternLength, 0,
                    bufErrorCode, bufErrorOffset, NULL);
                    
            if (compiledPattern.equals(NULL)) {
                showPcre2Error("pcre2_compile_8 failed at offset " +
                                bufErrorOffset.getAtIndex(ValueLayout.JAVA_INT, 0),
                        bufErrorCode.getAtIndex(ValueLayout.JAVA_INT, 0));
                throw new RuntimeException("Failed to compile pattern: " + pattern);
            }
            
            var jitCompileResult = (int) pcre2_jit_compile_8.invoke(
                    compiledPattern, PCRE2_JIT_COMPLETE);
                    
            showPcre2ErrorIfAny("pcre_2jit_compile_8", jitCompileResult);
            return compiledPattern;
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
    }

    private static void showPcre2ErrorIfAny(
            String description, int resultOrErrorCode) throws Throwable {
        if (resultOrErrorCode < 0) {
            showPcre2Error(description, resultOrErrorCode);
        }
    }

    private static void showPcre2Error(String description, int errorCode) throws Throwable {
        try (Arena arena = Arena.ofConfined()) {
            var bufSize = 1000;
            var buf = arena.allocate(bufSize);
            var errorMsgLength = (int) pcre2_get_error_message_8.invoke(
                    errorCode, buf, bufSize);
                    
            if (errorMsgLength >= 0) {
                var errorMsgBytes = new byte[errorMsgLength];
                buf.asByteBuffer().get(errorMsgBytes);
                var errorMsg = new String(errorMsgBytes, 0, errorMsgLength,
                        StandardCharsets.US_ASCII);
                new Exception(description + " " + errorCode +
                        " = " + errorMsg).printStackTrace(System.out);
            } else {
                new Exception(description +
                        " Error during getting error message: " +
                        errorMsgLength).printStackTrace(System.out);
            }
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
    }
}
