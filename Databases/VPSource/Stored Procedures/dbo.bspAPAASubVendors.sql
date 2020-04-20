SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             proc [dbo].[bspAPAASubVendors]
   	
   /***********************************************************
    * CREATED BY: MV   11/13/02
    * MODIFIED By : ES 03/11/04 - #23061 isnull wrap
	*				MV 03/11/08 - #127347 Intl addresses
	*				MV 07/30/09 - #133073 - remove cursor 
    *
    * USAGE:
    * Adds the master vendor address to bAPAA for all subvendors.
    * An error is returned if any of the following occurs
    * no vendorgroup passed, no vendor passed, seq does not exist
    * vendor isn't a master vendor, seq is not a payment address
    *
    * INPUT PARAMETERS
    *   VendorGroup   vendorgroup associated with the vendor
    *   Vendor	    Vendor
    *	AddressSeq    sequence # for the vendor address
    *	
    * OUTPUT PARAMETERS
    *	@msg   		error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@vendorgrp bGroup, @vendor bVendor, @seq int,@msg varchar(60) output) 
   as
   set nocount on
   
   declare @rcode int, @type tinyint, @openAPAA int, @subvendor bVendor,
   	@address varchar(60), @city varchar(60), @state varchar(4), @country char(2), @zip bZip,
   	@address2 varchar(60), @desc bDesc, @newseq int, @count smallint
   
   select @rcode = 0, @count = 0
   
   if @vendorgrp is null
   	begin
   	select @msg = 'Missing Vendor Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @vendor is null
   	begin
   	select @msg = 'Missing Vendor!', @rcode = 1
   	goto bspexit
   	end
   
   if @seq is null
   	begin
   	select @msg = 'Missing Address Sequence!', @rcode = 1
   	goto bspexit
   	end
   
   select 1 from bAPVM with (nolock) where VendorGroup=@vendorgrp and MasterVendor=@vendor
   	if @@rowcount = 0
   	begin
   	select @msg = 'Vendor is not a master vendor!', @rcode = 1
   	goto bspexit
   	end
   
   select @type=Type,@desc=Description, @address=Address, @city=City, @state=State, @zip=Zip,@country=Country,
	@address2=Address2
   	 from bAPAA with (nolock) where VendorGroup=@vendorgrp and Vendor=@vendor and AddressSeq=@seq 
   	if @@rowcount = 0
   	begin
   	select @msg = 'Address Sequence does not exist!', @rcode = 1
   	goto bspexit
   	end
        if @type > 1	--if address type is purchase order
   	begin
   	select @msg = 'Address Sequence is not a payment address!', @rcode = 1
   	goto bspexit
   	end
   
--   declare bcAPAA cursor for
--      select Vendor from bAPVM with (nolock) where VendorGroup=@vendorgrp and MasterVendor= @vendor
--      	order by Vendor
--   	-- open cursor
--   	open bcAPAA
--   	select @openAPAA = 1
--   next_APAA:
--     	fetch next from bcAPAA into @subvendor	--get next subvendor
--     	if @@fetch_status <> 0 goto end_APAA
--   	--get next sequence #
--   	select @newseq=isnull(max(AddressSeq),0) from bAPAA with(nolock) where VendorGroup=@vendorgrp and Vendor=@subvendor
   	-- add master vendor address to subvendor	
--   	insert into bAPAA (VendorGroup,Vendor,AddressSeq,Type,Description,Address,City,State,Zip,Country,Address2)
--   		values (@vendorgrp,@subvendor,(@newseq + 1),@type,@desc,@address,@city,@state,@zip,@country,@address2)

	insert into bAPAA (VendorGroup,Vendor,AddressSeq,Type,Description,Address,City,State,Zip,Country,Address2)
   		Select @vendorgrp,s.Vendor,isnull(max(a.AddressSeq),0) + 1,@type,@desc,@address,@city,@state,@zip,@country,@address2
	from bAPVM s Left outer join bAPAA a on a.VendorGroup=s.VendorGroup and a.Vendor=s.Vendor
	where s.VendorGroup=@vendorgrp and s.MasterVendor=@vendor
	group by s.Vendor
	select @count = @@rowcount

--   	if @@rowcount <> 1
--    	begin
--      	select @msg = 'Unable to add address to subvendor(s)!', @rcode = 1
--      	goto bspexit
--      	end
   	
--   	goto next_APAA  -- next subvendor
--   end_APAA:   
--   	  close bcAPAA
--   	  deallocate bcAPAA
--   	  select @openAPAA = 0

   	if @rcode= 0
   		begin
   		select @msg = 'Address was added to: ' + isnull(convert(varchar(3),@count), '') + ' subvendors.' 
   		end
   
   bspexit:
   	return @rcode

--   	if @openAPAA = 1
--    		begin
--    		close bcAPAA
--     		deallocate bcAPAA
--    		end

GO
GRANT EXECUTE ON  [dbo].[bspAPAASubVendors] TO [public]
GO
