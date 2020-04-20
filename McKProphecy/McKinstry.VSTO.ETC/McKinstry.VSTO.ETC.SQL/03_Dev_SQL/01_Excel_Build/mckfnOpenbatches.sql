use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnOpenBatches' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnOpenBatches'
	DROP FUNCTION dbo.mckfnOpenBatches
end
go

print 'CREATE FUNCTION dbo.mckfnOpenBatches'
go

create function dbo.mckfnOpenBatches
(
	@Login  	sysname
)
-- ========================================================================
-- mers.mckfnOpenBatches
-- Author:	Ziebell, Jonathan
-- Create date: 01/18/2017
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   
-- ========================================================================
returns table as return

select b.Contract as ContractOrJob, a.BatchId, a.Mth, 'Revenue' as Type
	FROM HQBC a 
		INNER JOIN JCIR b
			ON a.Co = b.Co
			AND a.Mth = b.Mth
			AND a.BatchId = b.BatchId
	WHERE a.Source='JC RevProj'
		AND a.CreatedBy=@Login
		AND a.Status<5
UNION
select b.Job as ContractOrJob, a.BatchId, a.Mth, 'Cost' as Type
	FROM HQBC a 
		INNER JOIN JCPB b
			ON a.Co = b.Co
			AND a.Mth = b.Mth
			AND a.BatchId = b.BatchId
	WHERE a.Source='JC Projctn'
		AND a.CreatedBy=@Login
		AND a.Status<5

go

Grant SELECT ON dbo.mckfnOpenBatches TO [MCKINSTRY\Viewpoint Users]