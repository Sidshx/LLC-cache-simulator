`include "pkg_line.sv"
import pkg_line::*;

module cache (

input logic [ADDR_SIZE-1:0] address,
output logic [INDEX_SIZE-1:0] index,
output logic [TAG_SIZE-1:0] tag
// output line_st cache_line_out

// input line_st mesi,
// input line_st valid,
// input line_st dirty,
// output wire [C_LINE_SIZE-1:0] offset,
);

set_st cache_mem[NUM_SETS];

// assign offset = tag_array[OFFSET_SIZE-1 :0];
    task initialize_cache();
        for (int i = 0; i < NUM_SETS; i++) begin
            cache_mem[i].plru_bits = 0; 
            for (int j = 0; j < N_WAY; j++) begin
                cache_mem[i].ways[j].valid = 0;
                cache_mem[i].ways[j].dirty = 0;
                cache_mem[i].ways[j].tag = 0;
            end
        end
    endtask


assign index = address[OFFSET_SIZE+INDEX_SIZE-1 :OFFSET_SIZE];
assign tag = address[ADDR_SIZE-1 :OFFSET_SIZE+INDEX_SIZE];

//assign cache_line_out = cache_mem[index].ways[0];

endmodule: cache