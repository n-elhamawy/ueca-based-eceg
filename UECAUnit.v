`include "parameters.vh"
module UECAUnit(
    input                   clk,
    input                enable,
    input                   mode, // 0 pointAddition,1 pointMultiplication
    input  [`DATAWIDTH - 1 : 0] k,
    input  [`DATAWIDTH - 1 : 0] Px,
    input  [`DATAWIDTH - 1 : 0] Py,
    input  [`DATAWIDTH - 1 : 0] P2x,
    input  [`DATAWIDTH - 1 : 0] P2y,
    output [`DATAWIDTH - 1 : 0] Qx,
    output [`DATAWIDTH - 1 : 0] Qy,
    output                 outReady
    );
   
integer i;
   
 //Inputs saved
reg  [3              : 0]  state;
reg  [`DATAWIDTH - 1 : 0]  m,pX,pY,x1,y1,x2,y2,x3,y3,xReady,yReady,lambda,
						   aAdd,bAdd,aSub,bSub,aMult,bMult,aInv,invResult; 
reg       				   workingMode,addFinished,addRequired,startFlag,startMult,startAdd,
                           startSub,startInv,ready,finished1,finished2,finished,pd;
wire [`DATAWIDTH - 1 : 0]  sum,product,inverse,difference;
wire                       addReady,multReady,invReady,subReady; 

localparam IDLE     = 4'h0; 
localparam INDEX 	= 4'h1;
localparam DOUBLE1  = 4'h2; 
localparam DOUBLE2  = 4'h3;
localparam DOUBLE3  = 4'h4;
localparam DOUBLE4  = 4'h5;
localparam X3_S1 	= 4'h6;
localparam X3_S2 	= 4'h7;
localparam Y3_S1    = 4'h8;
localparam Y3_S2    = 4'h9;
localparam Y3_S3    = 4'hA;
localparam ADD1   	= 4'hB;
localparam ADD2   	= 4'hC;
localparam ADD3   	= 4'hD;

//FSM block
always @(posedge clk) begin
case(state)
IDLE: 
    if(startFlag)begin  
            if(workingMode)//mode = point multiplication
            state = INDEX;
        else if(pd)//mode = point addition
            state = DOUBLE1;
        else
            state = ADD1;
    end                
INDEX: 
    if(finished)
		state = DOUBLE1;
DOUBLE1:
	if(finished)
		state = DOUBLE2;
DOUBLE2:
	if(finished)
		state = DOUBLE3;
DOUBLE3:
	if(finished)
		state = DOUBLE4;
DOUBLE4:
	if(finished)
		state = X3_S1;
X3_S1:
	if(finished)
		state = X3_S2;
X3_S2:
	if(finished)
		state = Y3_S1;
Y3_S1:
	if(finished)
		state = Y3_S2;
Y3_S2:
	if(finished)
		state = Y3_S3;
Y3_S3:
    if(finished)begin
	   if(ready)
		  state = IDLE;
	else
      if(addRequired)
         state = ADD1;
      else
        state = DOUBLE1;
	end		
ADD1:
	if(finished)
		state = ADD2;
ADD2:
	if(finished)
		state = ADD3;
ADD3:
	if(finished)
		state = X3_S1;    
