import os
import sys
SV2V = os.environ['SV2V']
PROJ_ROOT = os.environ['PROJ_ROOT']
FILELIST_DIR = f"{PROJ_ROOT}/src_new/lsuv1/flist.f"
NEW_FILELIST_DIR = f"{PROJ_ROOT}/src_new/lsuv1/vflist.f"
argv = sys.argv

usage = """\
a stupid python script.
usage:
    use ONLY one of the following options.
    -g, --generate, generate    : genegate v from sv using a filelist
    -c, --clean, clean          : delete generated v files
    -h, --help, help            : help
"""
if len(argv) != 2:
    print("illegal usage")
    print(usage)
elif argv[1] == "-h" or argv[1] == "--help" or argv[1] == "help":
    print(usage)
elif argv[1] == "-g" or argv[1] == "--generate" or argv[1] == "generate":
    flist = open(FILELIST_DIR, mode='r')
    newflist = open(NEW_FILELIST_DIR, mode='w')
    fstring = ""
    for line in flist:
        if(line == "\n"):
            continue
        if(line.find(".v") != -1):
            newflist.write(line)   
            continue
        if(line[0] == '/'  and line[1] == '/'):
            continue
        if(line[0] == '+' ):
            continue
        newflist.write(line.replace(".sv", ".v"))
        line = line.replace("\n", "")
        fstring += line
        fstring += " "
    print(fstring)
    os.system(f"{SV2V} {fstring} --write=adjacent --define=SYNTHESIS")
    flist.close()
    newflist.close()
elif argv[1] == "-c" or argv[1] == "--clean" or argv[1] == "clean":
    flist = open(FILELIST_DIR, mode='r')
    rmfilelist = []
    for line in flist:
        if(line == "\n"):
            continue
        if(line.find(".v") != -1):
            continue
        if(line[0] == '/'  and line[1] == '/'):
            continue
        if(line[0] == '+' ):
            continue
        line = line.replace("\n", "")
        rmfilelist.append(line.replace(".sv", ".v"))
    flist.close()
    for file in rmfilelist:
        os.system(f"rm {file}")
    # print(rmfilelist)
else:
    print("illegal usage")
    print(usage)