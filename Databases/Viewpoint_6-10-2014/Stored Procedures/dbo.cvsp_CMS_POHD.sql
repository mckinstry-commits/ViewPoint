SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



CREATE proc [dbo].[cvsp_CMS_POHD] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
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
	
	exec cvsp_CMS_POHD 1,15,50,1,'',0
*/

set @errmsg='';
set @rowcount=0;

declare 
	@VPtoco int = @toco,
	@fromco_1 int = @fromco1,
	@fromco_2 int = @fromco2,
	@fromco_3 int = @fromco3
	
--Defaults from HQCO
declare @VendorGroup tinyint
select @VendorGroup=VendorGroup from bHQCO where HQCo=@VPtoco;

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
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@VPtoco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';


ALTER Table bPOHD disable trigger all;
alter table vPMPOCO NOCHECK Constraint FK_vPMPOCO_bPOHD;

--delete trans
begin tran
delete bPOHD where POCo=@VPtoco;
commit tran

print 'done deleting';

-- add new trans
BEGIN TRAN
BEGIN TRY

	print 'begin insert' + STR(@@trancount)  ;

	--select * from CV_CMS_SOURCE.dbo.POTMCT--POHD
	--select * from CV_CMS_SOURCE.dbo.POTMDT--POIT


	insert bPOHD 
		( POCo
		, PO
		, VendorGroup
		, Vendor
		, Description
		, OrderedBy
		, OrderDate
		, ExpDate
		, Status
		, JCCo
		, Job
		, INCo
		, Loc
		, ShipLoc
		, PayTerms
		, MthClosed
		, Purge
		, AddedMth
		, udSource
		, udConv
		, udCGCTable
		, udMCKPONumber
		)

	select Distinct POCo			= @VPtoco
		 , PO			= cast(h.COMPANYNUMBER as varchar(30)) + '-' + cast(h.PONUMBER as varchar(30))
		 , VendorGroup	= @VendorGroup
		 , Vendor		= xv.NewVendorID
		 , Description	= d.DESCRIPTION1
		 , OrderedBy	= left(ltrim(BUYER15),10) /* deliberately taking only 10 characters, as POHD.OrderBy is only 10 long */
		 , OrderDate	= substring(convert(nvarchar(max),h.PODATE),5,2) + '/' +  
	  					  substring(convert(nvarchar(max),h.PODATE),7,2) + '/' + 
						  substring(convert(nvarchar(max),h.PODATE),1,4)
		 , ExpDate		= case when h.ACKDATE <> 0 then
								substring(convert(nvarchar(max),h.ACKDATE),5,2) + '/' +  
	  							substring(convert(nvarchar(max),h.ACKDATE),7,2) + '/' + 
								substring(convert(nvarchar(max),h.ACKDATE),1,4)
							  else null 
						  end
		 , Status		= CASE WHEN PO.BalanceAmount > 0 then 0 else 1 end
		 , JCCo			= @VPtoco
		 , Job			= case when h.JOBNUMBER='' then null 
							   else xj.VPJob --dbo.bfMuliPartFormat(RTRIM(h.JOBNUMBER) + RTRIM(h.SUBJOBNUMBER),@Job) 
						  end
		 , INCo			= @VPtoco
		 , Loc			= null
		 , ShipLoc		= case when JOBLOCNO='0' then null else JOBLOCNO end
		 , PayTerms		= isnull(vm.PayTerms,@defaultPayTerms)
		 , MthClosed	= null
		 , Purge		= 'N'
		 , AddedMth		= substring(convert(nvarchar(max),h.PODATE),5,2) + '/01' + '/' + 
						  substring(convert(nvarchar(max),h.PODATE),1,4)
		 , udSource		= 'POHD'
		 , udConv		= 'Y'
		 , udCGCTable	= 'POTMCT'
		 , udMCKPONumber = h.PONUMBER
	  from CV_CMS_SOURCE.dbo.POTMCT h 
	  join CV_CMS_SOURCE.dbo.POTMDT d
	    on d.PONUMBER = h.PONUMBER
	   and d.COMPANYNUMBER = h.COMPANYNUMBER
	   and d.DIVISIONNUMBER = h.DIVISIONNUMBER
			-- made Vendor cross reference an equal join
			--these  Vendors have PO's but they don't exist in the Vendor Master
			--2221,2707,3437,5210,15710,19281,19616,23963,29065,68295,75549)

			/* Custom View Bill O.(@McKinstry) made to bring over certain PO's, see view for notes CR 8/26/2013 */
	  join MCK_MAPPING_DATA.dbo.vwCGCPurchaseOrdersForConversion PO 
		ON PO.ACONO = h.COMPANYNUMBER
	   and PO.ADVNO = h.DIVISIONNUMBER
	   and PO.APONO = h.PONUMBER
		
	  left join Viewpoint.dbo.budxrefJCJobs xj
		on xj.COMPANYNUMBER = h.COMPANYNUMBER 
	   and xj.DIVISIONNUMBER = h.DIVISIONNUMBER 
	   and xj.JOBNUMBER = h.JOBNUMBER
	   and xj.SUBJOBNUMBER = h.SUBJOBNUMBER
	  JOIN budxrefAPVendor xv               
		on xv.Company        = @VendorGroup
	   and xv.OldVendorID   = h.VENDORNUMBER 
	   and xv.CGCVendorType = 'V' 
	  JOIN bAPVM vm
	    on vm.VendorGroup = @VendorGroup
	   and vm.Vendor = xv.NewVendorID
		
	 where h.COMPANYNUMBER in (@fromco_1,@fromco_2,@fromco_3);


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
