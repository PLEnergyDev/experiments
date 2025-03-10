/**
 * The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * based on Jarkko Miettinen's Java program
 * contributed by Tristan Dupont
 * *reset*
 */

import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class program {
    private static final int MIN_DEPTH = 4;
    private static int maxDepth;
    private static int stretchDepth;
    private static TreeNode longLivedTree;
    private static String[] results;
    private static ExecutorService executorService;

    public static void initialize(int n) {
        maxDepth = n < (MIN_DEPTH + 2) ? MIN_DEPTH + 2 : n;
        stretchDepth = maxDepth + 1;
        executorService = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
    }

    public static void run_benchmark() throws Exception {
        System.out.println("stretch tree of depth " + stretchDepth + "\t check: "
            + bottomUpTree(stretchDepth).itemCheck());

        longLivedTree = bottomUpTree(maxDepth);

        results = new String[(maxDepth - MIN_DEPTH) / 2 + 1];

        for (int d = MIN_DEPTH; d <= maxDepth; d += 2) {
            final int depth = d;
            executorService.execute(() -> {
                int check = 0;

                final int iterations = 1 << (maxDepth - depth + MIN_DEPTH);
                for (int i = 1; i <= iterations; ++i) {
                    final TreeNode treeNode1 = bottomUpTree(depth);
                    check += treeNode1.itemCheck();
                }
                results[(depth - MIN_DEPTH) / 2] =
                    iterations + "\t trees of depth " + depth + "\t check: " + check;
            });
        }

        executorService.shutdown();
        executorService.awaitTermination(120L, TimeUnit.SECONDS);

        for (final String str : results) {
            System.out.println(str);
        }

        System.out.println("long lived tree of depth " + maxDepth +
            "\t check: " + longLivedTree.itemCheck());
    }

    public static void cleanup() {
        executorService = null;
        longLivedTree = null;
        results = null;
    }

    private static TreeNode bottomUpTree(final int depth) {
        if (0 < depth) {
            return new TreeNode(bottomUpTree(depth - 1), bottomUpTree(depth - 1));
        }
        return new TreeNode();
    }

    private static final class TreeNode {

        private final TreeNode left;
        private final TreeNode right;

        private TreeNode(final TreeNode left, final TreeNode right) {
            this.left = left;
            this.right = right;
        }

        private TreeNode() {
            this(null, null);
        }

        private int itemCheck() {
            if (null == left) {
                return 1;
            }
            return 1 + left.itemCheck() + right.itemCheck();
        }

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

        int n = Integer.parseInt(args[0]);

        while (true) {
            initialize(n);
            if ((int) start_rapl.invokeExact() == 0) {
                break;
            }
            run_benchmark();
            stop_rapl.invokeExact();
            cleanup();            
        }
    }
}