default: state = IDLE;
endcase
end

    
always @(posedge clk)begin
case(state)
IDLE: 
    begin
        if(enable) begin
            startFlag 	= 1'b1;
			i        	= `DATAWIDTH - 1;
			m        	= k;
			pX       	= Px;
			pY      	= Py; 
			x1       	=  mode? 'h0 : Px;
			y1          =  mode? 'h0 : Py;
			x2       	=  mode? 'h0 : P2x;
			y2          =  mode? 'h0 : P2y;
			x3          =  'h0;
			y3          =  'h0;
			aSub        = mode? 'h0 : P2x; // for point addition
			bSub        = mode? 'h0 : Px; // for point addition
            aMult	    = mode? 'h0 : Px; // for point doubling
			bMult	    = mode? 'h0 : Px; // for point doubling  
			aAdd	    = mode? 'h0 : Py; // for point doubling
			bAdd	    = mode? 'h0 : Py; // for point doubling
			addFinished = 1'b0;
			addRequired = 1'b0;
			finished	= ~mode;
			finished1	= 1'b0;
			finished2	= 1'b0;
			startAdd	= 1'b0;
			startSub	= 1'b0;
			startInv	= 1'b0;
			startMult	= 1'b0;
			ready       = 1'b0;
			workingMode = mode;
			pd          = Py == P2y && Px == P2x;
		end
		else
			startFlag = 1'b0;
		
    end    
INDEX:
	begin
		if(m[i])  begin
			startFlag = 1'b0;
			x3		  = pX;
			y3 		  = pY;
			aMult	  = pX;
			bMult	  = pX;
			aAdd	  = pY;
			bAdd	  = pY;
			finished  = 1'b1;
		 end   
		i = i - 1;
	end
   
DOUBLE1:	
    begin
        x1       = mode? x3 : x1;
        y1       = mode? y3 : y1;
        x2       = mode? x3 : x1;
        y2       = mode? y3 : y1;
		if(!startAdd & finished)begin
			startAdd  = 1'b1;
			finished1 = 1'b0;
		end
		else 
			if(addReady)begin    
				aInv      = sum;
				startAdd  = 1'b0;
				finished1 = 1'b1;      
			end 
		if(!startMult & finished)begin
			startMult = 1'b1;
			finished2 = 1'b0;
		end
		else 
			if(multReady)begin    
				aMult     = product;
				bMult     =  'h3;
				startMult = 1'b0;
				finished2 = 1'b1;      
			end
		finished = finished1 & finished2;		
	end   
DOUBLE2:	
    begin
		if(!startInv & finished)begin
			startInv  = 1'b1;
			finished1 = 1'b0;
		end
		else 
			if(invReady)begin    
				invResult = inverse;
				startInv  = 1'b0;
				finished1 = 1'b1;      
			end 
		if(!startMult & finished)begin
			startMult = 1'b1;
			finished2 = 1'b0;
		end
		else 
			if(multReady)begin    
				aAdd      = product;
				bAdd      =  `A;
				startMult = 1'b0;
				finished2 = 1'b1;      
			end 
		finished = finished1 & finished2;		
	end           

DOUBLE3:
	if(!startAdd)begin
		startAdd = 1'b1;
		finished = 1'b0;
	end
	else
		if(addReady)begin
			aMult	 = sum;
			bMult	 = invResult;
			startAdd = 1'b0;
			finished = 1'b1;
		end
DOUBLE4:
    if(!startMult)begin
		startMult = 1'b1;
		finished  = 1'b0;
	end
	else
		if(multReady)begin
			lambda    = product;
			aMult	  = product;
			bMult	  = product;
			aAdd	  = x1;
			bAdd	  = x2;
			startMult = 1'b0;
			finished  = 1'b1;
		end
X3_S1:
	begin
		if(!startMult & finished)begin	
			startMult = 1'b1;
			finished1 = 1'b0;
		end
		else	
			if(multReady)begin
				aSub      = product;
				startMult = 1'b0;
				finished1 = 1'b1;
			end	
		if(!startAdd & finished)begin
			startAdd  = 1'b1;
			finished2 = 1'b0;
		end
		else
			if(addReady)begin
				bSub	  = sum;
				startAdd  = 1'b0;
				finished2 = 1'b1;
			end
		finished = finished1 & finished2;		
	end
X3_S2:
	if(!startSub)begin
		startSub = 1'b1;
		finished = 1'b0;
	end
	else
		if(subReady)begin
			x3		 = difference;
			aSub     = x1;
			bSub     = difference;
			startSub = 1'b0;
			finished = 1'b1;
        end
