import configparser as cp

def intIn32Hex(a, with0x=False):
    if with0x:
        return "{0:#0{1}x}".format(a, 10)
    else:
        return "{0:0{1}x}".format(a, 8)

config_file = cp.ConfigParser()
config_file.read('hw_config.ini')

if (not config_file.has_section("project")):
    print("Error! No [project] section found in the config file")
    exit()

print("Start parsing hw_config.ini ...")
with open("hwtab.coe", "w+") as coeFile:
    coeFile.write("memory_initialization_radix=16;\n")
    coeFile.write("memory_initialization_vector=\n")

    sec_names = config_file.sections()
    dma_secs = []
    mem_secs = []
    peri_secs = []

    for sec in sec_names:
        if sec.startswith('dma'):
            dma_secs.append(sec)
        if sec.startswith('mem'):
            mem_secs.append(sec)
        if sec.startswith('peri'):
            peri_secs.append(sec)

    # Table Overall Description generation
    num_subsecs = len(dma_secs) + len(mem_secs) + len(peri_secs)
    compas_id_lower = 0x4D504153
    compas_id_upper = 0x0000434F
    proj_info = int(config_file['project']['project_id'], 16) & 0xFFFF
    proj_info += (int(config_file['project']['major_version']) & 0xF) << 16
    proj_info += (int(config_file['project']['minor_version']) & 0xF) << 20
    proj_info += (num_subsecs & 0xFF) << 24
    coeFile.write(intIn32Hex(compas_id_lower) + ",\n" + \
        intIn32Hex(compas_id_upper) + ",\n" + \
        intIn32Hex(proj_info) + ",\n" + \
        intIn32Hex(0) + ",\n")

    # DMA sections generation
    for dma in dma_secs:
        dma_base_info = int(config_file[dma]['pci_bar_id']) & 0xF
        dma_base_info += (int(config_file[dma]['major_version']) & 0x1F) << 8
        dma_base_info += (int(config_file[dma]['minor_version']) & 0x7) << 13
        dma_base_info += (int(config_file[dma]['mode']) & 0xF) << 16
        dma_base_info += (int(config_file[dma]['vendor']) & 0xF) << 20
        dma_base_info += (int(config_file[dma]['peripheral_id']) & 0xF) << 24
        dma_base_info += (1 & 0xF) << 28
        coeFile.write(intIn32Hex(dma_base_info) + ",\n")
        dma_ext_info = int(config_file.getboolean(dma, 'alignment')) & 0xFF
        dma_ext_info += (int(config_file[dma]['sg_len_bit']) & 0xFF) << 8
        coeFile.write(intIn32Hex(dma_ext_info) + ",\n")
        coeFile.write(intIn32Hex(int(config_file[dma]['lower_offset'], 16)) + ",\n")
        coeFile.write(intIn32Hex(int(config_file[dma]['upper_offset'], 16)) + ",\n")

    for mem in mem_secs:
        mem_base_info = int(config_file[mem]['pci_bar_id']) & 0xF
        mem_base_info += (int(config_file[mem]['major_version']) & 0x1F) << 8
        mem_base_info += (int(config_file[mem]['minor_version']) & 0x7) << 13
        mem_base_info += (int(config_file[mem]['mode']) & 0xF) << 16
        mem_base_info += (int(config_file[mem]['vendor']) & 0xF) << 20
        mem_base_info += (int(config_file[mem]['peripheral_id']) & 0xF) << 24
        mem_base_info += (2 & 0xF) << 28
        coeFile.write(intIn32Hex(mem_base_info) + ",\n")
        mem_ext_info = int(config_file[mem]['mem_size']) & 0xFFFF
        mem_ext_info += (int(config_file[mem]['mem_type']) & 0xF) << 16
        coeFile.write(intIn32Hex(mem_ext_info) + ",\n")
        coeFile.write(intIn32Hex(int(config_file[mem]['lower_offset'], 16)) + ",\n")
        coeFile.write(intIn32Hex(int(config_file[mem]['upper_offset'], 16)) + ",\n")

    for idx, peri in enumerate(peri_secs):
        peri_base_info = int(config_file[peri]['pci_bar_id']) & 0xF
        peri_base_info += (int(config_file[peri]['major_version']) & 0x1F) << 8
        peri_base_info += (int(config_file[peri]['minor_version']) & 0x7) << 13
        peri_base_info += (int(config_file[peri]['mode']) & 0xF) << 16
        peri_base_info += (int(config_file[peri]['vendor']) & 0xF) << 20
        peri_base_info += (int(config_file[peri]['peripheral_id']) & 0xF) << 24
        peri_base_info += (3 & 0xF) << 28
        coeFile.write(intIn32Hex(peri_base_info) + ",\n")
        # peri_ext_info = int(config_file[peri]['peri_size']) & 0xFFFF
        # peri_ext_info += (int(config_file[peri]['peri_type']) & 0xF) << 16
        coeFile.write(intIn32Hex(0) + ",\n")
        coeFile.write(intIn32Hex(int(config_file[peri]['lower_offset'], 16)) + ",\n")
        if (idx == len(peri_secs)-1) :
            coeFile.write(intIn32Hex(int(config_file[peri]['upper_offset'], 16)) + "\n")
        else:
            coeFile.write(intIn32Hex(int(config_file[peri]['upper_offset'], 16)) + ",\n")

    