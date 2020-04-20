use ViewpointPropheyc
go

--Get JCCo for Contract
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetContractCompany' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnGetContractCompany'
	DROP FUNCTION mers.mfnGetContractCompany
end
go

print 'CREATE FUNCTION mers.mfnGetContractCompany'
go

create function mers.mfnGetContractCompany
(
	@Contract	bContract
)
-- ========================================================================
-- mers.mfnGetContractCompany
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
RETURNS bCompany
AS
BEGIN
declare @JCCo bCompany

select 
	@JCCo=JCCo 
from 
	JCCM  jccm join
	HQCO hqco on
		jccm.JCCo=hqco.HQCo
	and ( hqco.udTESTCo<>'Y' or hqco.udTESTCo is null )	
where 
	Contract=@Contract

return @JCCo 

end
go