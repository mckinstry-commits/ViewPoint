use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetUserProfile2' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnGetUserProfile2'
	DROP FUNCTION mers.mfnGetUserProfile2
end
go

print 'CREATE FUNCTION mers.mfnGetUserProfile2'
go

create function mers.mfnGetUserProfile2
(
	@JCCo	bCompany
,	@Login	sysname
)
-- ========================================================================
-- mers.mfnGetUserProfile2
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   7/27/2016  Remove Project Manager Restriction
--              J.Ziebell  11/10/2016  Only Return 1 field.
-- ========================================================================
returns table as return

select
	ddup.VPUserName
from DDUP ddup 
where
	(
			( @Login is not null and upper(ddup.VPUserName)=upper(@Login) )
		or ( @Login is null and upper(ddup.VPUserName)=upper(SUSER_SNAME()) ) 
		or ( upper(@Login) = 'ALL' )
	)
/*and (
		jcmp.JCCo=@JCCo or @JCCo is null
	)*/

go

Grant SELECT ON mers.mfnGetUserProfile2 TO [MCKINSTRY\Viewpoint Users]

go