import argparse

# opcode dict
opcode = { # for all instructions
    "add": "0110011", "addi": "0010011", "jal": "1101111", "jalr": "1100111", 
    "beq": "1100011", "ld": "0000011", "sd": "0100011", "csrrw": "1110011",
    "lui": "0110111", "auipc": "0010111", "ecall": "1110011" 
}
funct3 = { # for R, I, B, S-type
    "add": "000", "addi": "000", "jalr": "000", 
    "beq": "000", "ld": "011", "sd": "011", "csrrw": "001",
    "ecall": "000"
}
funct7 = { # for R-type
    "add": "0000000"
}
funct12 = { # for I-type privileged
    "ecall": "000000000000"
}

# instruction type list
r_type = ["add"]
i_type_imm = ["addi"]
i_type_offset= ["jalr", "ld"]
i_type_csr = ["csrrw"]
i_type_sys = ["ecall"]
b_type = ["beq"]
s_type = ["sd"]
u_type = ["lui", "auipc"]
j_type = ["jal"]

# register code
x_reg = {
    "x0": "00000", "x1": "00001", "x2": "00010", "x3": "00011", "x4": "00100", "x5": "00101", 
    "x6": "00110", "x7": "00111", "x8": "01000", "x9": "01001", "x10": "01010", "x11": "01011", 
    "x12": "01100", "x13": "01101", "x14": "01110", "x15": "01111", "x16": "10000", "x17": "10001", 
    "x18": "10010", "x19": "10011", "x20": "10100", "x21": "10101", "x22": "10110", "x23": "10111", 
    "x24": "11000", "x25": "11001", "x26": "11010", "x27": "11011", "x28": "11100", "x29": "11101", 
    "x30": "11110", "x31": "11111" 
}

# csr code
csr = {
    "mstatus": "001100000000"
}

# functions
def parse_args():
    """
    Create a command line parser.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", type=str,
                        help="The path of the input file containing instruction strings", dest="f")
    args = parser.parse_args()
    return args

def imm_gen(imm_int, imm_len):
    """
    Generate given length of immediate code in instructions.
    """
    imm_int  = imm_int % (2 ** imm_len)
    imm_bin  = bin(imm_int).replace("0b","")
    if imm_int >= 0:
        imm_code = "0" * (imm_len - len(imm_bin)) + imm_bin
    else:
        imm_code = "1" * (imm_len - len(imm_bin)) + imm_bin
    return imm_code

def bin2hex(instr_bin):
    """
    Translate the binary code of an instruction to the hexadecimal code.
    """
    hex_table = {
        "0000": "0", "0001": "1", "0010": "2", "0011": "3", "0100": "4", "0101": "5",
        "0110": "6", "0111": "7", "1000": "8", "1001": "9", "1010": "a", "1011": "b",
        "1100": "c", "1101": "d", "1110": "e", "1111": "f"
    }
    instr_hex = ""
    for i in range(len(instr_bin) // 4):
        instr_hex += hex_table[ instr_bin[4*i: 4*i+4] ]
    return instr_hex

def translate(line):
    """
    Translate an instruction assembly string to its 32-bit code.
    """
    line = line.strip("\n")
    fields = [i.strip(",") for i in line.split()]
    # print(fields)
    instr = fields[0]
    if instr in r_type:
        if7 = funct7[instr]
        if3 = funct3[instr]
        iop = opcode[instr]
        rd  = x_reg[fields[1]]
        rs1 = x_reg[fields[2]]
        rs2 = x_reg[fields[3]]
        icode = if7 + rs2 + rs1 + if3 + rd + iop 
    elif instr in i_type_imm:
        if3 = funct3[instr]
        iop = opcode[instr]
        rd  = x_reg[fields[1]]
        rs1 = x_reg[fields[2]]
        imm = imm_gen(int(fields[3]), 12)
        icode = imm + rs1 + if3 + rd + iop
    elif instr in i_type_offset:
        if3 = funct3[instr]
        iop = opcode[instr]
        rd  = x_reg[fields[1]]
        rs1 = x_reg[fields[2].split("(")[1].strip(")")]
        imm = imm_gen(int(fields[2].split("(")[0]), 12)
        icode = imm + rs1 + if3 + rd + iop
    elif instr in i_type_csr:
        if3 = funct3[instr]
        iop = opcode[instr]
        rd  = x_reg[fields[1]]
        rs1 = x_reg[fields[3]]
        csr = csr[fields[2]]
        icode = csr + rs1 + if3 + rd + iop
    elif instr in i_type_sys:
        if3 = funct3[instr]
        iop = opcode[instr]
        if12 = funct12[instr]
        icode = if12 + "00000" + if3 + "00000" + iop
    elif instr in b_type:
        if3 = funct3[instr]
        iop = opcode[instr]
        rs1 = x_reg[fields[1]]
        rs2 = x_reg[fields[2]]
        imm = imm_gen(int(fields[3]), 13)
        icode = imm[0] + imm[2:8] + rs2 + rs1 + if3 + imm[8:12] + imm[1] + iop
    elif instr in s_type:
        if3 = funct3[instr]
        iop = opcode[instr]
        rs2  = x_reg[fields[1]]
        rs1 = x_reg[fields[2].split("(")[1].strip(")")]
        imm = imm_gen(int(fields[2].split("(")[0]), 12)
        icode = imm[0:7] + rs2 + rs1 + if3 + imm[7:12] + iop
    elif instr in u_type:
        iop = opcode[instr]
        rd  = x_reg[fields[1]]
        imm = imm_gen(int(fields[2]), 20)
        icode = imm + rd + iop
    else: # j_type
        iop = opcode[instr]
        rd  = x_reg[fields[1]]
        imm = imm_gen(int(fields[2]), 21)
        icode = imm[0] + imm[10:20] + imm[9] + imm[1:9] + rd + iop

    return icode

def main():
    args = parse_args()
    filename = args.f.split(".asm")[0]
    asm = open(args.f, "r")
    asm_lines = asm.readlines()
    asm.close()
    data = open(filename+".data", "w")
    i = 0
    for line in asm_lines:
        data_line = bin2hex(translate(line))
        data.write(data_line)
        i = i + 1
        if (i%4 == 0):
            data.write("\n")
    data.close()

if __name__ == "__main__":
    main()