params.vh

-f $PROJ_ROOT/src_new/lsuv1/flist.f
-f $PROJ_ROOT/src_new/utils/commoncell/flist.f
-f $PROJ_ROOT/src_new/rvh_monolithic_mmu/flist.f

csr/excep_ctrl.v
rcu/rcu.sv
utils/commoncell/dpram64_2r1w.v

fetch/btb.v
fetch/gshare.v
fetch/ins_buffer.v
fetch/fetch.v

decode/rvc_decoder.v
decode/rv_decoder.v
decode/decode.v

fu/alu.v
fu/div.v
fu/lowRisc_mul_fast.v
fu/md.v
fu/fu.v
lsuv1/lsu_agu.v
lsuv1/lsu_bus_ctrl.v
lsuv1/lsu_lsq_entry.v
lsuv1/lsu_lsq.v
lsuv1/lsu_mc.v
lsuv1/lsu_pma_checker.v
lsuv1/lsu_wb_arb.v
lsuv1/lsuv1.v
csr/csr_regfile.v
csr/csr.sv

core.sv
tb_top.sv

/work/stu/xuzhixuan/workspace/hehecore-2-0/src_new/dpi_file/co_sim.cpp
