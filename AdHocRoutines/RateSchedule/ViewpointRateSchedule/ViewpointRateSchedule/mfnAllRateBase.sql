USE Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnAllRateBase')
begin
	print 'DROP FUNCTION dbo.mfnAllRateBase'
	DROP FUNCTION dbo.mfnAllRateBase
end
go

print 'CREATE FUNCTION dbo.mfnAllRateBase'
go

CREATE function mfnAllRateBase
(
	@Company	bCompany	= null
,	@Craft		bCraft		= null
,	@Class		bClass		= NULL
,	@Shift		INT			= NULL 
)
RETURNS TABLE 
AS
RETURN 
(
SELECT 
	* 
FROM 
	dbo.mfnStaffRateBase(@Company, @Craft,@Class,@Shift)
UNION
SELECT 
	* 
FROM 
	dbo.mfnUnionRateBase(@Company, @Craft,@Class,@Shift)
)
GO

GRANT SELECT ON mfnAllRateBase TO PUBLIC
go 

SELECT 
	* 
FROM 
	dbo.mfnAllRateBase(1, null,'501IN',null)
ORDER BY
	PRCo
,	Craft
,	Class
,	Shift