Y3_S1:
	if(!startSub)begin
		startSub = 1'b1;
		finished = 1'b0;
	end
	else
		if(subReady)begin
			aMult    = lambda;
			bMult    = difference;
			startSub = 1'b0;
			finished = 1'b1;
        end
Y3_S2:
	if(!startMult)begin
		startMult = 1'b1;
		finished  = 1'b0;
	end
	else
		if(multReady) begin
			aSub 	  = product;
			bSub	  = y1;
			startMult = 1'b0;
			finished  = 1'b1;
		end
Y3_S3:
	if(!startSub)begin
		startSub = 1'b1;
		finished = 1'b0;
	end
	else
		if(subReady)begin
			y3		 = difference;
			startSub = 1'b0;
			finished = 1'b1;
			if(!workingMode)begin //mode = point Addition
			    ready = 1'b1;
			    xReady = x3;
			    yReady = difference;
			end
			else    //mode = pointMultiplication
			     if(m[i])
				    if(addFinished)begin
				        if(i == 0) begin
				            ready  = 1'b1;
                            xReady = x3;
                            yReady = difference;
                        end
                        else begin
                            addRequired = 1'b0;
                            addFinished = 1'b0;
                            i           = i - 1;
                            aMult       = x3;
                            bMult       = x3;
                            aAdd        = difference;
                            bAdd        = difference;
                        end    
                    end	 
                    else begin
                        addRequired = 1'b1;
                        aSub		= x3;
                        bSub		= pX;
                        x1          = pX;
                        y1          = pY;
                        x2          = x3;
                        y2          = difference;
                    end
                else begin
                    if(i == 0 )begin
                        ready  = 1'b1;
                        xReady = x3;
                        yReady = difference;
                    end
                    else begin
                        i     = i - 1;
                        aMult = x3;
                        bMult = x3;
                        aAdd  = difference;
                        bAdd  = difference;
                    end
                end	
            end
             
ADD1:
    if(!startSub) begin
        startSub = 1'b1;
        finished = 1'b0;	
    end
    else
        if(subReady) begin
            aSub	 = workingMode? y3 : y2;
            bSub	 = workingMode? pY : y1;
            aInv	 = difference;
            startSub = 1'b0;
            finished = 1'b1;
        end
ADD2:
    begin
		if(!startSub & finished) begin
            startSub  = 1'b1;
            finished1 = 1'b0;    
        end
        else 
            if(subReady) begin
                aMult	  = difference;
                startSub  = 1'b0;
                finished1 = 1'b1;
        end				
		if(!startInv & finished) begin
			startInv  = 1'b1;
			finished2 = 1'b0;	
		end
		else
			if(invReady) begin
				bMult	  = inverse;
				startInv  = 1'b0;
				finished2 = 1'b1;
			end
		finished = finished1 & finished2;	
	end	
ADD3:
	if(!startMult)begin
		startMult = 1'b1;
		finished  = 1'b0;
	end
	else
		if(multReady)begin
			lambda		= product;
			aMult       = product;
			bMult       = product;
			aAdd        = x1;
			bAdd        = x2;
			startMult   = 1'b0;
			addFinished = 1'b1;
			finished	= 1'b1;
		end
endcase
 end
 

inversion
    inv(.clk(clk),.enable(startInv),
        .x(aInv),.inverse(inverse),.outReady(invReady));
modMultiplier
    mult(.clk(clk),.enable(startMult),
    .a(aMult),.b(bMult),.product(product),.outReady(multReady));
modAdder 
    add(.clk(clk),.enable(startAdd),
    .a(aAdd),.b(bAdd),.sum(sum),.outputReady(addReady));
modSubtraction 
    sub(.clk(clk),.enable(startSub),.a(aSub),.b(bSub),
    .result(difference),.outputReady(subReady));
     
assign Qx       =  xReady;
assign Qy       =  yReady;
assign outReady =  ready;

endmodule
