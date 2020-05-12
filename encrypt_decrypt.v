`include "parameters.vh"
module encrypt_decrypt(
    
    //General inputs
    input                    clk,
    input                    enable,
    input                    encrypt, // 1 encryption, 0 decryption
    
    //Inputs to decryption
    input  [`DATAWIDTH - 1 : 0] a,
    input  [`DATAWIDTH - 1 : 0] C1x_in,
    input  [`DATAWIDTH - 1 : 0] C1y_in,
    input  [`DATAWIDTH - 1 : 0] C2x_in,
    input  [`DATAWIDTH - 1 : 0] C2y_in,
    
    //Inputs to encryption
    input  [`DATAWIDTH - 1 : 0] k,
    input  [`DATAWIDTH - 1 : 0] Px,
    input  [`DATAWIDTH - 1 : 0] Py,
    input  [`DATAWIDTH - 1 : 0] PaX,
    input  [`DATAWIDTH - 1 : 0] PaY,
    input  [`DATAWIDTH - 1 : 0] Mx_in,
    input  [`DATAWIDTH - 1 : 0] My_in,
    
    //Outputs  of the encryption
    output [`DATAWIDTH - 1 : 0] C1x_out,
    output [`DATAWIDTH - 1 : 0] C1y_out,
    output [`DATAWIDTH - 1 : 0] C2x_out,
    output [`DATAWIDTH - 1 : 0] C2y_out,
    
    //Outputs  of the decryption
    output [`DATAWIDTH - 1 : 0] Mx_out,
    output [`DATAWIDTH - 1 : 0] My_out,
  
  // General ouptuts
   output                  outReady

    );
    
 reg                        enablePM,mode,ready,finished,wMode;
 reg  [             1 : 0 ] state;
 reg  [`DATAWIDTH - 1 : 0 ] x,y,x1,y1,x2,y2,c1x,c1y,c2x,c2y,mX,mY,n,plainX,plainY,tempX,tempY;

 wire [`DATAWIDTH - 1 : 0 ] qX,qY;
 wire pointReady;
 


 localparam IDLE    = 2'b00;
 localparam S1      = 2'b01;
 localparam S2      = 2'b10;
 localparam S3      = 2'b11;
 
always @(posedge clk) begin
case(state)
IDLE:
    if(finished)
        state = S1;
S1:
    if(finished)
        state = S2;
S2:
 if(finished)
    if(wMode)
      state = S3; 
    else
      state = IDLE;      
S3:
    if(finished)
        state = IDLE;
default: state = IDLE;    
endcase
end

always @(posedge clk) begin
case(state)
IDLE:
    begin
        if(enable)begin
            x         = encrypt? Px    : C1x_in;
            y         = encrypt? Py    : C1y_in;
            tempX     = encrypt? PaX   : C2x_in;
            tempY     = encrypt? PaY   : C2y_in;
            n         = encrypt? k     : a;
            plainX    = encrypt? Mx_in : 'hX;
            plainY    = encrypt? My_in : 'hX;
            mode      = 1'b1; // point mutiplication
            enablePM  = 1'b0;
            ready     = 1'b0;
            finished  = 1'b1;
            wMode     = encrypt;
            mX        = 'hX;
            mY        = 'hX;
            c1x       = 'hX;
            c1y       = 'hX;
            c2x       = 'hX;
            c2y       = 'hX;
        end
    end
S1:
    begin
        if(!enablePM)begin
            enablePM = 1'b1;
            finished = 1'b0;
        end
        else
            if(pointReady)begin
                x1       = wMode? qX  : 'hX;
                y1       = wMode? qY  : 'hX;
                x        = tempX;
                y        = tempY;
                x2       = wMode? 'hX : qX;
                y2       = wMode? 'hX : `p - qY;
                mode     = wMode; //enc: point multiplication dec: point addition
                enablePM = 1'b0;
                finished = 1'b1;
            end
    end
S2: 
   begin
        if(!enablePM)begin
            enablePM = 1'b1;
            finished = 1'b0;
        end
        else
            if(pointReady)begin
                if(wMode)begin
                    x    = plainX;
                    y    = plainY;
                    x2   = qX;
                    y2   = qY;
                    mode = 1'b0;
                end
                else begin
                    mX       = qX;
                    mY       = qY;
                    ready    = 1'b1;
                end
                enablePM = 1'b0;
                finished = 1'b1;
            end
    end
S3:
    begin
        if(!enablePM)begin
            enablePM = 1'b1;
            finished = 1'b0;
        end
        else 
            if(pointReady)begin
			c1x 	 = x1;
            c1y 	 = y1;
            c2x 	 = qX;
            c2y		 = qY;
            enablePM = 1'b0;
            finished = 1'b1;
            ready    = 1'b1;
            end   
     end                       
endcase
end 
UECAUnit UECA(.clk(clk),.enable(enablePM),.mode(mode),
                    .k(n),.Px(x),.Py(y),
                    .P2x(x2),.P2y(y2),
                    .Qx(qX),.Qy(qY),
                    .outReady(pointReady));
                       
assign Mx_out   = mX;    
assign My_out   = mY;
assign C1x_out  = c1x;    
assign C1y_out  = c1y;    
assign C2x_out  = c2x;    
assign C2y_out  = c2y;
assign outReady = ready;
    
endmodule
