using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text.Json;
using System.IO;

// inspired from https://stackoverflow.com/questions/24374658/check-the-operating-system-at-compile-time 
#if _LINUX
    const string pathToLib = @"target/release/librapl_lib.so";
#elif _WINDOWS
    const string pathToLib = @"target\release\rapl_lib.dll";
#else
    const string pathToLib = "none";
#endif

string[] arguments = Environment.GetCommandLineArgs();

uint count = uint.Parse(arguments[1]);

// reading input file
string json = File.ReadAllText(arguments[2]);
List<uint> data = JsonSerializer.Deserialize<List<uint>>(json);

// converting list to array
uint[] mergeParam = data.ToArray();

// DLL imports
[DllImport(pathToLib)]
static extern int start_rapl();

[DllImport(pathToLib)]
static extern void stop_rapl();

// instantiate sorter
var sorter = new MergeSort<uint>();

// running benchmark
for (int i = 0; i < count; i++)
{
    var toBeSorted = new List<uint>(mergeParam).ToArray();
    start_rapl();

    sorter.Sort(toBeSorted);

    stop_rapl();
    
    if (toBeSorted.Length < 42){
        foreach (var item in toBeSorted)
        {
            Console.Write(item + " ");
        }
        Console.WriteLine();
    }
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Rosetta code
public class MergeSort<T> where T : IComparable {
    #region Constants
    public const UInt32 INSERTION_LIMIT_DEFAULT = 12;
    public const Int32 MERGES_DEFAULT = 6;
    #endregion

    #region Properties
    public UInt32 InsertionLimit { get; }
    protected UInt32[] Positions { get; set; }

    private Int32 merges;
    public Int32 Merges {
      get { return merges; }
      set {
        // A minimum of 2 merges are required
        if (value > 1)
          merges = value;
        else
          throw new ArgumentOutOfRangeException($"value = {value} must be greater than one", nameof(Merges));

        if (Positions == null || Positions.Length != merges)
          Positions = new UInt32[merges];
      }
    }
    #endregion

    #region Constructors
    public MergeSort(UInt32 insertionLimit, Int32 merges) {
        InsertionLimit = insertionLimit;
        Merges = merges;
    }

    public MergeSort()
        : this(INSERTION_LIMIT_DEFAULT, MERGES_DEFAULT) {
    }
    #endregion

    #region Sort Methods
    public void Sort(T[] entries) {
      // Allocate merge buffer
        var entries2 = new T[entries.Length];
        Sort(entries, entries2, 0, entries.Length - 1);
    }

    // Top-Down K-way Merge Sort
    public void Sort(T[] entries1, T[] entries2, Int32 first, Int32 last) {
        var length = last + 1 - first;
        if (length < 2) return;      
        if (length < Merges || length < InsertionLimit) {
            InsertionSort<T>.Sort(entries1, first, last);
            return;
        }

        var left = first;
        var size = ceiling(length, Merges);
        for (var remaining = length; remaining > 0; remaining -= size, left += size) {
            var right = left + Math.Min(remaining, size) - 1;
            Sort(entries1, entries2, left, right);
        }

        Merge(entries1, entries2, first, last);
        Array.Copy(entries2, first, entries1, first, length);
    }
    #endregion

    #region Merge Methods
    public void Merge(T[] entries1, T[] entries2, Int32 first, Int32 last) {
        Array.Clear(Positions, 0, Merges);
        // This implementation has a quadratic time dependency on the number of merges
        for (var index = first; index <= last; index++)
            entries2[index] = remove(entries1, first, last);
    }

    private T remove(T[] entries, Int32 first, Int32 last) {
        T entry = default;
        Int32? found = default;
        var length = last + 1 - first;

        var index = 0;
        var left = first;
        var size = ceiling(length, Merges);
        for (var remaining = length; remaining > 0; remaining -= size, left += size, index++) {
            var position = Positions[index];
            if (position < Math.Min(remaining, size)) {
                var next = entries[left + position];
                if (!found.HasValue || entry.CompareTo(next) > 0) {
                    found = index;
                    entry = next;
                }
            }
        }

        // Remove entry
        Positions[found.Value]++;
        return entry;
    }
    #endregion

    #region Math Methods
    private static Int32 ceiling(Int32 numerator, Int32 denominator) {
        return (numerator + denominator - 1) / denominator;
    }
    #endregion
}

    #region Insertion Sort
    static class InsertionSort<T> where T : IComparable {
        public static void Sort(T[] entries, Int32 first, Int32 last) {
            for (var next = first + 1; next <= last; next++)
            insert(entries, first, next);
        }

        /// <summary>Bubble next entry up to its sorted location, assuming entries[first:next - 1] are already sorted.</summary>
        private static void insert(T[] entries, Int32 first, Int32 next) {
            var entry = entries[next];
            while (next > first && entries[next - 1].CompareTo(entry) > 0)
            entries[next] = entries[--next];
            entries[next] = entry;
        }
    }
    #endregion