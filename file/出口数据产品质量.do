*-设置路径（每次打开都要运行）
	global path "F:\Stata15\ado\personal\Intermediate import and innovation"  //定义课程目录
	global D    "$path\data"      //数据
	global R    "$path\refs"      //参考文献
	global O 	"$path\out"		//最后输出结果
	
*-批量转码目录及子目录下所有文件，解决变量乱码问题（运行一次即可）
	* Unicode all files (.do, .ado, .dta, .hlp, etc.) in CWD and files in sub-directories
	cd "$path"
	. ua: unicode encoding set gb18030
	. ua: unicode retranslate *, invalid

*-解决标签乱码问题（运行一次即可）
	cd "$D"
	unicode analyze *
	unicode encoding set gb18030
	unicode retranslate *, invalid
	
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
*-处理2000
*-将零散海关条目按公司-商品-出口国进行分类并生成价值和数量变量
	cd "$D\处理后出口数据"
	use export1_2000, clear
	format company %-40s //调整格式（字符型）
	format tel %-20s     //调整格式（字符型）
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set

*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
*-将每年出口数据和分类标准匹配
*（m:m进行匹配，不同年份hs代码会匹配乱，但是产品分类大类基本没错）
	*-处理2000（匹配hs02）
	gen hs02=substr(hs_id,1,6)
	merge m:m hs02 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop  hs07 hs12 hs6 _merge
	*-计算公司出口总金额
	sort party_id 
	bysort party_id :egen value_party=total(value_unitall) 
	label var value_party "公司出口总金额"
	*-计算公司出口所有中间品总金额
	keep if inlist(shm,"中间产品","投资品","消费品") 
	sort party_id 
	bysort party_id :egen value_intermediate=total(value_unitall) if shm=="中间产品"
	label var value_intermediate "公司出口所有中间品总金额"
	gen ratio_intermediate=value_intermediate/value_party
	label var ratio_intermediate "出口中间品/总出口"
	*-计算公司出口所有投资品总金额
	sort party_id 
	bysort party_id :egen value_invest=total(value_unitall) if shm=="投资品"
	label var value_invest "公司出口所有投资品总金额"
	gen ratio_invest1=value_invest/value_party
	label var ratio_invest "出口投资品/总出口"
	*-计算公司出口所有消费品总金额
	sort party_id 
	bysort party_id :egen value_consume=total(value_unitall) if shm=="消费品"
	label var value_consume "公司出口所有消费品总金额"
	gen ratio_consume=value_consume/value_party
	label var ratio_consume " 出口消费品/总出口"

	*-计算从发达国家出口比例
	bysort party_id : egen value_developed=total(value_unitall) if developing1==0 & shm=="中间产品"
	label var value_developed "从发达国家出口中间品总价值"
	gen ratio_developed=value_developed/value_intermediate
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	*-计算公司出口所有中间品种类数
	sort party_id 
	bysort party_id value_intermediate: gen cat_intermediate1=_N  if shm=="中间产品" //产生计数变量_N(_n是编号变量)
	label var cat_intermediate "公司出口所有中间品种类数"

*-按公司填充空白数据，方便最后清理
	rename (value_intermediate ratio_intermediate value_invest ratio_invest  ///
	value_consume ratio_consume cat_intermediate value_developed ratio_developed) ///
	(value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1) 
	
	bysort party_id :egen value_intermediate=mean(value_intermediate1)
	bysort party_id :egen ratio_intermediate=mean(ratio_intermediate1)
	bysort party_id :egen value_invest=mean(value_invest1)
	bysort party_id :egen ratio_invest=mean(ratio_invest1)
	bysort party_id :egen value_consume=mean(value_consume1)
	bysort party_id :egen ratio_consume=mean(ratio_consume1)
	bysort party_id :egen cat_intermediate=mean(cat_intermediate1)
	bysort party_id :egen value_developed=mean(value_developed1)
	bysort party_id :egen ratio_developed=mean(ratio_developed1)
	
	label var value_intermediate "公司出口所有中间品总金额"
	label var ratio_intermediate "出口中间品/总出口"
	label var value_invest "公司出口所有投资品总金额"
	label var ratio_invest "出口投资品/总出口"
	label var value_consume "公司出口所有消费品总金额"
	label var ratio_consume "出口消费品/总出口"
	label var cat_intermediate "公司出口所有中间品种类数"
	label var value_developed "从发达国家出口中间品总价值"
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	drop value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1
*-提取需要变量另存数据
	keep year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	order year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	bysort party_id  : gen A=_n     //产生编号变量A，筛选数据
	keep if A==1
	drop A
	save "$D\处理后出口数据\再次处理后数据\export1_2000_2",replace
*-------------------------------------------------------------------------------

*-循环处理2001-2006
	cd "$D\处理后出口数据"
