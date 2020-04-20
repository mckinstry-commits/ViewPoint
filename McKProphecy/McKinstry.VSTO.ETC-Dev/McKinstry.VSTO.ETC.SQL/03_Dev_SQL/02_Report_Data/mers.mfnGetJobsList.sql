use ViewpointProphecy
go

--Contract Selector List
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetJobsList' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnGetJobsList'
	DROP FUNCTION mers.mfnGetJobsList
end
go

print 'CREATE FUNCTION mers.mfnGetJobsList'
go

create function mers.mfnGetJobsList
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
)
-- ========================================================================
-- mers.mfnGetJobsList
-- Author:	Ziebell, Jonathan
-- Create date: 08/11/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return
select
	JM.Job
,	JM.Description AS JobDesc
FROM JCJM JM
	INNER JOIN HQCO HQ
		ON JM.JCCo = HQ.HQCo
		AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
WHERE ((JM.JCCo = @JCCo) OR (@JCCo IS NULL))
AND ((JM.Contract = @Contract) OR (@Contract IS NULL))
AND ((JM.Job = @Job) OR (@Job IS NULL))
go
