using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text.Json;
using System.Diagnostics; // for conditional compilation
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
uint[] sortParam = data.ToArray();

// DLL imports
[DllImport(pathToLib)]
static extern int start_rapl();

[DllImport(pathToLib)]
static extern void stop_rapl();

// instantiate sorter
var sorter = new QuickSort<uint>();

// running benchmark
for (int i = 0; i < count; i++)
{
    var toBeSorted = new List<uint>(sortParam).ToArray();
    start_rapl();

    sorter.Sort(toBeSorted);

    stop_rapl();
    
    // stopping compiler optimizations
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
class QuickSort<T> where T : IComparable {
    #region Constants
    public const UInt32 INSERTION_LIMIT_DEFAULT = 12;
    private const Int32 SAMPLES_MAX = 19;
    #endregion

    #region Properties
    public UInt32 InsertionLimit { get; }
    private T[] Samples { get; }
    private Int32 Left { get; set; }
    private Int32 Right { get; set; }
    private Int32 LeftMedian { get; set; }
    private Int32 RightMedian { get; set; }
    #endregion

    #region Constructors
    public QuickSort(UInt32 insertionLimit = INSERTION_LIMIT_DEFAULT) {
      this.InsertionLimit = insertionLimit;
      this.Samples = new T[SAMPLES_MAX];
    }
    #endregion

    #region Sort Methods
    public void Sort(T[] entries) {
      Sort(entries, 0, entries.Length - 1);
    }

    public void Sort(T[] entries, Int32 first, Int32 last) {
      var length = last + 1 - first;
      while (length > 1) {
        if (length < InsertionLimit) {
          InsertionSort<T>.Sort(entries, first, last);
          return;
        }

        Left = first;
        Right = last;
        var median = pivot(entries);
        partition(median, entries);
        //[Note]Right < Left

        var leftLength = Right + 1 - first;
        var rightLength = last + 1 - Left;

        //
        // First recurse over shorter partition, then loop
        // on the longer partition to elide tail recursion.
        //
        if (leftLength < rightLength) {
          Sort(entries, first, Right);
          first = Left;
          length = rightLength;
        }
        else {
          Sort(entries, Left, last);
          last = Right;
          length = leftLength;
        }
      }
    }

    /// <summary>Return an odd sample size proportional to the log of a large interval size.</summary>
    private static Int32 sampleSize(Int32 length, Int32 max = SAMPLES_MAX) {
      var logLen = (Int32)Math.Log10(length);
      var samples = Math.Min(2 * logLen + 1, max);
      return Math.Min(samples, length);
    }

    /// <summary>Estimate the median value of entries[Left:Right]</summary>
    /// <remarks>A sample median is used as an estimate the true median.</remarks>
    private T pivot(T[] entries) {
      var length = Right + 1 - Left;
      var samples = sampleSize(length);
      // Sample Linearly:
      for (var sample = 0; sample < samples; sample++) {
        // Guard against Arithmetic Overflow:
        var index = (Int64)length * sample / samples + Left;
        Samples[sample] = entries[index];
      }

      InsertionSort<T>.Sort(Samples, 0, samples - 1);
      return Samples[samples / 2];
    }

    private void partition(T median, T[] entries) {
      var first = Left;
      var last = Right;
    #if Tripartite
      LeftMedian = first;
      RightMedian = last;
    #endif
      while (true) {
        //[Assert]There exists some index >= Left where entries[index] >= median
        //[Assert]There exists some index <= Right where entries[index] <= median
        // So, there is no need for Left or Right bound checks
        while (median.CompareTo(entries[Left]) > 0) Left++;
        while (median.CompareTo(entries[Right]) < 0) Right--;

        //[Assert]entries[Right] <= median <= entries[Left]
        if (Right <= Left) break;

        Swap(entries, Left, Right);
        swapOut(median, entries);
        Left++;
        Right--;
        //[Assert]entries[first:Left - 1] <= median <= entries[Right + 1:last]
      }

      if (Left == Right) {
        Left++;
        Right--;
      }
      //[Assert]Right < Left
      swapIn(entries, first, last);

      //[Assert]entries[first:Right] <= median <= entries[Left:last]
      //[Assert]entries[Right + 1:Left - 1] == median when non-empty
    }
    #endregion

    #region Swap Methods
    [Conditional("Tripartite")]
    private void swapOut(T median, T[] entries) {
      if (median.CompareTo(entries[Left]) == 0) Swap(entries, LeftMedian++, Left);
      if (median.CompareTo(entries[Right]) == 0) Swap(entries, Right, RightMedian--);
    }

    [Conditional("Tripartite")]
    private void swapIn(T[] entries, Int32 first, Int32 last) {
      // Restore Median entries
      while (first < LeftMedian) Swap(entries, first++, Right--);
      while (RightMedian < last) Swap(entries, Left++, last--);
    }

    /// <summary>Swap entries at the left and right indicies.</summary>
    public void Swap(T[] entries, Int32 left, Int32 right) {
      Swap(ref entries[left], ref entries[right]);
    }

    /// <summary>Swap two entities of type T.</summary>
    public static void Swap(ref T e1, ref T e2) {
      var e = e1;
      e1 = e2;
      e2 = e;
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