foreach file in export1_2001 export1_2002 export1_2003 export1_2004 ///
			 export1_2005 export1_2006{
	use `file', clear
   format company %-40s //调整格式（字符型）
	format tel %-20s     //调整格式（字符型）
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set

*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
*-将每年出口数据和分类标准匹配
*（m:m进行匹配，不同年份hs代码会匹配乱，但是产品分类大类基本没错）
	*-处理2001-2006（匹配hs02）
	gen hs02=substr(hs_id,1,6)
	merge m:m hs02 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop  hs07 hs12 hs6 _merge
	*-计算公司出口总金额
	sort party_id 
	bysort party_id :egen value_party=total(value_unitall) 
	label var value_party "公司出口总金额"
	*-计算公司出口所有中间品总金额
	keep if inlist(shm,"中间产品","投资品","消费品") 
	sort party_id 
	bysort party_id :egen value_intermediate=total(value_unitall) if shm=="中间产品"
	label var value_intermediate "公司出口所有中间品总金额"
	gen ratio_intermediate=value_intermediate/value_party
	label var ratio_intermediate "出口中间品/总出口"
	*-计算公司出口所有投资品总金额
	sort party_id 
	bysort party_id :egen value_invest=total(value_unitall) if shm=="投资品"
	label var value_invest "公司出口所有投资品总金额"
	gen ratio_invest1=value_invest/value_party
	label var ratio_invest "出口投资品/总出口"
	*-计算公司出口所有消费品总金额
	sort party_id 
	bysort party_id :egen value_consume=total(value_unitall) if shm=="消费品"
	label var value_consume "公司出口所有消费品总金额"
	gen ratio_consume=value_consume/value_party
	label var ratio_consume " 出口消费品/总出口"

	*-计算从发达国家出口比例
	bysort party_id : egen value_developed=total(value_unitall) if developing1==0 & shm=="中间产品"
	label var value_developed "从发达国家出口中间品总价值"
	gen ratio_developed=value_developed/value_intermediate
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	*-计算公司出口所有中间品种类数
	sort party_id 
	bysort party_id value_intermediate: gen cat_intermediate1=_N  if shm=="中间产品" //产生计数变量_N(_n是编号变量)
	label var cat_intermediate "公司出口所有中间品种类数"

*-按公司填充空白数据，方便最后清理
	rename (value_intermediate ratio_intermediate value_invest ratio_invest  ///
	value_consume ratio_consume cat_intermediate value_developed ratio_developed) ///
	(value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1) 
	
	bysort party_id :egen value_intermediate=mean(value_intermediate1)
	bysort party_id :egen ratio_intermediate=mean(ratio_intermediate1)
	bysort party_id :egen value_invest=mean(value_invest1)
	bysort party_id :egen ratio_invest=mean(ratio_invest1)
	bysort party_id :egen value_consume=mean(value_consume1)
	bysort party_id :egen ratio_consume=mean(ratio_consume1)
	bysort party_id :egen cat_intermediate=mean(cat_intermediate1)
	bysort party_id :egen value_developed=mean(value_developed1)
	bysort party_id :egen ratio_developed=mean(ratio_developed1)
	
	label var value_intermediate "公司出口所有中间品总金额"
	label var ratio_intermediate "出口中间品/总出口"
	label var value_invest "公司出口所有投资品总金额"
	label var ratio_invest "出口投资品/总出口"
	label var value_consume "公司出口所有消费品总金额"
	label var ratio_consume "出口消费品/总出口"
	label var cat_intermediate "公司出口所有中间品种类数"
	label var value_developed "从发达国家出口中间品总价值"
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	drop value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1
*-提取需要变量另存数据
	keep year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	order year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	bysort party_id  : gen A=_n     //产生编号变量A，筛选数据
	keep if A==1
	drop A
	save "$D\处理后出口数据\再次处理后数据\\`file'_2.dta",replace 
	//  \之后再加\防止'被转义
} 
*-------------------------------------------------------------------------------

*-循环处理2007-2011
	cd "$D\处理后出口数据"
foreach file in export1_2007 export1_2008 export1_2009 export1_2010 ///
			 export1_2011 {
  	use `file', clear
   format company %-40s //调整格式（字符型）
	format tel %-20s     //调整格式（字符型）
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set

*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
*-将每年出口数据和分类标准匹配
*（m:m进行匹配，不同年份hs代码会匹配乱，但是产品分类大类基本没错）
	*-处理2007-2011（匹配hs07）
	gen hs07=substr(hs_id,1,6)
	merge m:m hs07 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop  hs02 hs12 hs6 _merge
	*-计算公司出口总金额
	sort party_id 
	bysort party_id :egen value_party=total(value_unitall) 
	label var value_party "公司出口总金额"
	*-计算公司出口所有中间品总金额
	keep if inlist(shm,"中间产品","投资品","消费品") 
	sort party_id 
	bysort party_id :egen value_intermediate=total(value_unitall) if shm=="中间产品"
	label var value_intermediate "公司出口所有中间品总金额"
	gen ratio_intermediate=value_intermediate/value_party
	label var ratio_intermediate "出口中间品/总出口"
	*-计算公司出口所有投资品总金额
	sort party_id 
	bysort party_id :egen value_invest=total(value_unitall) if shm=="投资品"
	label var value_invest "公司出口所有投资品总金额"
	gen ratio_invest1=value_invest/value_party
	label var ratio_invest "出口投资品/总出口"
	*-计算公司出口所有消费品总金额
	sort party_id 
	bysort party_id :egen value_consume=total(value_unitall) if shm=="消费品"
	label var value_consume "公司出口所有消费品总金额"
	gen ratio_consume=value_consume/value_party
	label var ratio_consume " 出口消费品/总出口"

	*-计算从发达国家出口比例
	bysort party_id : egen value_developed=total(value_unitall) if developing1==0 & shm=="中间产品"
	label var value_developed "从发达国家出口中间品总价值"
	gen ratio_developed=value_developed/value_intermediate
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	*-计算公司出口所有中间品种类数
	sort party_id 
	bysort party_id value_intermediate: gen cat_intermediate1=_N  if shm=="中间产品" //产生计数变量_N(_n是编号变量)
	label var cat_intermediate "公司出口所有中间品种类数"

*-按公司填充空白数据，方便最后清理
	rename (value_intermediate ratio_intermediate value_invest ratio_invest  ///
	value_consume ratio_consume cat_intermediate value_developed ratio_developed) ///
	(value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1) 
	
	bysort party_id :egen value_intermediate=mean(value_intermediate1)
	bysort party_id :egen ratio_intermediate=mean(ratio_intermediate1)
	bysort party_id :egen value_invest=mean(value_invest1)
	bysort party_id :egen ratio_invest=mean(ratio_invest1)
	bysort party_id :egen value_consume=mean(value_consume1)
	bysort party_id :egen ratio_consume=mean(ratio_consume1)
	bysort party_id :egen cat_intermediate=mean(cat_intermediate1)
	bysort party_id :egen value_developed=mean(value_developed1)
	bysort party_id :egen ratio_developed=mean(ratio_developed1)
	
	label var value_intermediate "公司出口所有中间品总金额"
	label var ratio_intermediate "出口中间品/总出口"
	label var value_invest "公司出口所有投资品总金额"
	label var ratio_invest "出口投资品/总出口"
	label var value_consume "公司出口所有消费品总金额"
	label var ratio_consume "出口消费品/总出口"
	label var cat_intermediate "公司出口所有中间品种类数"
	label var value_developed "从发达国家出口中间品总价值"
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	drop value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1
*-提取需要变量另存数据
	keep year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	order year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	bysort party_id  : gen A=_n     //产生编号变量A，筛选数据
	keep if A==1
	drop A
	save "$D\处理后出口数据\再次处理后数据\\`file'_2.dta",replace 
	//  \之后再加\防止'被转义
} 
*-------------------------------------------------------------------------------

