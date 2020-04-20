use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCBatchAllowedDates' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnJCBatchAllowedDates'
	DROP FUNCTION mers.mfnJCBatchAllowedDates
end
go

print 'CREATE FUNCTION mers.mfnJCBatchAllowedDates'
go

create function mers.mfnJCBatchAllowedDates
(
	@JCCo bCompany
)
-- ========================================================================
--  mers.mfnJCBatchAllowedDates
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return
with cte (JCCo, batchmonth, maxbatchmonth) as
(
    select 
		jcco.JCCo
	,	dateadd(month,glco.MaxOpen-1,glco.LastMthSubClsd) batchmonth
	,	dateadd(month,glco.MaxOpen,glco.LastMthSubClsd)  maxbatchmonth
    from 
	GLCO glco join 
	JCCO jcco on 
		glco.GLCo=jcco.GLCo 
	and jcco.JCCo=@JCCo
    union all
    select JCCo,  dateadd(month, 1, batchmonth), maxbatchmonth
    from cte
    where batchmonth < dateadd(day,( day(maxbatchmonth) * -1 ) + 1 ,maxbatchmonth) and JCCo=@JCCo
) 
select 
	JCCo
,	c.batchmonth
from 
	cte c
go
