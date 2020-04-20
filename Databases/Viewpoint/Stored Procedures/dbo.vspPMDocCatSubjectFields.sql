SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE proc [dbo].[vspPMDocCatSubjectFields]
/****************************************************************************
* Created By:	CHS 07/29/2009
* Modified By:	GF 10/18/2010 - TFS #793
*				GF 03/18/2011 - TK-02604
*				GF 03/28/2011 - TK-03289
*				GF 04/06/2011 - TK-03643
*				JG 05/03/2011 - TK-04388	CCO
*
* USAGE:
* Returns a resultset 
*
* INPUT PARAMETERS:
* PM Company, Document Category
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@pmco bCompany = null, @doccategory varchar(10) = null)
as
set nocount on

declare @rcode int
declare @columnslist table(ColumnNames varchar(60))

select @rcode = 0

--insert into @columnslist (ColumnNames)

--select 'JCJM.' + COLUMN_NAME
--from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'JCJM'
--and COLUMN_NAME not in ('JCCo', 'Notes', 'UniqueAttchID', 'KeyID')
--and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1


if isnull(@doccategory, '') = 'ACO'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMOH.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMOH'
		and COLUMN_NAME not in ('PMCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'DAILYLOG'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMDL.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMDL'
		and COLUMN_NAME not in ('PMCo', 'Notes', 'UniqueAttchID', 'UpdateAP', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'DRAWING'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMDG.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMDG'
		and COLUMN_NAME not in ('PMCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'INSPECT'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMIL.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMIL'
		and COLUMN_NAME not in ('PMCo', 'Notes', 'UniqueAttchID','KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'MTG'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMMM.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMMM'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'OTHER'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMOD.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMOD'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'UpdateAP', 'KeyID', 'ExcludeYN')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end	

if isnull(@doccategory, '') = 'PCO'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMOP.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMOP'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'PUNCH'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMPU.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMPU'
		and COLUMN_NAME not in ('PMCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'PURCHASE'
	begin
		insert into @columnslist (ColumnNames)
		select 'POHD.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'POHD'
		and COLUMN_NAME not in ('POCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'RFI'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMRI.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMRI'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'RFQ'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMRQ.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMRQ'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'SUB' or isnull(@doccategory, '') = 'SUBITEM'
	begin
		insert into @columnslist (ColumnNames)
		select 'SLHD.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'SLHD'
		and COLUMN_NAME not in ('SLCo', 'VendorGroup', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'SUBMIT'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMSM.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMSM'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'TEST'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMTL.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMTL'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID', 'ExcludeYN')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'TRANSMIT'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMTM.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMTM'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

if isnull(@doccategory, '') = 'JCJM'
	begin 
		insert into @columnslist (ColumnNames)
		select 'JCJM.' + COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'JCJM'
		and COLUMN_NAME not in ('JCCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end 

if isnull(@doccategory, '') = 'JCCM'
	begin 
		insert into @columnslist (ColumnNames)
		select 'JCCM.' + COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'JCCM'
		and COLUMN_NAME not in ('JCCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end 

if isnull(@doccategory, '') = 'PMFM'
	begin 
		insert into @columnslist (ColumnNames)
		select 'PMFM.' + COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMFM'
		and COLUMN_NAME not in ('JCCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end 

if isnull(@doccategory, '') = 'PMPM'
	begin 
		insert into @columnslist (ColumnNames)
		select 'PMPM.' + COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMPM'
		and COLUMN_NAME not in ('JCCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end 

if isnull(@doccategory, '') = 'PMSC'
	begin 
		insert into @columnslist (ColumnNames)
		select 'PMSC.' + COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMSC'
		and COLUMN_NAME not in ('JCCo', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end 

----TFS #793
if isnull(@doccategory, '') = 'ISSUE'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMIM.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMIM'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID', 'MasterIssue')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

----Tk-02604
if isnull(@doccategory, '') = 'SUBCO'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMSubcontractCO.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMSubcontractCO'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end

----Tk-03289
if isnull(@doccategory, '') = 'COR'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMChangeOrderRequest.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMChangeOrderRequest'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	END
	
----Tk-03643
if isnull(@doccategory, '') = 'PURCHASECO'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMPOCO.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMPOCO'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	end 
----TK-04388	
if isnull(@doccategory, '') = 'CCO'
	begin
		insert into @columnslist (ColumnNames)
		select 'PMContractChangeOrder.' + COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'PMContractChangeOrder'
		and COLUMN_NAME not in ('PMCo', 'VendorGroup', 'Notes', 'UniqueAttchID', 'KeyID')
		and isnull(DOMAIN_NAME,'') <> 'bNotes' and isnull(CHARACTER_MAXIMUM_LENGTH,0) <> -1
	END	

select * from @columnslist
order by ColumnNames

bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDocCatSubjectFields] TO [public]
GO
