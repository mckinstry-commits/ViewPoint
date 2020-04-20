SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








/**
=========================================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:		PR Employees (PREH) 
	Created:	04.20.2009
	Created By:	VCS Technical Services - Craig Rutter
	Revisions:	
		1. 5.18.09 - ADB - Edited for CMS, edited to bring all employees.
		2. 6.4.09 - ADB - Added TaxState, case statement for hourly vs. salary employees.
		3. 8.10.09 - CR removed code 998 from derived table DD
		4. 03/19/2012 BBA - Added drop code. 
		5. 05/14/12 - BTC - Added code to pick one record from PRPDED for Direct Deposit data.
			This code is set to first pull records with either the greatest percentage or the
			greatest Amount (using amount only in cases where percentage is not available.)
		6. 10/04/13 BTC - Added JCJobs cross reference
		
	exec cvsp_CMS_MASTER_PREH  1, 1, 'errmsg', 0
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_MASTER_PREH] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

AS


set @errmsg=''
set @rowcount=0

--get Customer defaults
declare @defaultPRGroup tinyint, @defaultInsCode varchar(10), @defaultTaxState varchar(2),
	@defaultInsState varchar(2), @defaultUnempState varchar(2), @defaultUseState varchar(1),
	@defaultUseLocal varchar(1), @defaultUseIns varchar(1), @defaultHrlyEC int,
	@defaultSalEC int, @defaultOTOpt varchar(1),
	@defaultPostToAll varchar(1), @defaultAuditYN varchar(1), @defaultPaySeq varchar(1), @defaultShift tinyint,
	@defaultAcctType varchar(1)

select @defaultPRGroup=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PRGroup' and a.TableName='bPREH';

select @defaultInsCode=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='InsCode' and a.TableName='bPREH';

select @defaultTaxState=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='TaxState' and a.TableName='bPREH';

select @defaultInsState=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='InsState' and a.TableName='bPREH';

select @defaultUnempState=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UnempState' and a.TableName='bPREH';

select @defaultUseState=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UseState' and a.TableName='bPREH';

select @defaultUseLocal=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UseLocal' and a.TableName='bPREH';

select @defaultUseIns=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UseIns' and a.TableName='bPREH';

select @defaultHrlyEC=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='HrlyEarnCode' and a.TableName='bPREH';

select @defaultSalEC=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='SalEarnCode' and a.TableName='bPREH';

select @defaultOTOpt=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OTOpt' and a.TableName='bPREH';

select @defaultPostToAll=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PostToAll' and a.TableName='bPREH';

select @defaultAuditYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='AuditYN' and a.TableName='bPREH';

select @defaultPaySeq=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultPaySeq' and a.TableName='bPREH';

select @defaultShift=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Shift' and a.TableName='bPREH'


--Find Direct Deposit data
--declare @toco int = 1,@fromco int = 1
select
	 ded.DCONO
	,ded.DEENO
	,ded.DSTAT
	,ded.DDENO
	,ded.DAMDE
	,ded.DDPCD
	,ded.DDEFQ
	,ded.DDEPC
	,ded.DBKID
	,ded.DBKAN
	,RecordSeq = ROW_NUMBER() over (partition by ded.DCONO, ded.DEENO order by ded.DDEPC, ded.DAMDE)
into #TempDirDeposit
--select *
from CV_CMS_SOURCE.dbo.PRPDED ded with (nolock)
left join CV_CMS_SOURCE.dbo.PRPDTR dtr with (nolock)
	on dtr.BCONO=ded.DCONO and dtr.BDINO=ded.DDENO and dtr.BDICD='M'
where ded.DCONO=@fromco 
  and ded.DSTAT='A' 
  and ded.DDEFQ>'0' 
  and dtr.BCACH='Y'
group by ded.DCONO
	,ded.DEENO
	,ded.DSTAT
	,ded.DDENO
	,ded.DAMDE
	,ded.DDPCD
	,ded.DDEFQ
	,ded.DDEPC
	,ded.DBKID
	,ded.DBKAN

delete #TempDirDeposit where DDEPC=0 and DAMDE=0

select td.* into #TempMaxDirDeposit
from #TempDirDeposit td
join (select DCONO, DEENO, MAX(RecordSeq) as MaxSeq from #TempDirDeposit group by DCONO, DEENO) d
	on d.DCONO=td.DCONO and d.DEENO=td.DEENO and d.MaxSeq=td.RecordSeq


alter table bPREH disable trigger all;

-- delete existing trans

delete from bPREH where PRCo=@toco

-- add new trans

BEGIN TRY
BEGIN TRAN	
;with EmpStateValues as (
		
	select Employee = pm.EMPLOYEENUMBER
		 , InsState
		 , LocalCode
		 , ResidentState
		 , TaxState
		 , UnempState
		 , UseIns
		 , UseInsState
		 , UseLocal
		 , UseState
		 , UseUnempState
		 , WOTaxState
	  from budxrefPRStates xprs
	  join CV_CMS_SOURCE.dbo.PRTMST pm
		on pm.UNIONNO = xprs.CMSUnion
	   and pm.STATECODE = xprs.ResidentState
	 where pm.STATUSCODE = 'A'
	   and pm.EMPLOYEENUMBER not in (select Employee from budxrefPRStatesEmp)

	union all
	select Employee
		 , InsState
		 , LocalCode
		 , ResidentState = STATECODE
		 , TaxState
		 , UnempState
		 , UseIns
		 , UseInsState
		 , UseLocal
		 , UseState
		 , UseUnempState
		 , WOTaxState
	  from budxrefPRStatesEmp xprse
	  join CV_CMS_SOURCE.dbo.PRTMST pm
		on pm.EMPLOYEENUMBER = xprse.Employee
	 where pm.STATUSCODE = 'A')
	 
	insert bPREH 
		( PRCo, Employee, Suffix, LastName, FirstName, MidName, SortName, 
			Address, City, State, Zip, Phone, SSN, Race, Sex, 
			BirthDate, HireDate, TermDate, PRGroup, PRDept, Craft, Class, InsCode, 
			TaxState, WOTaxState, UnempState, InsState, LocalCode, UseState, UseLocal, 
			UseIns, UseInsState, UseUnempState, Crew, GLCo, JCCo, Job, EarnCode, HrlyRate, 
			SalaryAmt, OTOpt, YTDSUI, DirDeposit, RoutingId, BankAcct, AcctType,
			ActiveYN, PensionYN, PostToAll, CertYN, AuditYN,  DefaultPaySeq, Shift, 
			udOrigHireDate, udEmpGroup, Email,
			udSource, udConv,udCGCTable,udCGCTableID,udJobTitle,RecentRehireDate)

	--declare @toco int = 1, @fromco int = 1 
	select PRCo = @toco
		 , Employee = T.EMPLOYEENUMBER
		 , Suffix = max(case when ltrim(rtrim(SUFFIX)) = '' then null else LTRIM(rtrim(SUFFIX))end)
		 , LastName = max(ltrim(rtrim(LASTNAME25)))
		 , FirstName = max(ltrim(rtrim(FIRSTNAME25)))
		 , MidName = case when max(MIDDLENAME1) = '' then null else ltrim(rtrim(max(substring(MIDDLENAME1,1,15)))) end
		 , SortName = max(upper(left(ABBREVIATION08, 8-len(T.EMPLOYEENUMBER)))+convert(varchar(10),T.EMPLOYEENUMBER))
		 , Address =max(rtrim(ADDRESS25A) + ' ' + ADDRESS25B)
		 , City = max(rtrim(CITY18))
		 , State = max(rtrim(STATECODE))
		 , Zip = max(rtrim(ZIPCODE))
		 , Phone = case when max(AREACODE) = 0 and max(PHONENO) <> 0 then '(   ' + ') ' 
					+ substring(convert(varchar(7),max(PHONENO)),1,3) + '-'
					+ substring(convert(varchar(7),max(PHONENO)),4,4)
				when max(AREACODE) = 0 and max(PHONENO) = 0 then null else 
					'(' + convert(varchar(3),max(AREACODE)) + ') ' + substring(convert(varchar(7),max(PHONENO)),1,3) + '-'
					+ substring(convert(varchar(7),max(PHONENO)),4,4) 
				end
		 , SSN = (substring(convert(nvarchar(max),(max(Right(('000000000'+ cast(SOCIALSECNO as varchar)),9)))),1,3)) + '-' 
		+ (substring(convert(nvarchar(max),(max(Right(('000000000'+ cast(SOCIALSECNO as varchar)),9)))),4,2)) + '-'
		 + (substring(convert(nvarchar(max),(max(Right(('000000000'+ cast(SOCIALSECNO as varchar)),9)))),6,4))
		
		 , Race =  max(MINORITYCODE)  /*  Get Minority Code Maintenance  these are user specific  */
		 , Sex = max(SEXCODE)
		 , Birthdate = case when max(BIRTHDATE) <> 0 then convert(smalldatetime,
					( substring(convert(nvarchar(max),(max(BIRTHDATE))),1,4)+'/'
					+ substring(convert(nvarchar(max),(max(BIRTHDATE))),5,2) +'/'
					+ substring(convert(nvarchar(max),(max(BIRTHDATE))),7,2))) else null end
		 , HireDate = case when max(ORIGHIREDATE) <> 0 then convert(smalldatetime,
					( substring(convert(nvarchar(max),(max(ORIGHIREDATE))),1,4)+'/'
					+ substring(convert(nvarchar(max),(max(ORIGHIREDATE))),5,2) +'/'
					+ substring(convert(nvarchar(max),(max(ORIGHIREDATE))),7,2))) else null end
		 , TermDate = case when max(TERMINATIONDATE) <> 0 then convert(smalldatetime,
					( substring(convert(nvarchar(max),(max(TERMINATIONDATE))),1,4)+'/'
					+ substring(convert(nvarchar(max),(max(TERMINATIONDATE))),5,2)+'/'
					+ substring(convert(nvarchar(max),(max(TERMINATIONDATE))),7,2))) else null end
		 , PRGroup = max(case when T.UNIONNO in ('001','002') then '1' else '2' end)--case when max(T.PAYFREQCDE) = 'WK' then 1 else 2 end
		 , PRDept = max(isnull(PRDept.VPPRDeptNumber,'00000'))
		 , Craft = max(isnull(udxrefUnion.Craft,'0000'))
		 , Class = max(isnull(udxrefUnion.Class,cast(T.EMPLOYEECLASS as varchar(10)) + CAST(T.EMPLTYPE as varchar(10))))
		 , InsCode = max(isnull(case when T.STATECODE in ('','WA') then udxrefPRIns.InsCodeWA else udxrefPRIns.InsCodeNonWA end,@defaultInsCode)) --@defaultInsCode --max(case when WCCODE=0 then @defaultInsCode else cast(WCCODE as nvarchar(4)) end)
		 , TaxState = MAX(isnull(isnull(esv.TaxState,STID.VPCODE),@defaultTaxState))--max(case when STATECODE='' then @defaultTaxState else STATECODE end)
		 , WOTaxState = MAX(isnull(isnull(esv.WOTaxState,case when CST.VPCODE is null then rtrim(STATECODE) else CST.VPCODE end),'N'))
		 , UnempState = max(isnull(isnull(esv.UnempState,case when HOME.VPCODE is null then rtrim(STATECODE) else HOME.VPCODE end),@defaultUnempState))--max(case when STATECODE='' then @defaultUnempState else STATECODE end)
		 , InsState =MAX(isnull(isnull(esv.InsState,case when CST.VPCODE is null then rtrim(STATECODE) else CST.VPCODE end),@defaultInsState))--MAX(T.STATECODE)--max(case when STATECODE='' then @defaultInsState else STATECODE end) 
		 , LocalCode = MAX(isnull(esv.LocalCode,case when T.LOCALCODE <> 0 then rtrim(T.LOCALCODE) else null end))--max(I.DLCode)
		 , UseState = max(isnull(esv.UseState,case when T.UNIONNO in ('001','002') then 'Y' else 'N' end))--@defaultUseState
		 , UseLocal = max(isnull(esv.UseLocal,'N'))
		 , UseIns = max(isnull(esv.UseIns,case when T.UNIONNO in ('001','002') then 'Y' else 'N' end))--@defaultUseIns
		 , UseInsState = max(isnull(esv.UseInsState,case when T.UNIONNO in ('001','002') then 'Y' else 'N' end))
		 , UseUnempState = max(isnull(esv.UseUnempState,case when T.UNIONNO in ('001','002') then 'Y' else 'N' end))
		 , Crew = null
		 , GLCo = @toco
		 , JCCo = @toco
		 , Job = max(xj.VPJob)
		 , EarnCode = '1'--case when max(PAYTYPE)='S' then @defaultSalEC else @defaultHrlyEC end
		 , HrlyRate = case when max(T.UNIONNO) in ('001','002')/*max(PAYTYPE)='H'*/ then isnull(max(M.REGRATE),isnull(max(E.REGRATE),0)) else 0 end
		 , SalaryAmt = case when max(PAYTYPE)='S' then (isnull(max(M.REGRATE),isnull(max(E.REGRATE),0)))*40 
			else 0 end
		 , OTOpt = @defaultOTOpt
		 , YTDSUI = 0
		 , DirDeposit = case when max(isnull(dd.DDENO,0))>0 then 'A' else 'N' end
		 , RoutingId = max(right('000000000' + convert(varchar(10), LTRIM(dd.DBKID)),9))
		 , BankAcct = MAX(replace(dd.DBKAN, ' ', ''))
		 , AcctType = case 
			when max(dd.DDPCD) = 22 then 'C'
			when MAX(dd.DDPCD) = 32 then 'S'
			else null end
		 , ActiveYN = case when max(TERMINATIONDATE) <> 0 then 'N' else 'Y' end
		 , PensionYN = max(T.PENSIONCODE)
		 , PostToAll = @defaultPostToAll
		 , CertYN = case max(EXEMPTCERTPR) when 'Y' then 'N' when 'N' then 'Y' end
		 , AuditYN = @defaultAuditYN
		 , DefaultPaySeq = @defaultPaySeq
		 , Shift = @defaultShift
		 , udOrigHireDate = case when max(ORIGHIREDATE) <> 0 then convert(smalldatetime,
							( substring(convert(nvarchar(max),(max(ORIGHIREDATE))),1,4)+'/'
							+ substring(convert(nvarchar(max),(max(ORIGHIREDATE))),5,2) +'/'
							+ substring(convert(nvarchar(max),(max(ORIGHIREDATE))),7,2))) else null end
		 , udEmpGroup = max(EMPLOYEEGROUP)
		 , Email = Max(case when N.EMAILADDR<> '' then N.EMAILADDR else null end )
		 , udSource='MASTER_PREH'
		 , udConv='Y'
		 , udCGCTable='PRTMST'
		 , udCGCTableID= max(T.PRTMSTID)
		 , udJobTitle = MAX(T.OCCUPATIONDESC)
		 , RehireDate = case when max(BEGININGDATE) <> 0 then convert(smalldatetime,
						( substring(convert(nvarchar(max),(max(BEGININGDATE))),1,4)+'/'
						+ substring(convert(nvarchar(max),(max(BEGININGDATE))),5,2) +'/'
						+ substring(convert(nvarchar(max),(max(BEGININGDATE))),7,2))) else null end

 --declare @toco int = 1, @fromco int = 1 select * 
	  from CV_CMS_SOURCE.dbo.PRTMST T with (nolock)
	  left join Viewpoint.dbo.budxrefJCJobs xj
	    on xj.COMPANYNUMBER = T.COMPANYNUMBER 
	   and xj.DIVISIONNUMBER = T.DIVISIONNUMBER 
	   and xj.JOBNUMBER = T.JOBNUMBER
	   and xj.SUBJOBNUMBER = T.SUBJOBNUMBER
	  left join CV_CMS_SOURCE.dbo.PRTERT E with (nolock) 
	    on T.COMPANYNUMBER = E.COMPANYNUMBER 
	   and T.EMPLOYEENUMBER=E.EMPLOYEENUMBER
	  left join (select COMPANYNUMBER
					  , EMPLOYEENUMBER
					  , REGRATE=MAX(E.REGRATE)
				   FROM CV_CMS_SOURCE.dbo.PRTERT E with (nolock)
				  WHERE COMPLDATE='99999999'
				  GROUP BY COMPANYNUMBER, EMPLOYEENUMBER) AS M 
		on T.COMPANYNUMBER = M.COMPANYNUMBER 
	   and T.EMPLOYEENUMBER=M.EMPLOYEENUMBER
	  left join CV_CMS_SOURCE.dbo.PRTLBR L with (nolock) 
	    on T.COMPANYNUMBER=L.COMPANYNUMBER 
	   and T.STDDEPTNUMBER=L.DEPARTMENTNO
	  left join #TempMaxDirDeposit dd
	    on dd.DCONO=T.COMPANYNUMBER 
	   and dd.DEENO=T.EMPLOYEENUMBER
	  left join udxrefUnion
	    on udxrefUnion.CMSUnion = T.UNIONNO
	   and udxrefUnion.CMSClass = T.EMPLOYEECLASS
	   and udxrefUnion.CMSType = T.EMPLTYPE
	   and udxrefUnion.Company = T.COMPANYNUMBER
	  left join udxrefPRIns
	    on udxrefPRIns.Class = udxrefUnion.Class
	   and udxrefPRIns.Craft = udxrefUnion.Craft
	--left join (select DDPCD, Company=DCONO, Employee=DEENO, EarnCode=DDENO, DirDeposit='Y',
	--				BankAcct=DBKAN, RoutingId=DBKID ,
	--				AcctType=case when DDPCD=22 then 'C' when DDPCD =32 then 'S' end 
	--			from CV_CMS_SOURCE.dbo.PRPDED
	--			where DDENO in (999)and DDEFQ='7'
	--				and DCONO=@fromco and DAMDE=0) 
	--			as DD 
	--			on T.COMPANYNUMBER = DD.Company 
	--				and T.EMPLOYEENUMBER=DD.Employee 
	--left join dbo.budxrefPRGroup g on g.Company=@fromco and g.CMSCode=T.PAYFREQCDE
	  left join udxrefPRDept_McK PRDept
	    on T.STDDEPTNUMBER = PRDept.CGCPRDeptNumber
	   and T.COMPANYNUMBER = PRDept.CGCCompany
	  left join CV_CMS_SOURCE.dbo.PRTECN N 
	    on T.COMPANYNUMBER=N.COMPANYNUMBER 
	   and T.EMPLOYEENUMBER=N.EMPLOYEENUMBER
	  left join budXRefStateName STID
	    on STID.CGCCODE = T.STIDCODE
	  left join budXRefStateName HOME 
	    on HOME.CGCCODE = T.HOMESTATECODE
	  left join budXRefStateName CST 
	    on CST.CGCCODE = T.MWCST
	--left join dbo.budxrefPRDedLiab I on I.Company=@fromco and I.CMSDedCode=T.LOCALCODE
	-- and CMSDedType = 'L'
	  left join EmpStateValues esv
	    on esv.Employee = T.EMPLOYEENUMBER
	 where T.COMPANYNUMBER=@fromco
	   and T.STATUSCODE = 'A'--McK Only wants active employees. Later will add in those that are inactive by paid in 2013 & 2014
	 group by T.COMPANYNUMBER, T.EMPLOYEENUMBER

	select @rowcount=@@rowcount;


/****  
Theresa Parker created this query and wants me to run for test data only.
this will need to be removed for go live.
possibley create a new stored proc to run, then not run it when we go live?

********/
IF @toco not in (1,20,60)
	begin
		ALTER TABLE bPREH disable trigger all;
		UPDATE bPREH
		set			SSN =  '999-9' + 
							SUBSTRING(CAST(KeyID as varchar),1,1) + '-' + 
							SUBSTRING(CAST(KeyID as varchar),2,4),  --this should ensure a unique ssn
			  Phone		= '(999)999-9999',
			  Address	= '1234 1st Ave NE',
			  Zip		= '12345',
			  BirthDate = '1970-01-01 00:00:00'
		where udSource = 'MASTER_PREH_Append' and PRCo = @toco;
		ALTER TABLE bPREH enable trigger all;
	end


COMMIT TRAN
end TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
end CATCH;


alter table bPREH enable trigger ALL;

return @@error








GO
