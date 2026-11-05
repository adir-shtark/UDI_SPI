module MasterSPI
(
    input clk,
    input rst, // Active high reset

    input  [7:0]  ClockDiv,
    input         Start,
    input  [31:0] DataIn,
    output        Busy,
    output [31:0] DataOut,

    output SCLK,
    output MOSI,
    input  MISO,
    output SS_n

);

// clock generator
reg [7:0] ClockDivCount;
always @(posedge clk)
    if (rst) ClockDivCount <= 8'h00;
    else if (Start) ClockDivCount <= 8'h00;
    else if (ClockDivCount == ClockDiv) ClockDivCount <= 8'h00;
    else ClockDivCount <= ClockDivCount + 1;

reg SPIclock;
always @(posedge clk)
    if (rst) SPIclock <= 1'b0;
    else if (Start) SPIclock <= 1'b0;
    else if (ClockDivCount == ClockDiv) SPIclock <= ~SPIclock;

wire posBit = (~SPIclock && (ClockDivCount == ClockDiv)) ? 1'b1 : 1'b0;
wire negBit = ( SPIclock && (ClockDivCount == ClockDiv)) ? 1'b1 : 1'b0;

// bit counter
reg [4:0] SPIbitCount;
always @(posedge clk)
    if (rst) SPIbitCount <= 5'h00;
    else if (Start) SPIbitCount <= 5'h00;
    else if (negBit) SPIbitCount <= SPIbitCount + 1;

// SS_n generator
reg RegSS_n;
always @(posedge clk)
    if (rst) RegSS_n <= 1'b1;
    else if (Start) RegSS_n <= 1'b0;
    else if ((negBit) && (SPIbitCount == 5'b11111)) RegSS_n <= 1'b1;

// MOSI generator
reg [31:0] RegMOSI;
always @(posedge clk)
    if (rst) RegMOSI <= 32'h00000000;
    else if (Start) RegMOSI <= DataIn;
    else if (!RegSS_n && negBit) RegMOSI <= {RegMOSI[30:0],RegMOSI[31]};

// MISO receiver
reg [31:0] RegMISO;
always @(posedge clk)
    if (rst) RegMISO <= 32'h00000000;
    else if (!RegSS_n && posBit) RegMISO <= {RegMISO[30:0],MISO};

// SPI signals
assign SCLK = (!RegSS_n) ? SPIclock : 1'b0;
assign MOSI = RegMOSI[31];
assign SS_n = RegSS_n;
// control signal
assign Busy = !RegSS_n;
assign DataOut = RegMISO;

endmodule