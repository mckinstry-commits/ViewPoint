use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnConProphHist' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnConProphHist'
	DROP FUNCTION dbo.mckfnConProphHist
end
go

print 'CREATE FUNCTION dbo.mckfnConProphHist'
go

create function dbo.mckfnConProphHist
(
	@JCCo		bCompany
,	@Contract 	bContract
)
-- ========================================================================
-- mers.mckfnConProphHist
-- Author:	Ziebell, Jonathan
-- Create date: 01/10/2017
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   
-- ========================================================================
returns table as return

select z.Contract, z.Job, z.DateTime as LastSave, z.VPUserName as SaveUser, z1.DateTime as LastPost, z1.VPUserName as PostUser
FROM	mers.ProphecyLog z 
LEFT OUTER JOIN mers.ProphecyLog z1
		ON z.Contract=z1.Contract
		AND z.JCCo = z1.JCCo
		AND z1.Job IS NULL
		AND z1.Action = 'POST REV'
		AND z1.DateTime =(SELECT MAX(x1.DateTime) FROM mers.ProphecyLog x1
				WHERE x1.Contract = z1.Contract
				AND x1.Job IS NULL
				AND x1.Action ='POST REV')
WHERE z.JCCo = @JCCo
AND z.Contract=@Contract
AND z.Job IS NULL
AND z.Action = 'SAVE REV JECT'
AND z.DateTime =(SELECT MAX(x.DateTime) FROM mers.ProphecyLog x
					WHERE x.Contract = z.Contract
					AND x.Job IS NULL
					AND x.Action ='SAVE REV JECT')
UNION
select z.Contract, z.Job, z.DateTime as LastSave, z.VPUserName as SaveUser, z1.DateTime as LastPost, z1.VPUserName as PostUser
FROM	mers.ProphecyLog z 
LEFT OUTER JOIN mers.ProphecyLog z1
		ON z.Contract=z1.Contract
		AND z.JCCo = z1.JCCo
		AND z.Job = z1.Job
		AND z1.Action = 'POST COST'
		AND z1.DateTime =(SELECT MAX(x1.DateTime) FROM mers.ProphecyLog x1
				WHERE x1.Contract = z1.Contract
				AND x1.Job = z1.Job
				AND x1.Action ='POST COST')
WHERE z.JCCo = @JCCo
AND z.Contract=@Contract
AND z.Action = 'SAVE COST JECT'
AND z.DateTime =(SELECT MAX(x.DateTime) FROM mers.ProphecyLog x
					WHERE x.Contract = z.Contract
					AND x.Job=z.Job
					AND x.Action ='SAVE COST JECT')

go

Grant SELECT ON dbo.mckfnConProphHist TO [MCKINSTRY\Viewpoint Users]