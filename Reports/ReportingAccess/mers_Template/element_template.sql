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

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnTestFunction')
begin
	print 'DROP FUNCTION mers.mfnTestFunction'
	DROP FUNCTION mers.mfnTestFunction
end
go

print 'CREATE FUNCTION mers.mfnTestFunction'
go

CREATE FUNCTION mers.mfnTestFunction 
(	
	-- Add the parameters for the function here
	@parmString	varchar(50) = ''
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT @@SERVERNAME as ServerName, db_name() as DatabaseName, suser_sname() as CurrentUser, getdate() as CurrentDateTime,@parmString as Note
)
GO

select * from mers.mfnTestFunction('Direct from function')
go


if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' and ROUTINE_NAME='mspTestFunction')
begin
	print 'DROP PROCEDURE mers.mspTestFunction'
	DROP PROCEDURE mers.mspTestFunction
end
go

print 'CREATE PROCEDURE mers.mspTestFunction'
go

CREATE PROCEDURE mers.mspTestFunction 
(	
	-- Add the parameters for the function here
	@parmString	varchar(50) = ''
)
AS
BEGIN
	select * from mers.mfnTestFunction(@parmString)
END
GO

exec mers.mspTestFunction @parmString='Called via Stored Procedure'
go

if exists ( select * from [INFORMATION_SCHEMA].[VIEWS] where TABLE_SCHEMA='mers' and TABLE_NAME='mvwTestFunction')
begin
	print 'DROP VIEW mers.mvwTestFunction'
	DROP VIEW mers.mvwTestFunction
end
go

print 'CREATE VIEW mers.mvwTestFunction'
go

CREATE VIEW mers.mvwTestFunction 
AS

select * from mers.mfnTestFunction('Called via database View')

GO

select * from mers.mvwTestFunction 
go





