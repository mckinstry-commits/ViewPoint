SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_PMSL_COs] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PM SL Detail - Change Orders
	Created on:	10.12.09
	Created by:     JJH
	Revisions:	1. 11/18/09 CR - added Open Job functionality
				2. 06/08/2012 BTC - Incorporated Vendor cross reference
				3. 06/11/2012 BTC - Modified Seq field to partition by Job				
				4. 06/11/2012 BTC - Added SubCO = d.GROUPNO, but had to modify to fit 
					smallint datatype.
	
**/


set @errmsg=''
set @rowcount=0

--Get Defaults from HQCO
declare @VendorGroup smallint, @PhaseGroup smallint
select @VendorGroup=VendorGroup, @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco

-- Open Jobs Only or all Jobs
declare @OpenJobsYN varchar(1)
select @OpenJobsYN = ISNULL(b.DefaultString,a.DefaultString)
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 

--Get Cusotmer defaults
--UM
declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UM' and a.TableName='bPMSL';

--ACO Item
declare @defaultACOItem varchar(10)
select @defaultACOItem=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ACOItem' and a.TableName='bPMSL';

--Declare Variables for functions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Declare @Phase varchar(30),  @JobLen smallint, @SubJobLen smallint
Set @Phase =  (Select InputMask from vDDDTc where Datatype = 'bPhase')
select @JobLen = LEFT(InputMask,1) from vDDDTc where Datatype = 'bJob'
select @SubJobLen = SUBSTRING(InputMask,4,1) from vDDDTc where Datatype = 'bJob';


--Declare Variables for proc
declare @seq bigint;
select @seq=max(Seq) from bPMSL;



ALTER Table bPMSL disable trigger ALL;


-- Transactions deleted in the PMSL - Original stored procedure

-- add new trans
BEGIN TRAN
BEGIN TRY



insert bPMSL (PMCo, Project, Seq, RecordType, ACO, ACOItem, VendorGroup, Vendor,
	PhaseGroup, Phase, CostType, SLCo, SLItem, SLItemDescription,
	SLItemType,Units, UM,UnitCost,Amount,WCRetgPct,SMRetgPct,InterfaceDate, SendFlag, 
	udSLContractNo, SubCO, udCMSItem,udSource,udConv,udCGCTable,udCGCTableID)

select @toco
	, Project=dbo.bfMuliPartFormat(right(space(@JobLen) + d.JOBNUMBER,@JobLen) + 
		left(d.SUBJOBNUMBER,@SubJobLen),@Job)
	, ISNULL(s.MaxSeq, 0) + ROW_NUMBER() OVER(partition by d.COMPANYNUMBER, d.JOBNUMBER, d.SUBJOBNUMBER
								order by isnull(xv.NewVendorID, xv.NewVendorID), d.CONTRACTNO, d.ITEMNUMBER)
	, RecordType='C'
	, ACO=SPACE(10-DATALENGTH(LTRIM(RTRIM(h.REVISIONNO)))) + LTRIM(RTRIM(h.REVISIONNO))
	, ACOItem= @defaultACOItem
	, @VendorGroup
	, Vendor=xv.NewVendorID--d.VENDORNUMBER
	, @PhaseGroup
	, Phase = x.newPhase
	, CostType=t.CostType
	, SLCo=@toco
	, SLItem=case when isnumeric(d.ITEMNUMBER)=1 then 
				case when convert(numeric(12,0), d.ITEMNUMBER)>32000 
					then 1000+convert(int,right(rtrim(d.ITEMNUMBER),3)) 
				else 
					--converts items with leading zeros to the 200 range
					case when left(ltrim(d.ITEMNUMBER),1)='0' then 
						case when left(ltrim(d.ITEMNUMBER),4)='0000' then '2'+'00'+convert(int,d.ITEMNUMBER)
						else '2'+convert(varchar(5),d.ITEMNUMBER) end
					else convert(int,d.ITEMNUMBER)  end
				end
			else
				case when len(d.ITEMNUMBER)=2 then left(d.ITEMNUMBER,1) 
					when len(d.ITEMNUMBER)=5 and right(rtrim(d.ITEMNUMBER),1)<>')' then left(d.ITEMNUMBER,3)
					when len(d.ITEMNUMBER)=5 and right(rtrim(d.ITEMNUMBER),1)=')' then left(d.ITEMNUMBER,2)
					when len(d.ITEMNUMBER)>2 then left(d.ITEMNUMBER,2) 
				else 1000+convert(int,right(rtrim(d.ITEMNUMBER),3)) 
				end
			end
	, Descrip=d.DESCRIPTION1
	, SLItemType=2
	, Units=d.ESTQTY
	, UM=@defaultUM
	, UnitCost=0
	, Amount=d.ESTIMATEAMT
	, WCRetg=0
	, SMRetg=0
	, InterfaceDate=substring(convert(nvarchar(max),h.RHDTRV),5,2) + '/' + substring(convert(nvarchar(max),h.RHDTRV),7,2) 
		+ '/' + substring(convert(nvarchar(max),h.RHDTRV),1,4)
	, SendFlag='Y'
	, CMSContractNo=d.CONTRACTNO
	, SubCO=case when d.GROUPNO<1000 then d.GROUPNO else 1000 + RIGHT(d.GROUPNO,4) end
	, d.ITEMNUMBER
	, udSource ='PMSL_COs'
	, udConv='Y'
	,udCGCTable='JCTCGH',udCGCTableID=JCTCGHID
