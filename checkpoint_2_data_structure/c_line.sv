`include "pkg_line.sv"
import line::*;

module cache (
input line::line_st tag_array,
input line::line_st dirty,
input line::line_st mesi,
output wire [C_LINE_SIZE-1:0] offset,
output wire [N_WAY-1:0] index,
output wire [ADDR_SIZE - C_LINE_SIZE - N_WAY-1:0] tag
);

assign offset = tag_array[C_LINE_SIZE-1 :0];
assign index = tag_array[C_LINE_SIZE+N_WAY-1 :C_LINE_SIZE];
assign tag = tag_array[ADDR_SIZE+C_LINE_SIZE+N_WAY-1 :C_LINE_SIZE+N_WAY];

endmodule: cache