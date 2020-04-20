SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/********************************************************/
CREATE procedure [dbo].[vspPMGetDocCatContacts]
/************************************************************************
* Created By:	AJW / GPT 11/27/12
* Modified By:	
*
* Returns PMPM contacts for given document catagory and source record
*
*************************************************************************/
(@templatetype varchar(10), @sourcetable varchar(30), @keyid bigint,@errmsg varchar(256)=NULL output)
AS
SET NOCOUNT ON

declare @distributiontable varchar(max),@distributionalias varchar(max),@sourcejoin varchar(max), @sourcealias varchar(max),
@selectclause varchar(max),@fromclause varchar(max),@whereclause varchar(max),@sourcejoinclause varchar(max),
@contactjoinclause varchar(max),@firmjoinclause varchar(max),@contactquery varchar(max)

IF (dbo.vfToString(@templatetype) = '') 
BEGIN
  set @errmsg = 'No Template Type Supplied'
  Return 1
END

IF (dbo.vfToString(@sourcetable) = '')
BEGIN
  set @errmsg = 'No Source Table Supplied'
  Return 1
END

IF (dbo.vfToString(@keyid) = '')
BEGIN
  set @errmsg = 'No Key ID Supplied'
  Return 1
END


select @distributiontable =  case 
	when @templatetype = 'RFI' then 'PMRD'
	when @templatetype = 'PCO' then 'PMCD'
	when @templatetype = 'RFQ' then 'PMQD'
	when @templatetype in ('SUB','SUBITEM') then 'PMSS'
	when @templatetype = 'OTHER' then 'PMOC'
	when  @templatetype = 'TRANSMIT' then 'PMTC'
	else 'PMDistribution' end

select @sourcealias=Alias,@sourcejoin=JoinClause
	from HQWO
	where TemplateType = @templatetype and ObjectTable = @sourcetable

select @distributionalias=Alias
	from HQWO
	where TemplateType = @templatetype and ObjectTable = @distributiontable

if (dbo.vfToString(@distributionalias) = '' or
    dbo.vfToString(@sourcealias) = '' or
	 dbo.vfToString(@sourcejoin) = '')
BEGIN
-- Assuming no distribution table required
return 0
END


select @selectclause = 'select ''PMPM'' as [Table],PMPM.KeyID,PMFM.FirmName as FirmName,ISNULL(PMPM.FirstName,'''') + '' '' + ISNULL(PMPM.MiddleInit,'''') + '' '' + ISNULL(PMPM.LastName,'''') AS ContactName',
@fromclause = 'from ' + @distributiontable + ' ' + @distributionalias,
@sourcejoinclause = 'join ' + @sourcetable + ' ' + @sourcealias + ' on ' + @sourcejoin,
@contactjoinclause = 'join PMPM on PMPM.VendorGroup='+@distributionalias+'.VendorGroup and PMPM.FirmNumber='+@distributionalias+'.SentToFirm and PMPM.ContactCode='+@distributionalias+'.SentToContact',
@firmjoinclause = 'join PMFM on PMFM.VendorGroup=PMPM.VendorGroup and PMFM.FirmNumber=PMPM.FirmNumber',
@whereclause = 'where '+@distributionalias+'.Send = ''Y'' and '+@distributionalias+'.CC = ''C'' and '+@sourcealias+'.KeyID = '+dbo.vfToString(@keyid)


select @contactquery =
	@selectclause+char(13)+
	@fromclause+char(13)+
	@sourcejoinclause+char(13)+
	@contactjoinclause+char(13)+
	@firmjoinclause+char(13)+
	@whereclause+char(13)

BEGIN TRY
    print @contactquery
	exec(@contactquery)
END TRY
BEGIN CATCH
	set @errmsg = 'Invalid Contact Query Generated for TemplateType '+dbo.vfToString(@templatetype)
	return 1
END CATCH
GO
GRANT EXECUTE ON  [dbo].[vspPMGetDocCatContacts] TO [public]
GO
