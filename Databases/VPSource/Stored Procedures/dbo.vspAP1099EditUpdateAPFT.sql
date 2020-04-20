SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAP1099EditUpdateAPFT]
   /***********************************************************
    * CREATED BY: MV 11/16/05
    * MODIFIED By :	MV 10/14/08 - #130189 update bAPTH with statment instead of EXEC 
    *
    * USAGE:
	* Backs out the amount paid in year from APFT for the specified
	*	 apco/vendorgroup/vendor/YEMO/1099type/box.
    * Adds an APFT entry for the specified apco/vendorgroup/vendor/YEMO/1099type
    * 	if one does not already exist.
	* Updates APFT with the amount paid in year for the specified
	*	 apco/vendorgroup/vendor/YEMO/1099type/box.
	* 
    * An error is returned if entry cannot be added.
    *
    *  INPUT PARAMETERS
    *   @apco		AP Company
    *   @vendgrp	Vendor group asssociated with vendor
    *   @vendor		Vendor number
    *   @yemo		Year ending month
    *	@amtpiy		Amt Paid in Year
	*	@old1099type Old 1099 type
	*	@old1099box	 Old box column name
    *   @new1099type new 1099 form type
	*	@new1099box  New box column name
	*	@backoutapft Flag to back out AmtPIY 
	*	@updateapft	 Flag to add AmtPIY
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@apco bCompany,@aptrans bTrans,@expmth bMonth, @vendorgroup bGroup, @vendor bVendor, @yemo bDate,
	@amtpiy bDollar,@old1099type varchar(10),@old1099box varchar(8),@new1099type varchar(10),
	@new1099box varchar(8),@backoutapft bYN, @updateapft bYN,@msg varchar(60) output)
   as
   set nocount on
  
   declare @rcode int, @box1amt bDollar, @box2amt bDollar, @box3amt bDollar, @box4amt bDollar,
   	@box5amt bDollar, @box6amt bDollar, @box7amt bDollar, @box8amt bDollar,
   	@box9amt bDollar, @box10amt bDollar, @box11amt bDollar, @box12amt bDollar,
   	@box13amt bDollar, @box14amt bDollar, @box15amt bDollar, @box16amt bDollar,
   	@box17amt bDollar, @box18amt bDollar, @updatestring varchar(500), @Box# varchar(2)
  
   select @rcode=0
   select @box1amt=0, @box2amt=0, @box3amt=0, @box4amt=0, @box5amt=0, @box6amt=0, @box7amt=0,
   	@box8amt=0, @box9amt=0, @box10amt=0, @box11amt=0, @box12amt=0, @box13amt=0,
      @box14amt=0, @box15amt=0, @box16amt=0, @box17amt=0, @box18amt=0
  
	BEGIN TRANSACTION
	-- reduce APFT by AmtPIY - Amount Paid in Year
	if @backoutapft = 'Y' 
	begin
		select @updatestring = null
		select @updatestring = 'update APFT set ' + @old1099box + ' = ' + @old1099box + ' - ' + convert(varchar(16),@amtpiy) +
				' from APFT where APCo= ' + convert(varchar(3),@apco) + ' AND VendorGroup= ' + convert(varchar(3),@vendorgroup) + 
				' AND Vendor = ' + convert(varchar(6),@vendor) + ' AND YEMO = ''' + convert(varchar(8),@yemo,1) +
				''' AND V1099Type = ''' + @old1099type + ''''
		EXEC (@updatestring)
		if @@rowcount=0
		begin
	   		select @msg = 'Error removing AmtPIY from APFT!' , @rcode=1
			goto bspexit
	   	end
		--update 1099 info in APTH
		if @updateapft = 'N'
		begin
			update bAPTH set V1099YN = 'N', V1099Type= null, V1099Box = null 
			Where APCo=@apco and APTrans=@aptrans and Mth=@expmth
			if @@rowcount=0
			begin
		   		select @msg = 'Error updating 1099 fields in APTH!' , @rcode=1
				goto bspexit
		   	end
		end
	end
	-- if update = yes check for existance of apft rec, create if needed
	if @updateapft = 'Y'
	begin
	   if not exists (select * from bAPFT where APCo=@apco and VendorGroup=@vendorgroup
	   		and Vendor=@vendor and YEMO=@yemo and V1099Type=@new1099type)
	   	begin
		   	insert into bAPFT (APCo, VendorGroup, Vendor, YEMO, V1099Type, Box1Amt, Box2Amt, Box3Amt,
		              Box4Amt, Box5Amt, Box6Amt, Box7Amt, Box8Amt, Box9Amt, Box10Amt, Box11Amt,
		              Box12Amt, Box13Amt, Box14Amt, Box15Amt, Box16Amt,
		              Box17Amt, Box18Amt, AuditYN)
		   	values(@apco, @vendorgroup, @vendor, @yemo, @new1099type, @box1amt, @box2amt, @box3amt,
		              @box4amt, @box5amt, @box6amt, @box7amt, @box8amt, @box9amt, @box10amt, @box11amt,
		              @box12amt, @box13amt, @box14amt, @box15amt, @box16amt,
		              @box17amt, @box18amt, 'N')
		   	if @@rowcount=0
			begin
		   		select @msg = 'Error adding new entry to APFT!' , @rcode=1
				goto bspexit
		   	end
		end
   		-- update apft with amtpiy
		select @updatestring = null
		select @updatestring = 'update APFT set ' + @new1099box + ' = ' + @new1099box + ' + ' + convert(varchar(16),@amtpiy) +
				' from APFT where APCo= ' + convert(varchar(3),@apco) + ' AND VendorGroup= ' + convert(varchar(3),@vendorgroup) + 
				' AND Vendor = ' + convert(varchar(6),@vendor) + ' AND YEMO = ''' + convert(varchar(8),@yemo,1) +
				''' AND V1099Type = ''' + @new1099type + ''''
		EXEC (@updatestring)
		if @@rowcount=0
		begin
	   		select @msg = 'Error updating AmtPIY to APFT!' , @rcode=1
			goto bspexit
	   	end
		-- update APTH
		select @Box# = Substring(@new1099box,4,len(@new1099box) - 6)
		Update bAPTH set V1099YN='Y', V1099Type=@new1099type, V1099Box=convert(tinyint,@Box#)
		Where APCo=@apco and APTrans=@aptrans and Mth=@expmth
		if @@rowcount=0
		begin
	   		select @msg = 'Error updating 1099 fields in APTH!' , @rcode=1
			goto bspexit
	   	end
	end
	COMMIT TRANSACTION
   bspexit:
  	if @rcode = 1
		begin
		ROLLBACK TRANSACTION
		end
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAP1099EditUpdateAPFT] TO [public]
GO
