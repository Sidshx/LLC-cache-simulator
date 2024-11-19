package line;

parameter ADDR_SIZE =32; 
parameter C_LINE_SIZE = 6; 
parameter N_WAY = 16;

typedef enum bit [1:0] {M, E, S, I} mesi_e;

typedef struct packed {
mesi_e mesi;
bit dirty;
reg [ADDR_SIZE-1:0] tag_array;
// wire [C_LINE-1:0] offset;
// wire [N_WAY-1:0] index;
// wire [ADDR_SIZE - C_LINE - N_WAY-1:0] tag;
} line_st;

endpackage
 