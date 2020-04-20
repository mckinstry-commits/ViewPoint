SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPMCopyProjectFirms]
   /************************************************************************
   * CREATED By:	MH 2/18/00
   * MODIFIED By:	GF 10/24/2001
   *				GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
   *
   * Purpose of Stored Procedure
   *    Copy a set of Firms from one Project to another.
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
   (@co bCompany, @sourceproject bProject, @destproject bProject, @vendor bVendor, @firmlist varchar(200),
    @contactlist varchar(200), @msg varchar(250) = '' output)
   as
   set nocount on
   
   declare @rcode int, @char char(1), @firm int, @contact int, @desc bDesc, @complete int, @seq int,
           @firmlistcommapos int,  @commapos int, @retstring varchar(8000), @retstringlist varchar(8000)
   
   if @co is null
       begin
       select @msg = 'Missing Company', @rcode = 1
       goto bspexit
       end
   
   if @sourceproject is null
       begin
       select @msg = 'Missing source project', @rcode = 1
       goto bspexit
       end
   
   if @destproject is null
       begin
       select @msg = 'Missing destination project', @rcode = 1
       goto bspexit
       end
   
   if @vendor is null
       begin
       select @msg = 'Missing vendor group', @rcode = 1
       goto bspexit
       end
   
   select @rcode = 0
   
   if @firmlist is null
       select @complete = 1
   else
       select @complete = 0
   
   while @complete = 0
   begin
   
       --get firm number
   
       select @char = ','
   
       exec dbo.bspParseString @firmlist, @char, @commapos output, @retstring output, @retstringlist output, @msg output
   
       --quest...what if firm is non-numeric such as a failure of bspParseString?  bFirm and bEmployee are numeric so
       --the only problems should be if ParseString fails and returns the comma....something like 100,
   
       if isnumeric(@retstring) = 1
           select @firm = convert(int, @retstring)
       else
           begin
               select @msg = 'Error getting information for Firm ' + isnull(@retstring,'') + '.', @rcode = 1
               goto bspexit
           end
   
           select @firmlist = @retstringlist
           select @firmlistcommapos = @commapos
   
       --get contact number
   
       select @char = ','
   
       exec dbo.bspParseString @contactlist, @char, @commapos output, @retstring output, @retstringlist output, @msg output
   
       if isnumeric(@retstring) = 1
           select @contact = convert(int, @retstring)
       else
           begin
               select @msg = 'Error getting information for Firm ' + convert(varchar(5),isnull(@firm,'')) + ' '
               select @msg = @msg + 'and Contact ' + isnull(@retstring,'') + '.', @rcode = 1
               goto bspexit
           end
   
       select @contactlist = @retstringlist
   
       --get existing description for this contact from source project
   
       select @desc = (select Description from PMPF with (nolock) where PMCo = @co and Project = @sourceproject and
                       VendorGroup = @vendor and FirmNumber = @firm and ContactCode = @contact)
   
       --insert into target project
   
       --verify firm/contact combination does not already exist in destination project
   
       select FirmNumber
       from PMPF with (nolock) 
       where PMCo = @co and Project = @destproject and VendorGroup = @vendor and
           FirmNumber = @firm and ContactCode = @contact
   
       if @@rowcount = 0
           begin
           select @seq=1
           select @seq=isnull(Max(Seq),0)+1
           from bPMPF with (nolock) where PMCo=@co and Project=@destproject
   
           insert into PMPF (PMCo, Project, Seq, VendorGroup, FirmNumber, ContactCode, Description)
           values(@co, @destproject, @seq, @vendor, @firm, @contact, @desc)
           end
   
   
       if @firmlistcommapos = 0
           select @complete = 1
   
   end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMCopyProjectFirms] TO [public]
GO
