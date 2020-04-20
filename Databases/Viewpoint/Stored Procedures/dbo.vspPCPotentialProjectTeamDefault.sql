SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPCPotentialProjectTeamDefault]
/***********************************************************
* CREATED BY:	GP 01/10/2010
* MODIFIED BY:
*				
* USAGE:
* Used in PC Potential Project Team to default contact info
*
* INPUT PARAMETERS
* JCCo   
* ContactSource
* VendorGroup
* CustomerGroup
* Firm/Vendor
* Contact 
*
* OUTPUT PARAMETERS
*
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@JCCo bCompany = null, @Source varchar(20) = null, @VendorGroup bGroup = null, @CustomerGroup bGroup = null, 
	@Firm bFirm = null, @Contact bEmployee = null, 
	@Name varchar(70) = null output, @Phone bPhone = null output, 
	@Mobile bPhone = null output, @Fax bPhone = null output, @Email varchar(60) = null output, 
	@WebAddress varchar(60) = null output, @FirmName varchar(60) = null output, @msg varchar(255) output)
as
set nocount on
  
declare @rcode int, @InfoNotFoundMsg varchar(30)
select @rcode = 0, @Name = '', @InfoNotFoundMsg = 'Contact info not found.'


--VALIDATION--
if @JCCo is null
begin
	select @msg = 'JCCo is missing.', @rcode = 1
	goto vspexit
end

if @Source is null
begin
	select @msg = 'Contact Source is missing.', @rcode = 1
	goto vspexit
end


--GET CONTACT INFO--
if @Source = 'APVM'
begin
	select @Name = Contact, @Phone = Phone, @Fax = Fax, @Email = EMail, @WebAddress = URL 
	from dbo.APVM with (nolock) 
	where VendorGroup=@VendorGroup and Vendor=@Contact
	if @@rowcount = 0
	begin
		select @Name = 'AP Vendor not on file.', @msg = 'AP Vendor not on file.', @rcode = 1
		goto vspexit
	end
	
	if @Name is null
	begin
		set @Name = @InfoNotFoundMsg
		goto vspexit
	end		
end

if @Source = 'ARCM'
begin
	select @Name = Contact, @Phone = Phone, @Fax = Fax, @Email = EMail, @WebAddress = URL 
	from dbo.ARCM with (nolock) 
	where CustGroup=@CustomerGroup and Customer=@Contact
	if @@rowcount = 0
	begin
		select @Name = 'AR Customer not on file.', @msg = 'AR Customer not on file.', @rcode = 1
		goto vspexit
	end
	
	if @Name is null
	begin
		set @Name = @InfoNotFoundMsg
		goto vspexit
	end	
end

if @Source = 'PMPM'
begin
	--firm validation
	exec @rcode = bspPMFirmVal @VendorGroup, @Firm, @Firm output, null, @msg output
	if @rcode = 1
	begin
		select @msg = 'PM Firm not on file.'
		goto vspexit
	end
	else
	begin
		set @FirmName = @msg
	end

	select @Name = isnull(CourtesyTitle,'') + ' ' + FirstName + ' ' + LastName,
		@Phone = Phone, @Mobile = MobilePhone, @Fax = Fax, @Email = EMail 
	from dbo.PMPM with (nolock) 
	where VendorGroup=@VendorGroup and FirmNumber=@Firm and ContactCode=@Contact
	if @@rowcount = 0
	begin
		select @Name = 'PM Firm Contact not on file.'--, @msg = 'PM Firm Contact not on file.', @rcode = 1
		goto vspexit
	end
	
	if @Name is null
	begin
		set @Name = @InfoNotFoundMsg
		goto vspexit
	end	
end

if @Source = 'PREH'
begin
	select @Name = FirstName + ' ' + LastName, @Phone = Phone, @Email = Email
	from dbo.PREH with (nolock)
	where PRCo=@JCCo and Employee=@Contact
	if @@rowcount = 0
	begin
		select @Name = 'PR Employee not on file.', @msg = 'PR Employee not on file.', @rcode = 1
		goto vspexit
	end
	
	if @Name is null
	begin
		set @Name = @InfoNotFoundMsg
		goto vspexit
	end
end

if @Source = 'JCMP'
begin
	select @Name = Name, @Phone = Phone, @Mobile = MobilePhone, @Fax = FAX, @Email = Email, @WebAddress = Internet 
	from dbo.JCMP with (nolock) 
	where JCCo=@JCCo and ProjectMgr=@Contact
	if @@rowcount = 0
	begin
		select @Name = 'Project Manager not on file.', @msg = 'JC Project Manager not on file.', @rcode = 1
		goto vspexit
	end	
	
	if @Name is null
	begin
		set @Name = @InfoNotFoundMsg
		goto vspexit
	end
end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectTeamDefault] TO [public]
GO
