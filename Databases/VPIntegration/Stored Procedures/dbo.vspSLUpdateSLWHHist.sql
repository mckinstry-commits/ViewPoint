SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLUpdateSLWHHist    ******/
CREATE proc [dbo].[vspSLUpdateSLWHHist]
/***********************************************************
* CREATED BY: TJL 02/23/09 - Issue #129889, SL Claims and Certifications
* MODIFIED By :		DC 8/10/09 - #134912 - AUS - Add fields 'Claim Number' & 'Date Claim Received'
*				GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*				GF 11/13/2012 TK-19330 SL CLAIM CLEANUP
*
*
* USAGE:
* 	Called 'bspSLUpdateAP' and 'vspSLUpdateAPUnapp' to copy SL Worksheet Header values
*	into SL Worksheet Header history table
*
*  INPUT PARAMETERS
*	    @co			SL/AP Co#
*   	@slusername	Worksheet UserName on header record
*   	@sl			SubContract
*
* OUTPUT PARAMETERS
*   	@msg      	error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
***********************************************************/
(@co bCompany = null, @slusername bVPUserName = null, @sl VARCHAR(30) = null, @msg varchar(60) output)

as

set nocount on

declare @rcode INT

----TK-19330
SET @rcode = 0

if @co is null
	begin
	select @msg = 'Missing SL Company.', @rcode = 1
	goto vspexit
	end
if @slusername is null
	begin
	select @msg = 'Missing UserName on record.', @rcode = 1
	goto vspexit
	end
if @sl is null
	begin
	select @msg = 'Missing SubContract.', @rcode = 1
	goto vspexit
	end

----TK-19330 Insert record into SLWHHist table
insert into vSLWHHist (SLCo, UserName, SL, JCCo, Job, [Description], VendorGroup, Vendor, PayControl, APRef, InvDescription,
	InvDate, PayTerms, DueDate, CMCo, CMAcct, HoldCode, ReadyYN, UniqueAttchID, Notes, SLKeyID)
select SLCo, UserName, SL, JCCo, Job, [Description], VendorGroup, Vendor, PayControl, APRef, InvDescription,
	InvDate, PayTerms, DueDate, CMCo, CMAcct, HoldCode, ReadyYN, UniqueAttchID, Notes, KeyID
from bSLWH with (nolock)
where SLCo = @co and UserName = @slusername and SL = @sl
if @@rowcount = 0
	begin
	select @msg = 'SL Worksheet Header was not saved to History table.', @rcode = 1
	goto vspexit
	end

vspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLUpdateSLWHHist] TO [public]
GO
