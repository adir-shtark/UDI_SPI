module SlaveSPI
(
    input clk,
    input rst, // Active high reset

//  input [7:0] ClockDiv,
//  input       Start,
    input  [31:0] DataIn,
    output        Busy,
    output [31:0] DataOut,

    input  SCLK,
    input  MOSI,
    output MISO,
    input  SS_n
);

// clock receiver
reg [1:0] clockDev;
always @(posedge clk)
    if (rst) clockDev <= 2'b00;
    else clockDev <= {clockDev[0],SCLK};

wire posBit = (clockDev == 2'b01) ? 1'b1 : 1'b0;
wire negBit = (clockDev == 2'b10) ? 1'b1 : 1'b0;


// MOSI receiver
reg [31:0] RegMOSI;
always @(posedge clk)
    if (rst) RegMOSI <= 32'h00000000;
    else if (!SS_n && posBit) RegMOSI <= {RegMOSI[30:0],MOSI};

// MISO receiver
reg [31:0] RegMISO;
always @(posedge clk)
    if (rst) RegMISO <= 32'h00000000;
    else if (SS_n) RegMISO <= DataIn;
    else if (!SS_n && negBit) RegMISO <= {RegMISO[30:0],MISO};

// SPI signals
assign MISO = RegMISO[31];
// control signal
assign Busy = !SS_n;
assign DataOut = RegMOSI;

endmodule