from CV_CMS_SOURCE.dbo.JCTCGH h 
	join CV_CMS_SOURCE.dbo.JCTDSC dc on h.RHCONO=dc.COMPANYNUMBER and h.JOBNUMBER=dc.JOBNUMBER
		and h.SUBJOBNUMBER=dc.SUBJOBNUMBER
	join CV_CMS_SOURCE.dbo.COTypes c on h.CHGORDERTYPE=c.COType
	left join CV_CMS_SOURCE.dbo.JCTCGO d on d.COMPANYNUMBER=h.RHCONO and d.JOBNUMBER=h.JOBNUMBER 
			and d.SUBJOBNUMBER=h.SUBJOBNUMBER and d.GROUPNO=h.RHGP05
	left join (select PMCo, Project, MAX(Seq) as MaxSeq 
				from bPMSL 
				group by PMCo, Project) s
				on s.Project=dbo.bfMuliPartFormat (right(space(@JobLen) + rtrim(d.JOBNUMBER),@JobLen)  
									+ left(ltrim(d.SUBJOBNUMBER),@SubJobLen),@Job)
				and s.PMCo=@toco
	
	left join Viewpoint.dbo.budxrefPhase x on x.Company=@fromco and x.oldPhase=d.JCDISTRIBTUION
	left join Viewpoint.dbo.budxrefCostType t on t.Company=@fromco and t.CMSCostType=d.COSTTYPE
	left join Viewpoint.dbo.budxrefAPVendor xv
		on xv.OldVendorID=d.VENDORNUMBER and xv.Company=d.COMPANYNUMBER and xv.CGCVendorType='V'
	left join (select PMCo, Project, Vendor, udSLContractNo, Phase, SLItem=min(SLItem), udCMSItem
				from bPMSL
				group by PMCo, Project, Vendor, udSLContractNo, Phase, udCMSItem)
				as p
				on p.PMCo=@toco
					and p.Project=dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) + '.' + RTRIM(d.SUBJOBNUMBER),@Job)
					and p.Vendor=d.VENDORNUMBER
					and p.udSLContractNo=d.CONTRACTNO
					and p.Phase=x.newPhase
					and d.ITEMNUMBER=p.udCMSItem
--Used to find maximum SL item to use on change orders that need to add a new item
	left join (select PMCo, Project, Vendor, udSLContractNo, SLItem=max(SLItem)
				from bPMSL
				group by PMCo, Project, Vendor, udSLContractNo)
				as m
				on m.PMCo=@toco
					and m.Project=dbo.bfMuliPartFormat(RTRIM(d.JOBNUMBER) + '.' + RTRIM(d.SUBJOBNUMBER),@Job)
					and m.Vendor=d.VENDORNUMBER
					and m.udSLContractNo=d.CONTRACTNO
where h.RHCONO=@fromco and isnull(dc.JOBSTATUS,0) <> case when @OpenJobsYN = 'Y' then 3 else 99 end  
and (c.SubOnly='Y' or c.SubCostOnly='Y' or c.UpdateAll='Y')


select @rowcount=@@rowcount;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPMSL enable trigger ALL;

return @@error

GO
