/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/

   contributed by Leonhard Holz
   modified to allow multiple iterations within main
*/

import java.io.*;
import java.util.*;
import java.util.concurrent.*;

public class revcomp
{
    private static final byte[] map = new byte[256];
    private static final int CHUNK_SIZE = 1024 * 1024 * 16; // 16 MB
    private static final int NUMBER_OF_CORES = Runtime.getRuntime().availableProcessors();

    static {
        for (int i = 0; i < map.length; i++) {
            map[i] = (byte) i;
        }
        map['t'] = map['T'] = 'A';
        map['a'] = map['A'] = 'T';
        map['g'] = map['G'] = 'C';
        map['c'] = map['C'] = 'G';
        map['v'] = map['V'] = 'B';
        map['h'] = map['H'] = 'D';
        map['r'] = map['R'] = 'Y';
        map['m'] = map['M'] = 'K';
        map['y'] = map['Y'] = 'R';
        map['k'] = map['K'] = 'M';
        map['b'] = map['B'] = 'V';
        map['d'] = map['D'] = 'H';
        map['u'] = map['U'] = 'A';
    }

    public static void main(String[] args) throws IOException
    {
        // Read all input data into a byte array using CHUNK_SIZE buffer
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[CHUNK_SIZE];
        int read;
        while ((read = System.in.read(buffer)) != -1) {
            baos.write(buffer, 0, read);
        }
        byte[] inputData = baos.toByteArray();

        // Create a new InputStream from the input data
        ByteArrayInputStream bais = new ByteArrayInputStream(inputData);

        // Run the benchmark
        revcomp benchmark = new revcomp();
        benchmark.runBenchmark(bais);
    }

    // Instance variables for each benchmark run
    private ExecutorService service;
    private List<byte[]> list;

    public void runBenchmark(InputStream in) throws IOException
    {
        service = Executors.newFixedThreadPool(NUMBER_OF_CORES);
        list = Collections.synchronizedList(new ArrayList<byte[]>());

        int read;
        byte[] buffer;
        Finder lastFinder = null;

        do {
            buffer = new byte[CHUNK_SIZE];
            read = in.read(buffer);
            if (read > 0) {
                // Only add the read bytes to the list
                list.add(Arrays.copyOf(buffer, read));
            }

            if (read == -1) {
                break;
            }

            Finder finder = new Finder(buffer, read, lastFinder);
            service.execute(finder);
            lastFinder = finder;

        } while (read == CHUNK_SIZE);

        if (lastFinder != null) {
            Status status = lastFinder.finish();
            Mapper mapper = new Mapper(status.lastFinding, status.count - 1, status.lastMapper);
            service.execute(mapper);
        }

        // Wait for all tasks to complete
        service.shutdown();
        try {
            service.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // Reset resources for the next iteration
        service = null;
        list = null;
    }

    // Inner class to hold the status between Finder and Mapper
    private final class Status
    {
        private int count = 0;
        private int lastFinding = 0;
        private Mapper lastMapper = null;
    }

    // Finder class to locate sequence headers
    private final class Finder implements Runnable
    {
        private int size;
        private byte[] a;
        private Status status;
        private Finder previous;
        private boolean done = false;

        public Finder(byte[] a, int size, Finder previous)
        {
            this.a = a;
            this.size = size;
            this.previous = previous;
        }

        public Status finish()
        {
            while (!done) {
                try {
                    Thread.sleep(1);
                } catch (InterruptedException e) {
                    // ignored
                }
            }
            return status;
        }

        public void run()
        {
            LinkedList<Integer> findings = new LinkedList<Integer>();

            for (int i = 0; i < size; i++) {
                if (a[i] == '>') {
                    findings.add(i);
                }
            }

            if (previous == null) {
                status = new Status();
            } else {
                status = previous.finish();
                findings.addFirst(status.lastFinding);
                for (int i = 1; i < findings.size(); i++) {
                    findings.set(i, findings.get(i) + status.count);
                }
            }

            if (findings.size() > 1) {
                for (int i = 0; i < findings.size() - 1; i++) {
                    status.lastMapper = new Mapper(findings.get(i), findings.get(i + 1) - 1, status.lastMapper);
                    service.execute(status.lastMapper);
                }
            }

            status.lastFinding = findings.getLast();
            status.count += size;
            done = true;
        }
    }

    // Mapper class to perform the reverse-complement
    private final class Mapper implements Runnable
    {
        private int end;
        private int start;
        private Mapper previous;
        private boolean done = false;

        public Mapper(int start, int end, Mapper previous)
        {
            this.start = start;
            this.end = end;
            this.previous = previous;
        }

        public void finish()
        {
            while (!done) {
                try {
                    Thread.sleep(1);
                } catch (InterruptedException e) {
                    // ignored
                }
            }
        }

        public void run()
        {
            int[] positions = find(list, start, end);

            int lp1 = positions[0];
            byte[] tob = list.get(lp1);

            int lp2 = positions[2];
            byte[] bot = list.get(lp2);

            int p1 = positions[1];
            while (tob[p1] != '\n') p1++;

            int p2 = positions[3];

            while (lp1 < lp2 || p1 < p2) {
                if (tob[p1] == '\n') {
                    p1++;
                } else if (bot[p2] == '\n') {
                    p2--;
                } else {
                    byte tmp = tob[p1];
                    tob[p1] = map[bot[p2]];
                    bot[p2] = map[tmp];
                    p1++;
                    p2--;
                }
                if (p1 == tob.length) {
                    lp1++;
                    if (lp1 < list.size()) {
                        tob = list.get(lp1);
                        p1 = 0;
                    } else {
                        break;
                    }
                }
                if (p2 == -1) {
                    lp2--;
                    if (lp2 >= 0) {
                        bot = list.get(lp2);
                        p2 = bot.length - 1;
                    } else {
                        break;
                    }
                }
            }

            if (previous != null) {
                previous.finish();
            }

            write(list, positions[0], positions[1], positions[2], positions[3]);
            done = true;
        }
    }

    // Method to write the output
    private void write(List<byte[]> list, int lpStart, int start, int lpEnd, int end)
    {
        byte[] a = list.get(lpStart);
        while (lpStart < lpEnd) {
            System.out.write(a, start, a.length - start);
            lpStart++;
            a = list.get(lpStart);
            start = 0;
        }
        System.out.write(a, start, end - start + 1);
    }

    // Method to find positions in the byte arrays
    private int[] find(List<byte[]> list, int start, int end)
    {
        int n = 0, lp = 0;
        int[] result = new int[4];
        boolean foundStart = false;

        for (byte[] bytes : list) {
            if (!foundStart && n + bytes.length > start) {
                result[0] = lp;
                result[1] = start - n;
                foundStart = true;
            }
            if (foundStart && n + bytes.length > end) {
                result[2] = lp;
                result[3] = end - n;
                break;
            }
            n += bytes.length;
            lp++;
        }
        return result;
    }
}
