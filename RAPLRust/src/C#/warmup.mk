measure: $(TARGET) $(RAPL)
	perf stat --all-cpus -I $(CACHE_MEASURE_FREQ_MS) \
		--append --output cache.txt \
		-e cache-misses,branch-misses,LLC-loads-misses,msr/cpu_thermal_margin/,cpu-clock,cycles \
		-e cstate_core/c3-residency/,cstate_core/c6-residency/,cstate_core/c7-residency/ \
		./$(TARGET) $(COUNT) $(INPUT)