*-循环处理2012-2014（2012-2013缺tel）
	cd "$D\处理后出口数据"
foreach file in export1_2012 export1_2013  {
    use `file', clear
    format company %-40s //调整格式（字符型）
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set

*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
*-将每年出口数据和分类标准匹配
*（m:m进行匹配，不同年份hs代码会匹配乱，但是产品分类大类基本没错）
	*-处理2012-2014（匹配hs12）
	gen hs12=substr(hs_id,1,6)
	merge m:m hs12 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop  hs02 hs07 hs6 _merge
	*-计算公司出口总金额
	sort party_id 
	bysort party_id :egen value_party=total(value_unitall) 
	label var value_party "公司出口总金额"
	*-计算公司出口所有中间品总金额
	keep if inlist(shm,"中间产品","投资品","消费品") 
	sort party_id 
	bysort party_id :egen value_intermediate=total(value_unitall) if shm=="中间产品"
	label var value_intermediate "公司出口所有中间品总金额"
	gen ratio_intermediate=value_intermediate/value_party
	label var ratio_intermediate "出口中间品/总出口"
	*-计算公司出口所有投资品总金额
	sort party_id 
	bysort party_id :egen value_invest=total(value_unitall) if shm=="投资品"
	label var value_invest "公司出口所有投资品总金额"
	gen ratio_invest1=value_invest/value_party
	label var ratio_invest "出口投资品/总出口"
	*-计算公司出口所有消费品总金额
	sort party_id 
	bysort party_id :egen value_consume=total(value_unitall) if shm=="消费品"
	label var value_consume "公司出口所有消费品总金额"
	gen ratio_consume=value_consume/value_party
	label var ratio_consume " 出口消费品/总出口"

	*-计算从发达国家出口比例
	bysort party_id : egen value_developed=total(value_unitall) if developing1==0 & shm=="中间产品"
	label var value_developed "从发达国家出口中间品总价值"
	gen ratio_developed=value_developed/value_intermediate
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	*-计算公司出口所有中间品种类数
	sort party_id 
	bysort party_id value_intermediate: gen cat_intermediate1=_N  if shm=="中间产品" //产生计数变量_N(_n是编号变量)
	label var cat_intermediate "公司出口所有中间品种类数"

*-按公司填充空白数据，方便最后清理
	rename (value_intermediate ratio_intermediate value_invest ratio_invest  ///
	value_consume ratio_consume cat_intermediate value_developed ratio_developed) ///
	(value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1) 
	
	bysort party_id :egen value_intermediate=mean(value_intermediate1)
	bysort party_id :egen ratio_intermediate=mean(ratio_intermediate1)
	bysort party_id :egen value_invest=mean(value_invest1)
	bysort party_id :egen ratio_invest=mean(ratio_invest1)
	bysort party_id :egen value_consume=mean(value_consume1)
	bysort party_id :egen ratio_consume=mean(ratio_consume1)
	bysort party_id :egen cat_intermediate=mean(cat_intermediate1)
	bysort party_id :egen value_developed=mean(value_developed1)
	bysort party_id :egen ratio_developed=mean(ratio_developed1)
	
	label var value_intermediate "公司出口所有中间品总金额"
	label var ratio_intermediate "出口中间品/总出口"
	label var value_invest "公司出口所有投资品总金额"
	label var ratio_invest "出口投资品/总出口"
	label var value_consume "公司出口所有消费品总金额"
	label var ratio_consume "出口消费品/总出口"
	label var cat_intermediate "公司出口所有中间品种类数"
	label var value_developed "从发达国家出口中间品总价值"
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	drop value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1
*-提取需要变量另存数据
	keep year party_id  company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	order year party_id  company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	bysort party_id  : gen A=_n     //产生编号变量A，筛选数据
	keep if A==1
	drop A
	save "$D\处理后出口数据\再次处理后数据\\`file'_2.dta",replace 
	//  \之后再加\防止'被转义
} 

