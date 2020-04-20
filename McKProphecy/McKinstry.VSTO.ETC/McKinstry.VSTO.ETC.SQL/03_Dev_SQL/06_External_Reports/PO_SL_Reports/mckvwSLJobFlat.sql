use Viewpoint
go

ALTER VIEW [dbo].[mckvwSLJobFlat] AS
-- ========================================================================
-- Object Name: dbo.mckvwSLJobFlat
-- Author:		Ziebell, Jonathan
-- Create date: 06/13/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   6/16/2017  Overspend and Tax add	
--				J.Ziebell   6/27/2017  Fix for Tax tYpe 1 Retainage				
-- ========================================================================
WITH SLCostSum (SLCo
				, SL
				, Job
				, PhaseGroup
				, Phase
				, CostType
				, Status
				, Item
				, ItemCount
				, Orig
				, Change
				, CurTax
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
						, MAX(Status) AS Status
						, MIN(SLItem) As Item
						, SUM(CASE WHEN U='1 SL Orig Entry' THEN 1 ELSE 0 END) AS ItemCount
						, SUM(OrigItemCost) AS Orig
						, SUM(ChangeOrderCost) AS Change
						, SUM(SLCurTax) AS CurTax
						, SUM(APTDAmt) AS Invoice
						, SUM(CASE WHEN TaxType = 0 THEN 0 
									WHEN TaxType = 1 THEN 0
									WHEN TaxType=2 THEN 0 
									ELSE APTaxAmt END) As InvPTax
						, SUM(CASE WHEN APTDStatus > 2 THEN APTDAmt ELSE 0 END) AS Paid
							, SUM(CASE WHEN TaxType = 0 THEN 0 
									WHEN TaxType = 1 THEN 0
									WHEN TaxType=2 THEN 0 
									WHEN APTDStatus > 2 THEN APTaxAmt
									ELSE 0 END) As PaidTax
						, SUM(CASE WHEN ((APTDStatus = 2) AND (PayType = 3)) THEN APTDAmt ELSE 0 END) AS Retainage
						, SUM(CASE WHEN ((APTDStatus = 2) AND (PayType = 3) AND (TaxType in (0,2,4))) THEN APTaxAmt 
									ELSE 0 END) As RetTax
					FROM brvSLSubContrByJob2 
						GROUP BY SLCo, SL, Job, PhaseGroup
						, Phase
						, JCCType)
SELECT  CS.SLCo
		, CS.SL
		, CS.Job
		, CS.PhaseGroup
		, CS.Phase
		, HD.Description-- AS 'Description'
		, HD.Vendor --AS 'Vendor #'
		, VM.Name --AS 'Vendor'
		, CS.CostType  
		--, CT.Abbreviation AS 'CostType'
		, IT.Description AS 'LineDescr'
		, CS.ItemCount --aS 'Line Count'
		, CASE WHEN HD.Status = 0 THEN '0-Open'
				WHEN HD.Status = 1 THEN '1-Complete'
				WHEN HD.Status = 2 THEN '2-Closed'
				WHEN HD.Status = 3 THEN '3-Pending' 
				ELSE 'Unknown' END AS 'SLStatus'
		, (CS.Orig + CS.Change + CS.CurTax) AS 'CurrentAmount'
		, (CS.Invoice - CS.InvTax) AS 'Invoiced'
		, (CS.Paid - CS.PaidTax) AS 'Paid'
		, (CS.Retain - CS.RetainTax)  AS 'Retainage'
		, (CS.Invoice - CS.InvTax - CS.Paid + CS.PaidTax - CS.Retain + CS.RetainTax) 'CurrentDue'
		, CASE WHEN CS.Status = 2 THEN 0
				WHEN (CS.Invoice >= (CS.Orig + CS.Change  + CS.CurTax + CS.InvTax)) THEN 0
				ELSE (CS.Orig + CS.Change  + CS.CurTax - CS.Invoice + CS.InvTax) END AS 'RemainingCommitted'
		,   CASE WHEN (CS.Invoice - CS.InvTax) <=0 THEN 0
			WHEN (CS.Invoice - CS.InvTax) > (CS.Orig + CS.Change + CS.CurTax) THEN ((CS.Invoice - CS.InvTax) - (CS.Orig + CS.Change + CS.CurTax)) 
			ELSE 0 END AS Overspend
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
	LEFT OUTER JOIN APVM VM 
		ON HD.VendorGroup = VM.VendorGroup 
		AND HD.Vendor = VM.Vendor

 GO

 Grant SELECT ON dbo.mckvwSLJobFlat TO [MCKINSTRY\Viewpoint Users]