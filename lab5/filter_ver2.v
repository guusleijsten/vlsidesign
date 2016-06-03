`timescale 1ns / 1ps

module filter
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 8,
	parameter M = 147,
	parameter M_LOG = 8,
	parameter CWIDTH = 4*L,
	parameter NR_STREAMS = 16,
    parameter NR_STREAMS_LOG = 4)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input [0:DWIDTH-1] data_in,
	output req_out,
	input ack_out,
	output [0:DWIDTH-1] data_out);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
	 
	 reg signed [0:DWIDTH-1] h_in_array [0:CWIDTH];
	 reg signed [0:DWIDTH-1] data_in_array0 [0:3];
	 reg signed [0:DWIDTH-1] data_in_array1 [0:3];
	 reg signed [0:DWIDTH-1] data_in_array2 [0:3];
	 reg signed [0:DWIDTH-1] data_in_array3 [0:3];
	
	
	initial $readmemh ("coeffs.txt", h_in_array);
	
	 reg signed [0:DDWIDTH-1] mul1;
	 reg signed [0:DDWIDTH-1] mul2;
	 reg signed [0:DDWIDTH-1] mul3;
	 reg signed [0:DDWIDTH-1] mul4;
	 reg unsigned [0:15] stream_id;
    // Accumulator (assigned to output directly)
    reg signed [0:DDWIDTH-1] sum;
    assign data_out = sum[0:15];
	 
  
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
				 mul1 <= 0;
				 mul2 <= 0;
				 mul3 <= 0;
				 mul4 <= 0;
				 stream_id <= 0;
            sum <= 0;				
        end
        // !Reset => run
        else begin
		  
            // Read handshake complete
            if (req_in && ack_in) begin
				     // Shift samples
					  data_in_array3[stream_id] <= data_in_array2[stream_id];
					  data_in_array2[stream_id] <= data_in_array1[stream_id];
					  data_in_array1[stream_id] <= data_in_array0[stream_id];
			        // Take new samples at data_in_array0[]
				     data_in_array0[stream_id] <= data_in;
                				              					                					  
            end			   				
				
			   //Read handshake is pending then stop producing output
			  if (req_in && !ack_in) begin  
                h_index0 <= index;
                h_index1 <= h_index0 + 160;	
                h_index2 <= h_index1 + 160;	 
					 h_index3 <= h_index2 + 160;
					 h0 <= h_in_array[h_index0];
					 h1 <= h_in_array[h_index1];
					 h2 <= h_in_array[h_index2];
					 h3 <= h_in_array[h_index3];
                req_out_buf <= 0;
            end 
								
            // Write handshake complete
            if (req_out && ack_out) begin                				   
				   req_in_buf <= 1; 
            end 

            //Write handshake is pending then stop acquiring output.
            if (req_out && !ack_out) begin                			                  
				   req_in_buf <= 0;
            end 			            			  
				
            // Idle state
            if (!req_in && !ack_in && !req_out && !ack_out) begin 
				  
               mul1 <= h0 * data_in_array0[stream_id];	
               mul2 <= h1 * data_in_array1[stream_id];	
               mul3 <= h2 * data_in_array2[stream_id];	
               mul4 <= h3 * data_in_array3[stream_id];	
               sum[stream_id] <= mul1 + mul2 + mul3 + mul4;	
				  
               if(stream_id == 0) begin				 
				         if(index >=L-M) begin  
						       req_in_buf <= 1;	
                         index <= index - 13;						
					      end		
			            else begin
					          //n <= n + 1;
						       //temp <= temp + M;
						       // ToDo : mul with add
						       //index <= (temp) % L;	
					          index <= index + 147;
					      end
              		
                    req_out_buf <= 1;					
            end
				
        end
    end

endmodule
