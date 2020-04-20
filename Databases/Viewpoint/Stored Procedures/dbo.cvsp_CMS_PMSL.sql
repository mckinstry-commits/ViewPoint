
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
	Title:		PM Subcontract Detail - Originals
	Created:	10.12.09
	Created by:	VCS Technical Services - JJH    
	Revisions:	
		1. CR 11/18/09 added Open Jobs functionality 
		2. 03/19/2012 BBA - Added drop code. 
		3. 06/11/2012 BTC - Added udCGCTable & udCGCTableID to the PMSL insert.
		4. 06/07/2012 BTC - Add WC Retainage from APTCNS.RETENTIONPCT		
		5. 06/08/2012 BTC - Incorporated Vendor cross reference
		6. 06/11/2012 BTC - Modified Seq field to partition by Job
		7. 06/12/2012 BTC - Modified InterfacedDate to pull the Day value.
		
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_PMSL] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

AS

set @errmsg=''
set @rowcount=0


-- get defaults from HQCO
DECLARE 
	  @VendGroup  smallint
	, @TaxGroup   smallint
	, @PhaseGroup smallint
	
SELECT @VendGroup  = VendorGroup
     , @PhaseGroup = PhaseGroup
     , @TaxGroup   = TaxGroup 
FROM  bHQCO 
WHERE HQCo=@toco

-- Open Jobs Only or all Jobs
declare @OpenJobsYN varchar(1)
select @OpenJobsYN = ISNULL(b.DefaultString,a.DefaultString)
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 


--get Customer defaults
--UM
declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UM' and a.TableName='bPMSL';


--declare variables for use in functions
Declare 
      @JobLen    smallint
	, @SubJobLen smallint
	, @JobFormat varchar(30)
	
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob')
select @JobLen = LEFT(InputMask,1) from vDDDTc where Datatype = 'bJob'
select @SubJobLen = SUBSTRING(InputMask,4,1) from vDDDTc where Datatype = 'bJob';





ALTER Table bPMSL disable trigger btPMSLi;
alter table bPMSL NOCHECK CONSTRAINT FK_bPMSL_bJCJM;

-- delete existing trans
BEGIN tran
delete from bPMSL where PMCo=@toco;
COMMIT TRAN;

-- add new trans
BEGIN TRAN;
BEGIN TRY;


with Subcontracts 
	(PMCo, Project, Seq, RecordType, VendorGroup, Vendor, PhaseGroup, Phase, CostType, 
	SLCo, SLItem, SLItemDescription,SLItemType,Units, UM,UnitCost,
	Amount,WCRetgPct,SMRetgPct,InterfaceDate, SendFlag, udSLContractNo, WITNO, udSource,udConv
	,udCGCTable,udCGCTableID)
