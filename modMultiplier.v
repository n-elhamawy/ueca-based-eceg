`include "parameters.vh"
module modMultiplier(
    input                       clk,
    input                       enable,
    input  [`DATAWIDTH - 1 : 0] a,
    input  [`DATAWIDTH - 1 : 0] b,    
    output [`DATAWIDTH - 1 : 0] product,
    output                      outReady
    );
    
localparam   [`DATAWIDTH   - 1 : 0] x = (`DATAWIDTH'd1 << (`DATAWIDTH )) - `p;

//Registers
reg [`DATAWIDTH   + 1 : 0]  u;
reg [`DATAWIDTH   - 1 : 0]  result,w,v;
reg [2*`DATAWIDTH + 1 : 0]  y;
reg [1               : 0]  state;
reg                        ready,moduloEnable,start,skip;
integer i;

wire [`DATAWIDTH   - 1 : 0] moduloResult;
wire                        moduloReady;
//FSM states:
localparam IDLE         = 2'b00;
localparam ITERATE      = 2'b01;
localparam CONVERSION   = 2'b10;
localparam OUTPUTREADY  = 2'b11;
    
//FSM block
always @(posedge clk)begin 
case(state)
IDLE:   
        if(start)begin
            if(skip)
                state = OUTPUTREADY;
            state = ITERATE; 
        end 
        else begin
             state = IDLE;
             end
           
ITERATE:    
            if(i < `DATAWIDTH )begin
                state = ITERATE;
            end
            else begin
                state = CONVERSION;
            end

CONVERSION: 
            if(i < `DATAWIDTH )begin
                state = CONVERSION;
            end
            else begin
                state = OUTPUTREADY;
            end
OUTPUTREADY: 
            if(ready == 1'b1)begin
                state = IDLE;
            end

default: state = IDLE;
endcase
end
    
always@(posedge clk)begin
case (state)
IDLE:
    begin // IDLE  state: initialize variables
        if(enable)begin
            i            = 0;
            u            = 'd0;
            w            = a;
            v            = b;
            y            = 'd0;
            ready        = 1'b0;
            moduloEnable = 1'b0;
            start        = 1'b1;
            if( a == 'h0 | b == 'h0)begin
                result = 'h0;
                skip   = 1'b1;
            end    
            else
                skip = 1'b0;
        end
        else
            start = 1'b0;
     end  
ITERATE: 
    begin //ITERATE state: Montgomery Multiplication Algorithm: result is a*b*inverse(2^k) % p
         u = w[i]? u + v : u;
         if(u[0] == 1'b1) begin
            u = u + `p;
         end
         u = u >> 1;
         i = i + 1;
    end 
CONVERSION: 
    begin // CONVERSION state: x = 2^k % p multiplied by c to transform the result back to a*b 
        if(i == `DATAWIDTH)begin
            u  = (u >= `p)? u - `p : u;
            i  = 0; 
        end
        else begin
            y  = x[i]? y + (u << i) : y;
            i  = i + 1;
        end
    end
OUTPUTREADY:
    begin //OUTPUTREADY state: 
          //calculate y mod p then output result with ready signal  
//        if( y > `p)
//        if(!skip)
            if(!moduloEnable )
                moduloEnable = 1'b1;    
            else 
                if(moduloReady)begin
                    result       = moduloResult;
                    moduloEnable = 1'b0;    
                    ready        = 1'b1;
            end         
    end 
endcase  
end

moduloP modP(.clk(clk),.enable(moduloEnable),
             .x(y),.result(moduloResult),.ready(moduloReady));

//Output results   
assign product  = result; 
assign outReady = ready;

endmodule
