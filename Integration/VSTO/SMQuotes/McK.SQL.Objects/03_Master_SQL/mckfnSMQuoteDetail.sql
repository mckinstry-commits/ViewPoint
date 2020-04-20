USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnSMQuoteDetail' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnSMQuoteDetail'
	DROP FUNCTION dbo.mckfnSMQuoteDetail
End
GO

Print 'CREATE FUNCTION dbo.mckfnQuoteDetail'
GO


CREATE FUNCTION [dbo].mckfnSMQuoteDetail
(
  @SMCo				bCompany
, @WorkOrderQuote	VARCHAR(15)
)
RETURNS TABLE
AS
 /* 
	Purpose:	Get quote detail
	Author:		Leo Gurdian
	Created:	10.25.2018	

	HISTORY:
	01.31.2019 LG - Removed Material Notes in detailed lines #3789
				  - Removed Customer input param
	10.31.2018 LG - PROD live! + MatNotes to Description
	10.30.2018 LG - query vrvSMWorkOrderQuote, it's more complete 
	10.25.2018 LG - Get quote detail
*/
RETURN
(
	 SELECT 
	  e.WorkOrderQuoteScope					 AS Scope
	, CASE WHEN LaborTotalBillable > 0 OR s.LaborPricingEst > 0 THEN 'Labor'
			WHEN MatlTotalBillable > 0 OR MaterialPricingEst > 0 THEN 'Material'
			WHEN MiscTotalBillable > 0 OR OtherPricingEst > 0 OR SubcontractPricingEst > 0  THEN 'Misc'
			WHEN EquipTotalBillable > 0 OR EquipmentPricingEst > 0 THEN 'Equipment'
			ELSE 'Other' 
	   END									 AS Type
	,  q.WorkOrderQuoteScopeDescription		 AS [Work Scope Description]
	, s.CallType 
					--+ CASE WHEN MatlTotalBillable > 0 OR MaterialPricingEst > 0 THEN ': ' + MatlNotes
 				--		ELSE	''
					--END						 
					AS [Description]
	, s.Price								 AS [Total Pricing Est]
	, q.WorkOrderQuoteScopeDerivedPricingEst AS [Derived Pricing Est]
	, q.WorkOrderQuoteScopePriceMethod		 AS	[PriceMethod]
	, CASE WHEN LaborTotalBillable > 0 OR s.LaborPricingEst > 0 THEN COALESCE(LaborTotalBillable,LaborPricingEst)
		WHEN MatlTotalBillable > 0 OR MaterialPricingEst > 0 THEN COALESCE(MatlTotalBillable, MaterialPricingEst)
		WHEN MiscTotalBillable > 0 OR OtherPricingEst > 0 OR SubcontractPricingEst > 0 THEN COALESCE(q.MiscTotalBillable,OtherPricingEst,SubcontractPricingEst)
		WHEN EquipTotalBillable > 0 OR EquipmentPricingEst > 0 THEN COALESCE(q.EquipTotalBillable,EquipmentPricingEst)
		END AS TotalBillable
	--, q.LaborQty
	--, q.LaborTotalBillable
	--, q.MatlQty
	--, q.MatlBillRate
	--, q.MatlTotalBillable
	--, q.MiscQty
	--, q.MiscBillRate
	--, q.MiscTotalBillable
	--, s.LaborPricingEst
	--, s.MaterialPricingEst
	--, s.EquipmentPricingEst
	--, s.SubcontractPricingEst
	--, s.OtherPricingEst
	--, q.EquipQty
	--, q.EquipBillRate
	--, q.EquipTotalBillable
	, q.WorkOrderQuoteScopeCustomerPO	AS [CustomerPO]
	FROM vrvSMWorkOrderQuote q 
		INNER JOIN SMWorkOrderQuoteScope s ON 
			q.SMCo = s.SMCo 
			AND q.WorkOrderQuote = s.WorkOrderQuote 
			AND q.WorkOrderQuoteScope = s.WorkOrderQuoteScope
		INNER JOIN SMEntity e ON 
			e.SMCo		= q.SMCo 
		--AND e.EntitySeq = q.EntitySeq 
		AND e.EntitySeq = q.WorkOrderQuoteScopeEntitySeq
		AND e.Type = 11
	WHERE q.SMCo = @SMCo AND q.WorkOrderQuote = @WorkOrderQuote
)

GO

Grant SELECT ON dbo.mckfnSMQuoteDetail TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnSMQuoteDetail(1, 208048, 1000171) -- material
 
Select * From dbo.mckfnSMQuoteDetail(1, 245764, 7) 

Select * From dbo.mckfnSMQuoteDetail(1, 10000152) 

*/