*-2014年的origin_id缺失，进行补充
	cd "$D\处理后出口数据"
	use 国家-ISO_countrycode.dta,clear	
	rename iso_3digit_alpha iso3
	rename 中文国家地区名称 chinaname
	keep iso3 chinaname
	merge m:m chinaname using"export1_2014未匹配.dta"
	keep if _merge==3
	drop _merge
	merge m:m iso3 using"country-code.dta"
	keep if _merge==3
	drop _merge
	save "export1_2014.dta",replace 
	
foreach file in  export1_2014 {
    use `file', clear
    format company %-40s //调整格式（字符型）
	format tel %-20s     //调整格式（字符型）
	**************************************************
	gen city11=substr(party_id,1,5) //2014年缺city11，自行生成一个
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set

*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
*-将每年出口数据和分类标准匹配
*（m:m进行匹配，不同年份hs代码会匹配乱，但是产品分类大类基本没错）
	*-处理2000-2001（匹配hs02）
	gen hs12=substr(hs_id,1,6)
	merge m:m hs12 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop  hs02 hs07 hs6 _merge
	*-计算公司出口总金额
	sort party_id 
	bysort party_id :egen value_party=total(value_unitall) 
	label var value_party "公司出口总金额"
	*-计算公司出口所有中间品总金额
	keep if inlist(shm,"中间产品","投资品","消费品") 
	sort party_id 
	bysort party_id :egen value_intermediate=total(value_unitall) if shm=="中间产品"
	label var value_intermediate "公司出口所有中间品总金额"
	gen ratio_intermediate=value_intermediate/value_party
	label var ratio_intermediate "出口中间品/总出口"
	*-计算公司出口所有投资品总金额
	sort party_id 
	bysort party_id :egen value_invest=total(value_unitall) if shm=="投资品"
	label var value_invest "公司出口所有投资品总金额"
	gen ratio_invest1=value_invest/value_party
	label var ratio_invest "出口投资品/总出口"
	*-计算公司出口所有消费品总金额
	sort party_id 
	bysort party_id :egen value_consume=total(value_unitall) if shm=="消费品"
	label var value_consume "公司出口所有消费品总金额"
	gen ratio_consume=value_consume/value_party
	label var ratio_consume " 出口消费品/总出口"

	*-计算从发达国家出口比例
	bysort party_id : egen value_developed=total(value_unitall) if developing1==0 & shm=="中间产品"
	label var value_developed "从发达国家出口中间品总价值"
	gen ratio_developed=value_developed/value_intermediate
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	*-计算公司出口所有中间品种类数
	sort party_id 
	bysort party_id value_intermediate: gen cat_intermediate1=_N  if shm=="中间产品" //产生计数变量_N(_n是编号变量)
	label var cat_intermediate "公司出口所有中间品种类数"

*-按公司填充空白数据，方便最后清理
	rename (value_intermediate ratio_intermediate value_invest ratio_invest  ///
	value_consume ratio_consume cat_intermediate value_developed ratio_developed) ///
	(value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1) 
	
	bysort party_id :egen value_intermediate=mean(value_intermediate1)
	bysort party_id :egen ratio_intermediate=mean(ratio_intermediate1)
	bysort party_id :egen value_invest=mean(value_invest1)
	bysort party_id :egen ratio_invest=mean(ratio_invest1)
	bysort party_id :egen value_consume=mean(value_consume1)
	bysort party_id :egen ratio_consume=mean(ratio_consume1)
	bysort party_id :egen cat_intermediate=mean(cat_intermediate1)
	bysort party_id :egen value_developed=mean(value_developed1)
	bysort party_id :egen ratio_developed=mean(ratio_developed1)
	
	label var value_intermediate "公司出口所有中间品总金额"
	label var ratio_intermediate "出口中间品/总出口"
	label var value_invest "公司出口所有投资品总金额"
	label var ratio_invest "出口投资品/总出口"
	label var value_consume "公司出口所有消费品总金额"
	label var ratio_consume "出口消费品/总出口"
	label var cat_intermediate "公司出口所有中间品种类数"
	label var value_developed "从发达国家出口中间品总价值"
	label var ratio_developed "从发达国家出口中间品总价值比例"
	
	drop value_intermediate1 ratio_intermediate1 value_invest1 ratio_invest1    ///
	value_consume1 ratio_consume1 cat_intermediate1 value_developed1 ratio_developed1
*-提取需要变量另存数据
	keep year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	order year party_id tel company city11 value_party value_intermediate ///
		 ratio_intermediate value_invest ratio_invest value_consume ///
		 ratio_consume cat_intermediate value_developed ratio_developed 
	bysort party_id  : gen A=_n     //产生编号变量A，筛选数据
	keep if A==1
	drop A
	save "$D\处理后出口数据\再次处理后数据\\`file'_2.dta",replace 
	//  \之后再加\防止'被转义
} 

*-------------------------------------------------------------------------------
*-合并各年份截面数据为面板数据
cd "$D\处理后出口数据\再次处理后数据"
use export1_2000_2, clear
forvalue i=1/9 {
     append using export1_200`i'_2.dta,force
}
save part,replace
use part,clear
forvalue i=10/14{
	append using export1_20`i'_2.dta,force
}
    format company %-40s 	  //调整格式（字符型）
	format tel %-20s     	  //调整格式（字符型）
	format party_id %-15s     //调整格式（字符型）
save "$O\处理后出口数据\alldata_ex_part1.dta",replace

*-出口产品质量计算
********************************************************************************
********************************************************************************
*-处理原始数据
	cd "$D\处理后出口数据"  //处理2000-2006
