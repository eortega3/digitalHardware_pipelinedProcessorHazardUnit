/*
 * core_controller.sv
 *
 * Authors: David and Sarah Harris
 * Updated By: Sat Garcia
 *
 * Module that implements control component of processor.
 */

module core_controller(input  logic [5:0] op, funct,
						input  logic	   clk, reset,
						input  logic       eq_d,
						output logic       mem_to_reg_w, dmem_write_m, dmem_write_d,
						output logic       pc_src_d, alu_src_x, instr_reset,
						output logic       reg_dest_x, reg_write_w,
						output logic       jump_d,
						input logic [4:0]  rs_d,rt_d, rs_x, rt_x, 
						input logic [4:0]  write_reg_x, write_reg_m, write_reg_w,
						output logic 	   stall_f, stall_d, flush_x,
						output logic 	   fwd_a_d, fwd_b_d,
						output logic [1:0] fwd_a_x, fwd_b_x,
						output logic 	   fwd_m_w, 
						output logic [2:0] alu_ctrl_x);

	logic [1:0] alu_op_d;

	logic reg_write_d, reg_write_x, reg_write_m;
	logic mem_to_reg_d, mem_to_reg_x, mem_to_reg_m;
	logic dmem_write_x;
	logic branch_d;
	logic [2:0] alu_ctrl_d;
	logic alu_src_d;
	logic reg_dest_d;

	// Note: Controller is active in Decode (D) stage so we need to make sure we
	// wire the maindec and aludec inputs/outputs up to our "_d" signals (e.g.
	// reg_write_d).
	maindec md(.op, .mem_to_reg(mem_to_reg_d), .dmem_write(dmem_write_d), 
				.branch(branch_d), .alu_src(alu_src_d), .reg_dest(reg_dest_d), 
				.reg_write(reg_write_d), .jump(jump_d),
				.alu_op(alu_op_d));
	aludec  ad(.funct, .alu_op(alu_op_d), .alu_ctrl(alu_ctrl_d));
	
	
	//hazard unit and follow the signals to mips core	
	hazard_unit hazard(.rs_d,
				.rt_d,
				.rs_x,
				.rt_x,
				.write_reg_x,
				.write_reg_m,
				.write_reg_w,
				.branch_d,
				.dmem_write_m,
				.dmem_write_d,
				.reg_write_x,
				.mem_to_reg_x,
				.reg_write_m,
				.mem_to_reg_m,
				.mem_to_reg_w,
				.reg_write_w,
				.stall_f,
				.stall_d,
				.flush_x,
				.fwd_m_w,
				.fwd_a_d,
				.fwd_b_d,
				.fwd_a_x,
				.fwd_b_x);

	assign pc_src_d = branch_d & eq_d;
	assign instr_reset = jump_d | pc_src_d;

	// D-X Inter-stage registers
	flopr #(1) reg_write_reg_d_x(.clk, .reset(flush_x | reset), .d(reg_write_d), .q(reg_write_x));
	flopr #(1) mem_to_reg_reg_d_x(.clk, .reset(flush_x | reset), .d(mem_to_reg_d), .q(mem_to_reg_x));
	flopr #(1) dmem_write_reg_d_x(.clk, .reset(flush_x | reset), .d(dmem_write_d), .q(dmem_write_x));
	flopr #(3) alu_ctrl_reg_d_x(.clk, .reset(flush_x | reset), .d(alu_ctrl_d), .q(alu_ctrl_x));
	flopr #(1) alu_src_reg_d_x(.clk, .reset(flush_x | reset), .d(alu_src_d), .q(alu_src_x));
	flopr #(1) reg_dest_reg_d_x(.clk, .reset(flush_x | reset), .d(reg_dest_d), .q(reg_dest_x));

	// X-M Inter-stage registers
	flopr #(1) reg_write_reg_x_m(.clk, .reset, .d(reg_write_x), .q(reg_write_m));
	flopr #(1) mem_to_reg_reg_x_m(.clk, .reset, .d(mem_to_reg_x), .q(mem_to_reg_m));
	flopr #(1) dmem_write_reg_x_m(.clk, .reset, .d(dmem_write_x), .q(dmem_write_m));

	// M-W Inter-stage registers
	flopr #(1) reg_write_reg_m_w(.clk, .reset, .d(reg_write_m), .q(reg_write_w));
	flopr #(1) mem_to_reg_reg_m_w(.clk, .reset, .d(mem_to_reg_m), .q(mem_to_reg_w));
	
endmodule
