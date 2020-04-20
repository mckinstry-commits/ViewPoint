SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPVendorValforSLEntry    Script Date: 8/28/99 9:34:06 AM ******/
    CREATE proc [dbo].[vspAPVendorValforSLEntry]
    /***********************************************************
	* CREATED BY: DC  02/15/07
	* MODIFIED By :		DC 11/19/08 - #127182 Warn when vendor is out of compliance.
	*					GP 6/28/10 - #135813 Changed bSL to varchar(30)
	*					MV 11/1/11 - TK-09070 added NULL output param to bspAPVendorVal
	*					GF 10/08/2012 TK-18356 need to pull AusBusNbf
	*
	*
	* Usage:
	*	Used by SL Entry.  In 5.x SL Entry called bspAPVendorVal to validate
	*						and return vendor info.  Then in code it would call 
	*						bspSLVendActivityCheck to check vendor activity.
	*						For 6.x, I combined this into the validation procedure.
	*
	* Input params:
	*	@co		Company
	*	@sl		Subcontract
	*	@vendgroup	Vendor Group
	*	@vendor		Vendor sort name or number
	*	@activeopt	Controls validation based on Active flag
	*			'Y' = must be an active
	*			'N' = must be inactive
	*			'X' = can be any value
	*	@typeopt	Controls validation based on Vendor Type
	*			'R' = must be Regular
	*			'S' = must be Supplier
	*			'X' = can be any value
	*	@origdate	OrigDate from SLHB
	*
	* Output params:
	*	@vendorout		Vendor number
	*	@payterms       payment terms for this vendor
	*	@slchkrc	Check for SL activity
	*	@slactivitymsg	What is the sl activity
	*   @compliedout	flag indicating if vendor is in compliance	
	*	@msg		Vendor Name or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*****************************************************/
(@co bCompany, @sl varchar(30), @vendgroup bGroup = null, @vendor varchar(15) = null, @activeopt char(1) = null,
 @typeopt char(1) = null, @origdate bDate, @vendorout bVendor=null output, @payterms bPayTerms=null output,
 @slchkrc int output, @slactivitymsg varchar(255) output, @compliedout bYN = null output,  --DC #127182,
 ----TK-18356
 @vendorABN varchar(20)=null output, @msg varchar(60) output)


    as
    set nocount on
    declare @rc int, 
        @eft char(1),
		@v1099yn bYN,
		@v1099Type varchar(10),
        @v1099Box tinyint,
		@holdyn bYN,
		@addnlinfo varchar(60),
        @address varchar(60), 
		@city varchar(30),
		@state bState,
        @zip bZip,
		@taxid varchar(12),
		@taxcode bTaxCode
        
    select @rc = 0

	--Call bspAPVendorVal
	--If you Need Country at some point, use vspAPVendorVal instead 
	exec @rc = bspAPVendorVal @co, @vendgroup, @vendor, @activeopt,
        @typeopt, @vendorout output, @payterms output, @eft output,
		@v1099yn output, @v1099Type output, @v1099Box output, @holdyn output, 
		@addnlinfo output, @address output, @city output, @state output,
        @zip output, @taxid output,@taxcode output, NULL, @msg output
	
	----TK-18356
	select @vendorABN=AusBusNbr from bAPVM Where VendorGroup=@vendgroup and Vendor=@vendor

	--Call bspSLVendActivityCheck
	exec @slchkrc = bspSLVendActivityCheck @co, @sl, @slactivitymsg output
	
	--DC #127182
	if exists(select top 1 1 from bAPVC v join bHQCP h on v.CompCode=h.CompCode
		where v.APCo=@co and v.VendorGroup=@vendgroup and v.Vendor=@vendor and v.Verify='Y' and 
		((h.CompType='D' and (v.ExpDate<@origdate or v.ExpDate is null)) or (h.CompType='F' and (v.Complied='N' or v.Complied is null))))
   		begin
   		select @compliedout = 'N'
   		end
	else
		begin
		select @compliedout = 'Y'
		end
	


    vspexit:
    	return @rc


GO
GRANT EXECUTE ON  [dbo].[vspAPVendorValforSLEntry] TO [public]
GO
