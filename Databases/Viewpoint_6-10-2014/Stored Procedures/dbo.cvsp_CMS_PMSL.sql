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
		8. 10/04/2013 BTC - Added JCJobs cross reference
		9. 03/24/2014 AEL - Added SLHD population
		
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_PMSL] 
(@fromco1 smallint, @fromco2 smallint, @fromco3 smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

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
	on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OpenJobYN' and a.TableName='OpenJobs'; 


--get Customer defaults
--UM
declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b 
	on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
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
ALTER TABLE bPMSL NOCHECK CONSTRAINT FK_bPMSL_bAPVM;

-- delete existing trans
BEGIN tran
delete from bPMSL where PMCo=@toco;
alter table bSLIT disable trigger all
delete from bSLIT where SLCo = @toco
alter table bSLIT enable trigger all
alter table bSLHD disable trigger all
delete from bSLHD where SLCo = @toco;
alter table bSLHD enable trigger all;
COMMIT TRAN;

-- add new trans
BEGIN TRY;
BEGIN TRAN;


with Subcontracts 
	(PMCo, Project, Seq, RecordType, VendorGroup, Vendor, PhaseGroup, Phase, CostType, 
	SLCo, SL, SLItem, SLItemDescription,SLItemType,Units, UM,UnitCost,
	Amount,WCRetgPct,SMRetgPct,InterfaceDate, SendFlag, udSLContractNo, WITNO, udSource,udConv
	,udCGCTable,udCGCTableID)
as(

select PMCo       = @toco
	, Project     = xj.VPJob --dbo.bfMuliPartFormat(ltrim(rtrim(s.JOBNUMBER)) +  ltrim(RTRIM(s.SUBJOBNUMBER)),@JobFormat)
	, Seq         = ROW_NUMBER() over (partition by @toco, xj.VPJob --s.JOBNUMBER, s.SUBJOBNUMBER
								 order by v.NewVendorID, s.CONTRACTNO, s.ITEMNUMBER)

	, RecordType  = 'O'
	, VendorGroup = @VendGroup
	, Vendor      = v.NewVendorID
	, PhaseGroup  = @PhaseGroup
	, Phase       = p.newPhase
	, CostType    = t.CostType
	, SLCo        = @toco
	, SL		  = cast(s.CONTRACTNO as varchar(20)) + '-' + s.JOBNUMBER
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
	, udCGCTableID   = max(SEQCTL04)
	
from CV_CMS_SOURCE.dbo.APTCNS s	

--INNER JOIN [MCK_MAPPING_DATA ].[dbo].[McKCGCActiveJobsForConversion2] jobs 
--		ON	jobs.GCONO = s.COMPANYNUMBER
--		AND jobs.GJBNO     = s.JOBNUMBER
--		and jobs.GSJNO  = s.SUBJOBNUMBER
		
join Viewpoint.dbo.budxrefJCJobs xj
	on xj.COMPANYNUMBER = s.COMPANYNUMBER and xj.DIVISIONNUMBER = s.DIVISIONNUMBER and xj.JOBNUMBER = s.JOBNUMBER
		and xj.SUBJOBNUMBER = s.SUBJOBNUMBER
   and xj.VPJob IS not null
join Viewpoint.dbo.budxrefAPVendor v
	on        v.Company = @VendGroup
	and   v.OldVendorID = s.VENDORNUMBER 
	and v.CGCVendorType ='V'
	
join CV_CMS_SOURCE.dbo.JCTDSC c 
	on s.COMPANYNUMBER = c.COMPANYNUMBER 
	and    s.JOBNUMBER = c.JOBNUMBER
	and s.SUBJOBNUMBER = c.SUBJOBNUMBER
	
left join Viewpoint.dbo.budxrefPhase p 
	on   p.Company = @PhaseGroup 
	and p.oldPhase = s.JCDISTRIBTUION
	
left join Viewpoint.dbo.budxrefCostType t 
	on      t.Company = @PhaseGroup
	and t.CMSCostType = s.COSTDSTTYP
		
WHERE 
	s.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)
	 
	
group by 
	  s.CONTROLCOMPANY
	, xj.VPJob
	, s.JOBNUMBER
	--, s.SUBJOBNUMBER
	, s.CONTRACTNO
	, v.NewVendorID
	, p.newPhase
	, t.CostType
	, ITEMNUMBER)



insert bPMSL (PMCo, Project, Seq, RecordType, VendorGroup, Vendor, PhaseGroup, 
	Phase, CostType, SLCo, SL, SLItem, SLItemDescription, SLItemType, Units, UM, UnitCost,
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
	, SL
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
group by PMCo, Project, Vendor, SLCo, SL, SLItem,udSLContractNo;

alter table bSLHD disable trigger all

;with slhd as(
select PMCo, SL
  from bPMSL 
 where PMCo = @toco
 group by PMCo, SL) 
 
insert bSLHD
	( SLCo	
	, SL	
	, JCCo	
	, Job	
	, Description
	, VendorGroup
	, Vendor	
	, PayTerms	
	, Status	
	, Purge		
	, Approved	
	, OrigDate	
	, MaxRetgOpt
	, MaxRetgPct
	, MaxRetgAmt
	, InclACOinMaxYN
	, MaxRetgDistStyle
	, ApprovalRequired
	, udSLContractNo
	, udSource		
	, udConv
	)
select SLCo				= sl.PMCo
	 , SL				= sl.SL
	 , JCCo				= @toco
	 , Job				= min(sl.Project)
	 , Description		= min(sl.SLItemDescription)
	 , VendorGroup		= min(sl.VendorGroup)
	 , Vendor			= min(sl.Vendor)
	 , PayTerms			= min(vm.PayTerms)
	 , Status			= 0
	 , Purge			= 'N'
	 , Approved			= 'N'
	 , OrigDate			= min(sl.InterfaceDate)
	 , MaxRetgOpt		= 'N'
	 , MaxRetgPct		= 0
	 , MaxRetgAmt		= 0
	 , InclACOinMaxYN	= 'Y'
	 , MaxRetgDistStyle	= 'C'
	 , ApprovalRequired	= 'N'
	 , udSLContractNo	= min(sl.udSLContractNo)
	 , udSource			= 'APTCNS'
	 , udConv			= 'Y'
  from bPMSL sl
  join slhd m
	on m.PMCo=sl.PMCo 
   and m.SL=sl.SL 
  left join bAPVM vm
    on vm.VendorGroup = sl.VendorGroup
   and vm.Vendor = sl.Vendor
 where sl.PMCo=@toco 
   and sl.SL is not null 
 group by sl.SL,sl.PMCo

select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPMSL enable trigger all;
alter table bPMSL CHECK CONSTRAINT FK_bPMSL_bJCJM;
alter table bSLHD enable trigger all;


return @@error














GO
