/*
 * The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

 * contributed by Jon Edvardsson
 * added parallel processing to the original
 * program by Anthony Donnefort and Enotus.
 */

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.RecursiveAction;

import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;

public final class program {

    static final ForkJoinPool fjPool = new ForkJoinPool();

    static final byte[] map = new byte[128];
    
    static byte[] inputData = null;

    static {
        String[] mm = {"ACBDGHK\nMNSRUTWVYacbdghkmnsrutwvy",
                       "TGVHCDM\nKNSYAAWBRTGVHCDMKNSYAAWBR"};
        for (int i = 0; i < mm[0].length(); i++)
            map[mm[0].charAt(i)] = (byte) mm[1].charAt(i);
            
        System.loadLibrary("rapl_interface");
    }

    private static class Reverse extends RecursiveAction {
        private byte[] buf;
        private int begin;
        private int end;

        public Reverse(byte[] buf, int begin, int end) {
            this.buf = buf;
            this.begin = begin;
            this.end = end;
        }

        protected void compute() {
            byte[] buf = this.buf;
            int begin = this.begin;
            int end = this.end;

            while (true) {
                byte bb = buf[begin];
                if (bb == '\n')
                    bb = buf[++begin];
                byte be = buf[end];
                if (be == '\n')
                    be = buf[--end];
                if (begin > end)
                    break;
                buf[begin++] = be;
                buf[end--] = bb;
            }
        }
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

        while ((int) start_rapl.invokeExact() > 0) {
            run_benchmark();
            stop_rapl.invokeExact();
        }
    }
    
    private static byte[] readInput(InputStream in) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        int bytesRead;
        while ((bytesRead = in.read(buffer)) != -1) {
            baos.write(buffer, 0, bytesRead);
        }
        return baos.toByteArray();
    }
    
    private static void run_benchmark() throws IOException {
        byte[] buf = inputData.clone();
        
        List<Reverse> tasks = new LinkedList<Reverse>();

        for (int i = 0; i < buf.length; ) {
            while (buf[i++] != '\n') ;
            int data = i;
            byte b;
            while (i < buf.length && (b = buf[i++]) != '>') {
                buf[i-1] = map[b];
            }
            Reverse task = new Reverse(buf, data, i - 2);
            fjPool.execute(task);
            tasks.add(task);
        }
        for (Reverse task : tasks) {
            task.join();
        }

        System.out.write(buf);
    }
}
