using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;
using System.Runtime.Intrinsics.X86;
using System.Runtime.Intrinsics;

public static class regexredux {
    const string pathToLib = "../../rapl-interface/target/release/librapl_lib.so";

    // DLL imports
    [DllImport(pathToLib)]
    static extern int start_rapl();

    [DllImport(pathToLib)]
    static extern void stop_rapl();

    static void Main(string[] args) {
        // Read input once at the beginning
        string sequence = Console.In.ReadToEnd();
        int initialLength = sequence.Length;

        // Remove FASTA sequence descriptions and new-lines
        sequence = Regex.Replace(sequence, ">.*\n|\n", "");
        int codeLength = sequence.Length;

        // Number of iterations
        int count = int.Parse(args[0]);

        for (int counter = 0; counter < count; counter++) {
            start_rapl();

            // Parallel substitution task
            Task<int> substitution = Task.Run(() => {
                // regex substitution
                string newseq = Regex.Replace(sequence, "tHa[Nt]", "<4>");
                newseq = Regex.Replace(newseq, "aND|caN|Ha[DS]|WaS", "<3>");
                newseq = Regex.Replace(newseq, "a[NSt]|BY", "<2>");
                newseq = Regex.Replace(newseq, "<[^>]*>", "|");
                newseq = Regex.Replace(newseq, "\\|[^|][^|]*\\|", "-");
                return newseq.Length;
            });

            // Divide sequence into chunks and search each in parallel
            int[][] sums = Chunks(sequence).AsParallel().Select(CountRegexes).ToArray();

            var variants = Variants.variantsCopy();
            for (int i = 0; i < 9; i++)
                Console.WriteLine("{0} {1}", variants[i], sums.Sum(a => a[i]));

            Console.WriteLine("\n{0}\n{1}\n{2}",
                initialLength, codeLength, substitution.Result);

            stop_rapl();
        }
    }

    private static IEnumerable<string> Chunks(string sequence) {
        int numChunks = Environment.ProcessorCount;
        int start = 0;
        int chunkSize = sequence.Length / numChunks;
        while (--numChunks >= 0) {
            if (numChunks > 0)
                yield return sequence.Substring(start, chunkSize);
            else
                yield return sequence.Substring(start);
            start += chunkSize;
        }
    }

    private static int[] CountRegexes(string chunk) {
        // regex match
        int[] counts = new int[9];
        string[] variants = Variants.variantsCopy();

        for (int i = 0; i < 9; i++)
            for (var m = Regex.Match(chunk, variants[i]); m.Success; m = m.NextMatch()) 
                counts[i]++;
        return counts;
    }
}

public class Variants {
    public static string[] variantsCopy() {
        return new string[] {
            "agggtaaa|tttaccct",
            "[cgt]gggtaaa|tttaccc[acg]",
            "a[act]ggtaaa|tttacc[agt]t",
            "ag[act]gtaaa|tttac[agt]ct",
            "agg[act]taaa|ttta[agt]cct",
            "aggg[acg]aaa|ttt[cgt]ccct",
            "agggt[cgt]aa|tt[acg]accct",
            "agggta[cgt]a|t[acg]taccct",
            "agggtaa[cgt]|[acg]ttaccct"
        };
    }
}
