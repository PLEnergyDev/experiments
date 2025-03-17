/* The Computer Language Benchmarks Game
 https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 
 contributed by James McIlree
 modified by Tagir Valeev
 */

import it.unimi.dsi.fastutil.longs.Long2IntOpenHashMap;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.nio.charset.StandardCharsets;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class program {
    static final byte[] codes = { -1, 0, -1, 1, 3, -1, -1, 2 };
    static final char[] nucleotides = { 'A', 'C', 'G', 'T' };
    
    // Store the input data for reuse across iterations
    static byte[] inputData = null;

    static {
        System.loadLibrary("rapl_interface");
    }

    public static void main(String[] args) throws Throwable { 
        SymbolLookup lookup = SymbolLookup.loaderLookup();

        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(
                lookup.find("start_rapl").get(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT)
        );

        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(
                lookup.find("stop_rapl").get(),
                FunctionDescriptor.ofVoid()
        );

        inputData = readInput(System.in);

        while (true) {
            if ((int) start_rapl.invokeExact() == 0) break;
            run_benchmark();
            stop_rapl.invokeExact();
        }
    }

    private static void run_benchmark() throws Exception {
        byte[] sequence = inputData;

        ExecutorService pool = Executors.newFixedThreadPool(Runtime.getRuntime()
                .availableProcessors());
        int[] fragmentLengths = { 1, 2, 3, 4, 6, 12, 18 };
        List<Future<Result>> futures = pool.invokeAll(createFragmentTasks(sequence,
                fragmentLengths));
        pool.shutdown();

        StringBuilder sb = new StringBuilder();

        sb.append(writeFrequencies(sequence.length, futures.get(0).get()));
        sb.append(writeFrequencies(sequence.length - 1,
                sumTwoMaps(futures.get(1).get(), futures.get(2).get())));

        String[] nucleotideFragments = { "GGT", "GGTA", "GGTATT", "GGTATTTTAATT",
                "GGTATTTTAATTTATAGT" };
        for (String nucleotideFragment : nucleotideFragments) {
            sb.append(writeCount(futures, nucleotideFragment));
        }

        System.out.print(sb);
    }
    
    static byte[] readInput(InputStream is) throws IOException {
        String line;
        BufferedReader in = new BufferedReader(new InputStreamReader(is,
                StandardCharsets.ISO_8859_1));
        while ((line = in.readLine()) != null) {
            if (line.startsWith(">THREE"))
                break;
        }
    
        byte[] bytes = new byte[1048576];
        int position = 0;
        while ((line = in.readLine()) != null && line.charAt(0) != '>') {
            if (line.length() + position > bytes.length) {
                byte[] newBytes = new byte[bytes.length * 2];
                System.arraycopy(bytes, 0, newBytes, 0, position);
                bytes = newBytes;
            }
            for (int i = 0; i < line.length(); i++)
                bytes[position++] = (byte) line.charAt(i);
        }
    
        return toCodes(bytes, position);
    }

    static class Result {
        Long2IntOpenHashMap map = new Long2IntOpenHashMap();
        int keyLength;
    
        public Result(int keyLength) {
            this.keyLength = keyLength;
        }
    }

    static ArrayList<Callable<Result>> createFragmentTasks(final byte[] sequence,
            int[] fragmentLengths) {
        ArrayList<Callable<Result>> tasks = new ArrayList<>();
        for (int fragmentLength : fragmentLengths) {
            for (int index = 0; index < fragmentLength; index++) {
                int offset = index;
                tasks.add(() -> createFragmentMap(sequence, offset, fragmentLength));
            }
        }
        return tasks;
    }

    static Result createFragmentMap(byte[] sequence, int offset, int fragmentLength) {
        Result res = new Result(fragmentLength);
        Long2IntOpenHashMap map = res.map;
        int lastIndex = sequence.length - fragmentLength + 1;
        for (int index = offset; index < lastIndex; index += fragmentLength) {
            map.addTo(getKey(sequence, index, fragmentLength), 1);
        }

        return res;
    }

    static Result sumTwoMaps(Result map1, Result map2) {
        map2.map.forEach((key, value) -> map1.map.addTo(key, value));
        return map1;
    }

    static String writeFrequencies(float totalCount, Result frequencies) {
        List<Entry<String, Integer>> freq = new ArrayList<>(frequencies.map.size());
        frequencies.map.forEach((key, cnt) -> freq.add(new SimpleEntry<>(keyToString(key,
                frequencies.keyLength), cnt)));
        freq.sort(Map.Entry.comparingByValue(Comparator.reverseOrder()));
        StringBuilder sb = new StringBuilder();
        for (Entry<String, Integer> entry : freq) {
            sb.append(String.format(Locale.ENGLISH, "%s %.3f\n", entry.getKey(),
                    entry.getValue() * 100.0f / totalCount));
        }
        return sb.append('\n').toString();
    }

    static String writeCount(List<Future<Result>> futures, String nucleotideFragment)
            throws Exception {
        byte[] key = toCodes(nucleotideFragment.getBytes(StandardCharsets.ISO_8859_1),
                nucleotideFragment.length());
        long k = getKey(key, 0, nucleotideFragment.length());
        int count = 0;
        for (Future<Result> future : futures) {
            Result f = future.get();
            if (f.keyLength == nucleotideFragment.length()) {
                count += f.map.get(k);
            }
        }

        return count + "\t" + nucleotideFragment + '\n';
    }

    /**
     * Convert long key to the nucleotides string
     */
    static String keyToString(long key, int length) {
        char[] res = new char[length];
        for (int i = 0; i < length; i++) {
            res[length - i - 1] = nucleotides[(int) (key & 0x3)];
            key >>= 2;
        }
        return new String(res);
    }

    /**
     * Get the long key for given byte array of codes at given offset and length
     * (length must be less than 32)
     */
    static long getKey(byte[] arr, int offset, int length) {
        long key = 0;
        for (int i = offset; i < offset + length; i++) {
            key = key * 4 + arr[i];
        }
        return key;
    }

    /**
     * Convert given byte array (limiting to given length) containing acgtACGT
     * to codes (0 = A, 1 = C, 2 = G, 3 = T) and returns new array
     */
    static byte[] toCodes(byte[] sequence, int length) {
        byte[] result = new byte[length];
        for (int i = 0; i < length; i++) {
            result[i] = codes[sequence[i] & 0x7];
        }
        return result;
    }
}
    