SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
	Copyright © 2012 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS
=========================================================================
	Title:		updates ud cross reference tables in Viewpoint
	Created:	2012-01-31
	Created by:	MG
	Function:	update ud cross reference tables after a new pull of data
	Revisions:	
			1. 01-31-2012 MTG  creation 
 			2. 03/19/2012 BBA - Added Drop code.
 			3. 10/24/2012 BTC - Added Vendor cross reference updates for Vendors and Lienors
 			4. 11/19/2013 BTC - Custom for McKinstry: Vendors start at 500,000
 			
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_Refresh_xref] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

AS


-------------------------------Viewpoint.dbo.budxrefAPVendor------------------------------
--First pull from Vendor file
insert budxrefAPVendor (Company, OldVendorID, CGCVendorType, VendorGroup, NewVendorID, Name, ActiveYN)
select
	  Company = v.COMPANYNUMBER
	, OldVendorID = v.VENDORNUMBER
	, CGCVendorType = 'V'
	, VendorGroup = co.VendorGroup
	, NewVendorID = ISNULL(mx.MaxNewVendorID, 499999) 
		+ ROW_NUMBER () over (partition by co.VendorGroup order by v.ENTEREDDATE, v.VENDORNUMBER)
	, Name = v.NAME25
	, ActiveYN = 'Y'
--select count(1)
from CV_CMS_SOURCE.dbo.APTVEN v
left join (select distinct COMPANYNUMBER, VENDORNUMBER from CV_CMS_SOURCE.dbo.APTOPC) c
	on c.COMPANYNUMBER=case when v.COMPANYNUMBER=99 then 1 else v.COMPANYNUMBER end
		and c.VENDORNUMBER=v.VENDORNUMBER
left join (select distinct COMPANYNUMBER, VENDORNUMBER from CV_CMS_SOURCE.dbo.APTHCK) h
	on h.COMPANYNUMBER=case when v.COMPANYNUMBER=99 then 1 else v.COMPANYNUMBER end
		and h.VENDORNUMBER=v.VENDORNUMBER
left join (select distinct COMPANYNUMBER, VENDORNUMBER from CV_CMS_SOURCE.dbo.POTMCT) p
	on p.COMPANYNUMBER=case when v.COMPANYNUMBER=99 then 1 else v.COMPANYNUMBER end
		and p.VENDORNUMBER=v.VENDORNUMBER
left join (select distinct COMPANYNUMBER, VENDORNUMBER from CV_CMS_SOURCE.dbo.APTCNS) s
	on s.COMPANYNUMBER=case when v.COMPANYNUMBER=99 then 1 else v.COMPANYNUMBER end
		and s.VENDORNUMBER=v.VENDORNUMBER
left join budxrefAPVendor x
	on x.Company=v.COMPANYNUMBER and x.OldVendorID=v.VENDORNUMBER and x.CGCVendorType='V'
join bHQCO co
	on co.HQCo = @toco
join (select VendorGroup, MAX(NewVendorID) as MaxNewVendorID from budxrefAPVendor
		group by VendorGroup) mx
	on mx.VendorGroup = co.VendorGroup
where x.OldVendorID is null and case when v.COMPANYNUMBER = 99 then @fromco else v.COMPANYNUMBER end = @fromco
	and (c.VENDORNUMBER is not null or h.VENDORNUMBER is not null or p.VENDORNUMBER is not null
			or s.VENDORNUMBER is not null)

