SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================

-- Author:		Dan Koslicki

-- Create date: 03/18/13

-- Description:	Validation for SM Agreement Amortize Revenue Mth

-- Modified:	

-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementAmortizeRevMthVal]

	@SMCo			AS bCompany, 
	@ThroughDate	AS bDate,
	@Mth			AS bMonth, 
	@msg			AS VARCHAR(255) = NULL OUTPUT



AS

BEGIN
	
	DECLARE @Source AS bSource 
	SELECT @Source = 'SMAmmortize'

	IF EXISTS(
				SELECT		AA.GLCo, 
							AA.AgreementRevDefGLAcct,
							AA.AgreementRevGLAcct
				
				FROM		vfSMAgreementAmortizedAmount(@SMCo, @ThroughDate) AA

				INNER JOIN	vfGLClosedMonths(@Source, @Mth) CM 
				
						ON
							AA.GLCo = CM.GLCo
				
				WHERE		CM.IsMonthOpen = 0)

	BEGIN
		SELECT @msg = 'The Month entered has been closed for one or more of the GL Accounts being used.'
		RETURN 1 
	END 

	RETURN 0 
END  
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementAmortizeRevMthVal] TO [public]
GO
