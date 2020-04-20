use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnSLSubByJob' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnSLSubByJob'
	DROP FUNCTION dbo.mckfnSLSubByJob
end
go

print 'CREATE FUNCTION dbo.mckfnSLSubByJob'
go

CREATE FUNCTION [dbo].[mckfnSLSubByJob]
(
	@Job		bJob 
)
-- ========================================================================
-- Object Name: dbo.mckfnSLSubByJob
-- Author:		Ziebell, Jonathan
-- Create date: 03/21/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	05/11/2017 Initial Build
--				J.Ziebell	06/09/2017 Update
-- ========================================================================
RETURNS TABLE
AS 
RETURN  
WITH SLCostSum (SLCo
				, SL
				, Job
				, PhaseGroup
				, Phase
				, CostType
				, Item
				, ItemCount
				, Orig
				, Change
				, Invoice
				, InvTax
				, Paid
				, PaidTax
				, Retain
				, RetainTax)
			AS (SELECT SLCo
						, SL
						, Job
						, PhaseGroup
						, Phase
						, JCCType
						, MIN(SLItem) As Item
						, SUM(CASE WHEN U='1 SL Orig Entry' THEN 1 ELSE 0 END) AS ItemCount
						, SUM(OrigItemCost) AS Orig
						, SUM(ChangeOrderCost) AS Change
						--, (SUM(OrigItemCost) + SUM(ChangeOrderCost)) AS Current
						, SUM(APTDAmt) AS Invoice
						, SUM(CASE WHEN TaxType = 0 THEN 0 
									WHEN TaxType=2 THEN 0 
									ELSE APTaxAmt END) As InvPTax
						, SUM(CASE WHEN APTDStatus > 2 THEN APTDAmt ELSE 0 END) AS Paid
							, SUM(CASE WHEN TaxType = 0 THEN 0 
				WHEN TaxType=2 THEN 0 
				WHEN APTDStatus > 2 THEN APTaxAmt
				ELSE 0 END) As PaidTax
						, SUM(CASE WHEN ((APTDStatus = 2) AND (PayType = 3)) THEN APTDAmt ELSE 0 END) AS Retainage
						, SUM(CASE WHEN ((APTDStatus = 2) AND (PayType = 3) AND (TaxType in (0,2,4))) THEN APTaxAmt 
									ELSE 0 END) As RetTax
					FROM brvSLSubContrByJob2 
						WHERE Job = @Job 
						GROUP BY SLCo, SL, Job, PhaseGroup
						, Phase
						, JCCType)
		--, LineCount (SLCo
		--			, SL
		--			, Job
		--			, LineCount)
		--	AS	(SELECT IT.SLCo
		--			, IT.SL
		--			, IT.Job
		--			, COUNT(DISTINCT(IT.SLItem))
		--			FROM SLIT IT
		--			WHERE IT.Job = @Job
		--			GROUP BY IT.SLCo
		--			, IT.SL
		--			, IT.Job)
SELECT    HD.SL AS 'SubContract'
		, HD.Description AS 'Description'
		, HD.Vendor AS 'Vendor #'
		, VM.Name AS 'Vendor'
		, IT.Phase AS 'Phase Code'
		--, CT.Abbreviation AS 'Cost Type'
		, IT.Description as 'Line Descr'
		, CS.ItemCount AS 'Line Count'
		, CASE WHEN HD.Status = 0 THEN '0-Open'
				WHEN HD.Status = 1 THEN '1-Complete'
				WHEN HD.Status = 2 THEN '2-Closed'
				WHEN HD.Status = 3 THEN '3-Pending' 
				ELSE 'Unknown' END AS 'SL Status'
		, (CS.Orig + CS.Change) AS 'Current Amount'
		, (CS.Invoice - CS.InvTax) AS 'Invoiced'
		, (CS.Paid - CS.PaidTax) AS 'Paid'
		, (CS.Retain - CS.RetainTax)  AS 'Retainage'
		, (CS.Invoice - CS.InvTax - CS.Paid + CS.PaidTax - CS.Retain + CS.RetainTax) 'Current Due'
		, (CS.Orig + CS.Change - CS.Invoice + CS.InvTax) 'Remaining Committed'
FROM SLHD HD
	INNER JOIN SLCostSum CS
		ON HD.SLCo = CS.SLCo
		AND HD.SL = CS.SL
		AND HD.Job = CS.Job
	LEFT OUTER JOIN SLIT IT
		ON CS.SLCo = IT.SLCo
		AND CS.SL = IT.SL
		AND CS.Job = IT.Job
		AND CS.Item = IT.SLItem
	INNER JOIN	JCCT CT 
		ON CS.PhaseGroup = CT.PhaseGroup
		AND CS.CostType = CT.CostType 
	--LEFT OUTER JOIN LineCount LC
	--	ON HD.SLCo = LC.SLCo
	--	AND HD.SL = LC.SL
	--	AND HD.Job = LC.Job
	LEFT OUTER JOIN APVM VM 
		ON HD.VendorGroup = VM.VendorGroup 
		AND HD.Vendor = VM.Vendor
WHERE HD.Job = @Job

 GO

 Grant SELECT ON dbo.mckfnSLSubByJob TO [MCKINSTRY\Viewpoint Users]

 ---select top 1000 * from brvSLSubContrByJob;