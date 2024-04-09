*-设置路径（每次打开都要运行）
	global path "F:\Stata17\ado\personal\Digital Economy and Export Product Switching"    //定义课程目录
	global D    "$path\data"      //数据
	global R    "$path\refs"      //参考文献 
	global O 	"$path\out"	 	  //最后输出结果

********************************************************************************
**#原始工企库处理
local start = 1
if `start' == 1 {
*乱码处理
	cd "$D\原始数据98-14"
	local dir_dta: dir . files "*.dta", respectcase //windows系统需要加respectcase选项以区分大小写
	cap mkdir "backup files"  //建立备份文件夹

foreach dta_file of local dir_dta {
	qui copy `dta_file' "backup files\", replace //将当前文件夹的dta数据备份至"backup files"文件夹中
	qui use `dta_file', clear
	
	*对数据标签进行转码
	local data_lbl: data label
	local data_lbl = ustrfrom("`data_lbl'", "gb18030", 1)
	label data "`data_lbl'"
	
	*对变量名、变量标签、字符型变量取值转码
	foreach v of varlist _all {
			* 对字符型变量取值进行转码
			local type: type `v'   //将变量的类型放入宏type中
			if strpos("`type'", "str") {
				replace `v' = ustrfrom(`v', "gb18030", 1)   //如果变量是字符型变量，使用ustrfrom()函数进行转码
			}
		* 对变量标签进行转码
		local lbl: var label `v'   //将变量的标签放入宏lbl中
		local lbl = ustrfrom("`lbl'", "gb18030", 1)   //使用ustrfrom()函数对`lbl'转码
		label var `v' `"`lbl'"'   //将转码后的字符串作为变量的标签
		* 对变量名进行转码
		local newname = ustrfrom(`"`v'"', "gb18030", 1)   //使用ustrfrom()函数将变量名字符串进行转码
		qui rename `v' `newname'   //将转码后的字符串重命名为变量名
	}

	*下面对数值标签进行转码
	qui label save using label.do, replace   //将数值标签的程序保存到label.do中
	preserve
	*- 将do文件的内容用txt的方式导入一个变量之中，然后再对该变量进行拉直
	qui import delimited using label.do, ///
	  varnames(nonames) delimiters("asf:d5f15g4dsf9qw8d4d5d",asstring) encoding(gb18030) clear
	qui describe
	if r(N) == 0 {
		restore
		save `dta_file', replace
	}
	else {
		qui levelsof v1, local(v1_lev)
		restore
		foreach label_modify of local v1_lev {    //这个的foreach与前面的local(v_lev)对应，细节可查看帮助文件
		`label_modify' //依次对原数据执行值标签替换操作
		} 
		save `dta_file', replace  //将转码好的dta文件替换原来的dta文件
	}
		
	* 删除中间临时文件
	erase label.do
}

	
*-合并两个2010年数据
	cd"$D\原始数据98-14\合并两个2010年"
	use 2010_1.dta,clear 
	duplicates drop frdm,force
	drop cyrs zczj yysr 
	save ,replace 
	use 2010_2.dta,clear 	
	duplicates drop frdm,force	
	drop xzqdm province city zycp1 zycp2 zycp3 xydm frdw qh tel fjh fax ///
	website yzbm zclx kgqk lsgx kysjn kysjy yyzt jglx kjlb dwszj qydws year ///
	email dqdm county village
	save ,replace
	use 2010_1.dta,clear 
	merge 1:1 frdm using 2010_2,force
	keep if _merge==3
	rename gyzczxz gyzczbbjxgd
	label var gyzczbbjxgd "工业总产值_不变价(千元)"
	rename gyxsczyz gyzczxjxgd
	label var gyzczxjxgd "工业总产值_当年价格(千元)"
	label var xcpcz "其中：新产品产值(千元)"
	label var ckjhz "其中：出口交货值(千元)"
	label var gyzjz  "工业增加值(千元)"
	rename cyrs nmcyry
	label var nmcyry "年末从业人员合计（人）" 
	rename cyrsjz cyrs
	label var cyrs  "全部从业人员年平均人数(人)"
	label var  zczj "资产总计(千元)"
	label var gdzchj  "固定资产合计(千元)"
	label var ldzchj "流动资产合计(千元)"	
	label var dqtz "短期投资(千元)"
	label var ch "存货(千元)"
	label var yszkje "其中：应收账款(千元)"
	label var ccp "其中：产成品(千元)"
	label var cqtz "长期投资(千元)"
	label var gdzcyjhj "固定资产原价合计(千元)"
	label var ljzj "累计折旧(千元)"
	label var ldfzhj "流动负债合计(千元)"
	label var wxzc "无形资产(千元)"
	label var cqfzhj "长期负债合计(千元)"
	label var yfzk "其中：应付帐款(千元)"
	label var fzhj "长期负债合计(千元)"
	label var syzqyhj "所有者权益合计(千元)"
	label var sszb "其中：实收资本(千元)"
	label var gjzbj "国家资本(千元)"
	label var frzbj "法人资本(千元)"
	label var jtzbj "集体资本(千元)"
	label var gatzbj "港澳台资本(千元)"
	label var grzbj "个人资本(千元)"
	label var wszbj "外商资本(千元)"
	label var yysr "营业收入合计(千元)"
	label var zycb "主营业务(产品销售)成本(千元)"
	label var zyywsr "主营业务(产品销售)收入(千元)"
	label var cpxssjjfj "主营业务（产品销售）税金及附加(千元)"
	label var qtywlr "其他业务利润(千元)"
	label var qtywsr "其他业务收入(千元)"
	label var glfy "管理费用(千元)"
	label var yyfy "营业费用（产品销售费用）(千元)"
	label var sj "其中：税金(千元)"
	label var cwfy "财务费用(千元)"
	label var lxzc "其中：利息支出(千元)"
	label var tzsy "投资收益(千元)"
	label var yylr "营业利润(千元)"
	label var yywsr "营业外收入(千元)"
	label var lrze "利润总额(千元)"
	label var lsze "利税总额(千元)"
	label var yjsds "应交所得税(千元)"
	label var yjkff "其中：研究开发费(千元)"
	label var bnyjzzs "应交增值税(千元)"
	rename ( gjzb frzb jtzb gatzb grzb ) ( gjzbj frzbj jtzbj gatzbj grzbj )
	rename qzsj sj
	rename zyywcb zycb	
	rename zyywfyjfj cpxssjjfj
	drop ksqydws _merge
	rename email dzyx
	destring zczj gyzczbbjxgd gyzczxjxgd xcpcz ckjhz gyzjz cyrs ldzchj ///
	dqtz ch yszkje ccp cqtz gdzchj gdzcyjhj ljzj ldfzhj wxzc cqfzhj yfzk ///
	fzhj syzqyhj sszb gjzbj frzbj jtzbj gatzbj grzbj wszbj nmcyry yysr zycb ///
	zyywsr cpxssjjfj qtywlr qtywsr glfy yyfy sj cwfy lxzc tzsy yylr lrze ///
	yywsr lsze yjsds yjkff bnyjzzs ,replace
	save "$D\原始数据98-14\2010", replace
	
*-合并各年份截面数据为面板数据	
	cd "$D\原始数据98-14"
	forvalues i=1998/2014{
	use `i',clear
	gen year=`i'
	save ,replace
	}
	
	cd "$D\原始数据98-14"
	use 2000.dta, clear					
forvalues i=2001/2013{
	append using `i'.dta, force
	}
	save "$D\原始数据98-14\2000-2013", replace	
	recast str60 qymc, force
	recast str25 frdbxm, force	
	recast str25 town, force	
	recast str35 c jdbsc jwh, force	
	recast str30 cp1 cp2 cp3, force	
	save "$D\原始数据98-14\2000-2013", replace

