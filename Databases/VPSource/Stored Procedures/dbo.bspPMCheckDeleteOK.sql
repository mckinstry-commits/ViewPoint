SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE  proc [dbo].[bspPMCheckDeleteOK]
/***********************************************************
 * Created By:	GF 04/12/2007 6.x 
 * Modified By: GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
 *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*
 * USAGE:
 * Called from the PMMOHeader, PMMSQuotes, PMPOHeader, PMSLHeader
 * to check if delete header is allowed.
 *
 *
 * INPUT PARAMETERS
 * RecType		- Record Type Flag - (Q)-MSQD, (M)-INMI, (P)-POIT, (S)-SLIT
 * CO			- Accouting Company
 * Quote		- MS Quote
 * MO			- IN Material Order
 * PO			- PO Purchase Order
 * SL			- SL Subcontract
 *
 *
 *
 * OUTPUT PARAMETERS
 *   @msg - error message if item exists
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@rectype varchar(1) = 'S', @co bCompany = 0, @quote varchar(10) = null, 
 @mo bMO = null, @po varchar(30) = null, @sl VARCHAR(30) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- depending on record type check appropiate items table
if isnull(@rectype,'') = 'Q'
	begin
	if exists(select MSCo from MSQD with (nolock) where MSCo=@co and Quote=@quote)
		begin
		select @msg = 'MS Quote Detail exists in MS for this quote, cannot delete.', @rcode = 1
		end
	end

if isnull(@rectype,'') = 'M'
	begin
	if exists(select INCo from INMI with (nolock) where INCo=@co and MO=@mo)
		begin
		select @msg = 'Material Order items exist in IN for this material order, cannot delete.', @rcode = 1
		end
	end

if isnull(@rectype,'') = 'P'
	begin
	if exists(select POCo from POIT with (nolock) where POCo=@co and PO=@po)
		begin
		select @msg = 'Purchase Order Items exist in PO for this purchase order, cannot delete.', @rcode = 1
		end
	end

if isnull(@rectype,'') = 'S'
	begin
	if exists(select SLCo from SLIT with (nolock) where SLCo=@co and SL=@sl)
		begin
		select @msg = 'Subcontract items exist in SL for this subcontract, cannot delete.', @rcode = 1
		end
	end






bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMCheckDeleteOK] TO [public]
GO
