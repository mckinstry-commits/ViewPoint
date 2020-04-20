SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPComplyCheck    Script Date: 8/28/99 9:32:31 AM ******/   
   CREATE        proc [dbo].[bspAPComplyCheck]
   /**********************************************************************
    * CREATED BY: kf 9/29/97
    * MODIFIED By : kb 2/1/99
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *			MV 01/15/03 - #17821 all invoice compliance checking
    *			MV 02/11/03 - #17821 rej 2 fix - took out all invoice flag
    *			MV 11/26/03 - #23061 isnull wrap
    *			ES 03/11/04 - #23061 more isnull wrap
    *			DC 02/11/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
    *			GP 6/28/10 - #135813 change bSL to varchar(30)
    *			GF 08/04/2011 - TK-07144 EXPAND PO
    *
    * USAGE:
    * 
    * INPUT PARAMETERS
    *   APCo      AP Co
    *   
    * OUTPUT PARAMETERS
    *
	*   
    * RETURN VALUE
    *   0 Success
    *   1 fail
    **********************************************************************/    
   (@apco bCompany, @mth bMonth = null, @aptrans bTrans, @apline smallint, @invdate bDate,
	@apref bAPReference, --DC #132186 
   	@msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @linetype tinyint, @compcode bCompCode, 
   	@verify bYN, @comptype char(1), @po VARCHAR(30), @sl varchar(30), 
   	@seq smallint, @expdate bDate, @vendorgroup bGroup, @vendor bVendor, 
   	@complied bYN
   
   select @rcode = 0
   
   select @linetype=LineType, @po=PO, @sl=SL 
   from bAPTL
   where APCo=@apco and APTrans=@aptrans and APLine=@apline and Mth=@mth
   
   if @linetype=6
   	begin
   	if exists(select * from bPOCT join bHQCP on bHQCP.CompCode=bPOCT.CompCode
   		where POCo=@apco and PO=@po and bPOCT.Verify='Y' /*and bHQCP.AllInvoiceYN='N'*/
   		and ((CompType='D' and (ExpDate<@invdate or ExpDate is null)) or
   			 (CompType='F' and (Complied='N' or Complied is null))))
   		begin
   		select @msg='PO#' + isnull(@po,'') + ' out of compliance, cannot pay AP trans#' + 
   			isnull(convert(varchar(10),@aptrans), ''), @rcode=1 --#23061
   		goto bspexit
   		end
   	end
   			
	IF @linetype=7
		BEGIN
		IF exists(SELECT 1 FROM bSLCT join bHQCP on bHQCP.CompCode=bSLCT.CompCode
   			WHERE SLCo=@apco and SL=@sl and bSLCT.Verify='Y' and 
   			(bSLCT.APRef is null or bSLCT.APRef = @apref) and  --DC #132186
   			((CompType='D' and (ExpDate<@invdate or ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
   			BEGIN
   			SELECT @msg='SL#' + isnull(@sl,'') + ' out of compliance, cannot pay AP trans#' + 
   				isnull(convert(varchar(10),@aptrans), ''), @rcode=1  --#23061
   			GOTO bspexit
   			END
   		END
   	
   bspexit:   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPComplyCheck] TO [public]
GO
