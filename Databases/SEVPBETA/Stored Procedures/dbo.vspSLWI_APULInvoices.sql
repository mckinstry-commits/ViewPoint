SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspSLWI_APULInvoices  Script Date: 02/15/05 9:34:10 AM ******/
CREATE proc [dbo].[vspSLWI_APULInvoices]
	/***************************************************************************************************
	* CREATED BY:  DC 03/20/2009
	* MODIFIED BY:  DC 03/03/10 - #129892 - Added Retainage column. Removed TaxType, GLCo and GLAcct
	*				DC 06/04/10 - #140030 - Don't format date (MTH) in the select.
	*				GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
	*
	* USAGE:
	*	Returns APUL invoices associated to the subcontract in the SL Worksheet, but not assigned to the SL Worksheet
	*	Used in Form SLWorksheet for lookup frmSLWI_APULInvoices
	*	
	* INPUT PARAMETERS
	*	@slco		SL Company
	*	@sl			Subcontract 
	*	@slitem		Subcontract Item
	*   	
	* OUTPUT PARAMETERS
	*   dataset returned by select statement.
	*
	* RETURN VALUE
	*   0         success
	*   1         msg & failure
	*****************************************************************************************************/
	(@slco bCompany, @sl VARCHAR(30), @slitem bItem)

	as
	set nocount on

	/* Open Invoices */
	SELECT UIMth, UISeq, Line, Description, UM, Units, UnitCost, ECM, GrossAmt, Retainage, TaxCode, TaxAmt, InvOriginator
	FROM APUL with (nolock)
	WHERE APCo = @slco and SL = @sl and SLItem = @slitem and SLKeyID is null	
	ORDER BY UIMth, UISeq, Line
		
	--DC #140030 - before
	--SELECT RIGHT(CONVERT(VARCHAR(8), UIMth, 3), 5) AS 'UIMth', UISeq, Line, Description, UM, Units, UnitCost, ECM, GrossAmt, Retainage, TaxCode, TaxAmt, InvOriginator
	--FROM APUL with (nolock)
	--WHERE APCo = @slco and SL = @sl and SLItem = @slitem and SLKeyID is null	
	--ORDER BY UIMth, UISeq, Line



vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspSLWI_APULInvoices] TO [public]
GO
