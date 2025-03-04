/*
   The Computer Language Benchmarks Game
   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

   contributed by Francois Green
*/

import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.io.*;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.Map.Entry;
import java.util.function.*;
import java.util.regex.*;
import static java.util.stream.Collectors.*;

public class program {
    static String input;

    public static void run_benchmark() throws Exception {
        final int initialLength = input.length();

        final String sequence = input.replaceAll(">.*\n|\n", "");

        CompletableFuture<String> replacements = CompletableFuture.supplyAsync(() -> {
            final Map<String, String> iub = new LinkedHashMap<>();
            iub.put("tHa[Nt]", "<4>");
            iub.put("aND|caN|Ha[DS]|WaS", "<3>");
            iub.put("a[NSt]|BY", "<2>");
            iub.put("<[^>]*>", "|");
            iub.put("\\|[^|][^|]*\\|", "-");

            String buffer = sequence;
            for (Map.Entry<String, String> entry : iub.entrySet()) {
                buffer = Pattern.compile(entry.getKey()).matcher(buffer).replaceAll(entry.getValue());
            }
            return buffer;
        });

        final int codeLength = sequence.length();

        final List<String> variants = Arrays.asList(
            "agggtaaa|tttaccct",
            "[cgt]gggtaaa|tttaccc[acg]",
            "a[act]ggtaaa|tttacc[agt]t",
            "ag[act]gtaaa|tttac[agt]ct",
            "agg[act]taaa|ttta[agt]cct",
            "aggg[acg]aaa|ttt[cgt]ccct",
            "agggt[cgt]aa|tt[acg]accct",
            "agggta[cgt]a|t[acg]taccct",
            "agggtaa[cgt]|[acg]ttaccct"
        );

        BiFunction<String, String, Entry<String, Long>> counts = (v, s) -> {
            Long count = Pattern.compile(v).splitAsStream(s).count() - 1;
            return new AbstractMap.SimpleEntry<>(v, count);
        };

        final Map<String, Long> results = variants.parallelStream()
            .map(variant -> counts.apply(variant, sequence))
            .collect(toMap(Map.Entry::getKey, Map.Entry::getValue));

        variants.forEach(variant -> System.out.println(variant + " " + results.get(variant)));

        System.out.println();
        System.out.println(initialLength);
        System.out.println(codeLength);
        System.out.println(replacements.join().length());
    }

    static {
        System.loadLibrary("rapl_interface");
    }

    public static void main(final String[] args) throws Throwable {
        SymbolLookup lookup = SymbolLookup.loaderLookup();

        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(
                lookup.find("start_rapl").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT)
        );

        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(
                lookup.find("stop_rapl").get(),
                FunctionDescriptor.ofVoid()
        );

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buf = new byte[65536];
        int count;
        while ((count = System.in.read(buf)) > 0) {
            baos.write(buf, 0, count);
        }
        input = baos.toString("US-ASCII");

        while (true) {
            if ((int) start_rapl.invokeExact() == 0) {
                break;
            }
            run_benchmark();
            stop_rapl.invokeExact();
        }
    }
}
