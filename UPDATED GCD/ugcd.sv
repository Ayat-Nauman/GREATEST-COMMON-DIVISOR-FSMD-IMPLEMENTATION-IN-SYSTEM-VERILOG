module ugcd #(parameter N = 6)(
	input  logic			  clk,
	input  logic			  rst,
	input  logic  [N-1:0]   xi,
	input  logic  [N-1:0]   yi,
	input  logic			 go_i,
	output logic  [N-1:0]  d_o
);

logic 			x_sel;
logic 			y_sel;
logic 			 x_ld;
logic 			 y_ld;
logic 			 d_ld;
logic 		  x_lt_y;
logic 	    x_neq_y;

//gcd_datapath
gcd_datapath dp(
.clk(clk),
.rst(rst),
.xi(xi),
.yi(yi),
.d_o(d_o),
.x_sel(x_sel),
.y_sel(y_sel),
.x_ld(x_ld),
.y_ld(y_ld),
.d_ld(d_ld),
.x_lt_y(x_lt_y),
.x_neq_y(x_neq_y)
);

//controller_fsm
controller fsm(
.clk(clk),
.rst(rst),
.go_i(go_i),
.x_sel(x_sel),
.y_sel(y_sel),
.x_ld(x_ld),
.y_ld(y_ld),
.d_ld(d_ld),
.x_lt_y(x_lt_y),
.x_neq_y(x_neq_y)
);

endmodule