`include "pkg_line.sv"
import pkg_line::*;

module cache (
input logic clk,
input logic rst,
input logic [ADDR_SIZE-1:0] address,
input logic read_req,
input logic write_req,
input logic invalidate,
output logic [INDEX_SIZE-1:0] index,
output logic [TAG_SIZE-1:0] tag
);

set_st cache_mem[NUM_SETS];
mesi_e fsm_state;

assign index = address[OFFSET_SIZE+INDEX_SIZE-1 :OFFSET_SIZE];
assign tag = address[ADDR_SIZE-1 :OFFSET_SIZE+INDEX_SIZE];
logic copy = 1;
// Instantiate the MESI FSM
    mesi_upd mesi_inst (
        .clk(clk),
        .rst(rst),
        .operation(),//thoth.cecs.pdx.edu/Home07/patilsid/My Documents/LLC/LLC_Cache_G11/LLC_Code/pkg_bus.sv
	.copy(copy),
        .address(address),
        .cache_mem(cache_mem), // Pass cache_mem here
        .current_state(fsm_state)
    );
// CACHE INITIALISATION TASK
    task initialize_cache();
        for (int i = 0; i < NUM_SETS; i++) begin
            cache_mem[i].plru_bits = 0; 
            for (int j = 0; j < N_WAY; j++) begin
               // cache_mem[i].ways[j].valid = 0;
              //  cache_mem[i].ways[j].dirty = 0;
                cache_mem[i].ways[j].tag = 0;
                cache_mem[i].ways[j].mesi = I;

            end
        end
    endtask

endmodule: cache
