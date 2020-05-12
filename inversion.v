`include "parameters.vh"
module inversion(
    input                       clk,
    input                       enable,
    input  [`DATAWIDTH - 1 : 0] x,
    output [`DATAWIDTH - 1 : 0] inverse,
    output                      outReady
    );

reg   [             1   : 0] state;    
reg                          divisionEnable,multiplyEnable,start,resultReady,finishedD,finishedM,finished;    
reg   [`DATAWIDTH - 1   : 0] q,r,s,t; 
reg   [`DATAWIDTH       : 0] ns,nt,nr,result;        

wire   [`DATAWIDTH - 1     : 0] quotient,remainder;
wire   [2*`DATAWIDTH - 1   : 0] product; 
wire                         divisionReady,multiplyReady; 

localparam IDLE      = 2'b00;
localparam CALCULATE = 2'b01;
localparam UPDATE    = 2'b10;
localparam READY     = 2'b11;

always @(posedge clk) begin
case (state)
IDLE:
    if(start)
        state = CALCULATE;
CALCULATE:
    if(finished)
        if(r == 1)
         state = READY;
       else
        state = UPDATE;  
UPDATE:
        state = CALCULATE;    
READY:
    state = IDLE;
default: state = IDLE;
endcase
end


always @(posedge clk) begin
case (state)
IDLE:
    if(enable) begin
        ns             = 'h0;
        nt             = 'h1; 
        s              = `p;
        t              =  x;
        start           = 1'b1;
        resultReady     = 1'b0;
        divisionEnable  = 1'b0;
        multiplyEnable  = 1'b0;
        finished        = 1'b0;
        finishedD       = 1'b0;
        finishedM       = 1'b0;
    end        
      else
        start = 1'b0;   
CALCULATE:
    begin
        if(!finishedD) begin
            if(!divisionEnable)
                divisionEnable = 1'b1;
            else 
                if(divisionReady) begin    
                    q              = quotient;
                    r              = remainder;
                    //nr             = ns - quotient*nt;
                    multiplyEnable = 1'b1;
                    divisionEnable = 1'b0;
    //                finished       = 1'b1;
                    finishedD      = 1'b1;
                end
            end
        else   
            if(multiplyReady) begin
                nr             = ns - product[`DATAWIDTH : 0];
                multiplyEnable = 1'b0;
                finishedM      = 1'b1;
            end
            finished = finishedD && finishedM;               
        end 
    
UPDATE:   
    begin
        s  = t;
        t  = r;
        ns = nt;
        nt = nr;
        finishedD = 1'b0;
        finishedM = 1'b0;
    end
READY: 
    begin
        resultReady = 1'b1;
        result      = nr [`DATAWIDTH] ? `p + nr : nr;
    end
endcase
end

division div(.clk(clk),.enable(divisionEnable),
             .dividend(s),.divisor(t),
             .quotient(quotient),.remainder(remainder),
             .ready(divisionReady));
 multiply mult (.clk(clk),.enable(multiplyEnable),
                .multiplicand(nt),.multiplier({1'b0,quotient}),
                .product(product),.ready(multiplyReady));            
assign inverse  = result[`DATAWIDTH - 1 : 0];
assign outReady = resultReady;
endmodule