foreach file in export1_2000 export1_2001 export1_2002 export1_2003 export1_2004 ///
			 export1_2005 export1_2006{
    use `file', clear
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set
*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
	gen hs02=substr(hs_id,1,6)
	merge m:m hs02 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop _merge
	keep year party_id hs_id origin_id value_unitall quantity_unitall valperunit ///
		 hs02 hs07 hs12 hs6 shm
	order year party_id hs_id origin_id value_unitall quantity_unitall valperunit ///
		  hs02 hs07 hs12 hs6 shm
	save "$D\处理后出口数据\产品质量数据\\`file'_quality.dta",replace 
	}
	
cd "$D\处理后出口数据"  //处理2007-2011
foreach file in export1_2007 export1_2008 export1_2009 export1_2010 ///
			 export1_2011{
    use `file', clear
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set
*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
	gen hs07=substr(hs_id,1,6)
	merge m:m hs07 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop _merge
	keep year party_id hs_id origin_id value_unitall quantity_unitall valperunit ///
		 hs02 hs07 hs12 hs6 shm
	order year party_id hs_id origin_id value_unitall quantity_unitall valperunit ///
		  hs02 hs07 hs12 hs6 shm
	save "$D\处理后出口数据\产品质量数据\\`file'_quality.dta",replace 
	}
	
	cd "$D\处理后出口数据"  //处理2012-2014
foreach file in export1_2012 export1_2013 export1_2014 {
    use `file', clear
	bysort party_id hs_id origin_id :egen value_unitall=sum(value)
	label var value_unitall "公司-商品-出口国年度价值"
	bysort party_id hs_id origin_id :egen quantity_unitall=sum(quantity)
	label var quantity_unitall "公司-商品-出口国年度数量"
	order party_id hs_id origin_id value value_unitall quantity quantity_unitall
	*-删除重复value_unitall和quantity_unitall重复值
	sort party_id hs_id origin_id
	by party_id hs_id origin_id: gen set=_n
	keep if set==1 //只保留一个数据
	drop set
*-将每年出口数据与国家分类标准匹配
	merge m:m origin_id using"$D\处理后出口数据\country-code.dta"
	keep if _merge==3
	drop _merge
	gen hs12=substr(hs_id,1,6)
	merge m:m hs12 using"$D\处理后出口数据\hs12-07-02-bec-sitc.dta"
	keep if inlist(_merge,3)
	drop _merge
	keep year party_id hs_id origin_id value_unitall quantity_unitall valperunit ///
		 hs02 hs07 hs12 hs6 shm
	order year party_id hs_id origin_id value_unitall quantity_unitall valperunit ///
		  hs02 hs07 hs12 hs6 shm
	save "$D\处理后出口数据\产品质量数据\\`file'_quality.dta",replace 
	}
*-合并年份数据为面板数据
	cd "$D\处理后出口数据\产品质量数据"
	use export1_2002_quality, clear		
	destring valperunit,replace  //字符转数值
	save,replace
	use export1_2003_quality, clear	
	destring valperunit,replace
	save,replace
	
use export1_2000_quality, clear
forvalue i=1/9 {
     append using export1_200`i'_quality.dta,force
}
save part,replace
use part,clear
forvalue i=10/14{
	append using export1_20`i'_quality.dta,force
}
save alldata.dta,replace
*-将每年出口数据与sigma_m匹配
	cd "$D\处理后出口数据\产品质量数据" 
	use alldata,clear
	destring hs6,replace
	merge m:m hs6 using"$D\处理后出口数据\产品质量数据\sigma_m.dta" //此处有800w的数据没有sigma
	keep if _merge==3
	drop _merge
	
*-生成产品层面质量
	gen pq=log(quantity_unitall)+sigma_m*log(valperunit)  //quantity改为quantity_all,price改为valperunit
	drop if pq==.
	egen pairdummy_ct=group(origin_id year)
	gen const=1
	a2reg pq const, individual(pairdummy_ct) unit(hs_id) resid(quality) //安装a2reg
	label variable quality "sigma"
	*****************************************************
	drop pq pairdummy_ct
	gen sigma=5
	gen pq=log(quantity_unitall)+sigma*log(valperunit)
	egen pairdummy_ct=group(origin_id year)
	a2reg pq const, individual(pairdummy_ct) unit(hs_id) resid( quality_5)
	label variable quality_5 "sigma=5"	
	*****************************************************
	drop sigma pq pairdummy_ct
	gen sigma=10
	gen pq=log(quantity_unitall)+sigma*log(valperunit)
	egen pairdummy_ct=group(origin_id year)
	a2reg pq const, individual(pairdummy_ct) unit(hs_id) resid(quality_10)
	drop sigma pq pairdummy_ct
	label variable quality_10 "sigma=10"
	save "$D\处理后出口数据\产品质量数据\product_quality_all.dta",replace
	
*-生成公司层面质量	
	cd  "$D\处理后出口数据\产品质量数据" 
	use product_quality_all.dta,clear
