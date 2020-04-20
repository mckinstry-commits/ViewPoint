use ViewpointProphecy
go

--Contract Selector List
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJobSelectorList' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJobSelectorList'
	DROP FUNCTION mers.mfnJobSelectorList
end
go

print 'CREATE FUNCTION mers.mfnJobSelectorList'
go

create function mers.mfnJobSelectorList
(
	@Contract		bContract	= null
)
-- ========================================================================
-- mers.mfnJobSelectorList
-- Author:	Ziebell, Jonathan
-- Create date: 07/26/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return
select
	JM.Job
,	JM.Description
FROM JCJM JM
	INNER JOIN HQCO HQ
		ON JM.JCCo = HQ.HQCo
		AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
WHERE JM.Contract = @Contract

go
