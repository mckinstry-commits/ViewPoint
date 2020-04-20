SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMDistFlagGet    ******/
CREATE proc [dbo].[vspEMDistFlagGet]
/***********************************************************
* CREATED BY:  TJL 12/20/06 - Issue #27977, 6x Recode EMBTCHUP (EM Batch Processing)
* MODIFIED BY:	
*
*
* USAGE:
*  Called from EM Batch Process form.
*
* INPUT PARAMETERS
*   @emco		EM Company to validate against
*   @source		Source of batch
*   @mth		BatchMth
*   @batchid	BatchId
*
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of EM
*   @flag - 0 if NO JC, IN or GL distribution entries
*		1st bit = Job distributions
*		2nd bit = Inventory distributions
*		3rd bit = GL distributions
*
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@emco bCompany = 0, @source bSource,
   @mth bMonth = null, @batchid bBatchID = null, @flag tinyint output, @msg varchar(60) output)

as
set nocount on
declare @rcode int, @tmp varchar(100)
select @rcode = 0, @flag = 0

if @source = 'EMRev'
   	begin
   	/* Job distributions */
   	if exists(select 1 from bEMJC with (nolock) where EMCo = @emco and Mth = @mth and BatchId = @batchid) select @flag = @flag | 1
   	/* GL distributions */
   	if exists(select 1 from bEMGL with (nolock) where EMCo = @emco and Mth = @mth and BatchId = @batchid) select @flag = @flag | 4
   	end

if @source in ('EMAdj', 'EMParts', 'EMDepr', 'EMFuel', 'EMTime', 'EMAlloc')
   	begin
   	/* Inventory distributions */
   	if exists(select 1 from bEMIN with (nolock) where EMCo = @emco and Mth = @mth and BatchId = @batchid) select @flag = @flag | 2
   	/* GL distributions */
   	if exists(select 1 from bEMGL with (nolock) where EMCo = @emco and Mth = @mth and BatchId = @batchid) select @flag = @flag | 4
   	end

if @source in ('EMMiles', 'EMMeter', 'EMXfer')
	begin
	/* No distributions */
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @msg = @msg
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMDistFlagGet] TO [public]
GO
