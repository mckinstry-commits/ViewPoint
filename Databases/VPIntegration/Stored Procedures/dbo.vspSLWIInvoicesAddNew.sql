SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspSLWIInvoicesAddNew  Script Date: 02/15/05 9:34:10 AM ******/
CREATE proc [dbo].[vspSLWIInvoicesAddNew]
	/***************************************************************************************************
	* CREATED BY:  DC 03/23/2009
	* MODIFIED BY:  DC 03/03/10 - #129892 Removed TaxType, GLCo and GLAcct columns
	*
	* USAGE:
	*		Used by the frmSLWI_APULInvoices
	*		form to insert the selected APUL Invoice into SLWIInvoices
	*
	*	
	* INPUT PARAMETERS
	*	@apulkeyid	worksheet key id
	*   	
	* OUTPUT PARAMETERS
	*   @msg      Description or error message
	*
	* RETURN VALUE
	*   0         success
	*   1         msg & failure
	*****************************************************************************************************/
	(@co bCompany, @uimth bMonth, @uiseq smallint, @line smallint, @slwh_keyid bigint)

	as
	set nocount on

	INSERT INTO SLWIInvoices(APULKeyID, SLCo, Line, UIMth, UISeq, SL, SLItem, Description, UM,
				Units, UnitCost, ECM, VendorGroup, Supplier, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup, 
				TaxCode, TaxBasis, TaxAmt, Retainage, Discount, PayCategory, InvOriginator, SLDetailKeyID, SLKeyID)
	SELECT KeyID, APCo, Line, UIMth, UISeq, SL, SLItem, Description, UM,
				Units, UnitCost, ECM, VendorGroup, Supplier, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup,
				TaxCode, TaxBasis, TaxAmt, Retainage, Discount, PayCategory, InvOriginator,SLDetailKeyID, SLKeyID
	FROM APUL	
	WHERE APCo = @co and UIMth = @uimth and UISeq = @uiseq and Line = @line
	
	--mark the apul record with the sl worksheet id
	UPDATE APUL
	Set SLKeyID = @slwh_keyid
	WHERE APCo = @co and UIMth = @uimth and UISeq = @uiseq and Line = @line


vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspSLWIInvoicesAddNew] TO [public]
GO
