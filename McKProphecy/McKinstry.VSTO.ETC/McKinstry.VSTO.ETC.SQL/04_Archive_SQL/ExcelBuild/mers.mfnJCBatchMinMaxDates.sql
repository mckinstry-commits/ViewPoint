use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCBatchMinMaxDates' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJCBatchMinMaxDates'
	DROP FUNCTION mers.mfnJCBatchMinMaxDates
end
go

print 'CREATE FUNCTION mers.mfnJCBatchMinMaxDates'
go

create function mers.mfnJCBatchMinMaxDates
(
	@JCCo bCompany
)
-- ========================================================================
-- mers.mfnJCBatchMinMaxDates
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return
select 
	jcco.JCCo
,	glco.LastMthSubClsd
,	glco.MaxOpen
,	dateadd(month,glco.MaxOpen-1,glco.LastMthSubClsd) as EarliestProjMonth
,	dateadd(month,glco.MaxOpen,glco.LastMthSubClsd) as LatestProjMonth 
from 
	GLCO glco join 
	JCCO jcco on 
		glco.GLCo=jcco.GLCo 
	and jcco.JCCo=@JCCo;
go

declare @JCCo bCompany
set @JCCo=1

select * from mers.mfnJCBatchMinMaxDates(@JCCo)
go