*******************************************************************************	
*-全产品质量测算
	bysort party_id year:egen value_all=total(value_unitall)
	gen rate_all=value_unitall/value_all //生成全产品rate
	
	bysort hs_id :egen quality_max=max(quality)
	bysort hs_id :egen quality_min=min(quality)
	gen quality_wide=quality_max-quality_min
	gen r_quality=(quality-quality_min)/quality_wide
	label var r_quality "标准化后的产品质量"
	gen rate_quality=rate_all*r_quality
	bysort party_id year:egen firm_quality=total(rate_quality)
	label var firm_quality "弹性变化时某年企业的全产品出口质量"
	drop quality_max quality_min quality_wide r_quality rate_quality
	
	bysort hs_id :egen quality_max5=max(quality_5)
	bysort hs_id :egen quality_min5=min(quality_5)
	gen quality_wide5=quality_max5-quality_min5
	gen r_quality5=(quality_5-quality_min5)/quality_wide5
	label var r_quality5 "标准化后的产品质量"
	gen rate_quality5=rate_all*r_quality5
	bysort party_id year:egen firm_quality5=total(rate_quality5)
	label var firm_quality5 "弹性5时某年企业的全产品出口质量"
	drop quality_max5 quality_min5 quality_wide5 r_quality5 rate_quality5
	
	bysort hs_id :egen quality_max10=max(quality_10)
	bysort hs_id :egen quality_min10=min(quality_10)
	gen quality_wide10=quality_max10-quality_min10
	gen r_quality10=(quality_10-quality_min10)/quality_wide10
	label var r_quality10 "标准化后的产品质量"
	gen rate_quality10=rate_all*r_quality10
	bysort party_id year:egen firm_quality10=total(rate_quality10)
	label var firm_quality10 "弹性10时某年企业的全产品出口质量"
	drop quality_max10 quality_min10 quality_wide10 r_quality10 rate_quality10
******************************************************************************
*-另外分类情况下的全产品质量测算	
	bysort hs_id origin_id year:egen quality_max_1=max(quality)
	bysort hs_id origin_id year:egen quality_min_1=min(quality)
	gen quality_wide_1=quality_max_1-quality_min_1
	gen r_quality_1=(quality-quality_min_1)/quality_wide_1
	label var r_quality_1 "另分类标准化后的产品质量"
	gen rate_quality_1=rate_all*r_quality_1
	bysort party_id year:egen firm_quality_1=total(rate_quality_1)
	label var firm_quality_1 "另分类弹性变化时某年企业的全产品出口质量"
	drop quality_max_1 quality_min_1 quality_wide_1 r_quality_1 rate_quality_1
	
	bysort hs_id origin_id year:egen quality_max5_1=max(quality_5)
	bysort hs_id origin_id year:egen quality_min5_1=min(quality_5)
	gen quality_wide5_1=quality_max5_1-quality_min5_1
	gen r_quality5_1=(quality_5-quality_min5_1)/quality_wide5_1
	label var r_quality5_1 "另分类标准化后的产品质量"
	gen rate_quality5_1=rate_all*r_quality5_1
	bysort party_id year:egen firm_quality5_1=total(rate_quality5_1)
	label var firm_quality5_1 "另分类弹性5时某年企业的全产品出口质量"
	drop quality_max5_1 quality_min5_1 quality_wide5_1 r_quality5_1 rate_quality5_1
	
	bysort hs_id origin_id year:egen quality_max10_1=max(quality_10)
	bysort hs_id origin_id year:egen quality_min10_1=min(quality_10)
	gen quality_wide10_1=quality_max10_1-quality_min10_1
	gen r_quality10_1=(quality_10-quality_min10_1)/quality_wide10_1
	label var r_quality10_1 "另分类标准化后的产品质量"
	gen rate_quality10_1=rate_all*r_quality10_1
	bysort party_id year:egen firm_quality10_1=total(rate_quality10_1)
	label var firm_quality10_1 "另分类弹性10时某年企业的全产品出口质量"
	drop quality_max10_1 quality_min10_1 quality_wide10_1 r_quality10_1 rate_quality10_1
*******************************************************************************	
*-中间品质量测算	
	bysort party_id year:egen value_intermediate=total(value_unitall) if shm=="中间产品"
	gen rate_intermediate=value_unitall/value_intermediate //生成中间品rate
	
	bysort hs_id :egen quality_max_intermediate=max(quality) if shm=="中间产品"
	bysort hs_id :egen quality_min_intermediate=min(quality) if shm=="中间产品"
	gen quality_wide_intermediate=quality_max_intermediate-quality_min_intermediate
	gen r_quality_intermediate=(quality-quality_min_intermediate)/quality_wide_intermediate
	label var r_quality_intermediate "标准化后的中间产品质量"
	gen rate_quality_intermediate=rate_intermediate*r_quality
	bysort party_id year:egen firm_quality_intermediate=total(rate_quality)
	label var firm_quality_intermediate "弹性变化时某年企业的中间品出口质量"
	drop quality_max_intermediate quality_min_intermediate quality_wide_intermediate r_quality_intermediate rate_quality_intermediate
	
	bysort hs_id :egen quality_max5_intermediate=max(quality_5) if shm=="中间产品"
	bysort hs_id :egen quality_min5_intermediate=min(quality_5) if shm=="中间产品"
	gen quality_wide5_intermediate=quality_max5_intermediate-quality_min5_intermediate
	gen r_quality5_intermediate=(quality_5-quality_min5_intermediate)/quality_wide5_intermediate
	label var r_quality5_intermediate "标准化后的中间产品质量"
	gen rate_quality5_intermediate=rate_intermediate*r_quality5_intermediate
	bysort party_id year:egen firm_quality5_intermediate=total(rate_quality5_intermediate)
	label var firm_quality5_intermediate "弹性5时某年企业的中间品出口质量"
	drop quality_max5_intermediate quality_min5_intermediate quality_wide5_intermediate r_quality5_intermediate rate_quality5_intermediate
	
	bysort hs_id :egen quality_max10_intermediate=max(quality_10) if shm=="中间产品"
	bysort hs_id :egen quality_min10_intermediate=min(quality_10) if shm=="中间产品"
	gen quality_wide10_intermediate=quality_max10_intermediate-quality_min10_intermediate
	gen r_quality10_intermediate=(quality_10-quality_min10_intermediate)/quality_wide10_intermediate
	label var r_quality10_intermediate "标准化后的中间产品质量"
	gen rate_quality10_intermediate=rate_intermediate*r_quality10_intermediate
	bysort party_id year:egen firm_quality10_intermediate=total(rate_quality10_intermediate)
	label var firm_quality10_intermediate "弹性10时某年企业的中间品出口质量"
	drop quality_max10_intermediate quality_min10_intermediate quality_wide10_intermediate r_quality10_intermediate rate_quality10_intermediate
	
