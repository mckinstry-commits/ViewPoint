use Viewpoint
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetBnOTaxReportingCode' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnGetBnOTaxReportingCode]'
	drop function [dbo].mfnGetBnOTaxReportingCode 
end
go

PRINT 'CREATE FUNCTION mfnGetBnOTaxReportingCode'
GO

CREATE FUNCTION mfnGetBnOTaxReportingCode 
(
	-- Add the parameters for the function here
	@TaxGroup	bGroup
,	@TaxCode	bTaxCode
)
RETURNS varchar(30)
AS
BEGIN
	-- =============================================
	-- Author:		Bill Orebaugh
	-- Create date: 2015-09-23
	-- Description:	
	--	Function to return "City" level reporting 
	--	code based on a given Parent Tax Code
	--	Used for B&O Reporting and the complexities 
	--  of WA State tax reporting	
	-- =============================================

	-- Declare the return variable here
	DECLARE @ReportingCode varchar(30)

	-- Add the T-SQL statements to compute the return value here
	select
		@ReportingCode = hqtx_c.udReportingCode 
	from
		HQTX hqtx left join
		HQTL hqtl on
			hqtx.TaxGroup=hqtl.TaxGroup
		and	hqtx.TaxCode=hqtl.TaxCode 
		and hqtx.MultiLevel='Y'
		and hqtl.TaxLink like '%[_]C%' left join
		HQTX hqtx_c on
			hqtl.TaxGroup=hqtx_c.TaxGroup
		and hqtl.TaxLink=hqtx_c.TaxCode
		and hqtx_c.MultiLevel='N'
	where
		hqtx.TaxGroup=@TaxGroup
	and	hqtx.TaxCode=@TaxCode
	and hqtx.MultiLevel='Y'

	-- Return the result of the function
	RETURN coalesce(@ReportingCode,'UNKNOWN')

END
GO

PRINT 'grant exec on mfnGetBnOTaxReportingCode to public'
GO

grant exec on mfnGetBnOTaxReportingCode to public
go

-- SAMPLES
/*
declare @TaxGroup bGroup
declare @TaxCode bTaxCode

set @TaxGroup = 1

set @TaxCode = 'WA0022X'
select 
	@TaxGroup as TaxGroup
,	@TaxCode as TaxCode
,	dbo.mfnGetBnOTaxReportingCode(@TaxGroup,@TaxCode) as ReportingCode

set @TaxCode = 'WA1130'
select 
	@TaxGroup as TaxGroup
,	@TaxCode as TaxCode
,	dbo.mfnGetBnOTaxReportingCode(@TaxGroup,@TaxCode) as ReportingCode

set @TaxCode = 'WA0018'
select 
	@TaxGroup as TaxGroup
,	@TaxCode as TaxCode
,	dbo.mfnGetBnOTaxReportingCode(@TaxGroup,@TaxCode) as ReportingCode
*/