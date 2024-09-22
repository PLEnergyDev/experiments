using CsharpRAPL.Benchmarking.Attributes;
using CsharpRAPL.Benchmarking.Attributes.Parameters;
using CsharpRAPL.Benchmarking.Lifecycles;

using SocketComm;

using System;
using System.IO;
using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.Intrinsics;
using System.Runtime.Intrinsics.X86;
using System.Threading.Tasks;

using static System.Runtime.CompilerServices.MethodImplOptions;

using V256d = System.Runtime.Intrinsics.Vector256<double>;

namespace EnergyTest;

public static unsafe class NativeBenchmarks {
    /* The Computer Language Benchmark Game */
    // ------------------------------------
    private const int MAX_N = 16;
    private static readonly int[] _factorials = new int[MAX_N + 1];
    private static int _n;
    private static int _checksum;
    private static byte _maxFlips;
    private static int _blockCount;
    private static int _blockSize;

    [MethodImpl(MethodImplOptions.AggressiveOptimization)]
    private static void pfannkuchThread() {
        var masks_shift = new Vector128<byte>[16];
        var c0 = Vector128<byte>.Zero;
        var c1 = Vector128.Create((byte)1);
        var ramp = Vector128.Create((byte)0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
        var ramp1 = Sse2.ShiftRightLogical128BitLane(ramp, 1);
        var vX = Sse2.Subtract(c0, ramp);
        var old = ramp;
        for (var x = 0; x < MAX_N; x++) {
            var v2 = Sse41.BlendVariable(vX, ramp, vX);
            var v1 = Sse41.BlendVariable(ramp1, v2, Sse2.Subtract(vX, c1));
            old = Ssse3.Shuffle(old, v1);
            masks_shift[x] = old;
            vX = Sse2.Add(vX, c1);
        }

        var checksum = 0;
        var maxFlips = 0;
        int blockId;
        var n = _n;
        var factorials = _factorials;
        var blockSize = _blockSize;
        while ((blockId = Interlocked.Decrement(ref _blockCount)) >= 0) {
            // First permutation in block
            var next = ramp;
            var i = n;
            var j = blockSize * blockId;
            var countVector = c0;
            var blockLeft = blockSize;
            var mask = Sse2.Subtract(ramp, Vector128.Create((byte)i));
            while (i-- > 0) {
                var d = j / factorials[i];
                j -= d * factorials[i];
                var v2 = Vector128.Create((byte)d);
                countVector = Ssse3.AlignRight(countVector, v2, 15);
                var v1 = Sse2.Add(ramp, v2);
                var v0 = Sse2.Add(mask, v2); // ramp - i + d
                v0 = Sse41.BlendVariable(v0, v1, v0);
                v2 = Ssse3.Shuffle(next, v0);
                next = Sse41.BlendVariable(next, v2, mask);
                mask = Sse2.Add(mask, c1);
            }


            do {
                var current = next;
                var v0 = Sse2.Subtract(countVector, ramp);
                var bits = BitOperations.TrailingZeroCount(Sse2.MoveMask(v0));
                v0 = Vector128.Create((byte)bits);
                var v1 = Sse2.AndNot(Sse2.CompareGreaterThan(v0.AsSByte(), ramp.AsSByte()).AsByte(), countVector);
                countVector = Sse2.Subtract(v1, Sse2.CompareEqual(v0, ramp));
                next = Ssse3.Shuffle(next, masks_shift[bits]);
                var first = Sse2.ConvertToInt32(current.AsInt32());
                {
                    var flips = 0;
                    var v3 = Ssse3.Shuffle(current, c0);
                    while ((first & 0xff) != 0)
                    {
                        v0 = Sse2.Subtract(v3, ramp);
                        v3 = Ssse3.Shuffle(current, v3);
                        v0 = Sse41.BlendVariable(v0, ramp, v0);
                        current = Ssse3.Shuffle(current, v0);
                        flips++;
                        first = Sse2.ConvertToInt32(v3.AsInt32());
                    }

                    checksum += flips;
                    if (flips > maxFlips) maxFlips = flips;
                }

                --blockLeft;
                if (blockLeft == 0) break;
                current = next;
                v0 = Sse2.Subtract(countVector, ramp);
                bits = (byte)BitOperations.TrailingZeroCount(Sse2.MoveMask(v0));
                v0 = Vector128.Create((byte)bits);
                v1 = Sse2.AndNot(Sse2.CompareGreaterThan(v0.AsSByte(), ramp.AsSByte()).AsByte(), countVector);
                countVector = Sse2.Subtract(v1, Sse2.CompareEqual(v0, ramp));
                next = Ssse3.Shuffle(next, masks_shift[bits]);
                first = Sse2.ConvertToInt32(current.AsInt32());
                {
                    var flips = 0;
                    var v3 = Ssse3.Shuffle(current, c0);
                    while ((first & 0xff) != 0)
                    {
                        v0 = Sse2.Subtract(v3, ramp);
                        v3 = Ssse3.Shuffle(current, v3);
                        v0 = Sse41.BlendVariable(v0, ramp, v0);
                        current = Ssse3.Shuffle(current, v0);
                        flips++;
                        first = Sse2.ConvertToInt32(v3.AsInt32());
                    }

                    checksum -= flips;
                    if (flips > maxFlips) maxFlips = flips;
                }

                --blockLeft;
            } while (blockLeft != 0);
        }

        Interlocked.Add(ref _checksum, checksum);
        if (maxFlips > _maxFlips) _maxFlips = (byte)maxFlips;
        if (maxFlips > _maxFlips) _maxFlips = (byte)maxFlips;
    }

    [Benchmark("Native", "Fannkuch-Redux Native", name: "FannkuchRedux", skip: false)]
    [MethodImpl(MethodImplOptions.AggressiveOptimization)]
    public static void FannkuchRedux([BenchmarkLoopiterations] ulong LoopIterations) {
        _n = 12;
        // Start Setup
        var factorials = _factorials;
        factorials[0] = 1;
        var factN = 1;
        for (var x = 0; x < MAX_N;) {
            factN *= ++x;
            factorials[x] = factN;
        }

        // End Setup
        // Thread Setup
        var nThreads = 4;
        var maxBlocks = 96 / 4;
        _blockCount = maxBlocks * nThreads;
        _blockSize = factorials[_n] / _blockCount;
        var threads = new Thread[nThreads];
        for (var i = 1; i < nThreads; i++)
            (threads[i] = new Thread(() => pfannkuchThread()) { IsBackground = true, Priority = ThreadPriority.Highest }).Start();
        Console.Out.Write("");
        pfannkuchThread();
        for (var i = 1; i < threads.Length; i++)
            threads[i].Join();
        Console.Out.WriteLineAsync(_checksum+ "\nPfannkuchen(" + _n + ") = " + _maxFlips);
    }


  [MethodImpl(AggressiveOptimization | AggressiveInlining)]
  private static V256d Square(V256d x)
    => Avx.Multiply(x, x);

  [MethodImpl(AggressiveOptimization | AggressiveInlining)]
  private static V256d Permute2x128AndBlend(V256d t0, V256d t1)
    => Avx.Add(Avx.Permute2x128(t0, t1, 0b10_0001), Avx.Blend(t0, t1, 0b1100));

  [MethodImpl(AggressiveOptimization | AggressiveInlining)][SkipLocalsInit]
  private static void InitDiffs(V256d* positions, V256d* rsqrts) {
    V256d* r = rsqrts, p = positions;
    for (int i = 1, k = 0; i < 5; ++i) {
      V256d pi = p[i];
      for (int j = 0; j < i; ++j, ++k) {
        V256d pj = p[j];
        r[k] = Avx.Subtract(pi, pj);
      }
    }
  }

  [MethodImpl(AggressiveOptimization | AggressiveInlining)][SkipLocalsInit]
  private static V256d FastReciprocalSqRoot(V256d c0375, V256d c1250, V256d c1875, V256d t0, V256d t1) {
    V256d s = Permute2x128AndBlend(t0, t1);
    V256d x = Avx.ConvertToVector256Double(Sse.ReciprocalSqrt(Avx.ConvertToVector128Single(s)));
    V256d y = Avx.Multiply(s, Avx.Multiply(x, x));
    V256d y0 = Avx.Multiply(Avx.Multiply(y, c0375), y);
    V256d y1 = Avx.Subtract(Avx.Multiply(y, c1250), c1875);
    return Avx.Multiply(x, Avx.Subtract(y0, y1));
  }


  [MethodImpl(AggressiveOptimization)][SkipLocalsInit]
  static void Advance(int iterations, double dt, V256d* masses, V256d* positions, V256d* velocities) {
    unchecked {
      V256d* v = velocities, p = positions, m = masses;
      V256d step = Vector256.Create(dt);
      V256d c0375 = Vector256.Create(0.375);
      V256d c1250 = Vector256.Create(1.25);
      V256d c1875 = Vector256.Create(1.875);
      V256d* r = stackalloc V256d[14];
      // Align the memory (C# doesn't have a built in way AFAIK) to prevent fault when calling Avx.LoadAlignedVector256 or Avx.StoreAligned
      r = (V256d*)((((UInt64)r)+31UL)&~31UL);
      double* w = (double*)(r+10);
    ADVANCE:
      InitDiffs(p, r);
      CalcStepDistances(step, c0375, c1250, c1875, r, r+10);
      CalcNewVelocities(v, m, r, w);
      CalcNewPositions(step, p, v);
      --iterations;
      if (iterations > 0) { goto ADVANCE; }


      [MethodImpl(AggressiveOptimization | AggressiveInlining)][SkipLocalsInit]
      static void CalcStepDistances(V256d step, V256d c0375, V256d c1250, V256d c1875, V256d* r, V256d* w) {
        w[0] = TimeAdjust(step, FastReciprocalSqRoot(c0375, c1250, c1875, Avx.HorizontalAdd(Square(r[0]), Square(r[1])), Avx.HorizontalAdd(Square(r[2]), Square(r[3]))));
        w[1] = TimeAdjust(step, FastReciprocalSqRoot(c0375, c1250, c1875, Avx.HorizontalAdd(Square(r[4]), Square(r[5])), Avx.HorizontalAdd(Square(r[6]), Square(r[7]))));
        w[2] = TimeAdjust(step, FastReciprocalSqRoot(c0375, c1250, c1875, Avx.HorizontalAdd(Square(r[8]), Square(r[9])), V256d.Zero));

        [MethodImpl(AggressiveOptimization | AggressiveInlining)][SkipLocalsInit]
        static V256d TimeAdjust(V256d rt, V256d x) => Avx.Multiply(Avx.Multiply(x, x), Avx.Multiply(x, rt));
      }

      [MethodImpl(AggressiveOptimization | AggressiveInlining)][SkipLocalsInit]
      static void CalcNewVelocities(V256d* v, V256d* m, V256d* r, double* w) {
        for (int i = 1; i < 5; ++i) {
          V256d iV = v[i];
          V256d iM = m[i];
          for (int j = 0; j < i; ++j) {
            V256d kW = Avx.BroadcastScalarToVector256(w);
            ++w;
            V256d kR = r[0];
            ++r;
            V256d jM = m[j];
            V256d jV = v[j];
            V256d t = Avx.Multiply(kR, kW);
            V256d jM_t = Avx.Multiply(jM, t);
            V256d iM_t = Avx.Multiply(iM, t);
            iV = Avx.Subtract(iV, jM_t);
            v[j] = Avx.Add(jV, iM_t);
          }
          v[i] = iV;
        }
      }

      [MethodImpl(AggressiveOptimization | AggressiveInlining)][SkipLocalsInit]
      static void CalcNewPositions(V256d step, V256d* p, V256d* v) {
        for (int i = 0; i < 5; ++i) {
          V256d iP = p[i];
          V256d iV = v[i];
          p[i] = Avx.Add(iP, Avx.Multiply(iV, step));
        }
      }
    }
  }

  [SkipLocalsInit]
  static double Energy(double* m, V256d* p, V256d* v) {
    unchecked {
      double e = SumComponents256(
        Avx.Multiply(
          Avx.Multiply(
            Permute2x128AndBlend(
              Avx.HorizontalAdd(Square(v[0]), Square(v[1])),
              Avx.HorizontalAdd(Square(v[2]), Square(v[3]))),
            Avx.LoadAlignedVector256(m)),
          Vector256.Create(0.5)))
        + Permute2x128AndBlend(Avx.HorizontalAdd(Square(v[4]), V256d.Zero), V256d.Zero).GetElement(0) * m[4] * 0.5;


      V256d* r = stackalloc V256d[14];
      // Align the memory (C# doesn't have a built in way AFAIK) to prevent fault when calling Avx.LoadAlignedVector256 or Avx.StoreAligned
      r = (V256d*)((((UInt64)r)+31UL)&~31UL);
      InitDiffs(p, r);

      V256d c0375 = Vector256.Create(0.375), c1250 = Vector256.Create(1.25), c1875 = Vector256.Create(1.875);
      r[10] = FastReciprocalSqRoot(c0375, c1250, c1875, Avx.HorizontalAdd(Square(r[0]), Square(r[1])), Avx.HorizontalAdd(Square(r[2]), Square(r[3])));
      r[11] = FastReciprocalSqRoot(c0375, c1250, c1875, Avx.HorizontalAdd(Square(r[4]), Square(r[5])), Avx.HorizontalAdd(Square(r[6]), Square(r[7])));
      r[12] = FastReciprocalSqRoot(c0375, c1250, c1875, Avx.HorizontalAdd(Square(r[8]), Square(r[9])), V256d.Zero);

      double* w = (double*)(r+10);
      for (int i = 1; i < 5; ++i) {
        double iMass = m[i];
        for (int j = 0; j < i; ++j, ++w) {
          e = e - (iMass * m[j] * w[0]);
        }
      }
      return e;

      [MethodImpl(AggressiveOptimization | AggressiveInlining)]
      static double SumComponents128(Vector128<double> x) => x.GetElement(1) + x.GetElement(0);
      [MethodImpl(AggressiveOptimization | AggressiveInlining)]
      static double SumComponents256(V256d x) => SumComponents128(Avx.Add(x.GetLower(), x.GetUpper()));
    }
  }

  [Benchmark("Native", "N-Body Native", name: "NBody", skip: false)]
  [SkipLocalsInit]
  public static void NBody([BenchmarkLoopiterations] ulong LoopIterations) {
    int iterations = 50000000;
    if (iterations <= 0) { return; }

    V256d* mem = stackalloc V256d[18];
    // Align the memory (C# doesn't have a built in way AFAIK) to prevent fault when calling Avx.LoadAlignedVector256 or Avx.StoreAligned
    mem = (V256d*)((((UInt64)mem)+31UL)&~31UL);

    InitSystem(mem, out V256d* m, out V256d* p, out V256d* v);

    Console.WriteLine(Energy((double*)mem, p, v).ToString("F9"));

    Advance(iterations, 0.01, m, p, v);

    Console.WriteLine(Energy((double*)mem, p, v).ToString("F9"));


    [SkipLocalsInit]
    static void InitSystem(V256d* mem, out V256d* m, out V256d* p, out V256d* v) {
      const double PI = 3.141592653589793;
      const double SOLAR_MASS = (4 * PI * PI);
      const double DAYS_PER_YEAR = 365.24;

      double* masses = (double*)mem;

      masses[0] = SOLAR_MASS;
      masses[1] = 9.54791938424326609e-04 * SOLAR_MASS;
      masses[2] = 2.85885980666130812e-04 * SOLAR_MASS;
      masses[3] = 4.36624404335156298e-05 * SOLAR_MASS;
      masses[4] = 5.15138902046611451e-05 * SOLAR_MASS;

      m = mem + 2;
      for (int i = 0; i < 5; ++i) { m[i] = Vector256.Create(masses[i]); }

      // positions
      p = mem + 7;
      p[0] = V256d.Zero;
      p[1] = Vector256.Create(0.0, 4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01);
      p[2] = Vector256.Create(0.0, 8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01);
      p[3] = Vector256.Create(0.0, 1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01);
      p[4] = Vector256.Create(0.0, 1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01);

      // velocities
      v = mem + 12;
      //v[0] = Vector256.Create(-1.0);
      v[1] = Vector256.Create(0.0, 1.66007664274403694e-03 * DAYS_PER_YEAR, 7.69901118419740425e-03 * DAYS_PER_YEAR, -6.90460016972063023e-05 * DAYS_PER_YEAR);
      v[2] = Vector256.Create(0.0, -2.76742510726862411e-03 * DAYS_PER_YEAR, 4.99852801234917238e-03 * DAYS_PER_YEAR, 2.30417297573763929e-05 * DAYS_PER_YEAR);
      v[3] = Vector256.Create(0.0, 2.96460137564761618e-03 * DAYS_PER_YEAR, 2.37847173959480950e-03 * DAYS_PER_YEAR, -2.96589568540237556e-05 * DAYS_PER_YEAR);
      v[4] = Vector256.Create(0.0, 2.68067772490389322e-03 * DAYS_PER_YEAR, 1.62824170038242295e-03 * DAYS_PER_YEAR, -9.51592254519715870e-05 * DAYS_PER_YEAR);

      // Offset Momentmum
      v[0] = Avx.Divide(Avx.Add(Avx.Add(Avx.Add(Avx.Multiply(v[1], m[1]),
                                                Avx.Multiply(v[2], m[2])),
                                        Avx.Multiply(v[3], m[3])),
                                Avx.Multiply(v[4], m[4])),
                        Avx.Multiply(Vector256.Create(-1.0), m[0]));
    }
  }
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    private static double A(int i, int j)
    {
        return (i + j) * (i + j + 1) / 2 + i + 1;
    }

    private static double dot(double* v, double* u, int n)
    {
        double sum = 0;
        for (var i = 0; i < n; i++)
            sum += v[i] * u[i];
        return sum;
    }

    [MethodImpl(MethodImplOptions.AggressiveOptimization)]
    private static void mult_Av(double* v, double* outv, int n)
    {
        Parallel.For(0, n, i =>
        {
            var sum = Vector128<double>.Zero;
            for (var j = 0; j < n; j += 2)
            {
                var b = Sse2.LoadVector128(v + j);
                var a = Vector128.Create(A(i, j), A(i, j + 1));
                sum = Sse2.Add(sum, Sse2.Divide(b, a));
            }

            var add = Sse3.HorizontalAdd(sum, sum);
            var value = Unsafe.As<Vector128<double>, double>(ref add);
            Unsafe.WriteUnaligned(outv + i, value);
        });
    }

    [MethodImpl(MethodImplOptions.AggressiveOptimization)]
    private static void mult_Atv(double* v, double* outv, int n)
    {
        Parallel.For(0, n, i =>
        {
            var sum = Vector128<double>.Zero;
            for (var j = 0; j < n; j += 2)
            {
                var b = Sse2.LoadVector128(v + j);
                var a = Vector128.Create(A(j, i), A(j + 1, i));
                sum = Sse2.Add(sum, Sse2.Divide(b, a));
            }

            var add = Sse3.HorizontalAdd(sum, sum);
            var value = Unsafe.As<Vector128<double>, double>(ref add);
            Unsafe.WriteUnaligned(outv + i, value);
        });
    }

    private static void mult_AtAv(double* v, double* outv, int n)
    {
        fixed (double* tmp = new double[n])
        {
            mult_Av(v, tmp, n);
            mult_Atv(tmp, outv, n);
        }
    }

    [Benchmark("Native", "Spectral-Norm Native", name: "SpectralNorm", skip: false)]
    public static void SpectralNorm([BenchmarkLoopiterations] ulong LoopIterations)
    {
        int n = 7000;
        fixed (double* u = new double[n])
        fixed (double* v = new double[n])
        {
            new Span<double>(u, n).Fill(1);
            for (var i = 0; i < 10; i++)
            {
                mult_AtAv(u, v, n);
                mult_AtAv(v, u, n);
            }

            var result = Math.Sqrt(dot(u, v, n) / dot(v, v, n));
            Console.WriteLine("{0:f9}", result);
        }
    }
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static unsafe byte GetByte(double* pCrb, double Ciby)
    {
        var res = 0;
        for (var i=0; i<8; i+=2)
        {
            var vCrbx = Unsafe.Read<Vector<double>>(pCrb+i);
            var vCiby = new Vector<double>(Ciby);
            var Zr = vCrbx;
            var Zi = vCiby;
            int b = 0, j = 49;
            do
            {
                for (int counter = 0; counter < 7; counter++)
                {
                    var nZr = Zr * Zr - Zi * Zi + vCrbx;
                    var ZrZi = Zr * Zi;
                    Zi = ZrZi + ZrZi + vCiby;
                    Zr = nZr;
                    j--;
                }

                var t = Zr * Zr + Zi * Zi;
                if (t[0]>4.0) { b|=2; if (b==3) break; }
                if (t[1]>4.0) { b|=1; if (b==3) break; }
            } while (j>0);
            res = (res << 2) + b;
        }
        return (byte)(res^-1);
    }

    public static unsafe void MainOld(int size)
    {
        Console.Out.WriteAsync(String.Concat("P4\n",size," ",size,"\n"));
        var Crb = new double[size+2];
        var lineLength = size >> 3;
        var data = new byte[size * lineLength];
        fixed (double* pCrb = &Crb[0])
        fixed (byte* pdata = &data[0])
        {
            var value = new Vector<double>(
                  new double[] {0,1,0,0,0,0,0,0}
            );
            var invN = new Vector<double>(2.0/size);
            var onePtFive = new Vector<double>(1.5);
            var step = new Vector<double>(2);
            for (var i=0; i<size; i+=2)
            {
                Unsafe.Write(pCrb+i, value*invN-onePtFive);
                value += step;
            }
            var _Crb = pCrb;
            var _pdata = pdata;
            Parallel.For(0, size, y =>
            {
                var Ciby = _Crb[y]+0.5;
                for (var x=0; x<lineLength; x++)
                {
                    _pdata[y*lineLength+x] = GetByte(_Crb+x*8, Ciby);
                }
            });
            Console.OpenStandardOutput().Write(data, 0, data.Length);
        }
    }

    // x86 version, AVX2
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static byte Process8(double x, double y, double dx)
    {
        // initial x coords
        var x01 = Vector256.Create(x+0*dx,x+1*dx,x+2*dx,x+3*dx);
        var x02 = Vector256.Create(x+4*dx,x+5*dx,x+6*dx,x+7*dx);
        
        // initial y coords
        var y0  = Vector256.Create(y); 
        
        Vector256<double> x1 = x01,y1 = y0; // current iteration 1
        Vector256<double> x2 = x02,y2 = y0; // current iteration 2

        Vector256<double> four = Vector256.Create(4.0); // 4 in each slot        

        var pass = 0;

        // temp space, C# requires init.
        Vector256<double> 
            x12=Vector256<double>.Zero,
            y12=Vector256<double>.Zero,
            x22=Vector256<double>.Zero,
            y22=Vector256<double>.Zero;

        // bit masks for results
        uint res1=1,res2=1;

        while (pass < 49 && (res1 != 0 || res2 != 0))
        {

            // do several between checks a time like other code
            for (var p = 0 ; p < 7; ++p)
            {
                // unroll loop 2x to decrease register stalls

                // squares x*x and y*y
                x12 = Avx2.Multiply(x1,x1);
                y12 = Avx2.Multiply(y1,y1);
                x22 = Avx2.Multiply(x2,x2);
                y22 = Avx2.Multiply(y2,y2);

                // mixed products x*y
                var xy1 = Avx2.Multiply(x1, y1);
                var xy2 = Avx2.Multiply(x2, y2);

                // diff of squares x*x - y*y
                var ds1 = Avx2.Subtract(x12, y12);
                var ds2 = Avx2.Subtract(x22, y22);

                // 2*x*y
                xy1 = Avx2.Add(xy1, xy1);
                xy2 = Avx2.Add(xy2, xy2);

                // next iters
                y1 = Avx2.Add(xy1, y0);
                y2 = Avx2.Add(xy2, y0);
                x1 = Avx2.Add(ds1, x01);
                x2 = Avx2.Add(ds2, x02);
            }
            pass+=7;

            // numbers overflow, which gives an Infinity or NaN, which, 
            // when compared N < 4, results in false, which is what we want

            // sum of squares x*x + y*y, compare to 4 (escape mandelbrot)
            var ss1  = Avx2.Add(x12, y12);
            var ss2  = Avx2.Add(x22, y22);

            // compare - puts all 0 in reg if false, else all 1 (=NaN bitwise)
            // when each register is 0, then all points escaped, so exit
            var cmp1 = Avx.Compare(ss1,four,
                    FloatComparisonMode.OrderedLessThanOrEqualNonSignaling);
            var cmp2 = Avx.Compare(ss2,four,
                    FloatComparisonMode.OrderedLessThanOrEqualNonSignaling);

            // take top bit from each byte
            res1 = (uint)Avx2.MoveMask(Vector256.AsByte(cmp1));
            res2 = (uint)Avx2.MoveMask(Vector256.AsByte(cmp2));
        }        

        // can make a mask of bits in any order, which is the +7, +6, .., +1, +0
        res1 &= 
            (1<<( 0+7)) |
            (1<<( 8+6)) |
            (1<<(16+5)) |
            (1<<(24+4));
        res2 &= 
            (1<<( 0+3)) |
            (1<<( 8+2)) |
            (1<<(16+1)) |
            (1<<(24+0));

        var res = res1|res2;
        res |= res>>16;
        res |= res>>8;
        return (byte)(res);
    }

    static void Test(byte [] data)
    {
        var filename = "mandelbrot-output.txt";
        if (!File.Exists(filename))
        {
            System.Console.WriteLine($"Cannot open file {filename}");
            return;
        }
        var len = data.Length;
        var truth = File.ReadAllBytes(filename);
        Array.Copy(truth,truth.Length-len,truth,0,len);
        for (var i = 0; i < len; ++i)
        {
            if (data[i] != truth[i])
            {
                var bits = data[i]^truth[i];
                System.Console.Write($"ERROR: Mismatch {i}: {data[i]:X2} != {truth[i]:X2}, ^={bits:X2},");
                var x = ((i*8)%200);
                var y = (i*8)/200;
                while (bits != 0)
                {
                    if ((bits&1) != 0)
                        System.Console.Write($"({x},{y}), ");
                    ++x;
                    bits>>=1;                    
                }
                System.Console.WriteLine();

            }
        }

    }

    static byte Process8a(double x0_, double y0, double delta)
    {
        var ans = 0;
        for (var bit = 0; bit < 8; ++bit)
        {

            var x0 = x0_+delta*bit;
            double x1 = x0, y1 = y0;
            for (var pass = 0; pass < 49; ++pass)
            {
                var xt = x1*x1-y1*y1+x0;
                y1 = 2*x1*y1+y0;
                x1 = xt;
            }
            ans <<= 1;
            if (x1*x1 + y1*y1 <= 4.0)
                ans |= 1;
            x0 += delta;
        }
        return (byte)ans;
    }

    public static void MainNew(int size)
    {
        Console.Out.WriteAsync(String.Concat("P4\n",size," ",size,"\n"));
        var lineLength = size >> 3;
        var data = new byte[size * lineLength];

        // step size
        var delta = 2.0/size; // (0.5 - (-1.5))/size;

        Parallel.For(0, size, y =>
        {
            var yd = y*delta-1;
            for (var x=0; x<lineLength; x++)
            {
                var xd = (x*8)*delta-1.5;
                data[y*lineLength+x] = Process8(xd,yd,delta);
            }
        }
        );
        //if (size == 200)
        //    Test(data);
        Console.OpenStandardOutput().Write(data, 0, data.Length);
    }


    [Benchmark("Native", "Mandelbrot Native", name: "Mandelbrot", skip: false)]
    public static void Mandelbrot([BenchmarkLoopiterations] ulong LoopIterations)
    {
        int size = 16000;
        if (System.Runtime.Intrinsics.X86.Avx2.IsSupported)
            MainNew(size);
        else
            MainOld(size);
    }

    /* The Computer Language Benchmark Game */
    // ------------------------------------

    /* Peter Sestoft */
    // -------------
    [Benchmark("Native", "Division Intensive Loop Native",
    name: "DivisionLoop", skip: false)]
    public static double DivisionLoop([BenchmarkLoopiterations] ulong LoopIterations) {
        int M = 22;
        double sum = 0.0;
        int n = 0;
        while (sum < M) {
            n++;
            sum += 1.0 / n;
        }
        return sum;
    }

    static double[,] InitMatrix(int rows, int cols) {
        double[,] m = new double[rows, cols];
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                m[i, j] = i + j;
            }
        }
        return m;
    }

    [Benchmark("Native", "Matrix Multiplication Native",
    name: "MatrixMultiplicationU", skip: false)]
    public static double MatrixMultiplication([BenchmarkLoopiterations] ulong LoopIterations) {
        int rows = 80, cols = 80;
        double[,] R = new double[rows, cols];
        double[,] A = InitMatrix(rows, cols);
        double[,] B = InitMatrix(rows, cols);

        // Maintaining consistency with "Numeric performance in C, C# and Java"
        // by Peter Sestoft
        int aCols = A.GetLength(1);
        int rRows = R.GetLength(0);
        int rCols = R.GetLength(1);

        double sum = 0.0;
        for (int r = 0; r < rRows; r++) {
            for (int c = 0; c < rCols; c++) {
                sum = 0.0;
                for (int k = 0; k < aCols; k++) {
                    sum += A[r, k] * B[k, c];
                }
                R[r, c] = sum;
            }
        }
        return sum;
    }

    [Benchmark("Native", "Matrix Multiplication Unsafe Native",
    name: "MatrixMultiplicationUnsafe", skip: false)]
    public static double MatrixMultiplicationUnsafe([BenchmarkLoopiterations] ulong LoopIterations) {
        int rows = 80, cols = 80;
        double[,] R = new double[rows, cols];
        double[,] A = InitMatrix(rows, cols);
        double[,] B = InitMatrix(rows, cols);

        // Maintaining consistency with "Numeric performance in C, C# and Java"
        // by Peter Sestoft
        int aCols = A.GetLength(1);
        int bCols = B.GetLength(1);
        int rRows = R.GetLength(0);
        int rCols = R.GetLength(1);

        double sum = 0.0;
        for (int r = 0; r < rRows; r++) {
            for (int c = 0; c < rCols; c++) {
                sum = 0.0;
                unsafe {
                    fixed (double* abase = &A[r, 0], bbase = &B[0, c]) {
                        for (int k = 0; k < aCols; k++) {
                            sum += abase[k] * bbase[k*bCols];
                        }
                    }
                }
                R[r, c] = sum;
            }
        }
        return sum;
    }

    static double[] InitCS(int n) {
        double[] cs = new double[n];
        for (int i = 0; i < n; i++) {
            cs[i] = 1.1 * i;
            if (i % 3 == 0) {
                cs[i] *= -1;
            }
        }

        return cs;
    }

    [Benchmark("Native", "Polynomial Evaluation",
    name: "PolynomialEvaluation", skip: false)]
    public static double PolynomialEvaluation([BenchmarkLoopiterations] ulong LoopIterations) {
        int n = 10000;
        double[] cs = InitCS(n);
        double res = 0.0;

        for (int i = 0; i < n; i++) {
            res = cs[i] + 5.0 * res;
        }

        return res;
    }
    /* Peter Sestoft */
    // -------------
}
