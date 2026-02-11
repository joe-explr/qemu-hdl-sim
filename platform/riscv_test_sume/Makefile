
all:
	vivado -mode batch -source newprj.tcl

clean:
	- rm -rf *.cache *.hw *.ip_user_files *.sim *.srcs *.xpr .Xil *.tmp
	- rm -rf *.runs
	- rm -rf *.sdk
	- rm -rf updatemem.*
	- rm -rf webtalk*
	- rm -rf vivado*
	- rm -rf hs_err*
	- rm -rf *.bit

dlm:
	vivado -mode batch -source download_moosehead.tcl

dlt:
	vivado -mode batch -source download_triangle.tcl

syn:
	vivado -mode batch -source syn.tcl

par:
	vivado -mode batch -source par.tcl

new: clean all

