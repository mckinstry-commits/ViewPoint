SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************/
CREATE procedure [dbo].[vspPMCopyProjectFirms]
/************************************************************************
 * Created By:	GF 06/07/2005
 * Modified By:
 *
 *
 * Purpose of Stored Procedure
 * Copy a set of Firms from one Project to another.
 * Called from PMProjectFirmsCopy form
 *
 *
 *
 * Notes about Stored Procedure
 *
 *
 * returns 0 if successfull
 * returns 1 and error msg if failed
 *
 *************************************************************************/
(@pmco bCompany, @srcproject bProject, @destproject bProject, @vendorgroup bGroup, 
 @firmcontactlist varchar(4000), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @char char(1), @firm int, @contact int, @desc bDesc, 
		@complete int, @seq int, @firmcontactlistsemipos int,  @commapos int, 
		@semipos int, @retstring varchar(8000), @retstringlist varchar(8000),
		@firmstring varchar(20), @contactstring varchar(20), @firmcount int

select @rcode = 0, @msg = '', @firmcount = 0

if @pmco is null
	begin
	select @msg = 'Missing Company', @rcode = 1
	goto bspexit
	end

if @srcproject is null
	begin
	select @msg = 'Missing source project', @rcode = 1
	goto bspexit
	end

if @destproject is null
	begin
	select @msg = 'Missing destination project', @rcode = 1
	goto bspexit
	end

if @vendorgroup is null
	begin
	select @msg = 'Missing vendor group', @rcode = 1
	goto bspexit
	end
  

-- -- -- if firm contact list is empty then nothing to copy
if isnull(@firmcontactlist,'') = ''
	select @complete = 1
else
	select @complete = 0



-- -- -- parse firm contact list and insert into destination project
while @complete = 0
BEGIN

	-- -- -- get firm and contact
	select @char = ';'
	exec dbo.bspParseString @firmcontactlist, @char, @semipos output, @retstring output, @retstringlist output, @msg output
	select @retstring, @retstringlist
	-- -- -- separate firm and contact from @retstring
	select @char = ','
	exec dbo.bspParseString @retstring, @char, @commapos output, @firmstring output, @contactstring output, @msg output
	select @firmstring, @contactstring

	select @firmcontactlist = @retstringlist
	select @firmcontactlistsemipos = @semipos

	-- -- -- @firmstring should have firm and @contactstring should have contact
	-- -- -- both should be numeric, if not throw error
	if isnumeric(@firmstring) = 1
		select @firm = convert(int, @firmstring)
	else
		begin
		select @msg = 'Error getting information for Firm ' + isnull(@firmstring,'') + '.', @rcode = 1
		goto bspexit
		end

	if isnumeric(@contactstring) = 1
		select @contact = convert(int, @contactstring)
	else
		begin
		select @msg = 'Error getting information for Contact ' + isnull(@contactstring,'') + '.', @rcode = 1
		goto bspexit
		end

	-- -- -- get existing description for this firm and contact from source project
	select @desc = (select Description from PMPF with (nolock) where PMCo = @pmco and Project = @srcproject 
					and VendorGroup = @vendorgroup and FirmNumber = @firm and ContactCode = @contact)
	
	-- -- -- verify firm/contact combination does not already exist in destination project
	if not exists(select top 1 1 from PMPF with (nolock) where PMCo=@pmco and Project=@destproject
				and VendorGroup=@vendorgroup and FirmNumber=@firm and ContactCode=@contact)
		begin
		-- -- -- get next sequence number
	    select @seq=max(Seq) + 1
	    from PMPF where PMCo=@pmco and Project=@destproject
		if isnull(@seq,0) = 0 set @seq = 1

		insert into PMPF (PMCo, Project, Seq, VendorGroup, FirmNumber, ContactCode, Description)
		select @pmco, @destproject, @seq, @vendorgroup, @firm, @contact, @desc

		select @firmcount = @firmcount + 1
		end



	if @firmcontactlistsemipos = 0 select @complete = 1
	IF isnull(@firmcontactlist,'') = '' select @complete = 1
	select @firmcontactlist, @firmcontactlistsemipos

END






bspexit:
	if @rcode = 0 
		select @msg = 'Project Firms and Contacts copied: ' + convert(varchar(8),@firmcount) + '.'
	else
		select @msg = isnull(@msg,'')

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCopyProjectFirms] TO [public]
GO
