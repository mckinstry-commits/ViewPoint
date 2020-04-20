SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/********************************************************/
CREATE procedure [dbo].[vspPMGetDistributionContacts]
/************************************************************************
* Created By:	SCOTTP  04/25/13 TFS-42264
* Modified By:	SCOTTP  04/29/13 TFS-42264
*							Add DistributionTable and DistributionTableKeyID columns
*							to return table set
*				SCOTTP	07/09/13 TFS-55224
*							Change vspPMGetDistributionContacts.sql to use Preferred Method of Send
*							from the Distribution table instead of from PMPM
*				SCOTTP	07/09/13 TFS-55224
*							Move code into loop that sets @sendflagclause so that @distTable has been set
*				AJW     07/16/13 TFS 55878 filter on PMCo Project
*
* Returns all PMPM vContacts within Distribution Table
* for a given document catagory and source record
*
*************************************************************************/
(@doccategory varchar(10), @sourcekeyid bigint, @pmco bCompany, @project bProject, @sendflag varchar(1)=null, @errmsg varchar(256)=NULL output)
AS
SET NOCOUNT ON

declare @rcode tinyint
select @rcode = 0

declare @opencursor tinyint
set @opencursor = 0
  
if (dbo.vfToString(@doccategory) = '') 
begin
  select @errmsg = 'No Document Category Supplied', @rcode = 1
  goto vspexit
end

if (dbo.vfToString(@sourcekeyid) = '')
begin
  select @errmsg = 'No Source Table Key ID Supplied'
  goto vspexit
end

if (dbo.vfToString(@pmco) = '')
begin
  select @errmsg = 'No company supplied'
  goto vspexit
end

if (dbo.vfToString(@project) = '')
begin
  select @errmsg = 'No project supplied'
  goto vspexit
end

declare @vendorGroup tinyint, @sentToFirm int, @sentToContact int,
@distTable varchar(MAX), @distKeyID bigint

declare @selectclause varchar(MAX), @fromclause varchar(MAX), @contactjoinclause varchar(MAX),
@firmjoinclause varchar(MAX), @whereclause varchar(MAX), @sendflagclause varchar(MAX), @contactquery varchar(MAX)

declare @ContactTable TABLE(
  [FirmName] VARCHAR(MAX),
  [ContactName] VARCHAR(MAX),
  [SortName] VARCHAR(MAX),
  [Email]  VARCHAR(MAX),
  [Phone] VARCHAR(MAX),
  [Fax] VARCHAR(MAX),
  [Mobile] VARCHAR(MAX),
  [PreferredMethod] VARCHAR(MAX),
  [Title] VARCHAR(MAX),
  [Send] VARCHAR(MAX),
  [SendType] VARCHAR(MAX),
  [VendorGroup] TINYINT,
  [FirmNumber] INT,
  [ContactCode] INT,  
  [DistributionTable] VARCHAR(MAX),
  [DistributionTableKeyID] BIGINT,  
  [SourceTable] VARCHAR(MAX),
  [KeyID] BIGINT)
    
-- declare cursor
declare bcPMDocDist cursor LOCAL FAST_FORWARD
for select VendorGroup, SentToFirm, SentToContact, DistributionTable, DistributionKeyID
from PMDocDistribution
where DocCat = @doccategory and DocKeyID = @sourcekeyid and PMCo = @pmco and Project = @project

---- open cursor
open bcPMDocDist
set @opencursor = 1

PMDocDist_Loop:

fetch next from bcPMDocDist into @vendorGroup, @sentToFirm, @sentToContact, @distTable, @distKeyID

IF @@fetch_status <> 0 goto PMDocDist_end
IF @@FETCH_STATUS = -1 goto PMDocDist_end

if @sendflag is not null
begin
	select @sendflagclause = ' and ' + @distTable + '.[Send]= ''' + @sendflag + ''''
end
else
begin
	select @sendflagclause = ''
end

select @selectclause =
'SELECT PMFM.FirmName as [FirmName], ISNULL(PMPM.FirstName,'''') + '' '' + ISNULL(PMPM.MiddleInit,'''') + '' '' + ISNULL(PMPM.LastName,'''') as ContactName,
PMPM.SortName as [SortName], PMPM.EMail as [Email], PMPM.Phone + CASE WHEN PMPM.PhoneExt IS NOT NULL THEN '' ext. '' + PMPM.PhoneExt ELSE '''' END as [Phone],
PMPM.Fax as [Fax], PMPM.MobilePhone as [Mobile], ' + @distTable + '.PrefMethod as [PreferredMethod], PMPM.Title,
[Send] as [Send], CC as [SendType],
PMPM.VendorGroup as [VendorGroup], PMPM.FirmNumber as [FirmNumber], PMPM.ContactCode as [ContactCode],
''' + @distTable + ''' as [DistributionTable], ' + dbo.vfToString(@distKeyID) + ' as [DistributionTableKeyID],
''PMPM'' as [SourceTable], PMPM.KeyID as [KeyID]',
@fromclause = 'FROM ' + @distTable,
@contactjoinclause = 'join PMPM on PMPM.VendorGroup='+dbo.vfToString(@vendorGroup)+' and PMPM.FirmNumber='+dbo.vfToString(@sentToFirm)+' and PMPM.ContactCode='+dbo.vfToString(@sentToContact),
@firmjoinclause = 'join PMFM on PMFM.VendorGroup=PMPM.VendorGroup and PMFM.FirmNumber=PMPM.FirmNumber',
@whereclause = 'WHERE ' + @distTable + '.KeyID = ' + dbo.vfToString(@distKeyID) + @sendflagclause

select @contactquery =
	@selectclause+char(13)+
	@fromclause+char(13)+
	@contactjoinclause+char(13)+
	@firmjoinclause+char(13)+
	@whereclause+char(13)

begin try
	print @contactquery
	
	insert @ContactTable
		([FirmName],[ContactName],[SortName],[Email],[Phone],[Fax],[Mobile],[PreferredMethod],
		[Title],[Send],[SendType],[VendorGroup],[FirmNumber],[ContactCode],
		[DistributionTable],[DistributionTableKeyID],[SourceTable],[KeyID])
	exec (@contactquery)
end try
begin catch
	select @errmsg = 'Invalid Contact Query Generated for Document Category '+dbo.vfToString(@doccategory), @rcode = 2
	goto PMDocDist_end
end catch

goto PMDocDist_Loop

PMDocDist_end:
	
if @opencursor <> 0
begin
	close bcPMDocDist
	deallocate bcPMDocDist
	select @opencursor = 0
end

select * from @ContactTable

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMGetDistributionContacts] TO [public]
GO
