`timescale 1ns / 1ps

module fifo #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input reset,
    input wr,
    input rd,
    input [DATA_WIDTH-1:0] wdata,
    output [DATA_WIDTH-1:0] rdata,
    output full,
    output empty
    );

    wire [3:0] waddr, raddr;

    fifo_control_unit u_fifo_cu(
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .rd(rd),
        .waddr(waddr),
        .raddr(raddr),
        .full(full),
        .empty(empty)
    );

    register_file u_reg_file(
        .clk(clk),
        .waddr(waddr),
        .wdata(wdata),
        .wr((!full) & wr),
        .rd(rd),
        .raddr(raddr),
        .rdata(rdata)
    );
endmodule

module fifo_control_unit (
    input clk,
    input reset,
    input wr,
    input rd,
    output [3:0] waddr,
    output [3:0] raddr,
    output full,
    output empty
);
    reg full_reg, full_next, empty_reg, empty_next;
    reg [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;

    assign waddr = wptr_reg;
    assign raddr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            full_reg <= 0;
            empty_reg <= 1;
            wptr_reg <= 0;
            rptr_reg <= 0;
        end
        else begin
            full_reg <= full_next;
            empty_reg <= empty_next;
            wptr_reg <= wptr_next;
            rptr_reg <= rptr_next;
        end
    end

    always @(*) begin
        full_next = full_reg;
        empty_next = empty_reg;
        wptr_next = wptr_reg;
        rptr_next = rptr_reg;
        case ({wr,rd})
            2'b01: begin
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end    
            end 
            2'b10: begin
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                if (empty_reg == 1'b1) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 0;
                end
                else if(full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                end
                else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
            //default: 
        endcase
    end
endmodule

module register_file (
    input clk,
    input [3:0] waddr,
    input [7:0] wdata,
    input wr,
    input rd,
    input [3:0] raddr,
    output [7:0] rdata
);
    reg [7:0] mem [0:15];

    always @(posedge clk) begin
        if (wr) begin
            mem[waddr] <= wdata;
        end
    end

    //assign rdata = rd ? mem[raddr] : 0;
    assign rdata = mem[raddr];
endmodule
