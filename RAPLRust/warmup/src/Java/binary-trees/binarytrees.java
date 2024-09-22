import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class binarytrees {

    private static final int MIN_DEPTH = 4;

    public static void main(final String[] args) throws Exception {
        var dll_path = System.getProperty("user.dir") + "/../../rapl-interface/target/release/librapl_lib.so";
        System.load(dll_path);

        // Loading functions
        MemorySegment start_rapl_symbol = SymbolLookup.loaderLookup().find("start_rapl").get();
        MethodHandle start_rapl = Linker.nativeLinker().downcallHandle(start_rapl_symbol,
                FunctionDescriptor.of(ValueLayout.JAVA_INT));

        MemorySegment stop_rapl_symbol = SymbolLookup.loaderLookup().find("stop_rapl").get();
        MethodHandle stop_rapl = Linker.nativeLinker().downcallHandle(stop_rapl_symbol,
                FunctionDescriptor.of(ValueLayout.JAVA_INT));

        int count = Integer.parseInt(args[0]);
        for (int counter = 0; counter < count; counter++) {
            try {
                start_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }

            // Initialize ExecutorService inside the loop so it's fresh each iteration
            ExecutorService executorService = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

            int n = 0;
            if (args.length > 1) {
                n = Integer.parseInt(args[1]);
            }

            final int maxDepth = n < (MIN_DEPTH + 2) ? MIN_DEPTH + 2 : n;
            final int stretchDepth = maxDepth + 1;

            System.out.println("stretch tree of depth " + stretchDepth + "\t check: " 
               + bottomUpTree(stretchDepth).itemCheck());

            final TreeNode longLivedTree = bottomUpTree(maxDepth);

            final String[] results = new String[(maxDepth - MIN_DEPTH) / 2 + 1];

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

            // Properly shut down the ExecutorService after tasks are done
            executorService.shutdown();
            executorService.awaitTermination(120L, TimeUnit.SECONDS);

            for (final String str : results) {
                System.out.println(str);
            }

            System.out.println("long lived tree of depth " + maxDepth + 
                "\t check: " + longLivedTree.itemCheck());

            try {
                stop_rapl.invoke();
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
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
}
