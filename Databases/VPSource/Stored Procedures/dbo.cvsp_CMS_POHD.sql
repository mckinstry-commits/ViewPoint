
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



CREATE proc [dbo].[cvsp_CMS_POHD] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PO Purchase Order Header
	Created:	08.31.10
	Created by:	JJH
	Revisions:	1. 10/25/2012 BTC - Incorporated Vendor cross reference for Hoar.
*/

set @errmsg='';
set @rowcount=0;

--Defaults from HQCO
declare @VendorGroup tinyint
select @VendorGroup=VendorGroup from bHQCO where HQCo=@toco;

--Declare Variables to use in fucntions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')
Declare @Phase varchar(30)
Set @Phase =  (Select InputMask from vDDDTc where Datatype = 'bPhase');

--get defaults from Customer Defaults
--PayTerms
declare @defaultPayTerms varchar(5)
select @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';


ALTER Table bPOHD disable trigger all;
alter table vPMPOCO NOCHECK Constraint FK_vPMPOCO_bPOHD;

--delete trans
delete bPOHD where POCo=@toco
	and udConv = 'Y';

print 'done deleting';

-- add new trans
BEGIN TRAN
BEGIN TRY

print 'begin insert' + STR(@@trancount)  ;

--select * from CV_CMS_SOURCE.dbo.POTMCT--POHD
--select * from CV_CMS_SOURCE.dbo.POTMDT--POIT


insert bPOHD (POCo, PO, VendorGroup, Vendor, Description, OrderDate, 
	ExpDate, Status, JCCo, Job, INCo, Loc, ShipLoc, 
	PayTerms, MthClosed, 
	Purge, AddedMth, udSource, udConv, udCGCTable)

select POCo       =@toco
	, PO          =h.PONUMBER
	, VendorGroup =@VendorGroup
	, Vendor      = xv.NewVendorID
	, Description = h.REFERENCENO10
	, OrderDate   = substring(convert(nvarchar(max),h.PODATE),5,2) + '/' +  
					substring(convert(nvarchar(max),h.PODATE),7,2) + '/' + 
					substring(convert(nvarchar(max),PODATE),1,4)
	, ExpDate     = null
	, Status      = 1
	, JCCo        = @toco
	, Job         = case 
						when h.JOBNUMBER='' then null 
						else xj.VPJob --dbo.bfMuliPartFormat(RTRIM(h.JOBNUMBER) + RTRIM(h.SUBJOBNUMBER),@Job) 
					end
	, INCo		  = @toco
	, Loc         = null
	, ShipLoc     = case when JOBLOCNO='0' then null else JOBLOCNO end
	, PayTerms    = @defaultPayTerms
	, MthClosed   = null
	, Purge       = 'N'
	, AddedMth    = substring(convert(nvarchar(max),h.PODATE),5,2) + '/01' + '/' + 
	                substring(convert(nvarchar(max),PODATE),1,4)
	, udSource    = 'POHD'
	, udConv      = 'Y'
	, udCGCTable  = 'POTMCT'
	
from CV_CMS_SOURCE.dbo.POTMCT h 

-- made Vendor cross reference an equal join
--these  Vendors have PO's but they don't exist in the Vendor Master
--2221,2707,3437,5210,15710,19281,19616,23963,29065,68295,75549)

/* Custom View Bill O.(@McKinstry) made to bring over certain PO's, see view for notes CR 8/26/2013 */
join CV_CMS_SOURCE.dbo.cvspMcKvwCGCPurchaseOrdersForConversion PO 
	ON PO.COMPANYNUMBER   = h.COMPANYNUMBER
	and PO.DIVISIONNUMBER = h.DIVISIONNUMBER
	and PO.PONUMBER       = h.PONUMBER
	
left join Viewpoint.dbo.budxrefJCJobs xj
	on xj.COMPANYNUMBER = h.COMPANYNUMBER and xj.DIVISIONNUMBER = h.DIVISIONNUMBER and xj.JOBNUMBER = h.JOBNUMBER
		and xj.SUBJOBNUMBER = h.SUBJOBNUMBER
	

/*LEFT*/ JOIN budxrefAPVendor xv               
	on xv.Company        = h.CONTROLCOMPANY 
	and xv.OldVendorID   = h.VENDORNUMBER 
	and xv.CGCVendorType = 'V' 
	
where h.COMPANYNUMBER=@fromco;


select @rowcount=@@rowcount;

print STR(@rowcount);

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bPOHD enable trigger all;
alter table vPMPOCO CHECK Constraint FK_vPMPOCO_bPOHD;

return @@error


GO