*-生产率测算LP
	cd "$D\原始数据98-14"
	use 2000-2013.dta, clear
	*-补齐数据
	*（1）补齐工业增加值
	rename id id1
	gen id=substr(id,3,8)
	destring id ,replace
	xtset id year
	gen Y=gyzjz
	*2004采用工业增加值=销售收入（主营业务收入）+期末存货-期初存货-工业中间投入
	*				    +增值税（刘小玄 2018）
	bysort id: gen ch1=D.ch 
	replace Y=zyywsr+ch1-zjtrhj if year==2004	
	*2008-2013采用平均推算（刘诗一 2017）
	bysort year: egen sum_gyzjz=sum(Y) if year<2008
	bysort year: egen sum_gyzczxjxgd=sum(gyzczxjxgd) if year<2008
	gen ratio_gyzjz=sum_gyzjz/sum_gyzczxjxgd if year<2008
	egen av_ratio_gyzjz=mean(ratio_gyzjz) 
	replace Y=av_ratio_gyzjz*gyzczxjxgd if year>2007
	
	*（2）固定资产原价近似代替固定资产净值
	gen K=gdzchj
	
	*（3）从业人数
	gen L=cyrs
	
	*（4）中间投入
	*2008以后采用中间投入的估算值="存货"－"存货中的产成品"+"主营业务成本"－ "主营业务应付工资总额(或'本年应付工资总额') "－"主营业务应付福利费总额"（陈林 2018）
	gen M=zjtrhj
	gen A=ch
	gen B=ccp
	gen C=zycb
	gen D=bnyfgzze
	gen E=zyywyfflfze
	*-前三年平均填充2008工资
	bysort id : egen D1 = mean(D) if year>=2005&year<=2007
	bysort id : egen D2 = mean(D1) 	
	bysort id : replace D = D2 if D==. & year==2008
	drop D1 D2
	*-后三年平均填充2010工资
	bysort id : egen D1 = mean(D) if year>=2011&year<=2013
	bysort id : egen D2 = mean(D1) 	
	bysort id : replace D = D2 if D==. & year==2010
	drop D1 D2
	*-后三年平均填充2009工资
	bysort id : egen D1 = mean(D) if year>=2010&year<=2012
	bysort id : egen D2 = mean(D1) 	
	bysort id : replace D = D2 if D==. & year==2009
	drop D1 D2
	*-前三年平均填充2008福利
	bysort id : egen E1 = mean(E) if year>=2005&year<=2007
	bysort id : egen E2 = mean(E1) 	
	bysort id : replace E = E2 if E==. & year==2008
	drop E1 E2
	*-前三年平均填充2009福利
	bysort id : egen E1 = mean(E) if year>=2006&year<=2008
	bysort id : egen E2 = mean(E1) 	
	bysort id : replace E = E2 if E==. & year==2009
	drop E1 E2	
	*-前三年平均填充2010福利
	bysort id : egen E1 = mean(E) if year>=2007&year<=2009
	bysort id : egen E2 = mean(E1) 	
	bysort id : replace E = E2 if E==. & year==2010
	drop E1 E2	
	*-前三年平均填充2011福利
	bysort id : egen E1 = mean(E) if year>=2008&year<=2010
	bysort id : egen E2 = mean(E1) 	
	bysort id : replace E = E2 if E==. & year==2011
	drop E1 E2	
	*-前三年平均填充2012福利
	bysort id : egen E1 = mean(E) if year>=2009&year<=2011
	bysort id : egen E2 = mean(E1) 	
	bysort id : replace E = E2 if E==. & year==2012
	drop E1 E2	
	*-前三年平均填充2013福利
	bysort id : egen E1 = mean(E) if year>=2010&year<=2012
	bysort id : egen E2 = mean(E1) 	
	bysort id : replace E = E2 if E==. & year==2013
	drop E1 E2	
	*-其余缺失值填充为0
	replace D=0 if D==.
	replace E=0 if E==.	
	*-填充中间投入缺失值
	replace M=A-B+C-D-E if M==.
	drop A B C D E 
	*（5）计算tfp
	gen lnY=log(Y)
	gen lnL=log(L)
	gen lnK=log(K)
	gen lnM=log(M)
	levpet lnY, free(lnL) proxy(lnM) capital(lnK) i(id) t(year)
	predict tfp_lp,omega
	gen tfp=ln(tfp_lp)
	*-填补企业名称、法人代码、电话缺失值
	save, replace
}
********************************************************************************
**#工企-专利匹配
local start = 1
if `start' == 1 {
	cd "$D\专利与工业库汇总版"
	use 工企专利数量all.dta,clear
	*统一变量名
	keep 年份 设计型专利 发明型专利 实用型专利 总专利数量 企业匹配唯一标识码 省地县码
	rename (企业匹配唯一标识码 年份) (id1 year)
	label var id1 "企业匹配唯一标识码"
	label var year  "年份"
	duplicates drop year id1, force
	*匹配
	merge 1:1 year id1 using "$D\原始数据98-14\2000-2013"
	keep if __merge==3
	drop _merge
	*工企海关模糊名处理
	replace qymc=subinstr(qymc,"省","",.) 
	replace qymc=subinstr(qymc,"市","",.)
	replace qymc=subinstr(qymc,"县","",.)
	replace qymc=subinstr(qymc,"公司","",.)
	replace qymc=subinstr(qymc,"有限","",.)
	replace qymc=subinstr(qymc,"责任","",.)	
	save "$D\专利与工业库汇总版\工企-专利.dta",replace
}
********************************************************************************
**#清理工企-专利
local start = 1
if `start' == 1 {
*-1.剔除产值、销售额、职工人数、固定资产、总资产等重要变量缺省的样本
*-2.剔除存在问题的样本，比如当年折旧大于累计折旧、总资产小于流动资产、总资产小于固定资产净值、实收资本小于或者等于0的样本
	cd "$D\专利与工业库汇总版"
	use "工企-专利",clear

	*-剔除不需要年份
	drop if year<2000
	
	*-剔除从业人数缺失
	drop if cyrs<0|cyrs==.
	
	*-剔除固定资产缺失
	drop if gdzchj<0|gdzchj==.
	
	*-剔除总资产缺失
	drop if zczj<0|cyrs==.
	
	*-剔除总资产小于流动资产
	drop if zczj<ldzchj
	
	*-实收资本小于或者等于0
	drop if sszb<=0
	
	*-缺失值填充
	drop Y ch1 sum_gyzjz sum_gyzczxjxgd ratio_gyzjz av_ratio_gyzjz K L ///
	M lnY lnL lnK lnM tfp_lp dqdm
	sort id1 year
	bysort id1 : carryforward frdm, replace 
	gsort id1 -year
	bysort id1 : carryforward frdm, replace 
	sort id1 year
	bysort id1 : carryforward telephone , replace
	gsort id1 -year
	bysort id1 : carryforward telephone, replace 
	sort id1 year
	bysort id1 : carryforward qymc , replace
	gsort id1 -year
	bysort id1 : carryforward qymc, replace 
	
	duplicates drop year qymc ,force
	
	save "$D\专利与工业库汇总版\工企-专利-清洗版", replace

}	
********************************************************************************
**#新旧专利库合并（旧）
local start = 1
if `start' == 1 {
********************************************************************************
**#城市补充数据
	
	*直接可在excel中修改，有更新时运行一遍即可
	import excel "$D\2000~2019年中国城市统计年鉴地级市面板数据\地级市补充数据.xlsx", sheet("Sheet1")  firstrow clear
	tostring city_code,replace
	save "$D\2000~2019年中国城市统计年鉴地级市面板数据\地级市补充数据.dta",replace

	use "$D\2000~2019年中国城市统计年鉴地级市面板数据\中国城市统计年鉴地级市面板数据.dta",clear 
	rename (行政区划代码 城市) (city_code1 city) 
	gen city_code11=string(city_code1)   //	gen x=real(substr(string(city_code1),1,4))
	gen city_code=substr(city_code11,1,4)
	keep city_code city  //筛选数据，形成city_code city唯一代码
	order city_code city
	bysort city_code : gen A=_n
	keep if A==1
	drop A
*-时时更新数据
	append using "$D\2000~2019年中国城市统计年鉴地级市面板数据\地级市补充数据.dta",force
	save "$D\2000~2019年中国城市统计年鉴地级市面板数据\地级市面板数据.dta", replace
********************************************************************************
*-合并专利库（1998-2013）
	cd "$D\专利与工业库汇总版"
	use 工企专利数量1998, clear
	keep gqid 年份 设计型专利 发明型专利 实用型专利 总专利数量 企业匹配唯一标识码 ///
				组织机构代码 企业名称 省自治区直辖市 地区市州盟 固定电话 ///
				行业门类代码 行业大类代码 行业中类代码 行业小类代码 控股情况 ///
				隶属关系 登记注册类型 省地县码
	append using 工企专利数量1999.dta,force
	save 工企专利数量part1,replace

	use 工企专利数量2000, clear
forvalue i=1/9 {
	keep gqid 年份 设计型专利 发明型专利 实用型专利 总专利数量 企业匹配唯一标识码 ///
				组织机构代码 企业名称 省自治区直辖市 地区市州盟 固定电话 行业门类代码 ///
				行业大类代码 行业中类代码 行业小类代码 控股情况 隶属关系 登记注册类型 省地县码
	append using 工企专利数量200`i'.dta,force
}
	save 工企专利数量part2,replace

