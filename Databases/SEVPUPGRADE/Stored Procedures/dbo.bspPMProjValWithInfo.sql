SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE   proc [dbo].[bspPMProjValWithInfo]
   /***********************************************************
    * Created By:  JE 11/10/1996
    * Modified By: GF 08/11/2000
    *              GF 10/12/2001 - Changed logic where information comes from for PMProjMgr. Issue #14850
    *				GF 08/04/2003 - issue #21541 - added add'l address line as output param.
    *
    * USAGE:
    * validates JC Job
    * and returns contract and Contract Description
    * an error is returned if any of the following occurs
    * no job passed, no job found in JCJM, no contract found in JCCM
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against
    *   Job    Job to validate
    *
    * OUTPUT PARAMETERS
    *   a whole bunch of them - see the command statement
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@jcco bCompany = 0, @project bJob = null, @contractdesc varchar(42) output,
    @status varchar(20) output, @ownername varchar(30) output,
    @ownercontact varchar(30) output, @ownerphone bPhone output, @ownerfax bPhone output,
    @archname varchar(60) output,@archcontact varchar(30) output,
    @archphone bPhone output, @archfax bPhone output, @address varchar (60) output,
    @city varchar(30) output, @state varchar(4) output, @zip bZip output,
    @address2 varchar(60) output, @jobstatus tinyint output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @archengfirm bVendor, @contactcode bEmployee,
           @firstname varchar(30), @lastname varchar(30), @phone bPhone, @fax bPhone
   
   select @rcode = 0, @contractdesc='', @status='', @ownername='', @ownercontact='',
          @ownerphone='', @ownerfax='', @archname='',@archcontact='', @archphone='', @archfax=''
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @project is null
   	begin
   	select @msg = 'Missing Job!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = j.Description, @contractdesc= j.Contract + ' ' + isnull(c.Description,''),
          @status= case j.JobStatus
   		        when 0 then 'Pending Project'
                   when 1 then 'Open'
                   when 2 then 'Soft Close'
                   when 3 then 'Final Close' end,
          @ownername=a.Name, @ownercontact=a.Contact, @ownerphone=a.Phone, @ownerfax=a.Fax,
   	   @archname=PMFM.FirmName, @archcontact=PMFM.ContactName,
          @archphone=PMFM.Phone, @archfax=PMFM.Fax,
   	   @address = j.ShipAddress, @city = j.ShipCity,
   	   @state = j.ShipState, @zip = j.ShipZip, @address2 = j.ShipAddress2, @jobstatus = j.JobStatus
   from JCJM j with (nolock) left join JCCM c with (nolock) on j.JCCo = c.JCCo and j.Contract=c.Contract
   left join ARCM a with (nolock) on a.CustGroup=c.CustGroup and a.Customer=c.Customer
   left join PMFM PMFM with (nolock) on PMFM.VendorGroup=j.VendorGroup and PMFM.FirmNumber=j.ArchEngFirm
   where j.JCCo = @jcco and j.Job = @project
   if @@rowcount = 0
   	begin
   	select @msg = 'Job not on file, or no associated contract!', @rcode = 1
   	goto bspexit
   	end
   
   -- check for ArchEng contact information
   select @vendorgroup=VendorGroup, @archengfirm=ArchEngFirm, @contactcode=ContactCode
   from JCJM with (nolock) where JCCo=@jcco and Job=@project
   if @@rowcount = 0 goto bspexit
   -- exit if no archeng firm
   if isnull(@archengfirm,'') = '' goto bspexit
   
   -- if no ArchEng contact for project, get minimum from PMPF
   if isnull(@contactcode,'') = ''
       begin
       select @contactcode = min(ContactCode)
       from PMPF with (nolock) where PMCo=@jcco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@archengfirm
       if @@rowcount = 0 goto bspexit
       end
   
   -- get ArchEng contact info from Firm contacts
   select @firstname=FirstName, @lastname=LastName, @phone=Phone, @fax=Fax
   from PMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@archengfirm and ContactCode=@contactcode
   if @@rowcount = 1
       begin
       select @archcontact = isnull(@firstname,'') + ' ' + isnull(@lastname,''), @archphone=@phone, @archfax=@fax
       end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjValWithInfo] TO [public]
GO
