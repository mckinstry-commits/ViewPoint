SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPOVal    Script Date: 09/16/2005 ******/
CREATE  proc [dbo].[vspPMPOVal]
/*************************************
 * Created By:	GF 01/19/2009
 * Modified by:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 * called from PMPOHeader from 'StdBeforeRecAdd' routine to check if the PO was added via
 * another process. This is strictly a work-around for an existing standards problem.
 * Hopefully temporary.
 *
 * Pass:
 * POCo			PM PO Company
 * PO			PM Purchase Order
 *
 * Returns:
 *
 *
 * Success returns:
 *	0 or 1 and error message
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@poco bCompany, @po varchar(30), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- check if PO already exists in POHD
if exists(select top 1 1 from POHD where POCo=@poco and PO=@po)
	begin
	select @msg = 'PO has already been added via another process. Duplicate PO problem.', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOVal] TO [public]
GO
