`include "memory.sv"

module game_of_life#(
    parameter INIT_FILE = ""
)(
    input logic clk, 
    input logic state,
    input logic [5:0] address,
    output logic [7:0] read_data
);
    // declare logic for memory module input
    logic [7:0] color_value;
    logic [1:0] write_flag;
    logic previous_state; 
    logic [2:0] counter;

    // declare logic for memory module output
    logic [63:0] previous_line;
    logic [63:0] current_line;
    logic [63:0] next_line;

    // declare local params for reading and writing into memory
    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

    // declare dead alive local params
    localparam [7:0] DEAD = 8'h00;
    localparam [7:0] ALIVE = 8'hFF;

    // declare local params for getting IDLE / transmit
    localparam TRANSMIT_FRAME = 1'b0;
    localparam IDLE = 1'b1;

    // get column and row
    logic [2:0] row = address[5:3];
    logic [2:0] column = address[2:0];
    logic [7:0] start_index, end_index, previous_start, previous_end, next_start, next_end;

    assign start_index = 8*column;
    assign end_index = start_index+7;
    assign previous_start = (start_index == 0) ? (63 - 7) : start_index - 8;
    assign previous_end = start_index + 7;
    assign next_start = (start_index == 56) ? (0) : start_index + 8;
    assign next_end = next_start+7;

    initial begin
        color_value = 8'b0;
        previous_line = 64'b0;
        current_line = 64'b0;
        next_line = 64'b0;
        write_flag = WRITE;
    end

    memory #(
        .INIT_FILE      (INIT_FILE)
    ) mem_module (
        .clk                    (clk),
        .pixel                  (address),
        .new_pixel_value        (color_value),
        .write_flag             (write_flag),
        .read_data              (read_data),
        .previous_line          (previous_line),
        .current_line           (current_line),
        .next_line              (next_line)
    );

    always_comb begin
        counter = 3'b000;
        logic [7:0] neighbors;

        // declare all neighbors
        neighbors[0] = (previous_line[previous_start +:8] != 0);
        neighbors[1] = (previous_line[start_index +: 8] != 0);
        neighbors[2] = (previous_line[next_start +: 8] != 0);
        neighbors[3] = (current_line[previous_start +: 8] !=0);
        neighbors[4] = (current_line[next_start +: 8] !=0);
        neighbors[5] = (next_line[previous_start +: 8] != 0);
        neighbors[6] = (next_line[start_index +: 8] != 0);
        neighbors[7] = (next_line[next_start +: 8] != 0);

        // count all the neighbors
        counter = $countones(neighbors)
    end

    always_comb begin
        case (write_flag):
            (REPLACE): write_flag <= WRITE;
        endcase
    end

    always_ff @(posedge clk) begin

        if (counter < 2 & read_data != DEAD) begin
            color_value <= DEAD;
        end else if (counter <= 3 & read_data != DEAD) begin
            color_value <= ALIVE; 
        end else if (counter > 3 & read_data != DEAD) begin
            color_value <= DEAD; 
        end else if (counter == 3 & read_data == DEAD) begin
            color_value <= ALIVE; 
        end else begin
            color_value <= DEAD;
        end

        case (address):
            (63): write_flag <= REPLACE;
            default: //do nothing
        endcase
    end


endmodule