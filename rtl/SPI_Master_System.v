module SPI_Master_System (
    input         clk,
    input         rst,           // Active-high reset

    // Avalon-MM CPU Interface (from SPIregisters)
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

    // External SPI Physical Interface (from MasterSPI)
    output        SCLK,
    output        MOSI,
    input         MISO,
    output        SS_n
);

    // Internal wires connecting the Registers to the SPI Core
    wire [7:0]  int_clockDiv;
    wire        int_start;
    wire [31:0] int_dataIn;
    wire        int_busy;
    wire [31:0] int_dataOut;

    // Instantiate the Memory-Mapped Registers
    SPIregisters u_spi_regs (
        .clk            (clk),
        .rst            (rst),
        
        // CPU side
        .waitrequest    (waitrequest),
        .readdata       (readdata),
        .debugaccess    (debugaccess),
        .address        (address),
        .read           (read),
        .byteenable     (byteenable),
        .readdatavalid  (readdatavalid),
        .writedata      (writedata),
        .write          (write),
        .burstcount     (burstcount),
        
        // Hardware side (Control & Status)
        .clockDiv       (int_clockDiv),
        .Start          (int_start),
        .DataIn         (int_dataIn),
        .Busy           (int_busy),
        .DataOut        (int_dataOut)
    );

    // Instantiate the SPI Master Core
    MasterSPI u_spi_master (
        .clk            (clk),
        .rst            (rst),
        
        // Control & Status (Connected to registers)
        .ClockDiv       (int_clockDiv),
        .Start          (int_start),
        .DataIn         (int_dataIn),
        .Busy           (int_busy),
        .DataOut        (int_dataOut),
        
        // Physical Pins
        .SCLK           (SCLK),
        .MOSI           (MOSI),
        .MISO           (MISO),
        .SS_n           (SS_n)
    );

endmodule