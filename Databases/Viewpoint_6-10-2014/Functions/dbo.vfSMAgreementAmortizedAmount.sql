SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Matthew Bradford
-- Create date: 3/14/2013
-- Amount to Recognize = MIN(Invoiced Amount Sum, Recognizble Amount Sum up to through date) - Recognized Amount Sum
-- Task 43554 --Active expired and terminated
-- =============================================
CREATE FUNCTION [dbo].[vfSMAgreementAmortizedAmount]
(	
	-- Add the parameters for the function here
	@SMCo bCompany,
	@ThroughDate bDate --Month to recognize revenue up to.
)
RETURNS TABLE 
AS
RETURN
	WITH SumDeferralCTE
	AS
	(
	SELECT 
		SMCo 
		,Agreement 
		,Revision 
		,[Service] 
		,SUM(CASE WHEN Date <= @ThroughDate THEN vSMAgreementRevenueDeferral.Amount Else 0 END) AS Amount
		--Case added to sum instead of where clause because Null is skipped in Min function
		--If a null is present treat it as a 0 instead of Null.
	FROM 
		vSMAgreementRevenueDeferral
	WHERE 
		SMCo = @SMCo
	GROUP BY 
		SMCo, Agreement, Revision, [Service]
	UNION ALL
	SELECT 
		SMCo
		,Agreement 
		,Revision
		,[Service] 
		,SUM(CASE WHEN SMInvoiceID IS NOT NULL THEN vSMAgreementBillingSchedule.BillingAmount Else 0 END) AS Amount
	FROM 
		vSMAgreementBillingSchedule
	WHERE 
		SMCo = @SMCo AND
		vSMAgreementBillingSchedule.BillingType = 'S'
	GROUP BY 
		SMCo, Agreement, Revision, [Service]
	),
	RecognizedAmtCTE(SMCo, Agreement, Revision, [Service], Amount)
	AS
	(
	SELECT
		SMCo
		,Agreement 
		,Revision 
		,[Service] 
		,SUM(vSMAgreementAmrt.Amount) AS Amount
	FROM
		vSMAgreementAmrt
	WHERE
		SMCo = @SMCo
	GROUP BY
		SMCo, Agreement, Revision, [Service]
	),
	RecognizableAmountsCTE
	AS
	(	
	SELECT 
	SMCo
	,Agreement
	,Revision
	,[Service]
	,SUM(Amount) AS RecognizableAmount
	FROM
	(
		SELECT
			SMCo 
			,Agreement 
			,Revision 
			,[Service] 
			,MIN(Amount) AS Amount
		FROM
			SumDeferralCTE
		GROUP BY
			SMCo, Agreement, Revision, [Service]
		UNION ALL
		SELECT
			SMCo, 
			Agreement, 
			Revision, 
			[Service],		
			-Amount
		FROM
			RecognizedAmtCTE
	) RecognizableAmounts 

	GROUP BY SMCo, Agreement, Revision, [Service]
	)
	
	SELECT 			
		RecognizableAmountsCTE.SMCo 
		,RecognizableAmountsCTE.Agreement 
		,RecognizableAmountsCTE.Revision 
		,RecognizableAmountsCTE.[Service]		
		,RecognizableAmountsCTE.RecognizableAmount
		,vSMDepartment.AgreementRevDefGLAcct
		,vSMDepartment.AgreementRevGLAcct
		,vSMDepartment.GLCo
	FROM 
		RecognizableAmountsCTE
	INNER JOIN
		SMAgreementExtended
	ON
		RecognizableAmountsCTE.SMCo = SMAgreementExtended.SMCo AND
		RecognizableAmountsCTE.Agreement = SMAgreementExtended.Agreement AND
		RecognizableAmountsCTE.Revision = SMAgreementExtended.Revision 
	INNER JOIN
		vSMAgreementType
	ON
		SMAgreementExtended.SMCo = vSMAgreementType.SMCo AND
		SMAgreementExtended.AgreementType = vSMAgreementType.AgreementType
	INNER JOIN
		vSMDepartment
	ON
		vSMAgreementType.SMCo = vSMDepartment.SMCo AND
		vSMAgreementType.Department = vSMDepartment.Department
	WHERE
		SMAgreementExtended.RevenueRecognition = 'S' AND
		SMAgreementExtended.RevisionStatus >= 2
		
	

	
GO
GRANT SELECT ON  [dbo].[vfSMAgreementAmortizedAmount] TO [public]
GO
