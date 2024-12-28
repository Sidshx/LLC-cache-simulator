package pkg_line;

	parameter CACHE_SIZE = 16*1024*1024;
	parameter ADDR_SIZE =32; 
	parameter LINE_SIZE = 64;
	parameter OFFSET_SIZE = $clog2(LINE_SIZE); 
	parameter N_WAY = 16;
	parameter NUM_SETS = CACHE_SIZE / (LINE_SIZE * N_WAY);
	parameter INDEX_SIZE = $clog2(NUM_SETS);
	parameter TAG_SIZE = ADDR_SIZE - OFFSET_SIZE - INDEX_SIZE;
	

	typedef enum bit [1:0] {M = 2'b10, E = 2'b11, S = 2'b01, I = 2'b00} mesi_e;
	
	
	typedef struct packed {
		mesi_e mesi;
		logic [TAG_SIZE-1:0] tag;
	} line_st;
	
	typedef struct {
	    logic [N_WAY-2:0] plru_bits;  // PLRU bits
	    line_st ways[N_WAY];  // Array of lines (ways) - this is packed
	} set_st;
	
	set_st cache_mem[NUM_SETS];

	function automatic bit addr_check (
	    ref set_st cache_mem[NUM_SETS],  // Cache memory passed by reference
	    input bit [ADDR_SIZE-1:0] address,
	    output int way_idx               // Address to check
	);
	
	    bit [INDEX_SIZE-1:0] index = address[OFFSET_SIZE+INDEX_SIZE-1:OFFSET_SIZE];  // Extract index from the address
	    way_idx = 'z;  // Default value when no match is found
	
	    // Loop through the ways in the set
	    for (int i = 0; i < N_WAY; i++) begin
	        if ((cache_mem[index].ways[i].mesi != 0) && 
	            (cache_mem[index].ways[i].tag == address[ADDR_SIZE-1 : ADDR_SIZE-TAG_SIZE])) begin
	            way_idx = i;  // Store the way index where the match occurs
	            return 1'b1;   // Return 1 if a match is found
	        end
	    end
	
	    // If no match found
	    return 1'b0;  // Return 0 if no match was found
	endfunction: addr_check



// IMPLEMENTING COUNTERS TO COUNT THE NUMBER OF CACHE HITS AND MISSES

  int cache_hits = 0;    // Processor cache hits
  int cache_misses = 0;  // Processor cache misses
  int cache_reads = 0;   // Snooping cache hits
  int cache_write = 0; // Snooping cache misses
  real cache_hit_ratio = 0;

	function void hit_ratio();

	$display ("Cache Hit Ratio = %0f ", (real'(cache_hits) / (cache_hits + cache_misses)));

	endfunction : hit_ratio

  // Functions to increment counters
  function void increment_hit();
    cache_hits++;
  endfunction: increment_hit

  function void increment_miss();
    cache_misses++;
  endfunction: increment_miss

  function void increment_read();
    cache_reads++;
  endfunction: increment_read

  function void increment_write();
    cache_write++;
  endfunction: increment_write

// CACHE INITIALISATION TASK
    task initialize_cache();
        for (int i = 0; i < NUM_SETS; i++) begin
            cache_mem[i].plru_bits = 0; 
            for (int j = 0; j < N_WAY; j++) begin
                cache_mem[i].ways[j].tag = 0;
                cache_mem[i].ways[j].mesi = I;

            end
        end
    endtask

endpackage : pkg_line
 