as(

select PMCo       = @toco
	, Project     = dbo.bfMuliPartFormat(ltrim(rtrim(s.JOBNUMBER)) +  ltrim(RTRIM(s.SUBJOBNUMBER)),@JobFormat)
	, Seq         = ROW_NUMBER() over (partition by s.COMPANYNUMBER, s.JOBNUMBER, s.SUBJOBNUMBER
								 order by v.NewVendorID, s.CONTRACTNO, s.ITEMNUMBER)

	, RecordType  = 'O'
	, VendorGroup = @VendGroup
	, Vendor      = v.NewVendorID
	, PhaseGroup  = @PhaseGroup
	, Phase       = p.newPhase
	, CostType    = t.CostType
	, SLCo        = @toco
	, SLItem      = case 
					when isnumeric(ITEMNUMBER)=1 
					then 
				        case 
				        when convert(numeric(12,0), ITEMNUMBER)>32000 
					    then 1000+convert(int,right(rtrim(ITEMNUMBER),3)) 
				        else 
					--converts items with leading zeros to the 200 range
					        case 
					        when left(ltrim(ITEMNUMBER),1)='0' 
					        then 
						        case 
						        when left(ltrim(ITEMNUMBER),4)='0000' 
						        then '2'+'00'+convert(int,ITEMNUMBER)
						        else '2'+convert(varchar(5),ITEMNUMBER) 
						        end
					        else convert(int,ITEMNUMBER)  
					        end
				        end
			        else
				        case 
				        when len(ITEMNUMBER)=2 
				        then left(ITEMNUMBER,1) 
					    when len(ITEMNUMBER)=5 and right(rtrim(ITEMNUMBER),1)<>')' 
					    then left(ITEMNUMBER,3)
					    when len(ITEMNUMBER)=5 and right(rtrim(ITEMNUMBER),1)=')' 
					    then left(ITEMNUMBER,2)
					    when len(ITEMNUMBER)>2 
					    then left(ITEMNUMBER,2) 
				        else 1000+convert(int,right(rtrim(ITEMNUMBER),3)) 
				        end
			        end
	, Descrip        = max(CONTRDESC1)
	, SLItemType     = 1    --1=Regular, 2=ChangeOrder, 3=BackCharge, 4=Addon
	, Units          = sum(ESTQTY)
	, UM             = @defaultUM
	, UnitCost       = 0
	, Amount         = sum(CONTRACTAMT3)
	, WCRetg         = MAX(s.RETENTIONPCT)/100
	, SMSRetg        = 0
	, InterfaceDate  = max(case 
						when ENTEREDDATE=0  
						then convert(varchar(5),datepart(mm,getdate())) + '/' + 
							 convert(varchar(5),datepart(dd,getdate())) + '/' + 
							 convert(varchar(5),datepart(yy,getdate()))
						else substring(convert(nvarchar(max),ENTEREDDATE),5,2) + '/' +
						     SUBSTRING(convert(nvarchar(max),ENTEREDDATE),7,2) + '/' +
						     substring(convert(nvarchar(max),ENTEREDDATE),1,4)
		end)
	, SendFlag       = 'Y'
	, udSLContractNo = (s.CONTRACTNO)
	, WITNO          = ITEMNUMBER
	, udSource       = 'PMSL'
	, udConv         = 'Y'
	, udCGCTable     = 'APTCNS'
	, udCGCTableID   = max(APTCNSID)
	
from CV_CMS_SOURCE.dbo.APTCNS s	

INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = s.COMPANYNUMBER
		AND jobs.JOBNUMBER     = s.JOBNUMBER
		and jobs.SUBJOBNUMBER  = s.SUBJOBNUMBER

join Viewpoint.dbo.budxrefAPVendor v
	on        v.Company = s.CONTROLCOMPANY 
	and   v.OldVendorID = s.VENDORNUMBER 
	and v.CGCVendorType ='V'
	
join CV_CMS_SOURCE.dbo.JCTDSC c 
	on s.COMPANYNUMBER = c.COMPANYNUMBER 
	and    s.JOBNUMBER = c.JOBNUMBER
	and s.SUBJOBNUMBER = c.SUBJOBNUMBER
	
left join Viewpoint.dbo.budxrefPhase p 
	on   p.Company = @fromco 
	and p.oldPhase = s.JCDISTRIBTUION
	
left join Viewpoint.dbo.budxrefCostType t 
	on      t.Company = @fromco 
	and t.CMSCostType = s.COSTDSTTYP
		
WHERE 
	s.COMPANYNUMBER=@fromco 
	 
	
group by 
	  s.COMPANYNUMBER
	, s.CONTROLCOMPANY
	, s.JOBNUMBER
	, s.SUBJOBNUMBER
	, s.CONTRACTNO
	, v.NewVendorID
	, p.newPhase
	, t.CostType
	, ITEMNUMBER)



insert bPMSL (PMCo, Project, Seq, RecordType, VendorGroup, Vendor, PhaseGroup, 
	Phase, CostType, SLCo, SLItem, SLItemDescription, SLItemType, Units, UM, UnitCost,
	Amount,WCRetgPct,SMRetgPct,InterfaceDate, SendFlag, udSLContractNo, udCMSItem, udSource,udConv
	,[udCGCTable],[udCGCTableID])

select PMCo
	, Project
	, Seq=min(Seq)
	, RecordType='O'
	, min(VendorGroup)
	, Vendor
	, min(PhaseGroup)
	, min(Phase)
	, min(CostType)
	, SLCo
	, SLItem
	, min(SLItemDescription)
	, 1
	, sum(Units)
	, max(UM)
	, min(UnitCost)
	, sum(Amount)
	, WCRetgPct=MAX(WCRetgPct)
	, SMRetgPct=0
	, min(InterfaceDate)
	, SendFlag='Y'
	, udSLContractNo
	, udCMSItem=min(WITNO)
	, udSource ='PMSL'
	, udConv='Y'
	, udCGCTable = MIN(udCGCTable)
	, udCGCTableID = MIN(udCGCTableID)
from Subcontracts 
group by PMCo, Project, Vendor, SLCo, SLItem,udSLContractNo;


select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPMSL enable trigger all;
alter table bPMSL CHECK CONSTRAINT FK_bPMSL_bJCJM;

return @@error




GO