use 工企专利数量2010,clear
forvalue i=11/13{
	keep gqid 年份 设计型专利 发明型专利 实用型专利 总专利数量 企业匹配唯一标识码 ///
				组织机构代码 企业名称 省自治区直辖市 地区市州盟 固定电话 行业门类代码 ///
				行业大类代码 行业中类代码 行业小类代码 控股情况 隶属关系 登记注册类型 省地县码
	append using 工企专利数量20`i'.dta,force
}
	save 工企专利数量part3,replace	
	
	use 工企专利数量part1,replace
	append using 工企专利数量part2,force
	append using 工企专利数量part3,force
	keep 年份 设计型专利 发明型专利 实用型专利 总专利数量 企业匹配唯一标识码 ///
				组织机构代码 企业名称 省自治区直辖市 地区市州盟 固定电话 行业门类代码 ///
				行业大类代码 行业中类代码 行业小类代码 控股情况 隶属关系 登记注册类型 省地县码
save 工企专利数量all,replace
******************************************************************************** 
**#检查城市电话
*检查哪些城市固定电话是8位，方便从海关库提取电话
*use"$D\专利与工业库汇总版\工企专利数量all.dta" ,clear
*bysort 地区市州盟 :gen A=_n  
*keep 省自治区直辖市 地区市州盟 固定电话 A
*sort 省自治区直辖市
*bro 省自治区直辖市 地区市州盟 固定电话  if A ==1|A==2|A==3
*-8位固话城市：北京市 上海市 天津市 广州市 沈阳市 武汉市 重庆市 深圳市（海关库用）
*-前面多了0的7位固话：山东省，内蒙古自治区（工企专利用）
	use "$D\专利与工业库汇总版\工企专利数量all.dta" ,clear
	rename 年份 year
	gen tel1=substr(固定电话,-7,7) if 省自治区直辖市=="山东省"|省自治区直辖市=="内蒙古自治区"
	gen tel=固定电话
	replace tel=tel1 if 省自治区直辖市=="山东省"|省自治区直辖市=="内蒙古自治区"
	gen city=地区市州盟
	replace city=省自治区直辖市 if 省自治区直辖市=="北京市"|省自治区直辖市=="天津市" ///
	|省自治区直辖市=="重庆市" |省自治区直辖市=="上海市"
	drop tel1
	drop if missing(tel)
	rename 企业名称 company
	format company %-40s //调整格式（字符型）
	format tel %-20s     //调整格式（字符型）
	gen company1=company
	save "$D\专利与工业库汇总版\工企专利数量all_匹配.dta",replace
********************************************************************************
*-匹配城市数据和海关库
	use "$O\处理后出口数据\alldata_ex_final.dta" , clear
	gen city_code=substr(city11,1,4)
	merge m:1 city_code using "$D\2000~2019年中国城市统计年鉴地级市面板数据\地级市面板数据.dta"
	keep if _merge==3
	drop _merge
*-8位固话城市：北京市 上海市 天津市 广州市 沈阳市 武汉市 重庆市 深圳市
	rename tel tel1
	gen tel2=substr(tel,-8,8) if city=="北京市"|city=="上海市"|city=="天津市" ///
	|city=="广州市"|city=="沈阳市"|city=="武汉市"|city=="重庆市"|city=="深圳市"
	gen tel=substr(tel1,-7,7) 
	replace tel=tel2 if city=="北京市"|city=="上海市"|city=="天津市" ///
	|city=="广州市"|city=="沈阳市"|city=="武汉市"|city=="重庆市"|city=="深圳市"
	drop tel1 tel2 
	save "$O\处理后出口数据\alldata_ex_final_城市.dta",replace	
********************************************************************************


}
	
********************************************************************************
**#工企-专利-海关匹配
local start = 1
if `start' == 1 {
	cd "$D\细分数据"
	use export1_all_factor.dta, clear
	rename (company tel )(qymc telephone)
	label var telephone "固定电话"
	*海关数据模糊名处理
	replace qymc=subinstr(qymc,"省","",.)
	replace qymc=subinstr(qymc,"市","",.)
	replace qymc=subinstr(qymc,"县","",.)
	replace qymc=subinstr(qymc,"公司","",.)
	replace qymc=subinstr(qymc,"有限","",.)
	replace qymc=subinstr(qymc,"责任","",.)	
	duplicates drop year party_id ,force //删掉11W数据
	bysort party_id : gen A=_N  //生成指示变量方便后面剔除
	br qymc party_id A
	drop if A==1&qymc=="" 
	drop A
	replace telephone="" if telephone=="NULL"
	*填充企业名称
	sort party_id year
	bysort party_id : carryforward qymc, replace 
	gsort party_id -year
	bysort party_id : carryforward qymc, replace 
	*填充电话
	sort party_id year
	bysort party_id : carryforward telephone , replace
	gsort party_id -year
	bysort party_id : carryforward telephone, replace 
	*填充城市代码
	sort party_id year
	bysort party_id : carryforward city_code , replace
	gsort party_id -year
	bysort party_id : carryforward city_code, replace
	*匹配城市代码数据
	merge m:1 city_code using "$D\2000~2019年中国城市统计年鉴地级市面板数据\地级市面板数据.dta"
	drop if _merge==2
	
	*处理各城市电话（去除区号、符号等）
	*生成tel进行处理
	gen tel=telephone
	*1.去除空格、-、（）
	replace tel=subinstr(tel," ","",.) //去空格
	replace tel=subinstr(tel,"-","",.) //去-
	replace tel=subinstr(tel,"(","",.) //去(
	replace tel=subinstr(tel,")","",.) //去）
	
	*处理4位电话区号
	*哈尔滨市
	*识别各地区区号并进行标记后,删除有标记的区号
	gen A=substr(tel,1,4) if city=="哈尔滨市"
	gen tel1=substr(tel,5,.) if A=="0451" & city=="哈尔滨市"
	replace tel=tel1 if A=="0451" & city=="哈尔滨市"
	drop A tel1
	*长春市
	gen A=substr(tel,1,4) if city=="长春市"
	gen tel1=substr(tel,5,.) if A=="0431" & city=="长春市"
	replace tel=tel1 if A=="0431" & city=="长春市"
	drop A tel1
	*大连市
	gen A=substr(tel,1,4) if city=="大连市'"
	gen tel1=substr(tel,5,.) if A=="0411" & city=="大连市"
	replace tel=tel1 if A=="0411" & city=="大连市"
	drop A tel1	
	*石家庄市
	gen A=substr(tel,1,4) if city=="石家庄市'"
	gen tel1=substr(tel,5,.) if A=="0311" & city=="石家庄市"
	replace tel=tel1 if A=="0311" & city=="石家庄市"
	drop A tel1	
	*济南市
	gen A=substr(tel,1,4) if city=="济南市'"
	gen tel1=substr(tel,5,.) if A=="0531" & city=="济南市"
	replace tel=tel1 if A=="0531" & city=="济南市"
	drop A tel1
	*青岛市
	gen A=substr(tel,1,4) if city=="青岛市'"
	gen tel1=substr(tel,5,.) if A=="0532" & city=="青岛市"
	replace tel=tel1 if A=="0532" & city=="青岛市"
	drop A tel1
	*郑州市
	gen A=substr(tel,1,4) if city=="郑州市'"
	gen tel1=substr(tel,5,.) if A=="0371" & city=="郑州市"
	replace tel=tel1 if A=="0371" & city=="郑州市"
	drop A tel1
	*南阳市
	gen A=substr(tel,1,4) if city=="南阳市'"
	gen tel1=substr(tel,5,.) if A=="0377" & city=="南阳市"
	replace tel=tel1 if A=="0377" & city=="南阳市"
	drop A tel1
	*洛阳市
	gen A=substr(tel,1,4) if city=="洛阳市'"
	gen tel1=substr(tel,5,.) if A=="0379" & city=="洛阳市"
	replace tel=tel1 if A=="0379" & city=="洛阳市"
	drop A tel1
	*南昌市
	gen A=substr(tel,1,4) if city=="南昌市"
	gen tel1=substr(tel,5,.) if A=="0791" & city=="南昌市"
	replace tel=tel1 if A=="0791" & city=="南昌市"
	drop A tel1
	*长沙市
	gen A=substr(tel,1,4) if city=="长沙市"
	gen tel1=substr(tel,5,.) if A=="0731" & city=="长沙市"
	replace tel=tel1 if A=="0731" & city=="长沙市"
	drop A tel1
	*昆明市
	gen A=substr(tel,1,4) if city=="昆明市"
	gen tel1=substr(tel,5,.) if A=="0871" & city=="昆明市"
	replace tel=tel1 if A=="0871" & city=="昆明市"
	drop A tel1
	*杭州市
	gen A=substr(tel,1,4) if city=="杭州市"
	gen tel1=substr(tel,5,.) if A=="0571" & city=="杭州市"
	replace tel=tel1 if A=="0571" & city=="杭州市"
	drop A tel1
	*合肥市
	gen A=substr(tel,1,4) if city=="合肥市"
	gen tel1=substr(tel,5,.) if A=="0551" & city=="合肥市"
	replace tel=tel1 if A=="0551" & city=="合肥市"
	drop A tel1
	*苏州市
	gen A=substr(tel,1,4) if city=="苏州市"
	gen tel1=substr(tel,5,.) if A=="0512" & city=="苏州市"
	replace tel=tel1 if A=="0512" & city=="苏州市"
	drop A tel1
	*无锡市
	gen A=substr(tel,1,4) if city=="无锡市"
	gen tel1=substr(tel,5,.) if A=="0510" & city=="无锡市"
	replace tel=tel1 if A=="0510" & city=="无锡市"
	drop A tel1
	*常州市
	gen A=substr(tel,1,4) if city=="常州市"
	gen tel1=substr(tel,5,.) if A=="0519" & city=="常州市"
	replace tel=tel1 if A=="0519" & city=="常州市"
	drop A tel1
	*镇江市
	gen A=substr(tel,1,4) if city=="镇江市"
	gen tel1=substr(tel,5,.) if A=="0511" & city=="镇江市"
	replace tel=tel1 if A=="0511" & city=="镇江市"
	drop A tel1
	*扬州市
	gen A=substr(tel,1,4) if city=="扬州市"
	gen tel1=substr(tel,5,.) if A=="0514" & city=="扬州市"
	replace tel=tel1 if A=="0514" & city=="扬州市"
	drop A tel1
	*泰州市
	gen A=substr(tel,1,4) if city=="泰州市"
	gen tel1=substr(tel,5,.) if A=="0523" & city=="泰州市"
	replace tel=tel1 if A=="0523" & city=="泰州市"
	drop A tel1
	*南通市
	gen A=substr(tel,1,4) if city=="南通市"
	gen tel1=substr(tel,5,.) if A=="0513" & city=="南通市"
	replace tel=tel1 if A=="0513" & city=="南通市"
	drop A tel1
	*盐城市
	gen A=substr(tel,1,4) if city=="盐城市"
	gen tel1=substr(tel,5,.) if A=="0515" & city=="盐城市"
	replace tel=tel1 if A=="0515" & city=="盐城市"
	drop A tel1
	*淮安市
	gen A=substr(tel,1,4) if city=="淮安市"
	gen tel1=substr(tel,5,.) if A=="0517" & city=="淮安市"
	replace tel=tel1 if A=="0517" & city=="淮安市"
	drop A tel1
	*宿迁市
	gen A=substr(tel,1,4) if city=="宿迁市"
	gen tel1=substr(tel,5,.) if A=="0527" & city=="宿迁市"
	replace tel=tel1 if A=="0527" & city=="宿迁市"
	drop A tel1
	*连云港市
	gen A=substr(tel,1,4) if city=="连云港市"
	gen tel1=substr(tel,5,.) if A=="0518" & city=="连云港市"
	replace tel=tel1 if A=="0518" & city=="连云港市"
	drop A tel1
	*徐州市
	gen A=substr(tel,1,4) if city=="徐州市"
	gen tel1=substr(tel,5,.) if A=="0516" & city=="徐州市"
	replace tel=tel1 if A=="0516" & city=="徐州市"
	drop A tel1
	*宁波市
	gen A=substr(tel,1,4) if city=="宁波市"
	gen tel1=substr(tel,5,.) if A=="0574" & city=="宁波市"
	replace tel=tel1 if A=="0574" & city=="宁波市"
	drop A tel1
	*温州市
	gen A=substr(tel,1,4) if city=="温州市"
	gen tel1=substr(tel,5,.) if A=="0577" & city=="温州市"
	replace tel=tel1 if A=="0577" & city=="温州市"
	drop A tel1
	*佛山市
	gen A=substr(tel,1,4) if city=="佛山市"
	gen tel1=substr(tel,5,.) if A=="0755" & city=="佛山市"
	replace tel=tel1 if A=="0755" & city=="佛山市"
	drop A tel1
	*东莞市
	gen A=substr(tel,1,4) if city=="东莞市"
	gen tel1=substr(tel,5,.) if A=="0769" & city=="东莞市"
	replace tel=tel1 if A=="0769" & city=="东莞市"
	drop A tel1
	*中山市
	gen A=substr(tel,1,4) if city=="中山市"
	gen tel1=substr(tel,5,.) if A=="0760" & city=="中山市"
	replace tel=tel1 if A=="0760" & city=="中山市"
	drop A tel1
	*汕头市
	gen A=substr(tel,1,4) if city=="汕头市"
	gen tel1=substr(tel,5,.) if A=="0754" & city=="汕头市"
	replace tel=tel1 if A=="0754" & city=="汕头市"
	drop A tel1
	*福州市
	gen A=substr(tel,1,4) if city=="福州市"
	gen tel1=substr(tel,5,.) if A=="0591" & city=="福州市"
	replace tel=tel1 if A=="0591" & city=="福州市"
	drop A tel1
	*厦门市
	gen A=substr(tel,1,4) if city=="厦门市"
	gen tel1=substr(tel,5,.) if A=="0592" & city=="厦门市"
	replace tel=tel1 if A=="0592" & city=="厦门市"
	drop A tel1
	*泉州市
	gen A=substr(tel,1,4) if city=="泉州市"
	gen tel1=substr(tel,5,.) if A=="0595" & city=="泉州市"
	replace tel=tel1 if A=="0595" & city=="泉州市"
	drop A tel1
	*海口市
	gen A=substr(tel,1,4) if city=="海口市"
	gen tel1=substr(tel,5,.) if A=="0898" & city=="海口市"
	replace tel=tel1 if A=="0898" & city=="海口市"
	drop A tel1
	*三亚市
	gen A=substr(tel,1,4) if city=="三亚市"
	gen tel1=substr(tel,5,.) if A=="0898" & city=="三亚市"
	replace tel=tel1 if A=="0898" & city=="三亚市"
	drop A tel1
	*处理3位电话区号
	*沈阳市
	gen A=substr(tel,1,3) if city=="沈阳市"
	gen tel1=substr(tel,4,.) if A=="024" & city=="沈阳市"
	replace tel=tel1 if A=="024" & city=="沈阳市"
	drop A tel1
	*北京市
	gen A=substr(tel,1,3) if city=="北京市"
	gen tel1=substr(tel,4,.) if A=="010" & city=="北京市"
	replace tel=tel1 if A=="010" & city=="北京市"
	drop A tel1
	*天津市
	gen A=substr(tel,1,3) if city=="天津市"
	gen tel1=substr(tel,4,.) if A=="022" & city=="天津市"
	replace tel=tel1 if A=="022" & city=="天津市"
	drop A tel1
	*武汉市
	gen A=substr(tel,1,3) if city=="武汉市"
	gen tel1=substr(tel,4,.) if A=="027" & city=="武汉市"
	replace tel=tel1 if A=="027" & city=="武汉市"
	drop A tel1
	*西安市
	gen A=substr(tel,1,3) if city=="西安市"
	gen tel1=substr(tel,4,.) if A=="029" & city=="西安市"
	replace tel=tel1 if A=="029" & city=="西安市"
	drop A tel1
	*重庆市
	gen A=substr(tel,1,3) if city=="重庆市"
	gen tel1=substr(tel,4,.) if A=="023" & city=="重庆市"
	replace tel=tel1 if A=="023" & city=="重庆市"
	drop A tel1
	*成都市
	gen A=substr(tel,1,3) if city=="成都市"
	gen tel1=substr(tel,4,.) if A=="028" & city=="成都市"
	replace tel=tel1 if A=="028" & city=="成都市"
	drop A tel1
	*上海市
	gen A=substr(tel,1,3) if city=="上海市"
	gen tel1=substr(tel,4,.) if A=="021" & city=="上海市"
	replace tel=tel1 if A=="021" & city=="上海市"
	drop A tel1
	*南京市
	gen A=substr(tel,1,3) if city=="南京市"
	gen tel1=substr(tel,4,.) if A=="025" & city=="南京市"
	replace tel=tel1 if A=="025" & city=="南京市"
	drop A tel1
	*广州市
	gen A=substr(tel,1,3) if city=="广州市"
	gen tel1=substr(tel,4,.) if A=="020" & city=="广州市"
	replace tel=tel1 if A=="020" & city=="广州市"
	drop A tel1
	*处理其他城市
	gen tel1=substr(telephone,-7,7) if city!="哈尔滨市"|city!="长春市"|city!="大连市" ///
	|city!="石家庄市"|city!="济南市"|city!="青岛市"|city!="郑州市"|city!="南阳市" ///
	|city!="洛阳市"|city!="南昌市"|city!="长沙市"|city!="西安市"|city!="昆明市" ///
	|city!="南京市"|city!="杭州市"|city!="合肥市"|city!="苏州市"|city!="无锡市" ///
	|city!="常州市"|city!="镇江市"|city!="扬州市"|city!="扬州市"|city!="南通市" ///
	|city!="盐城市"|city!="淮安市"|city!="宿迁市"|city!="连云港市"|city!="徐州市" ///
	|city!="宁波市"|city!="广州市"|city!="温州市"|city!="佛山市"|city!="东莞市" ///
	|city!="中山市"|city!="汕头市"|city!="福州市"|city!="厦门市"|city!="泉州市" ///
	|city!="沈阳市"|city!="北京市"|city!="天津市"|city!="武汉市"|city!="重庆市" ///
	|city!="成都市"|city!="上海市"|city!="深圳市"|city!="海口市"|city!="三亚市"  //其他城市提取7位
	
	replace tel=tel1 if city!="哈尔滨市"|city!="长春市"|city!="大连市" ///
	|city!="石家庄市"|city!="济南市"|city!="青岛市"|city!="郑州市"|city!="南阳市" ///
	|city!="洛阳市"|city!="南昌市"|city!="长沙市"|city!="西安市"|city!="昆明市" ///
	|city!="南京市"|city!="杭州市"|city!="合肥市"|city!="苏州市"|city!="无锡市" ///
	|city!="常州市"|city!="镇江市"|city!="扬州市"|city!="扬州市"|city!="南通市" ///
	|city!="盐城市"|city!="淮安市"|city!="宿迁市"|city!="连云港市"|city!="徐州市" ///
	|city!="宁波市"|city!="广州市"|city!="温州市"|city!="佛山市"|city!="东莞市" ///
	|city!="中山市"|city!="汕头市"|city!="福州市"|city!="厦门市"|city!="泉州市" ///
	|city!="沈阳市"|city!="北京市"|city!="天津市"|city!="武汉市"|city!="重庆市" ///
	|city!="成都市"|city!="上海市"|city!="深圳市"|city!="海口市"|city!="三亚市" //其他城市提取7位
	drop tel1 _merge
	rename telephone telephone1
	rename tel telephone
	label var telephone "固定电话"
	duplicates drop year qymc, force
	save "$D\细分数据\export1_all_factor_模糊名",replace

	*工企-专利-海关匹配
	cd "$D\细分数据"
	use export1_all_factor_模糊名.dta, clear
	*1.用公司名匹配
	merge 1:1 year qymc using "$D\专利与工业库汇总版\工企-专利-清洗版.dta"
	drop if _merge==2
	rename _merge m2
	label var m2 "qymc匹配情况"
	save "$D\专利与工业库汇总版\工企_专利_海关_merge1.dta",replace
	*2.用电话匹配	
	use "$D\专利与工业库汇总版\工企-专利-清洗版.dta",clear
	drop if telephone==""
	duplicates drop year telephone, force	//删去重复值
	save "$D\专利与工业库汇总版\工企-专利-清洗版_notel.dta",replace	
	
	use export1_all_factor_模糊名.dta, clear
	drop if telephone==""
	duplicates drop year telephone, force	
	merge 1:1 year telephone using "$D\专利与工业库汇总版\工企-专利-清洗版_notel.dta"
	keep if _merge==3
	drop _merge 
	save "$D\专利与工业库汇总版\工企_专利_海关_merge2.dta",replace

*-3.合并匹配数据并删除重复值
	
	use "$D\专利与工业库汇总版\工企_专利_海关_merge1.dta",clear
	append using "$D\专利与工业库汇总版\工企_专利_海关_merge2.dta"	
	duplicates drop year qymc,force	
	save "$D\专利与工业库汇总版\工企_专利_海关.dta"	,replace
}
