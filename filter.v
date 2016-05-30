`timescale 1ns / 1ps

module filter
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 8,
	parameter M = 147,
	parameter M_LOG = 8,
	parameter CWIDTH = 4*L)
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
	//Accumulator (assigned to output directly)
	
	reg signed [0:DWIDTH-1] h_in_array [0:CWIDTH];
	
	
	initial $readmemh ("coeffs.txt", h_in_array);
	
	reg signed [0:DWIDTH-1] data_in_array [0:3];
	
	reg signed [0:DDWIDTH-1] sum;

	reg signed [0:DDWIDTH-1] mul;
	assign data_out = sum[0:15];

	reg unsigned [0:2] counter;

	reg unsigned [0:9] index;
   reg unsigned [0:15] n;
	reg unsigned [0:9] h_index;
	integer k;
	
	always @(posedge clk) begin
		// Reset State => initialize
		if (rst) begin 
			req_in_buf <= 1; // go the input stage 
			req_out_buf <= 0;
			counter <=0;
			index<=0;
			h_index <=0;
			sum <= 0;
			mul<=0;
			n<=0;
		
			
		end
	
		else begin
			
			// Input state, shift inputs take new input 
			if (req_in && ack_in) begin	
				
				for (k=3; k>0; k=k-1) begin
					data_in_array[k] <= data_in_array[k-1];
				end
				
				data_in_array[0] <= data_in;	
				req_in_buf <= 0;			
			end
						
			
			if (req_out && ack_out) begin
				req_out_buf <= 0;
				sum<=0;
				h_index<=index;
			end
			
			if (!req_in && !req_out && !ack_in && !ack_out) begin 
			    
				if(counter==4) begin
				    counter <=0;
					if(index >=L-M) begin  
					 //  index <= index - 13;
						req_in_buf <= 1;					
					end		
			     // else begin
					   n <= n + 1;
						// ToDo : mul with add
						index <= (n*M) % L;	
                  						
				//	end
					req_out_buf <= 1; 
				end
            else if (	counter < 4	) begin		
				    
					mul<=h_in_array[h_index]*data_in_array[counter];
					sum <= sum + mul;
					counter<=counter+1;
					h_index <=h_index+160; 
					
				end	
			end
		end
	end
endmodule