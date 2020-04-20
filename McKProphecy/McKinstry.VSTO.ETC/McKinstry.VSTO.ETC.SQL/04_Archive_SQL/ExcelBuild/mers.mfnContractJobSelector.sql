use ViewpointProphecy
go

--Contract Selector List
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobSelector' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobSelector'
	DROP FUNCTION mers.mfnContractJobSelector
end
go

print 'CREATE FUNCTION mers.mfnContractJobSelector'
go

CREATE FUNCTION mers.mfnContractJobSelector
(
	  @JCCo			bCompany	= NULL
	, @Contract     bContract   = NULL
)
-- ========================================================================
-- mers.mfnContractJobSelector
-- Author:	Ziebell, Jonathan
-- Create date: 08/2/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
RETURNS TABLE AS RETURN
SELECT
	  CM.JCCo
	, LTRIM(CM.Contract) AS TrimContract
	, CM.Contract
	, JM.Job
FROM
	JCCM CM 
	INNER JOIN HQCO HQ
		ON CM.JCCo = HQ.HQCo
		AND ((HQ.udTESTCo<>'Y') OR (HQ.udTESTCo is null))
	INNER JOIN JCJM JM
		ON CM.JCCo = JM.JCCo
		AND CM.Contract = JM.Contract
WHERE CM.ContractStatus <2
AND ((CM.JCCo = @JCCo) or (@JCCo is null))
AND ((CM.Contract = @Contract) or (@Contract is null))

GO
