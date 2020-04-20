SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspAPICRptGetInfo]
/*************************************
* CREATED BY    : MAV  01/25/05 for 6X recode
* LAST MODIFIED : 
*
* Gets ICReport info from APCO and APFT
*	This is a combination of bspAPICRptGetAPCOInfo and
*	bspAPGetICDate
*
* Pass:
*	APCompany
*
* Returns:
*	APCO.ICRptYN, APCO.ICRptTitle, APFT.ICRptDate to
*	DDFH LoadProc for frmAPICRpt
*
* Success returns:
*   0
*
* Error returns:
*	1 
**************************************/
(@APCo bCompany, @ICRptYN varchar(1) output, @ICRptId int output,@ICRptDate varchar(11) output,
	 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @year as varchar (4), @ICRptName as varchar (40)

select @rcode = 0

-- Get APCO info
select @ICRptYN = ICRptYN, @ICRptName = ICRptTitle
FROM APCO
WHERE APCo = @APCo
if @@rowcount = 0
begin
	select @msg = 'Company# ' + convert(varchar,@APCo) + ' not setup in AP', @rcode = 1
	goto vspexit
end

--Get Report ID
if @ICRptName is not null
begin 
select @ICRptId=ReportID from RPRT where Title=rtrim(@ICRptName)
end

-- Get latest IC report date from vAPFT
SELECT @year = DATEPART(yy, GETDATE()) 

select @ICRptDate = max(ICRptDate)
FROM APFT with (nolock)
WHERE APCo = @APCo and datepart(yy,YEMO) = @year
if @@rowcount = 0 or @ICRptDate is null
begin
	SELECT @year = DATEPART(yy, GETDATE())-1 
	select @ICRptDate = max(ICRptDate)
	FROM APFT with (nolock)
	WHERE APCo = @APCo and datepart(yy,YEMO) = @year
end

if @ICRptDate is null select @ICRptDate = ''

vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPICRptGetInfo] TO [public]
GO
