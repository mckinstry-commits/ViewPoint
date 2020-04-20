USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspPOReport' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspPOReport'
	DROP PROCEDURE dbo.MCKspPOReport
End
GO

Print 'CREATE PROCEDURE dbo.MCKspPOReport'
GO


CREATE Procedure [dbo].[MCKspPOReport]
(
	@co bCompany,
	@POFrom varchar(30),
	@POTo varchar(30) = NULL,
	@DateFrom bMonth	= NULL,
	@DateTo bMonth		= NULL
)
AS
 /* 
	Purpose:			Retrieve PO Purchase Orders 
	Logging:			mspLogPOAction, mckPOLog
	Viewpoint:		
	Created:			1.12.2018
	Modified:		2.29.2018
	Author:			Leo Gurdian
	1.12.2018	- L.Gurdian - Initial
	1.23.2018	- set HQPT.Description as PayTerms
	1.31.2018	- add order date range
	2.29.2018	- add JCCo
*/
Begin

 	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 

	POHD.JCCo,

	-- PURCHASE ORDER NO
	POHD.udMCKPONumber As udMCKPONumber_POHD, 
	--POHD.PO As PO_POHD, --??????? WHEN TO USE ???????

	-- ORDER DATE
	POHD.OrderDate As OrderDate_POHD,

	-- SELLER
	APVM.Name As Name_APVM,
	APVM.Address As Address_APVM,
	APVM.City As City_APVM,
	APVM.State As State_APVM,
	APVM.Zip As Zip_APVM,

	-- ATTN  / PHONE  / EMAIL
	POHD.Attention As Attention_POHD, -- Need parsing out phone number
 
	-- Vendor number
	POHD.Vendor As Vendor_POHD,

	-- PAYMENT TERMS
	--POHD.PayTerms,
	HQPT.Description As PayTerms_HQPT,

	-- FREIGHT PAYMENT
	udFOB.Description As Description_udFOB, 

	-- SHIP METHOD
	udShipMethod.Description As Description_udShipMethod,

	-- PROMISED SHIP DATE
	PMMF.ReqDate As ReqDate_POIT,

	-- SHIPPING POINT
	SMWorkOrder.ServiceSite As ServiceSite_SMWorkOrder, 
	SMServiceSite.Description As Description_SMServiceSite, 

	-- Ship To
	POHD.Address As Address_POHD,
	POHD.City As City_POHD,
	POHD.State As State_POHD,
	POHD.Zip As Zip_POHD,
	POHD.Country As Country_POHD, 

	-- SHIPPING INSTRUCTIONS
	POHD.ShipIns As ShipIns_POHD, 

	-- INVOICE TO
	HQCO.Name As Name_HQCO, 
	HQCO.Address As Address_HQCO, 
	HQCO.City As City_HQCO, 
	HQCO.State As State_HQCO, 
	HQCO.Zip As Zip_HQCO, 

	-- ITEM NO
	PMMF.POItem As POItem_POIT,

	-- QUANTITY
	--  ?????
	--PMMF.BOUnits,
	--PMMF.CurUnits,
	--PMMF.InvUnits,
	--PMMF.OrigUnits,
	--PMMF.RecvdUnits,
	--PMMF.RemUnits,
	--PMMF.TotalUnits,

	-- UNITS OF MEASURE (UOM)

	PMMF.UM As UM_POIT,

	-- DESCRIPTION
	PMMF.Description As Description_POIT,
	PMMF.Notes As Notes_POIT,

	POHD.Notes As Notes_POHD,

	-- EXTENDED PRICE
	PMMF.OrigCost As OrigCost_POIT,

	-- PROJECT / PHASE CODE or WORK ORDER
	PMMF.SMWorkOrder As SMWorkOrder_POIT,
	PMMF.Job As Job_POIT,
	PMMF.Phase As Phase_POIT,

	-- SALES TAX
	PMMF.OrigTax As OrigTax_POIT

	--HQCO.HQCo,
	--POHD.POCo As POCo_POHD,
	--POHD.ExpDate As ExpDate_POHD,
	--POHD.ShipLoc,

	--PMMF.POCo As POCo_PMMF,
	--PMMF.PO As PO_PMMF,
	--PMMF.CurUnits,
	--PMMF.CurUnitCost,
	--PMMF.ItemType,
	--PMMF.GLAcct,

	--JCJM.Description As Description_JCJM, 
	--JCJM_WOJob.Description As Description_JCJM_WOJob, 
	--POSL.Description As Description_POSL, 

	--PREHFullName.FullName, 
	--mrvPMPM1WVendorGroup.FullContactName As FullContactName_mrvPMPM1WVendorGroup, 
	--SMWorkOrder.Job As Job_SMWorkOrder,
	--PMPM1_cmd.FullContactName As FullContactName_PMPM1_cmd, 
	--ISNULL(HQCO.udTESTCo,'N') As udTESTCo, 
	--SUSER_SNAME() As VPUserName

	FROM   Viewpoint.dbo.POHD POHD INNER JOIN Viewpoint.dbo.POIT PMMF 
			ON POHD.POCo = PMMF.POCo 
			AND POHD.PO = PMMF.PO INNER JOIN Viewpoint.dbo.mrvPMPM1_cmd PMPM1_cmd 
				ON POHD.VendorGroup = PMPM1_cmd.VendorGroup 
			AND POHD.udPurchaseContact = PMPM1_cmd.ContactCode 
			AND POHD.JCCo = PMPM1_cmd.PMCo 
			LEFT OUTER JOIN Viewpoint.dbo.HQPT HQPT ON POHD.PayTerms = HQPT.PayTerms 
			LEFT OUTER JOIN Viewpoint.dbo.POSL POSL ON POHD.ShipLoc = POSL.ShipLoc 
			AND POHD.POCo = POSL.POCo 
			LEFT OUTER JOIN Viewpoint.dbo.udFOB udFOB ON POHD.udPOFOB = udFOB.Code 
			LEFT OUTER JOIN Viewpoint.dbo.udShipMethod udShipMethod ON POHD.udShipMethod = udShipMethod.Code 
			LEFT OUTER JOIN Viewpoint.dbo.PREHFullName PREHFullName ON POHD.udPurchaseContact = PREHFullName.Employee 
			AND POHD.POCo = PREHFullName.PRCo 
			LEFT OUTER JOIN Viewpoint.dbo.HQCO HQCO ON POHD.POCo = HQCO.HQCo 
			LEFT OUTER JOIN Viewpoint.dbo.APVM APVM ON POHD.VendorGroup = APVM.VendorGroup 
			AND POHD.Vendor = APVM.Vendor 
			LEFT OUTER JOIN Viewpoint.dbo.mrvPMPM1WVendorGroup mrvPMPM1WVendorGroup ON POHD.VendorGroup = mrvPMPM1WVendorGroup.VendorGroup 
			AND POHD.JCCo = mrvPMPM1WVendorGroup.PMCo
			AND POHD.udOrderedBy = mrvPMPM1WVendorGroup.ContactCode 
			LEFT OUTER JOIN Viewpoint.dbo.JCJM JCJM ON PMMF.Job = JCJM.Job 
			AND PMMF.POCo = JCJM.JCCo 
			LEFT OUTER JOIN Viewpoint.dbo.SMWorkOrder SMWorkOrder ON PMMF.SMCo = SMWorkOrder.SMCo 
			AND PMMF.SMWorkOrder = SMWorkOrder.WorkOrder 
			LEFT OUTER JOIN Viewpoint.dbo.SMServiceSite SMServiceSite ON SMWorkOrder.SMCo = SMServiceSite.SMCo 
			AND SMWorkOrder.ServiceSite = SMServiceSite.ServiceSite 
			LEFT OUTER JOIN Viewpoint.dbo.JCJM JCJM_WOJob ON SMWorkOrder.JCCo = JCJM_WOJob.JCCo 
			AND SMWorkOrder.Job = JCJM_WOJob.Job
	WHERE  PMMF.POCo = @co
			AND ISNULL(HQCO.udTESTCo,'N') <> 'Y' 
			AND 
				(	
				RTRIM(LTRIM(ISNULL(POHD.udMCKPONumber,' '))) >= @POFrom -- '17342161' -- start PO
				AND 
				RTRIM(LTRIM(ISNULL(POHD.udMCKPONumber,' '))) <= @POTo   -- '17342161' -- end PO
				)
			AND 
				(
				POHD.OrderDate >= ISNULL (@DateFrom, POHD.OrderDate) 
				AND
				POHD.OrderDate >= ISNULL (@DateTo, POHD.OrderDate) 
				)
			--AND POHD.udMCKPONumber = '17342161' -- AND PMMF.PO='17342161'
	ORDER BY PMMF.PO, PMMF.POItem desc

	SET NOCOUNT OFF;

End

GO

Grant EXECUTE ON dbo.MCKspPOReport TO [MCKINSTRY\Viewpoint Users]



-- exec dbo.MCKspPOReport 1, '15345111', '15345111'

-- 2 items
-- 14237138

 -- 4 items   (got all fields except Shipping Point (Service Site)
 -- 15026094 

 -- 10 ITEMS
 -- 15345111

 /*
	PO			POItems
	16021078	45
	15215253	22
	15345188	21
	15289043	14
	15345111	10
	15342093	9
	15345176	8
	15345107	8
	15345101	8
	15245208	8
 */