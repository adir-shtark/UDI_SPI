module RegistersSPI
(
    input clk,
    input rst, // Active high reset

    output        waitrequest,   
    output [31:0] readdata,      
    input         debugaccess,   
    input  [5:0]  address,       
    input         read,          
    input  [3:0]  byteenable,    
    output        readdatavalid, 
    input  [31:0] writedata,     
    input         write,         
    input  [0:0]  burstcount,    

    output [7:0]  clockDiv,
    output        Start,
    output [31:0] DataIn,
    input         Busy,
    input  [31:0] DataOut
);

reg        Reg_Start   ;
reg [31:0] Reg_DataIn  ;
reg [7:0]  Reg_ClockDiv;

always @(posedge clk)
    if (rst) Reg_Start <= 1'b0;
    else if (Reg_Start) Reg_Start <= 1'b0;
    else if (write && (address[5:0] == 6'h00)) Reg_Start <= writedata[0:0];

always @(posedge clk)
    if (rst) Reg_DataIn <= 32'h00000000;
    else if (write && (address[5:0] == 6'h08)) Reg_DataIn <= writedata;

always @(posedge clk)
    if (rst) Reg_ClockDiv <= 8'h00;
    else if (write && (address[5:0] == 6'h10)) Reg_ClockDiv <= writedata[7:0];

assign readdata = (address[5:0] == 6'h00) ? {31'h00000000,Reg_Start} :
                  (address[5:0] == 6'h04) ? {31'h00000000,Busy} :
                  (address[5:0] == 6'h08) ? {Reg_DataIn} :
                  (address[5:0] == 6'h0c) ? {DataOut} :
                  (address[5:0] == 6'h10) ? {24'h000000,Reg_ClockDiv}: 32'h00000000;


reg Regvalid;
always @(posedge clk)
    if (rst) Regvalid <= 1'b0;
    else Regvalid <= read;

assign readdatavalid = Regvalid;
assign waitrequest = 1'b0;

assign clockDiv = Reg_ClockDiv;
assign Start    = Reg_Start   ;
assign DataIn   = Reg_DataIn  ;

endmodule