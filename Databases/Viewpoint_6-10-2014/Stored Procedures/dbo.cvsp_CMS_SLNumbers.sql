SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[cvsp_CMS_SLNumbers] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
   as SET NOCOUNT ON



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Assign Subcontracts (PMSL)
	Created on:	10.12.09
	Author:     JJH    
	Revisions:	1. None
	Notes:		IMPORTANT: MAKE SURE PM COMPANY PARAMETERS HAS AN AP COMPANY ASSINGED, 
				SUBCONTRACTS ARE SET TO ASSIGN SL NUMBERS BASED ON PROJ/SEQUENCE 
				WITH SIGNIFICANT JOB PART ASSIGNED.
				ALSO, MAKE SURE THERE IS A STARTING SEQUENCE ASSIGNED.
				** if this fails to run first check to see if the all the vendors
					in PMSL are in the APVM.

***  Code to look for Vendors  ***
select l.Vendor, m.Vendor from PMSL l
left join APVM m on l.VendorGroup=m.VendorGroup and l.Vendor=m.Vendor 
where l.Vendor is null or m.Vendor is null

**/

/*****
the following code will change the PM company parameter table inorder to make the conversion 
run smoothly and without issues.  
*****/

/* if bPMCO_Copy exists, drop it*/
if exists(select name from sys.objects where name = 'bPMCO_copy')
drop table bPMCO_copy;

/* create new copy of bPMCO into bPMCO_copy */
select * into bPMCO_copy from bPMCO;

/* update bPMCO Subcontract Parameter Tab with fields for conversion only */
BEGIN TRAN
update bPMCO
set SLNo='P'     /* Project/Sequence */
, SigPartJob='Y' 
, SLSeqLen=5     /* can be 1 - 8, also note that SL Proj Char + Seq Len cannot exceed 20 */
, SLStartSeq=1   /* starting at 1 */
;
COMMIT TRAN


ALTER Table bSLHD disable trigger ALL;
ALTER table bPMFM disable trigger ALL;

--delete existing records
begin tran
delete bSLHD where SLCo=@toco
commit tran 

declare @co bCompany, @project bJob, @rectype char(1), @cotype bDocType, @aco bACO, 
	@coitem bACOItem, @pmslseqlist varchar(2000), @CMSContract varchar(10), @msg varchar(200)

declare SLNo_Cursor cursor FAST_FORWARD FORWARD_ONLY for
select PMCo, Project, RecordType, COType=null,ACO, ACOItem, PMSLSeqList=null, udSLContractNo
from bPMSL 
where bPMSL.PMCo=@toco and bPMSL.Phase is not null 
order by PMCo, Project, Vendor, SLItem, RecordType, udSLContractNo

OPEN SLNo_Cursor
FETCH NEXT FROM SLNo_Cursor into @co, @project, @rectype, @cotype, @aco, @coitem, @pmslseqlist, @CMSContract
WHILE @@FETCH_STATUS = 0
   BEGIN

if @rectype='C' select @rectype='A'
exec cvsp_CMS_PMSLInitConversion @co, @project, @rectype, @cotype, @aco, @coitem, @pmslseqlist, @CMSContract, @msg output

      FETCH NEXT FROM SLNo_Cursor into @co, @project, @rectype, @cotype, @aco, @coitem, @pmslseqlist, @CMSContract
   END
CLOSE SLNo_Cursor
DEALLOCATE SLNo_Cursor;

update bSLHD
set udSource='SLNumbers', udConv='Y'




/* update PM Company parameters back to original from copy of table */
begin tran
update bPMCO
set SLNo=x.SLNo, SigPartJob=x.SigPartJob, SLSeqLen=x.SLSeqLen, SLStartSeq=x.SLStartSeq
from bPMCO
join bPMCO_copy x on x.PMCo=bPMCO.PMCo;
commit tran
ALTER Table bSLHD enable trigger ALL;
ALTER table bPMFM enable trigger ALL;

GO
