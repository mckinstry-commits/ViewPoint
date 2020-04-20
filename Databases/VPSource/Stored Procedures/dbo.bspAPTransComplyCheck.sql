SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPTransComplyCheck    Script Date: 8/28/99 9:32:31 AM ******/
   
   CREATE     proc [dbo].[bspAPTransComplyCheck]
   /**********************************************************************
    * CREATED BY: kb 8/9/00
    * MODIFIED By : kb 8/16/00, issue #9442
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *			  MV 01/13/03 - #17821 - all invoice compliance checking
    *			ES 03/12/04 - #23061 isnull wrapping
    *			DC 02/24/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
    *			GP 6/28/10 - #135813 change bSL to varchar(30) 
    *			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *
    * USAGE:
    *
    * INPUT PARAMETERS
    *   APCo      AP Co
    *
    * OUTPUT PARAMETERS
    *
   
    * RETURN VALUE
    *   0 Success
    *   1 fail
    **********************************************************************/   
   (@apco bCompany, @mth bMonth = null, @aptrans bTrans, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @linetype tinyint, @compcode bCompCode,
   	@verify bYN, @comptype char(1), @po varchar(30), @sl varchar(30),
   	@seq smallint, @expdate bDate, @vendorgroup bGroup, @vendor bVendor,
   	@complied bYN, @apline int, @invdate bDate,@allcompchkyn bYN, @rc int,
   	@apref bAPReference --DC #132186 
   
	select @rcode = 0,@complied = 'Y',@rc = 0
   
	select @invdate = InvDate, @vendorgroup=VendorGroup, @vendor= Vendor,
			@apref = APRef  --DC #132186 
   	from bAPTH where APCo = @apco and APTrans = @aptrans and Mth = @mth
   
   --all invoice vendor compliance
	select @allcompchkyn=AllCompChkYN from bAPCO where APCo=@apco
	if @allcompchkyn='Y'
		begin
		exec @rc = bspAPComplyCheckAll @apco, @vendorgroup, @vendor, @invdate, @complied output
		if @complied = 'N'
			begin 
			select @msg='Vendor: ' + isnull(convert(varchar (10),@vendor), '') + ' out of compliance.', @rcode=1  --#23061
			goto bspexit
			end
		end
   
	if @complied='Y'	--if vendor level compliance passed, check PO or SL lines
		begin
		select @apline = min(APLine) from bAPTL where APCo = @apco and APTrans = @aptrans and Mth = @mth
		while @apline is not null
			begin
			select @linetype=LineType, @po=PO, @sl=SL
			from APTL where APCo=@apco and APTrans=@aptrans and APLine=@apline and Mth=@mth
			
			IF @linetype=6
				BEGIN
				if exists(select * from POCT join HQCP on HQCP.CompCode=POCT.CompCode
					where POCo=@apco and PO=@po and POCT.Verify='Y' and ((CompType='D' and (ExpDate<@invdate or
					ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
					BEGIN
					select @msg='PO#' + isnull(@po, '') + ' out of compliance.', @rcode=1 --#23061
					goto bspexit
					END
				END
   
			IF @linetype=7
				BEGIN
       			IF exists(SELECT 1 FROM SLCT join HQCP on HQCP.CompCode=SLCT.CompCode
       				WHERE SLCo=@apco and SL=@sl and SLCT.Verify='Y' and 
       				(SLCT.APRef is null or SLCT.APRef = @apref) and  --DC #132186
       				((CompType='D' and (ExpDate<@invdate or ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
       				BEGIN
       				SELECT @msg='SL#' + isnull(@sl, '') + ' out of compliance', @rcode=1 --#23061
       				GOTO bspexit
       				END
       			END
      
			SELECT @apline = min(APLine) 
			FROM bAPTL 
			WHERE APCo = @apco and APTrans = @aptrans and Mth = @mth and APLine > @apline
   
			end
		end
		
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPTransComplyCheck] TO [public]
GO