********************************************************************************
*-投资品质量测算	
	bysort party_id year:egen value_invest=total(value_unitall) if shm=="投资品"
	gen rate_invest=value_unitall/value_invest //生成投资品rate
	
	bysort hs_id :egen quality_max_invest=max(quality) if shm=="投资品"
	bysort hs_id :egen quality_min_invest=min(quality) if shm=="投资品"
	gen quality_wide_invest=quality_max_invest-quality_min_invest
	gen r_quality_invest=(quality-quality_min_invest)/quality_wide_invest
	label var r_quality_invest "标准化后的投资品质量"
	gen rate_quality_invest=rate_invest*r_quality_invest
	bysort party_id year:egen firm_quality_invest=total(rate_quality_invest)
	label var firm_quality_invest "弹性变化时某年企业的投资品出口质量"
	drop quality_max_invest quality_min_invest quality_wide_invest r_quality_invest rate_quality_invest
	
	bysort hs_id :egen quality_max5_invest=max(quality_5) if shm=="投资品"
	bysort hs_id :egen quality_min5_invest=min(quality_5) if shm=="投资品"
	gen quality_wide5_invest=quality_max5_invest-quality_min5_invest
	gen r_quality5_invest=(quality_5-quality_min5_invest)/quality_wide5_invest
	label var r_quality5_invest "标准化后的投资品质量"
	gen rate_quality5_invest=rate_invest*r_quality5_invest
	bysort party_id year:egen firm_quality5_invest=total(rate_quality5_invest)
	label var firm_quality5_invest "弹性5时某年企业的投资品出口质量"
	drop quality_max5_invest quality_min5_invest quality_wide5_invest r_quality5_invest rate_quality5_invest
	
	bysort hs_id :egen quality_max10_invest=max(quality_10) if shm=="投资品"
	bysort hs_id :egen quality_min10_invest=min(quality_10) if shm=="投资品"
	gen quality_wide10_invest=quality_max10_invest-quality_min10_invest
	gen r_quality10_invest=(quality_10-quality_min10_invest)/quality_wide10_invest
	label var r_quality10_invest "标准化后的投资品质量"
	gen rate_quality10_invest=rate_invest*r_quality10_invest
	bysort party_id year:egen firm_quality10_invest=total(rate_quality10_invest)
	label var firm_quality10_invest "弹性10时某年企业的投资品出口质量"	
	drop quality_max10_invest quality_min10_invest quality_wide10_invest r_quality10_invest rate_quality10_invest
********************************************************************************
*-消费品质量测算
	bysort party_id year:egen value_consume=total(value_unitall) if shm=="消费品"
	gen rate_consume=value_unitall/value_consume //生成消费品rate
	
	bysort hs_id :egen quality_max_consume=max(quality) if shm=="消费品"
	bysort hs_id :egen quality_min_consume=min(quality) if shm=="消费品"
	gen quality_wide_consume=quality_max_consume-quality_min_consume
	gen r_quality_consume=(quality-quality_min_consume)/quality_wide_consume
	label var r_quality_consume "标准化后的消费品质量"
	gen rate_quality_consume=rate_consume*r_quality_consume
	bysort party_id year:egen firm_quality_consume=total(rate_quality_consume)
	label var firm_quality_consume "弹性变化时某年企业的消费品出口质量"
	drop quality_max_consume quality_min_consume quality_wide_consume r_quality_consume rate_quality_consume

	
	bysort hs_id :egen quality_max5_consume=max(quality_5) if shm=="消费品"
	bysort hs_id :egen quality_min5_consume=min(quality_5) if shm=="消费品"
	gen quality_wide5_consume=quality_max5_consume-quality_min5_consume
	gen r_quality5_consume=(quality_5-quality_min5_consume)/quality_wide5_consume
	label var r_quality5_consume "标准化后的消费品质量"
	gen rate_quality5_consume=rate_consume*r_quality5_consume
	bysort party_id year:egen firm_quality5_consume=total(rate_quality5_consume)
	label var firm_quality5_consume "弹性5时某年企业的消费品出口质量"
	drop quality_max5_consume quality_min5_consume quality_wide5_consume r_quality5_consume rate_quality5_consume
	
	bysort hs_id :egen quality_max10_consume=max(quality_10) if shm=="消费品"
	bysort hs_id :egen quality_min10_consume=min(quality_10) if shm=="消费品"
	gen quality_wide10_consume=quality_max10_consume-quality_min10_consume
	gen r_quality10_consume=(quality_10-quality_min10_consume)/quality_wide10_consume
	label var r_quality10_consume "标准化后的消费品质量"
	gen rate_quality10_consume=rate_consume*r_quality10_consume
	bysort party_id year:egen firm_quality10_consume=total(rate_quality10_consume)
	label var firm_quality10_consume "弹性10时某年企业的消费品出口质量"		
	drop quality_max10_consume quality_min10_consume quality_wide10_consume r_quality10_consume rate_quality10_consume

