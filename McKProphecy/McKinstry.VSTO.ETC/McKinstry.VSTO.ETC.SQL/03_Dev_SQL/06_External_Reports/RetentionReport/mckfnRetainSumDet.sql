use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnRetainSumDet' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnRetainSumDet'
	DROP FUNCTION dbo.mckfnRetainSumDet
end
go

print 'CREATE FUNCTION dbo.mckfnRetainSumDet'
go

CREATE FUNCTION [dbo].[mckfnRetainSumDet]
(
	  @JCCo			bCompany
    , @Dept			bDept
	, @Contract		bContract
	, @Customer		bCustomer  
)
-- ========================================================================
-- Object Name: dbo.mckfnRetainSum
-- Author:		Ziebell, Jonathan
-- Create date: 05/26/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	05/26/2017 Initial Build
-- ========================================================================

RETURNS TABLE
AS RETURN
	SELECT	--CM.JCCo
		 CM.Contract
		, CM.Department AS 'JC Department'
		, DM.udGLDept AS 'GL Department'
		, CM.Customer
		, IT.Item
		, IT.BillMonth
		, IT.BillNumber
		, IT.AmtBilled
		, IT.RetgBilled
		, IT.RetgRel
		, IT.AmountDue
		, IT.TaxGroup
		, IT.TaxCode
		, IT.TaxAmount
FROM JCCM CM
	--INNER JOIN JCCI CI
	--	ON CM.JCCo = CI.JCCo
	--	AND CM.Contract = CI.Contract
	INNER JOIN JCDM DM
		ON CM.JCCo = DM.JCCo
		AND CM.Department = DM.Department
	INNER JOIN JBIT IT
		ON CM.JCCo = IT.JBCo
		AND CM.Contract = IT.Contract
		--AND CI.Item = JS.Item
WHERE CM.JCCo =  @JCCo
	AND ISNULL(@Contract,CM.Contract) = CM.Contract 
	AND ISNULL(@Customer,CM.Customer) = CM.Customer
	AND ISNULL(@Dept,DM.udGLDept) = DM.udGLDept
	AND CM.ContractStatus in (1,2)
	AND CM.ContractAmt > 0 
	AND CM.CurrentRetainAmt <> 0

--RETURN

--END

GO

Grant select on dbo.mckfnRetainSumDet  to [MCKINSTRY\Viewpoint Users]


