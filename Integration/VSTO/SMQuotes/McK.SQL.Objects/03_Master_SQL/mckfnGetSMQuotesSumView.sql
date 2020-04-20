USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnGetSMQuotesSumView' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnGetSMQuotesSumView'
	DROP FUNCTION dbo.mckfnGetSMQuotesSumView
End
GO

Print 'CREATE FUNCTION dbo.mckfnGetSMQuotesSumView'
GO


CREATE FUNCTION [dbo].mckfnGetSMQuotesSumView
(
  @SMCo				bCompany
, @Customer			bCustomer = NULL	
, @WorkOrderQuote	VARCHAR(15)  = NULL	
, @QuoteStatus		CHAR(1) = NULL
)
RETURNS TABLE
AS
 /* 
	Purpose:	Get SM Quote summary view for McK SM Quotes VSTO
	Author:	Leo Gurdian
	Created:	10.24.2018	
	HISTORY:

	11.27.19 LG - MCK SM Quotes Excel VSTO is Doubling the Quoted Price -- TFS 5806  removed SUMs
	06.18.19 LG - was getting the default Customer Contact Email now fixed to get it from HQContact match by name - rework TFS 3845
	06.13.19 LG - Missing Customer Contact Email when more than one contact in SM Service Sites - TFS 3845
	05.10.19 LG - Updated join boost performance.
					- Added [Customer Contact Email] - TFS 3845
	03.06.19 LG - Remove Customer Number join as a quote may not have a customer no yet
	10.25.18 LG - [Scope Of Work] udpated to get WorkScopeDescription
	10.24.18 LG - Get SM Quote data
*/
RETURN
(
/*	TEST 
DECLARE @SMCo bCompany = 1
DECLARE @Customer bCustomer = 200901
DECLARE @WorkOrderQuote VARCHAR(15)  = NULL --'10000123'
DECLARE @QuoteStatus CHAR(1) = NULL --'A'

DECLARE @WorkOrderQuote VARCHAR(15)  = 1001558 --'10000123'
DECLARE @WorkOrderQuote VARCHAR(15)  = 102336 --'10000123'
*/

  SELECT DISTINCT
   Q.SMCo						As [SMCo]
 , Q.WorkOrderQuote				As [QuoteID]
 , Q.WorkOrderQuoteScope
 --, Q.SortOrder
 ,  Q.Customer						AS [Customer]
 ,  Q.CustomerName				As [Customer Name]
 ,  Q.CustomerContactName		As [Customer Contact Name]
 ,  Q.CustomerContactPhone		As [Customer Contact Phone]
 ,  smc.Email							AS [Customer Contact Email]
 , Q.WorkOrderQuoteScopeDescription			AS [Scope Of Work]
 , CASE WHEN Q.WorkOrderQuoteScopePriceMethod = 'T' Then 'Time & Material'
		WHEN Q.WorkOrderQuoteScopePriceMethod	 = 'D' Then 'Derived Flat Price'
		WHEN Q.WorkOrderQuoteScopePriceMethod	 = 'F' Then 'Flat Price'
		ELSE NULL 
   END														AS [Price Method]
 , Q.WorkOrderQuoteScopeDerivedEstimate			AS [Derived Estimate]
 , Q.WorkOrderQuoteScopeDerivedPricingEst			AS [Derived Pricing Est]	
 , Q.WorkOrderQuoteScopeMaterialPricingEst		As [Material Pricing Est]
 , Q.WorkOrderQuoteScopeLaborPricingEst			As [Labor Pricing Est]
 , Q.WorkOrderQuoteScopeEquipmentPricingEst		As [Equipment Pricing Est]
 , Q.WorkOrderQuoteScopeSubcontractPricingEst	As [Subcontract Pricing Est]
 , Q.WorkOrderQuoteScopeOtherPricingEst			As [Other Pricing Est]
 , Q.WorkOrderQuoteScopeCustomerPO				AS [Customer PO]
 , X.EnteredDate								AS [Entered Date]
 , REPLACE(ISNULL(X.EnteredBy,''),'MCKINSTRY\','') As [EnteredBy]
 , X.udExpirationDate			AS [Expiration Date]
 , Q.ServiceSite				As [Service Site]
 , Q.ServiceSiteDescription		As [Service Site Description]
 , Q.ServiceSiteAddress1		As [Service Site Address1]
 , Q.ServiceSiteAddress2		As [Service Site Address2]
 , Q.ServiceSiteCity			As [Service Site City]
 , Q.ServiceSiteState			As [Service Site State]
 , Q.ServiceSiteZip				As [Service Site Zip]
 FROM  dbo.SMWorkOrderQuoteExt X ----(A)pproved, (C)anceled, (O)pen
		LEFT JOIN dbo.vrvSMWorkOrderQuote Q
			ON		 X.SMCo = Q.SMCo
				AND X.WorkOrderQuote = Q.WorkOrderQuote
		LEFT OUTER JOIN dbo.SMServiceSite S
			ON		S.ServiceSite = Q.ServiceSite
		LEFT OUTER  JOIN SMServiceSiteContact  smssc
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
		AND (X.Customer = @Customer OR @Customer IS NULL)
		AND (X.Status = @QuoteStatus OR @QuoteStatus IS NULL)
)

GO

Grant SELECT ON dbo.mckfnGetSMQuotesSumView TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnGetSMQuotesSumView(1, null , '1000100', NULL)

Select * From dbo.mckfnGetSMQuotesSumView(1, 201268 , 1000321, 'A')

SELECT * FROM mckfnGetSMQuotesSumView(1, 200901, null, null)

Select * From mckfnGetSMQuotesSumView(1, null, 10001170, 'A')

*/