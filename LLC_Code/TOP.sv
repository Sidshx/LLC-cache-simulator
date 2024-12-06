`timescale 1ns / 1ps
`include "pkg_line.sv"
`include "pkg_bus.sv"
import pkg_line::*;
import pkg_bus::*;
module LLC_Cache;
  // Define the default trace file name
  string trace_filename = "rwims.din"; 	// changed path
  int file;
  string line;
//Initializing
  set_st cache_mem[NUM_SETS];
  mesi_e fsm_state;

  initial begin
    `ifdef DEBUG
      $display("Working code to read and parse an input trace file (the name of which is specified by the user) with correct default if none specified");
    `endif

    // Check if a custom filename was provided
    if (!$value$plusargs("trace_file=%s", trace_filename)) begin
      `ifdef DEBUG
        $display("No input trace file specified. Using default: %s", trace_filename);
      `endif
    end else begin
      `ifdef DEBUG
        $display("Using input trace file: %s", trace_filename);
      `endif
    end

    // Open the trace file

      file = $fopen(trace_filename, "r");    	// Added else condition 
      if (file) begin
        `ifdef DEBUG
          $display("File opened successfully: %s \n", trace_filename);
        `endif
      end else begin
        $fatal("Error opening file: %s \n", trace_filename);
      end 
	// Set all bits to 0 and MESI to Invalid
      	initialize_cache();
      // Read and parse the file line-by-line
      while (!$feof(file)) begin
        int n;
        bit [31:0] address;
	bit[TAG_SIZE-1 :0] tag;
	bit[INDEX_SIZE-1 :0] index;
	automatic bit match_found = 0;
        // Read a line from the file
        if ($fgets(line, file)) begin
          // Parse the line format "n address" where n is a number and address is a hex
          if ($sscanf(line, "%d %h %h", n, address) == 2) begin
          //  address1 = decode_address(address);
            `ifdef DEBUG
              $display("Parsed: n = %0d, \nAddress: Tag[31:20] = %h, Index[19:6] = %h , Offset[5:0] = %h",
               		n, address[31:20], address[19:6], address[5:0] );
            `endif
	//Address Read from trace file and segregated in tag and index bit
	tag = address[31:20];
	index = address[19:6];

	for (int way_idx = 0; way_idx < 16; way_idx++) begin
		if(cache_mem[index].ways[way_idx].tag == address[31:20]) begin 
		match_found = 1;
		//Cache HIT
		end
	
	end
	if (match_found == 0)begin
		//Cache MISS
	end




            // Process each trace event based on `n` value
            case (n)
              0: $display("Read request from L1 data cache, Address: %h \n", address);
              1: $display("Write request from L1 data cache, Address: %h\n", address);
              2: $display("Read request from L1 instruction cache, Address: %h\n", address);
              3: $display("Snooped read request, Address: %h\n", address);
              4: $display("Snooped write request, Address: %h\n", address);
              5: $display("Snooped read with intent to modify request, Address: %h\n", address);
              6: $display("Snooped invalidate command, Address: %h\n", address);
              8: $display("Clear the cache and reset all state\n");
              9: $display("Print contents and state of each valid cache line (doesn't end simulation!)\n");
              default: $display("Unknown trace event: %d\n", n);
            endcase
          end else begin
            $display("Invalid line format: %s", line);
          end
        end
      end

      // Close the file after reading
      $fclose(file);
      `ifdef DEBUG
        $display("Finished reading from %s.", trace_filename);
      `endif
    
  end

endmodule