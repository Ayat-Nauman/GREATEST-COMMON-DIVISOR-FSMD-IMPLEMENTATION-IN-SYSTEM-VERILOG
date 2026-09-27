//The greatest common divisor (GCD) is the largest positive integer that divides 
//evenly into two or more numbers without leaving a remainder

//GCD DATAPATH
module gcd_datapath #(parameter N = 6)(
	// I/O from top module
	input  logic			  clk,
	input  logic			  rst,
	input  logic  [N-1:0]   xi,
	input  logic  [N-1:0]   yi,
	output logic  [N-1:0]  d_o,
	// control signals from FSM
	input  logic 			x_sel,
	input  logic 			y_sel,
	input  logic 			 x_ld,
	input  logic 			 y_ld,
	input  logic 			 d_ld,
	output logic 		  x_lt_y,
	output logic 	    x_neq_y
	
);
logic [N-1:0] x;
logic [N-1:0] y;
logic [N-1:0] d;
logic [N-1:0] y_x;
logic [N-1:0] x_y;
logic [N-1:0] mux1;
logic [N-1:0] mux2;

// Mux 1 to load x or x-y
assign mux1 = (x_sel)? x_y : xi;

// Mux 2 to load y or y-x
assign mux2 = (y_sel)? y_x : yi;

//load x
always_ff @(posedge clk or posedge rst) begin
	if(rst) 
		x <= '0;
	else if(x_ld)
		x <= mux1;
	else 
		x <= x;
end

//load y
always_ff @(posedge clk or posedge rst) begin
	if(rst) 
		y <= '0;
	else if(y_ld)
		y <= mux2;
	else 
		y <= y;
end
	
// x less than y comparator
assign x_lt_y = (x < y)? 1:0;

// x not equal to y comparator
assign x_neq_y = (x != y)? 1:0;

// subtractors 
assign y_x = y - x;
assign x_y = x - y;

//load d
always_ff @(posedge clk or posedge rst) begin
	if(rst) 
		d <= '0;
	else if(d_ld)
		d <= x;
	else 
		d <= d;
end

// Output assignment
assign d_o = d;
endmodule