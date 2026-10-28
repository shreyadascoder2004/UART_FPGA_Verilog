`timescale 1ns / 1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  wire                   clk,
    input  wire                   reset,

    input  wire                   wr_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output wire                   full,

    input  wire                   rd_en,
    output reg  [DATA_WIDTH-1:0]  rd_data,
    output wire                   empty
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH:0] wr_ptr, rd_ptr; // extra MSB to distinguish full/empty

    assign full  = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) &&
                   (wr_ptr[PTR_WIDTH]     != rd_ptr[PTR_WIDTH]);

    assign empty = (wr_ptr == rd_ptr);

    always @(posedge clk) begin
        if (reset) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[PTR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            rd_ptr  <= 0;
            rd_data <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr[PTR_WIDTH-1:0]];
            rd_ptr  <= rd_ptr + 1;
        end
    end

endmodule
