use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME='mers')
BEGIN
	print 'SCHEMA ''mers'' already exists  -- McKinstry Enterprise Reporting Schema'
END
ELSE
BEGIN
	print 'CREATE SCHEMA ''mers'' -- McKinstry Enterprise Reporting Schema'
	EXEC sp_executesql N'CREATE SCHEMA mers AUTHORIZATION dbo'
END
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnARDetail')
begin
	print 'DROP FUNCTION mers.mfnARDetail'
	DROP FUNCTION mers.mfnARDetail
end
go

print 'CREATE PROCEDURE mers.mfnARDetail'
GO


CREATE FUNCTION mers.mfnARDetail 
(	
	-- Declare Input Parameters
	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
)
/*
Declare Table Variable to be returned
*/
RETURNS @retTable TABLE 
(
	Year					INT					null
,	PRCo					bCompany			null
,	Employee				bEmployee			null
,	EmployeeName			VARCHAR(85)			null
,	Craft					bCraft				null
,	CraftDesc				bDesc				null
,	Class					bClass				null
,	ClassDesc				bDesc				null
,	PRGLCo					bCompany			null
,	PRGLDept				VARCHAR(20)			null
,	PRGLDeptDesc			bDesc				null
,	UtilizationGoal			bPct				null
,	AsOfPREndDate			SMALLDATETIME		null
,	OverheadHours			bHrs				null default (0)
,	OverheadHoursPct		bPct				null default (0)
,	NonRevenueJobHours		bHrs				null default (0)
,	NonRevenueJobHoursPct	bPct				null default (0)
,	TotalOverheadHours		bHrs				null default (0)
,	TotalOverheadHoursPct	bPct				null default (0)
,	RevenueJobHours			bHrs				null default (0)
,	RevenueJobHoursPct		bPct				NULL default (0)
,	TotalHours				bHrs				null default (0)
)
AS
BEGIN
	/*
	Perform initial validation and error checking.
	*/	
	IF NOT EXISTS ( SELECT 1 FROM HQCO WHERE HQCo=@Company OR @Company IS NULL )
	BEGIN
		SELECT @Company=null
	END 

	/*
	Populate Table to return
	*/
	INSERT @retTable
	        ( 
	        )
	SELECT

	FROM 

	WHERE


	Complete:

	RETURN 
END
GO

GRANT SELECT ON mers.mfnARDetail to PUBLIC
GO
