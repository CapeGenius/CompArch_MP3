// memory module that can change from read state to write state
module memory#(
    parameter INIT_FILE=""
)(
    input logic clk,
    input logic [5:0] pixel,
    input logic [7:0] new_pixel_value,
    input logic [1:0] write_flag,
    output logic [7:0] read_data,
    output logic [63:0] previous_line,
    output logic [63:0] current_line,
    output logic [63:0] next_line
);
    // declaring state parameters for the writing flag
    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] REPLACE = 2'b10;

    //declaring local memory
    logic [63:0] read_mem [0:7];
    logic [63:0] write_mem [0:7];

    //create row and column
    logic [2:0] row;
    logic [2:0] column;

    //start and end index of row vector
    logic [7:0] start_index;
    logic [7:0] end_index;

    assign start_index = 8*column;
    assign end_index = start_index+7;
    assign row = pixel[5:3];
    assign column = pixel[2:0];

    initial begin
        $readmemh(INIT_FILE, read_mem);
        $readmemh(INIT_FILE, write_mem);
    end

    always_ff @(posedge clk) begin 

        current_line <= read_mem[row];
        previous_line <= (row == 0) ? read_mem[7] : read_mem[row-1];
        next_line <= (row == 7) ? read_mem[0] : read_mem[row+1];
        read_data <= read_mem[row][start_index +: 8];

        case (write_flag) 
            WRITE: 
                write_mem[row][start_index +: 8] <= new_pixel_value;
            REPLACE: 
                begin
                    read_mem[0] <= write_mem[0];
                    read_mem[1] <= write_mem[1];
                    read_mem[2] <= write_mem[2];
                    read_mem[3] <= write_mem[3];
                    read_mem[4] <= write_mem[4];
                    read_mem[5] <= write_mem[5];
                    read_mem[6] <= write_mem[6];
                    read_mem[7] <= write_mem[7];
                end
        endcase
    end

endmodule