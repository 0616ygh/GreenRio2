#include <cstring>
#include <svdpi.h>
#include <cstdio>
#include <stdint.h>
#include <vector>
#include <cstdlib>
#include <memory>

std::shared_ptr<std::vector<uint64_t>> preg;

// std::vector<int64_t> *preg; //在C++中维护一个物理寄存器堆来完成同步

extern "C"
{

    FILE *cosim_log;
#define coprint(...) fprintf(cosim_log, __VA_ARGS__)

    uint32_t bit32_tailor(int32_t origin, int32_t left, int32_t right)
    { // put the result at lowest position of the return value
        uint32_t mask = 1;
        uint32_t mask_width = left - right;
        for (int32_t i = 0; i < mask_width; i++)
        {
            mask <<= 1;
            mask++;
        }
        return (origin >> right) & mask;
    }

    void init_cosim()
    {
        preg = std::make_shared<std::vector<uint64_t>>(48);
        cosim_log = std::fopen("./cosim.log", "w");
        coprint("CoSim Initiated ...");
    }

    // insert into phsical_regfile.v to sync preg in C++
    void preg_sync(
        int32_t alu1_valid,
        int32_t alu2_valid,
        int32_t md_valid,
        int32_t lsu_valid,
        int32_t csru_valid,
        int64_t alu1_address,
        int64_t alu2_address,
        int64_t md_address,
        int64_t lsu_address,
        int64_t csru_address,
        int64_t alu1_data,
        int64_t alu2_data,
        int64_t md_data,
        int64_t lsu_data,
        int64_t csru_data)
    {
        if (alu1_valid & (alu1_address != 0))
        {
            preg->at(alu1_address) = alu1_data;
        }
        if (alu1_valid & (alu2_address != 0))
        {
            preg->at(alu2_address) = alu2_data;
        }
        if (alu1_valid & (md_address != 0))
        {
            preg->at(md_address) = md_data;
        }
        if (lsu_valid & (lsu_address != 0))
        {
            preg->at(lsu_address) = lsu_data;
        }
        if (alu1_valid & (csru_address != 0))
        {
            preg->at(csru_address) = csru_data;
        }
        preg->at(0) = 0;
    }

    bool csr_monitor_read = false; //当发射了一条csr指令时，当它在写csr的过程中就将其打印下来，这个必然是下个commit的结果
    bool csr_need_print = false;   //只有特定的csr被修改时才需要打印
    char const *csr_name;
    int64_t csr_value;

    // to do
    // char* csr_name_translate(int32_t address){
    //     switch(address){
    //         case 0x300: return "mstatus";
    //         case 0x344: return "mip";
    //         case 0x304: return "mie";
    //         case 0x305: return "mtvec";
    //         case 0x340: return "mscratch";
    //         case 0x341: return "mepc";
    //         case 0x342: return "mcause";
    //         case 0xb00: return "mcycle";
    //         case 0xb01: return "mtime";
    //         case 0xb02: return "instret";
    //         case 0xbc0: return "mtimecmp";
    //     }
    //     return "what";
    // }

    // csr write data
    void csr_monitor(int32_t address, uint8_t csr_write_valid, int64_t write_data)
    { //将信息保存下来， 在commit时使用
        if (csr_monitor_read && csr_write_valid)
        {
            // printf("3 %s\n", csr_name);
            csr_need_print = true;
            switch (address)
            {
            case 0x300: // mstatus
                csr_value = write_data;
                break;
            case 0x302: // medeleg
                csr_value = write_data & 0xaaaa;
                break;
            case 0x303: // mideleg
                csr_value = write_data & 0xaaa;
                break;
            case 0x305: // mtvec
                csr_value = write_data & 0xfffffffffffffffc;
                break;
            case 0x340: // mscratch
                csr_value = write_data;
                break;
            case 0x341: // mepc    note that in hehe it's 32bit
                csr_value = write_data;
                break;
            case 0x342: // mcause
                csr_value = 0x800000000000000f & write_data;
                break;
            case 0x343: // mtval
                csr_value = write_data;
                break;
            case 0x100: // sstatus
                csr_value = write_data;
                break;
            case 0x105: // stvec
                csr_value = write_data & 0xfffffffffffffffc;
                break;
            case 0x140: // sscratch
                csr_value = write_data;
                break;
            case 0x141: // sepc    note that in hehe it's 32bit
                csr_value = write_data;
                break;
            case 0x142: // scause
                csr_value = 0x800000000000000f & write_data;
                break;
            case 0x143: // stval
                csr_value = write_data;
                break;
            case 0x180: // satp
                csr_value = write_data;
                break;
            }
        }
    }

    // embed this function in rcu, when one instruction is commited, print it in the log file
    void log_print(
        int32_t do_rob_commit_first,
        int32_t do_rob_commit_second,
        int64_t rob_pc_first,
        int64_t rob_pc_second,
        int32_t rob_rd_first,
        int32_t rob_rd_second,
        int32_t rob_prd_first,
        int32_t rob_prd_second,
        int32_t rob_is_store_first,
        int32_t rob_is_store_second,
        int32_t rob_fence_first,
        int32_t rob_mret_first,
        int32_t rob_wfi_first,
        int32_t rob_is_csr,
        int32_t rob_csr_address)
    {
        if (do_rob_commit_first)
        {
            coprint("-----\n");
            coprint("0x%08X\n", rob_pc_first);
            // if(co_pc_in == 0x80000278)
            //     coprint("x%d <- 0x%016lX\n", co_rob_rd, preg->at(co_prf_name));
            if (rob_is_csr)
            { // Zicsr
                // printf("4 %s\n", csr_name_translate(co_csr_address));
                if (csr_need_print)
                {
                    // printf("2 %s\n", csr_name);
                    coprint("CSR %s <- 0x%016lX\n", csr_name, csr_value);
                    csr_need_print = false;
                }
                if (rob_rd_first)
                {
                    switch (rob_csr_address)
                    {
                    case 0x305: // mtvec
                        csr_name = "mtvec";
                        // printf("5 pc: 0x%08X\n", co_pc_in);
                        csr_monitor_read = true;
                        break;
                    case 0x340: // mscratch
                        csr_name = "mscratch";
                        csr_monitor_read = true;
                        break;
                    case 0x341: // mepc    note that in hehe it's 32bit
                        csr_name = "mepc";
                        csr_monitor_read = true;
                        break;
                    case 0x342: // mcause
                        csr_name = "mcause";
                        csr_monitor_read = true;
                        break;
                    } // more csr regfile to do
                    coprint("x%d <- 0x%016lX\n", rob_rd_first, preg->at(rob_prd_first));
                }
                csr_monitor_read = false;
            }
            else if (rob_fence_first)
            { // fence
              // coprint("fence\n");
            }
            else if (rob_mret_first)
            {
                // coprint("mret\n");
            }
            else if (rob_wfi_first)
            {
                // coprint("wfi\n");
            }
            else if (rob_is_store_first)
            {
            }
            else
            {
                if (!rob_is_csr)
                {
                    if (rob_rd_first)
                    {
                        // if(co_pc_in == 0x80000278){
                        // printf("now rd: %lx\n", co_prf_name);
                        //     printf("??? 0x%lx\n", preg->at(co_prf_name));
                        // }
                        // printf("x%d <- 0x%016lX\n", co_rob_rd, preg->at(co_prf_name));
                        coprint("x%d <- 0x%016lX\n", rob_rd_first, preg->at(rob_prd_first));
                    }
                }
            }
        }
    }
}
