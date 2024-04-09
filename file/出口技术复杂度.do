*计算k的出口技术复杂度*
local i=2003
while `i'<=2013 {
import delimited `i'.csv,clear 
save BACI_`i'.dta,replace
local i=`i'+1
}

use BACI_2003.dta,clear
append using BACI_2004 BACI_2005 BACI_2006 BACI_2007 BACI_2008 BACI_2009 BACI_2010 BACI_2011 BACI_2012 BACI_2013 BACI_2014

gen q1=subinstr(q,"NA",".",.)
destring q1, g(nq)
bysort i k t:egen  sv=sum(v)
bysort i k t:egen  sq=sum(nq)
drop j v q q1 nq
gen price=sv/sq
duplicates drop t i k,force
bysort t i k: gen x=sv
bysort t i: egen XX=sum(sv)
gen es=x/XX
bysort t k: egen ses=sum(es)
gen rca=es/ses
bysort t k: egen ksq=sum(sq)
gen u=sq/ksq
gen uprice=u*price
bysort t k: egen suprice=sum(uprice)
gen qk=price/suprice

label var t "year"
label var i "exporter"
label var k "product"
label var sv "一国产品k的出口额" 
label var sq "一国产品k的出口数量"
label var x "一国产品k的出口额"
label var XX "一国总出口额"
label var es "一国k的出口份额"
label var ses "各国k的出口份额的总和"
label var rca "显示性比较优势"
label var ksq "k的世界总出口数量"
label var u "一国产品k的出口占世界上产品k总出口的比重"
label var qk "相对价格指数"

merge m:1 t i using GDP2014.dta
drop if _merge==1
drop if _merge==2
drop _merge
gen rcagdp=rca*GDP
bysort t k: egen prody=sum(rcagdp)
gen prodyqua=(qk^0.2)*prody

rename k hs6 
rename t year
duplicates drop year hs6,force

save BACI总5.dta,replace

*计算企业的出口技术复杂度及控制变量-新数据03-13*
append using 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013
drop yzbm telph kysjy yyzt sjjg dzyj wz sfygh ghrs yysr zyywsr ncch dqtz yfzk zycb zysj qtsr qtlr yyfy clf ghjf bgf zgjyf pwf tzsy yywsr yywzc ggf ldbxf ylbxf zfgjj zjcl zzzjtr glzjtr yyzjtr jyxje tzxje czxje qbcyr yjkff sybxf jyxjr jyxjc tzxjr tzxjc czxjr czxjc ylylbxf qtywsr yszk yycb yysjjfj lxsr zcjzss gyjzbdsy zyywcb ncccp
drop if impexp==1

cd C:\Users\lenovo\Desktop\实验\实验5.0
order frdm hs6 year
destring hs6, replace force
merge m:1 year hs6 using BACI总5.dta
drop i sv sq price x XX es ses rca ksq u uprice suprice qk GDP rcagdp 
drop if _merge==1
drop if _merge==2
drop _merge
destring frdm, replace force
drop if frdm==.
format frdm %20.0f

****这一段是改过的
bysort frdm year hs6:egen  Sumexk=sum(fpvalue)
format Sumexk %20.0f
duplicates drop frdm year hs6,force
gen kckbz=Sumexk/SumEx
gen kjqpj=kckbz*prody
bysort frdm year:egen  EXPY=sum(kjqpj)
gen lnEXPY=ln(EXPY)

gen kjqpjqua=kckbz*prodyqua
bysort frdm year:egen  EXPYqua=sum(kjqpjqua)
gen lnEXPYqua=ln(EXPYqua)

label var Sumexk "企业出口k的总额"
label var SumEx "企业出口所有产品的总额"
label var kckbz "k的出口比重"
label var kjqpj "k的加权平均"
label var kjqpjqua "考虑质量的k的加权平均"
label var EXPY "企业出口技术复杂度"
label var lnEXPY "企业出口技术复杂度的对数"
label var EXPYqua "考虑质量的企业出口技术复杂度"
label var lnEXPYqua "考虑质量的企业出口技术复杂度的对数"

duplicates drop frdm year,force
