# 2D_magtopo
在二维材料数据库2Dmatpeida中寻找磁性拓扑材料的工作流  
数据库网站：http://2dmatpedia.org/  
需要的软件包：pymatgen，Phonopy，FINDSYM，Mvasp2trace  
  
工作流程：  
1. 从网站上下载材料数据库db.json，然后使用dbjson2poscar.sh批量生成POSCAR  
2. 从db.json中获取每个结构的空间群，存放在db_sgnumber中  
3. 使用checksg_db_phonopy_lattice.sh，调用Phonopy使POSCAR标准化  
4. 检查checksg_diff，看有哪些结构Phonopy判断的空间群和db_sgnumber中的不一致  
5. 若有空间群不一致的结构，更改checksg_db_phonopy_lattice.sh中开头部分，让脚本读取checksg_diff中的结构；调整phonopy判断对称性的精度。最终直到所有结构的空间群一致  
6. 使用posmag.sh，该脚本将调用FINDSYM判断磁空间群然后生成magset文件，该文件包含了结构的POSCAR，磁空间群(BNS)，INCAR中的LSORBIT和MAGMOM部分，以及Mvasp2trace中的高对称k点  
7. 使用vasp_htcal.sh完成任务的批量提交，其中每个计算的脚本为vaspjob.sh  
8. 计算完毕后使用jobcheck.sh检查自洽，能带，态密度，对称性指标的计算是否成功完成。scfcheck_result，bandcheck_result，doscheck_result，sicheck_result文件中输出内容不全的结构就是相应计算有误的。特别要注意自洽检查结果scfcheck_result，确保里面输出内容全，并且迭代次数未达到NELM (成功收敛)  
9. 分别使用piliang_topobandplot_soc.sh和piliang_tracecal.sh批量输出能带和trace.txt  
10. 使用autoWEB中的magtopo_identify.py，将trace.txt逐个提交至Bilbao网站上的"Check Topological Magnetic Mat."进行鉴定，并下载结果  
  
说明：  
1. 本计算预先把含有strong_corr中元素的结构挑出，计算为LSDA+SOC+U，只针对strong_corr中的元素加磁性和U，初始磁矩全部设为z方向3μB (0 0 3)，只对d轨道加U  
2. dbjson2poscar.sh生成的POSCAR的真空层都是c轴方向，但是经过Phonopy标准化处理之后不一定在c轴方向。因此特别注意：能带计算不能简单地使用vaspkit生成的2D kpath，这里使用的是Mvasp2trace中高对称k点连起来的路径；如果要计算Chern数，不能简单地将倒空间平面设置为(100,010)  
3. 能带计算的费米能级是从态密度计算中的DOSCAR中读取的，piliang_topobandplot_soc.sh批量画出的能带将费米能设为0eV，并且占据带 (能带序号为：1-电子数) 都标红，注意奇数电子的体系最高占据带颜色由于简并可能被盖住了  
  