*-每家公司保留一个条目
foreach i of varlist firm_quality firm_quality5 firm_quality10 ///
firm_quality_1 firm_quality5_1 firm_quality10_1 ///
firm_quality_intermediate firm_quality5_intermediate firm_quality10_intermediate ///
firm_quality_invest firm_quality5_invest firm_quality10_invest ///
firm_quality_consume firm_quality5_consume firm_quality10_consume{
	rename `i' `i'_11
	bysort party_id year :egen `i'=mean(`i'_11)
	drop `i'_11
	}
********************************************************************************	
	keep year party_id  firm_quality firm_quality5 firm_quality10 ///
			firm_quality_1 firm_quality5_1 firm_quality10_1 ///
		firm_quality_intermediate firm_quality5_intermediate firm_quality10_intermediate ///
		firm_quality_invest firm_quality5_invest firm_quality10_invest	///
		firm_quality_consume firm_quality5_consume firm_quality10_consume
	order year party_id  firm_quality firm_quality5 firm_quality10 ///
			firm_quality_1 firm_quality5_1 firm_quality10_1 ///
		firm_quality_intermediate firm_quality5_intermediate firm_quality10_intermediate ///
		firm_quality_invest firm_quality5_invest firm_quality10_invest	///
		firm_quality_consume firm_quality5_consume firm_quality10_consume
	bysort year party_id  firm_quality firm_quality5 firm_quality10 ///
			firm_quality_1 firm_quality5_1 firm_quality10_1 ///
		firm_quality_intermediate firm_quality5_intermediate firm_quality10_intermediate ///
		firm_quality_invest firm_quality5_invest firm_quality10_invest	///
		firm_quality_consume firm_quality5_consume firm_quality10_consume : ///
	gen A=_n     //产生编号变量A，筛选数据
	keep if A==1
	drop A
	save "$O\处理后出口数据\alldata_ex_part2.dta",replace
********************************************************************************
*-合并part1和part2
	cd "$O\处理后出口数据" 
	use alldata_ex_part2.dta ,clear
	merge 1:1 year party_id using"$O\处理后出口数据\alldata_ex_part1.dta"
	keep if _merge==3
	drop _merge
	order year party_id company tel city11
	save "$O\处理后出口数据\alldata_ex_final.dta",replace


	
********************************************************************************
*-城市补充数据（直接可在excel中修改，有更新时运行一遍即可）
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
				组织机构代码 企业名称 省自治区直辖市 地区市州盟 固定电话 行业门类代码 ///
				行业大类代码 行业中类代码 行业小类代码 控股情况 隶属关系 登记注册类型 省地县码
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

*-检查哪些城市固定电话是8位，方便从海关库提取电话
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
	

*-新老工企库匹配
	use "$D\专利与工业库汇总版\工企专利数量all_匹配",clear
	replace company=subinstr(company,"省","",.)
	replace company=subinstr(company,"市","",.)
	replace company=subinstr(company,"县","",.)
	replace company=subinstr(company,"公司","",.)
	replace company=subinstr(company,"有限","",.)
	replace company=subinstr(company,"责任","",.)
	save "$D\专利与工业库汇总版\工企专利数量all_匹配_模糊名"
	
	use "$D\工企库\industrynew_simple" ,clear
	rename qymc company	
	replace company=subinstr(company,"省","",.)
	replace company=subinstr(company,"市","",.)
	replace company=subinstr(company,"县","",.)
	replace company=subinstr(company,"公司","",.)
	replace company=subinstr(company,"有限","",.)
	replace company=subinstr(company,"责任","",.)
	rename city city_code1
	merge m:m year company using "$D\专利与工业库汇总版\工企专利数量all_匹配_模糊名" ,force
	drop if _merge==2
	rename _merge m1
	label var m1 "区分新老工企库匹配情况"
	save "$D\工企库\工企专利" ,replace
	
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

		
*-进口	
*-1.用公司名匹配	
*匹配海关库和企业专利库，杨红丽2015
	use "$O\处理后出口数据\alldata_ex_final_城市.dta",clear
	replace company=subinstr(company,"省","",.)
	replace company=subinstr(company,"市","",.)
	replace company=subinstr(company,"县","",.)
	replace company=subinstr(company,"公司","",.)
	replace company=subinstr(company,"有限","",.)
	replace company=subinstr(company,"责任","",.)	
	save "$O\处理后出口数据\alldata_ex_final_城市_模糊名.dta",replace
	
	use "$D\工企库\工企专利",clear
	merge m:m year company using "$O\处理后出口数据\alldata_ex_final_城市_模糊名.dta",force
	drop if _merge==2
	rename _merge m2
	label var m2 "区分companny匹配情况"
	save "$O\处理后出口数据\工企_专利_海关_merge1.dta",replace
	
	
*-2.用电话匹配	
*匹配海关库和企业专利库
	use "$D\工企库\工企专利",clear
	merge m:m year tel using "$O\处理后出口数据\alldata_ex_final_城市_模糊名.dta",force
	keep if _merge==3
	drop _merge 
	save "$O\处理后出口数据\工企_专利_海关_merge2.dta",replace

*-3.合并匹配数据并删除重复值
	
	use "$O\处理后出口数据\工企_专利_海关_merge1.dta",clear
	append using "$O\处理后出口数据\工企_专利_海关_merge2.dta"	
	duplicates drop year company,force	
	save "$O\处理后出口数据\工企_专利_海关.dta"	,replace