/**
--Then pull from Lienor file
insert budxrefAPVendor (Company, OldVendorID, CGCVendorType, VendorGroup, NewVendorID, Name, ActiveYN)
select
	  Company = l.COMPANYNUMBER
	, OldVendorID = l.LIENORNUMBER
	, CGCVendorType = 'L'
	, VendorGroup = co.VendorGroup
	, NewVendorID = l.LIENORNUMBER
	, Name = l.NAME25
	, ActiveYN = 'Y'
--select count(1)
from CV_CMS_SOURCE.dbo.APTLNN l
left join (select distinct COMPANYNUMBER, LIENORNUMBER from CV_CMS_SOURCE.dbo.APTOPC) c
	on c.COMPANYNUMBER=case when l.COMPANYNUMBER=99 then 1 else l.COMPANYNUMBER end
		and c.LIENORNUMBER=l.LIENORNUMBER
left join (select distinct COMPANYNUMBER, LIENORNUMBER from CV_CMS_SOURCE.dbo.APTHCK) h
	on h.COMPANYNUMBER=case when l.COMPANYNUMBER=99 then 1 else l.COMPANYNUMBER end
		and h.LIENORNUMBER=l.LIENORNUMBER
left join (select distinct COMPANYNUMBER, LIENORNUMBER from CV_CMS_SOURCE.dbo.APTCNS) s
	on s.COMPANYNUMBER=case when l.COMPANYNUMBER=99 then 1 else l.COMPANYNUMBER end
		and s.LIENORNUMBER=l.LIENORNUMBER
left join budxrefAPVendor x
	on x.Company=l.COMPANYNUMBER and x.OldVendorID=l.LIENORNUMBER and x.CGCVendorType='L'
join bHQCO co
	on co.HQCo = @toco
where x.OldVendorID is null and case when l.COMPANYNUMBER = 99 then 1 else l.COMPANYNUMBER end = @fromco
	and (c.LIENORNUMBER is not null or h.LIENORNUMBER is not null or s.LIENORNUMBER is not null)


-------------------------------Viewpoint.dbo.budxrefCostType------------------------------
insert into Viewpoint.dbo.budxrefCostType
select distinct COMPANYNUMBER, COSTTYPE ,Null,Null
from CV_CMS_SOURCE.dbo.APTOPD a 
left join Viewpoint.dbo.budxrefCostType x on a.COMPANYNUMBER=x.Company and a.COSTTYPE=x.CMSCostType
where x.Company is null

------------------------------Viewpoint.dbo.budxrefEMCostCodes------------------------------

insert into Viewpoint.dbo.budxrefEMCostCodes
select distinct COMPONENTNO03,null,null  
from CV_CMS_SOURCE.dbo.EQPDTL e 
left join Viewpoint.dbo.budxrefEMCostCodes x on e.COMPONENTNO03=x.CMSComponent
where x.CMSComponent is null

------------------------------Viewpoint.dbo.budxrefEMCostType------------------------------
insert into Viewpoint.dbo.budxrefEMCostType
select distinct  COMPANYNUMBER, COSTTYPE , NULL, NULL
from CV_CMS_SOURCE.dbo.APTOPD a 
left join Viewpoint.dbo.budxrefEMCostType x on a.COMPANYNUMBER=x.Company and a.COSTTYPE=x.CMSCostType
where x.Company is null

-------------------------------Viewpoint.dbo.budxrefGLAcct------------------------------
insert into Viewpoint.dbo.budxrefGLAcct
select distinct COMPANYNUMBER, GENLEDGERACCT ,NULL, left(DESC25A,30),  null, null
from CV_CMS_SOURCE.dbo.GLTMST g
left join Viewpoint.dbo.budxrefGLAcct x on g.MSCONO=x.Company and g.MSGLAN=x.oldGLAcct 
where x.Company is null

-------------------------------Viewpoint.dbo.budxrefGLAcctTypes------------------------------
insert into Viewpoint.dbo.budxrefGLAcctTypes
select distinct COMPANYNUMBER, GLACCTTYPE, NULL, null
from CV_CMS_SOURCE.dbo.GLTMST g 
left join iewpoint.dbo.budxrefGLAcctTypes x on g.MSCONO=x.Company and g.MSTYAC=x.oldAcctType
where x.Company is null

-------------------------------Viewpoint.dbo.budxrefGLJournals------------------------------
insert into Viewpoint.dbo.budxrefGLJournals
select distinct left(JOURNALCTL,2) , NULL, NULL, NULL
from CV_CMS_SOURCE.dbo.GLTPST g 
left join Viewpoint.dbo.budxrefGLJournals x on  left(JOURNALCTL,2)=x.CMSCode
where x.CMSCode is null

-------------------------------Viewpoint.dbo.budxrefGLSubLedger------------------------------
insert into Viewpoint.dbo.budxrefGLSubLedger
select distinct MSCONO, MSAPCD, 	NULL,NULL
from CV_CMS_SOURCE.dbo.GLPMST g
left join Viewpoint.dbo.budxrefGLSubLedger x on g.MSCONO=x.Company and g.MSAPCD=x.oldAppCode
where x.Company is null

-------------------------------Viewpoint.dbo.budxrefJCDept------------------------------
insert into Viewpoint.dbo.budxrefJCDept
select distinct COMPANYNUMBER,DEPARTMENTNO , NULL, NULL
      from CV_CMS_SOURCE.dbo.JCTDSC j
left join Viewpoint.dbo.budxrefJCDept x on j.COMPANYNUMBER=x.Company and j.DEPARTMENTNO=x.CMSDept
where x.Company is null

-------------------------------Viewpoint.dbo.budxrefPhase------------------------------

insert into Viewpoint.dbo.budxrefPhase
select  distinct x.COMPANYNUMBER, ltrim(rtrim(JCDISTRIBTUION)), null , null
from 
	(select Distinct COMPANYNUMBER, JCDISTRIBTUION
	from CV_CMS_SOURCE.dbo.JCTPST p 
		union all
	select Distinct  COMPANYNUMBER, JCDISTRIBTUION
	from CV_CMS_SOURCE.dbo.JCTMST j  
	) x
left join Viewpoint.dbo.budxrefPhase p on x.COMPANYNUMBER=p.Company 
and ltrim(rtrim(x.JCDISTRIBTUION)) = ltrim(rtrim(p.oldPhase))
where x.JCDISTRIBTUION <>'' and p.oldPhase is null

-------------------------------Viewpoint.dbo.budxrefPRDedLiab------------------------------
insert into Viewpoint.dbo.budxrefPRDedLiab
select x.CMSDedCode, x.CMSDedType, x.CMSUnion, x.Company, null, null, null, null 
from 
(select distinct CMSDedType=null, CMSDedCode=DEDNUMBER, CMSUnion=null, Company=COMPANYNUMBER
from CV_CMS_SOURCE.dbo.PRTMED where DEDNUMBER < 995
union all
select distinct  CMSDedType =RECORDCODE, CMSDedCode =DISTNUMBER, CMSUnion=null,Company=COMPANYNUMBER
from CV_CMS_SOURCE.dbo.PRTTCE where DISTNUMBER < 995
union all
select distinct CMSDedType =null, CMSDedCode =NUDTY, CMSUnion=UNIONNO,Company=COMPANYNUMBER
from CV_CMS_SOURCE.dbo.PRTMUN
where NUDTY < 995) x
left join Viewpoint.dbo.budxrefPRDedLiab xref on x.Company=xref.Company and x.CMSDedCode=xref.CMSDedCode 
	and x.CMSDedType=xref.CMSDedType and x.CMSUnion=xref.CMSUnion
where xref.Company is null and x.CMSDedCode<995

-------------------------------Viewpoint.dbo.budxrefPRDept------------------------------
insert into Viewpoint.dbo.budxrefPRDept
select distinct COMPANYNUMBER, STDDEPTNUMBER,NULL, NULL 
from CV_CMS_SOURCE.dbo.PRTMST p
left join Viewpoint.dbo.budxrefPRDept x on p.COMPANYNUMBER=x.Company and p.STDDEPTNUMBER=x.CMSCode
where x.Company is null


-------------------------------Viewpoint.dbo.budxrefPREarn------------------------------
insert into Viewpoint.dbo.budxrefPREarn
select distinct c.COMPANYNUMBER, c.CMSDedCode, c.CMSCode, null, null, null from 
(
Select distinct  COMPANYNUMBER,OTHHRSTYPE as CMSDedCode, 'OTH' as CMSCode from CV_CMS_SOURCE.dbo.PRTTCH 
union all
Select distinct  COMPANYNUMBER,convert(nvarchar(10),DEDNUMBER) as CMSDedCode ,'A' as CMSCode from CV_CMS_SOURCE.dbo.PRTMAJ 
union all
Select distinct  COMPANYNUMBER,convert(nvarchar(10),BENEFITNUMBER) as CMSDedCode, 'H' as CMSCode from CV_CMS_SOURCE.dbo.HRTMBN
) as c
left join Viewpoint.dbo.budxrefPREarn x on c.COMPANYNUMBER=x.Company and c.CMSDedCode=x.CMSDedCode and c.CMSCode=x.CMSCode
where x.Company is null

-------------------------------Viewpoint.dbo.budxrefPRGroup------------------------------
insert into Viewpoint.dbo.budxrefPRGroup
select distinct COMPANYNUMBER, PAYFREQCDE, null, null, null 
from CV_CMS_SOURCE.dbo.PRTMST p
left join Viewpoint.dbo.budxrefPRGroup x on p.COMPANYNUMBER=x.Company and p.PAYFREQCDE=x.CMSCode

-------------------------------Viewpoint.dbo.budxrefUnion------------------------------
insert into Viewpoint.dbo.budxrefUnion  (Company, CMSUnion, CMSClass, CMSType) 
select distinct COMPANYNUMBER, UNIONNO , convert(varchar(max),EMPLOYEECLASS), EMPLTYPE 
from CV_CMS_SOURCE.dbo.PRTTCH p 
left join Viewpoint.dbo.budxrefUnion x on p.COMPANYNUMBER=x.Company and p.UNIONNO=x.CMSUnion and p.EMPLOYEECLASS=x.CMSClass and 
	p.EMPLTYPE=x.CMSType
where x.Company is null

-------------------------------Viewpoint.dbo.xrefInsState------------------------------
insert into Viewpoint.dbo.budxrefInsState
select distinct h.COMPANYNUMBER , STIDCODE, Null, NULL
from CV_CMS_SOURCE.dbo.PRTTCH h 
left join Viewpoint.dbo.budxrefInsState x on h.COMPANYNUMBER=x.Company and h.STIDCODE=x.InsCode 
where x.Company is null

-------------------------------Viewpoint.dbo.budxrefUM------------------------------
insert into Viewpoint.dbo.budxrefUM
select distinct UNITOFMEASURE, Null, Null 
from CV_CMS_SOURCE.dbo.JCTMST j
left join Viewpoint.dbo.budxrefUM x on j.UNITOFMEASURE=x.CGCUM
where UNITOFMEASURE<>'' and x.CGCUM is null


**/
GO
