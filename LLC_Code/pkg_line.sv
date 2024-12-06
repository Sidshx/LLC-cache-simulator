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
	//bit dirty;
	//bit valid;
	// logic [ADDR_SIZE-1:0] tag_array;
	// wire [C_LINE-1:0] offset;
	// wire [N_WAY-1:0] index;
	logic [TAG_SIZE-1:0] tag;

} line_st;

typedef struct {
    logic [N_WAY-2:0] plru_bits;  // PLRU bits
    line_st ways[N_WAY];  // Array of lines (ways) - this is packed
} set_st;

set_st cache_mem[NUM_SETS];

function automatic bit addr_check (
    ref set_st cache_mem[NUM_SETS],  // Cache memory passed by reference
    input bit [31:0] address,              // Address to check
    output logic[$clog2(N_WAY)-1:0 ] way_idx                     // Way index where match happens
	);

bit [INDEX_SIZE-1:0] index = address[19:6];  // Extract index from the address
    way_idx = 'z;  // Default value when no match is found

    // Loop through the ways in the set
    for (int i = 0; i < 16; i++) begin
        if ((cache_mem[index].ways[i].mesi != I) && 
		(cache_mem[index].ways[i].tag == address[31:20])) begin
            way_idx = i;  // Store the way index where the match occurs
            return 1'b1;   // Return 1 if a match is found
        end
    end

    // If no match found
    return 1'b0;  // Return 0 if no match was found
endfunction: addr_check

// set_st cache[]; // Array of sets

endpackage : pkg_line
 
