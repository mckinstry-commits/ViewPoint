USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnGetSMQuotesDetailView' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnGetSMQuotesDetailView'
	DROP FUNCTION dbo.mckfnGetSMQuotesDetailView
End
GO

Print 'CREATE FUNCTION dbo.mckfnGetSMQuotesDetailView'
GO


CREATE FUNCTION [dbo].mckfnGetSMQuotesDetailView
(
  @SMCo				bCompany
, @Customer			bCustomer = NULL	
, @WorkOrderQuote	VARCHAR(15)  = NULL	
, @QuoteStatus		CHAR(1) = NULL
)
RETURNS TABLE
AS
 /* 
	Purpose:	Get SM Quote detail view data for McK SM Quotes VSTO
	Author:	Leo Gurdian
	Created:	10.24.2018	
	HISTORY:

	11.27.19 LG - MCK SM Quotes Excel VSTO is Doubling the Quoted Price -- TFS 5806  removed SUMs
	06.27.19 LG - Removed the contact name filter that is blocking data and moved it to left outer join; line #170-174. TFS 4783
					- Scope Of Work is now WorkOrderQuoteScopeDescription
	06.18.19 LG - was getting the default Customer Contact Email now fixed to get it from HQContact match by name  - rework TFS 3845
	06.13.19 LG - Missing Customer Contact Email when more than one contact in SM Service Sites - TFS 3845
	05.10.19 LG - Updated join boost performance.
					- Added [Customer Contact Email] TFS 3845
	03.06.19 LG - Remove Customer Number join as a quote may not have a customer no yet
	10.24.18 LG - Get SM Quote data
*/
RETURN
(
/*	TEST

DECLARE @SMCo bCompany = 1
DECLARE @Customer bCustomer = NULL --243368
DECLARE @WorkOrderQuote VARCHAR(15)  = '1002947' --102336 --NULL --'10000123'
DECLARE @QuoteStatus CHAR(1) = NULL --'A'
 */
  SELECT		
   Q.SMCo							AS [SMCo]
 , Q.WorkOrderQuote				AS [QuoteID]
 --, Q.WorkOrderQuoteScope
 --, Q.SortOrder
 ,  Q.Customer						AS [Customer]
 ,  Q.CustomerName				AS [Customer Name]
 ,  Q.CustomerContactName		As [Customer Contact Name]
 ,  Q.CustomerContactPhone		As [Customer Contact Phone]
 ,  smc.Email							AS [Customer Contact Email]
 --,  S.Division					AS [Division]
 --, Q.Seq							As [Seq]
 , Q.WorkScopeDescription		AS [Work Scope Description]
 --, Q.WorkOrderQuoteNotes					AS [Scope Of Work]
 --, CASE WHEN Q.MatlNotes IS NOT NULL THEN Q.MatlNotes
 --						ELSE	COALESCE(Q.LaborNotes,Q.MiscNotes,Q.EquipNotes,Q.TaskNotes)
	--END											AS [Scope Of Work]
 , Q.WorkOrderQuoteScopeDescription			AS [Scope Of Work]
 , CASE WHEN Q.WorkOrderQuoteScopePriceMethod = 'T' Then 'Time & Material'
		WHEN Q.WorkOrderQuoteScopePriceMethod = 'D' Then 'Derived Flat Price'
		WHEN Q.WorkOrderQuoteScopePriceMethod = 'F' Then 'Flat Price'
		ELSE NULL 
   END														AS [Price Method]
 , Q.WorkOrderQuoteScopeDerivedEstimate			AS [Derived Estimate]
 , CASE WHEN ISNULL(WorkOrderQuoteScopeDerivedPricingEst,0) = 0.00 
			THEN ISNULL(WorkOrderQuoteScopeMaterialPricingEst,0) + ISNULL(WorkOrderQuoteScopeLaborPricingEst,0)
				+ ISNULL(WorkOrderQuoteScopeEquipmentPricingEst,0) +  ISNULL(WorkOrderQuoteScopeSubcontractPricingEst,0) + ISNULL(WorkOrderQuoteScopeOtherPricingEst,0)
	ELSE	ISNULL(WorkOrderQuoteScopeDerivedPricingEst,0)
	END AS [Total Pricing Est] -- TFS 5806  removed SUMs
 , Q.WorkOrderQuoteScopeDerivedPricingEst			AS [Derived Pricing Est]	
 , Q.WorkOrderQuoteScopeMaterialPricingEst		As [Material Pricing Est]
 , Q.WorkOrderQuoteScopeLaborPricingEst			As [Labor Pricing Est]
 , Q.WorkOrderQuoteScopeEquipmentPricingEst		As [Equipment Pricing Est]
 , Q.WorkOrderQuoteScopeSubcontractPricingEst	As [Subcontract Pricing Est]
 , Q.WorkOrderQuoteScopeOtherPricingEst			As [Other Pricing Est]
 --, Q.LaborBillRate							As [Labor Bill Rate]
 --, Q.EquipTotalBillable							AS [Equip Total Billable]
 --, Q.LaborTotalBillable							AS [Labor Total Billable]
 --, Q.QuoteStatus								AS [Quote Status]
 , Q.WorkOrderQuoteScopeCustomerPO				AS [Customer PO]
 , X.EnteredDate								AS [Entered Date]
 , REPLACE(ISNULL(X.EnteredBy,''),'MCKINSTRY\','') As [EnteredBy]
 , X.udExpirationDate			AS [Expiration Date]
 --, Q.ServiceCenter				As [Service Center]
 , Q.ServiceSite					AS [Service Site]
 , Q.ServiceSiteDescription	As [Service Site Description]
 , Q.ServiceSiteAddress1		As [Service Site Address1]
 , Q.ServiceSiteAddress2		As [Service Site Address2]
 , Q.ServiceSiteCity				AS [Service Site City]
 , Q.ServiceSiteState			As [Service Site State]
 , Q.ServiceSiteZip				As [Service Site Zip]
 , Q.WorkOrderQuoteScope		AS [Quote Scope]
-- , Q.ServiceSiteCountry			As [Service Site Country]
 --, Q.MaterialDescription
 --, Q.MatlQty
 --, Q.MatlCostRate
 --, Q.MatlCostTotal
 --, Q.MaterialTaxEst
 --, Q.MatlTaxAmount
 --, Q.MatlBillRate
 --, Q.MatlTotalBillable

 --, Q.MiscDescription
 --, Q.MiscQty
 --, Q.MiscCostRate
 --, Q.MiscCostTotal
 --, Q.MiscTaxAmount
 --, Q.MiscBillRate
 --, Q.MiscTotalBillable

 --, Q.EquipQty
 --, Q.EquipCostRate
 --, Q.EquipBillRate
 --, Q.CategoryDescription
 --, Q.TimeUM
 --, Q.RevQty
 --, Q.LaborQty
 --, Q.CraftDescription
 --, Q.ClassDescription
 --, Q.LaborCostRate

 --, Q.Name
 --, Q.WorkOrderQuoteScopeNotToExceed
 --, Q.DateApproved
 --, Q.DateCanceled
 --, Q.WorkOrderQuoteScopeCustomerPO
 --, Q.WorkOrderQuoteScopeStatus
 --, Q.WorkOrderQuoteScopeDateApproved
 --, Q.LaborTaxAmount
 --, Q.EquipTaxAmount
 --, Q.LaborTaxEst
 --, Q.EquipmentTaxEst
 --, Q.SubcontractTaxEst
 --, Q.OtherTaxEst
-- , dbo.vf_rptAddressFormat
--(
--    Q.CustomerAddress1
--    , Q.CustomerAddress2
--    , Q.CustomerCity
--    , Q.CustomerState
--    , Q.CustomerZip
--    , Q.CustomerCountry
--    , 'H'
--)

 --, Q.RequestedBy
 --, Q.RequestedPhone
 --, Q.RequestedDate

--, Q.StandardTaskDescription			As [Service Site Country]
--, Q.ServiceItemDescription			As [Service Site Country]
--, Q.WorkOrderQuoteScopeNotes		As [Service Site Country]
--, Q.WorkOrderQuoteScopeDescription	As [Scope Description]
 FROM  Viewpoint.dbo.SMWorkOrderQuoteExt X ----(A)pproved, (C)anceled, (O)pen
		LEFT JOIN dbo.vrvSMWorkOrderQuote Q
			ON		 X.SMCo = Q.SMCo
				AND X.WorkOrderQuote = Q.WorkOrderQuote
		LEFT OUTER JOIN dbo.SMServiceSite S
			ON		S.ServiceSite = Q.ServiceSite
		LEFT OUTER  JOIN dbo.SMServiceSiteContact  smssc
			ON		
					 S.ServiceSite = smssc.ServiceSite
				AND S.ContactGroup = smssc.ContactGroup
				--AND S.ContactSeq = smssc.ContactSeq -- this is the default Contact 
		LEFT OUTER 	JOIN dbo.SMContact smc  -- TFS 3845
			ON 
					smc.ContactGroup = smssc.ContactGroup
				AND smc.ContactSeq = smssc.ContactSeq
				AND  RTrim(Coalesce(smc.FirstName + ' ','') 
	 					 --+ Coalesce(smc.MiddleInitial + ' ', '') -- SM WO Quote doesn't use it
						 + Coalesce(smc.LastName + ' ', '')) = Q.CustomerContactName -- I hate doing this but there's no 'ContactSeq' in SMWorkOrderQuoteExt
 WHERE 
			 Q.SMCo			  = @SMCo
		AND (LTRIM(RTRIM(Q.WorkOrderQuote)) = LTRIM(RTRIM(@WorkOrderQuote)) OR (@WorkOrderQuote IS NULL))
		AND (Q.Customer = @Customer OR @Customer IS NULL)
		AND (X.Status = @QuoteStatus OR @QuoteStatus IS NULL)
GROUP BY Q.SMCo, Q.WorkOrderQuote, Q.Customer
 , Q.CustomerName, Q.CustomerContactName, Q.CustomerContactPhone, smc.Email, Q.WorkScopeDescription,  Q.WorkOrderQuoteScopeDescription, Q.WorkOrderQuoteScopePriceMethod
 , Q.WorkOrderQuoteScopeDerivedEstimate, Q.WorkOrderQuoteScopeDerivedPricingEst, Q.WorkOrderQuoteScopeMaterialPricingEst, Q.WorkOrderQuoteScopeLaborPricingEst, Q.WorkOrderQuoteScopeEquipmentPricingEst, Q.WorkOrderQuoteScopeSubcontractPricingEst, Q.WorkOrderQuoteScopeOtherPricingEst
 , Q.WorkOrderQuoteScopeCustomerPO, X.EnteredDate, X.EnteredBy, X.udExpirationDate, Q.ServiceSite, Q.ServiceSiteDescription, Q.ServiceSiteAddress1, Q.ServiceSiteAddress2, Q.ServiceSiteCity, Q.ServiceSiteState, Q.ServiceSiteZip, WorkOrderQuoteScope
 , smc.FirstName, smc.LastName

 )

GO

Grant SELECT ON dbo.mckfnGetSMQuotesDetailView TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnGetSMQuotesDetailView(1, null , null, 'A')

Select * From dbo.mckfnGetSMQuotesDetailView(1, null ,1000134, 'N')

Select * From dbo.mckfnGetSMQuotesDetailView(1, null ,1000314, 'N')

Select * From dbo.mckfnGetSMQuotesDetailView(1, null, 1004319, 'A')

*/