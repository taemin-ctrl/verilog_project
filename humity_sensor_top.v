`timescale 1ns / 1ps

module top_sensor(
    // global ports
    input clk, 
    input rst,
    
    // uart ports
    input rx,
    output tx,

    // sensor
    input btn_start,
    inout dht_io,

    // fnd
    output [7:0] seg,
    output [3:0] seg_comm
    );

    wire [39:0] w_data;
    reg [39:0] pipeline;
    wire [39:0] w_pip;
    assign w_pip = pipeline;
    
    wire [7:0] ctl_data;
    wire [7:0] w_ctl_data;
    wire [7:0] odata;
    wire w_start;
    wire start;
    wire en;
    wire empty;

    // data register to send fnd, uart
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            pipeline <= 0;
        end
        else begin
            if (w_data != 0) pipeline <= w_data;
            else pipeline <= pipeline;
        end
    end

    top_module u_uart(
        .clk(clk),
        .reset(rst),
        .rx(rx),
        .tx(tx),
        .en(en),
        .cdata(ctl_data),
        .odata(odata),
        .empty(empty)
    );

    uart_cu u_cu(
        .i_data(w_ctl_data),
        .o_data(w_start)
    );

    btn_debounce u_btn(
        .clk(clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(start)
    );

    conti_data u_send(
        .clk(clk),
        .rst(rst),
        .data(w_data),
        .en(en),
        .split_data(odata)
    );

    trigger u_tig(
        .empty(empty),
        .data(ctl_data),
        .tig(w_ctl_data)
    );

    humity_sensor_top u_sensor(
        .clk(clk),
        .rst(rst),
    
        .btn_start(w_start|start),
    
        .dht_io(dht_io),
        .data(w_data)
    );

    fnd_controller u_fnd(
        .clk(clk),
        .reset(rst),
        .data({w_pip[39:32],w_pip[23:16]}),
        .seg(seg),
        .seg_comm(seg_comm)
    );
endmodule

// chagne ascii data to control data 
module uart_cu(
    input [7:0] i_data,
    output o_data
    );
    
    reg [4:0] r_data;
    
    assign o_data = r_data;

    always @(*) begin
        case (i_data)
            8'h72: r_data= 1; // r -> 0x72
            default: r_data = 0;
        endcase
    end
endmodule

// transmit to 5 uart data
module conti_data (
    input clk,
    input rst,
    input [39:0] data,
    output en,
    output [7:0] split_data
);
    reg [39:0] mem_n, mem_r;
    
    // tx fifo write flag
    reg en_r,en_n;
    assign en = en_r;

    // output data
    reg [7:0] o_data;
    assign split_data = mem_r[39:32];

    // fsm register
    localparam IDLE = 0, DATA1= 1;
    reg state, next;
    

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            mem_r <= 0;
            en_r <= 0;
        end
        else begin
            state <= next;
            mem_r <= mem_n;
            en_r <= en_n;
        end
    end

    always @(*) begin
        next = state;
        mem_n = mem_r;
        en_n = en_r;
        case (state)
            IDLE: begin
                en_n = 0;
                mem_n = 0; 
                if (|data) begin
                    next = DATA1;
                    mem_n = data;
                    en_n = 1;
                end
            end 
            DATA1: begin
                if(mem_n[31:0] == 0) begin
                    next = IDLE;
                    en_n = 0;
                    mem_n = 0;
                end
                else begin
                    mem_n = {mem_r[31:0],8'b0};
                end
            end
            default: mem_n = 0;
        endcase
    end
endmodule

// trigger generator
module trigger (
    input empty,
    input [7:0] data,
    output [7:0] tig
);
    assign tig = empty? 0: data;
endmodule
