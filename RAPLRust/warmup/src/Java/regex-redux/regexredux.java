import java.io.*;
import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.Map.Entry;
import java.util.function.*;
import java.util.regex.*;

import static java.util.stream.Collectors.*;

public class regexredux {

    public static void main(String[] args) throws IOException {
        var dll_path = System.getProperty("user.dir") + "/../../rapl-interface/target/release/librapl_lib.so";
        System.load(dll_path);

        // Loading functions
        MemorySegment start_rapl_symbol = SymbolLookup.loaderLookup().find("start_rapl").get();
        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(start_rapl_symbol,
            FunctionDescriptor.of(ValueLayout.JAVA_INT));

        MemorySegment stop_rapl_symbol = SymbolLookup.loaderLookup().find("stop_rapl").get();
        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(stop_rapl_symbol,
            FunctionDescriptor.of(ValueLayout.JAVA_INT));

        // Read input once before the loop
        ByteArrayOutputStream baos = new ByteArrayOutputStream(); {
            byte[] buf = new byte[65536];
            int count;
            while ((count = System.in.read(buf)) > 0) {
                baos.write(buf, 0, count);
            }
        }
        final String input = baos.toString("US-ASCII");

        // Store initial length and cleaned-up sequence
        final int initialLength = input.length();
        final String sequence = input.replaceAll(">.*\n|\n", "");
        final int codeLength = sequence.length();

        // Number of iterations
        int loop_count = Integer.parseInt(args[0]);

        // Main iteration loop
        for (int counter = 0; counter < loop_count; counter++) {
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }

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
                Long count = Pattern.compile(v).splitAsStream(s).count() - 1; // Off by one
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

            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }
}
