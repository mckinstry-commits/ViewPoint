SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                        proc [dbo].[bspEMHQMatlValReturnValidUM]
/********************************************************
* CREATED BY: 	JM 9/22/98
* MODIFIED BY:	JM 4/26/99 - Added return of HQMT.Stocked
*               JM 10/5/99 - Revised to validate vs bEMEP or alternately bHQMT. Also added return of error
*   		if part not valid in bHQMT if bEMCO.MatlValid = 'Y'.
*	JM 3/21/01 - Ref Issue 11586: Corrected parameter passed from HQMaterial to EMPartNo, 
*		translated that to HQMaterial in bEMEP, and ran validation on that value. Was running
*		validation on EMPartCode which return error every time.
*	JM 4/2/01 - Ref Issue 11586 rejection: Since this procedure must validate both an HQ and an
*		EM part no, changed to first try against bEMEP and then against bHQMT. This order per Rob.
*		Can be valid in both tables - customer will need to understand how this validation works per
*		documentation. For valid UM wil return either bEMEP.UM or bHQMT.StdUM.
*	JM 4/11/01 - Ref Issue 11586: Rewrote material validation into subroutine bspEMEquipPartVal.
*	JM 5/30/01 - Added return param @category to bspEMEquipPartVal call
*	JM - 6/5/01 - Added null return for new TaxCode return param from bspEMEquipPartVal (not passed up
*		since neither EMStdMaintGroupItems or EMWOEditItems uses tax info)
*	JM 8/6/01 - Ref Issue 13870 - Added null to param list for bspEMEquipPartVal @taxcode_in; tax not 
*		considered in this procedure.
*	JM 3/14/02 - Added INCo input param; added INCo to params in ref to bspEMEquipPartVal. Changed @price
*		and @taxcode from local vars to return params so that this proc can be used for EMFuelPosting form.
*   TV 03/27/03 20831 - Needs to allow null UM
*   TV 04/08/03 20831 - needs to allow null description
*   TV 02/11/04 - 23061 added isnulls	
*   TRL 02/16/07 - 127133 made @hqmatl an outp param, added IsNull and begin/end 
* USAGE:
*	Validates against EMEP and/or HQMT. Returns error msg if EMCO.MatlValid = 'Y' and
* 	Retrieves the StandardUM and Stocking Status from bHQMT or bEMEP for
*	a valid Material; if Material is invalid, returns UM passed in.
*
* INPUT PARAMETERS:
*   	EM Company
*   	Equipment
*   	HQ Material Group
*	Material (either HQ or EM equip no)
*	Default UM
*
* OUTPUT PARAMETERS:
*	Valid UM  (bEMEP.UM or bHQMT.StdUM)
*	Stocking Status = 'P' or 'S' where bHQMT.Stocked = 'Y' -> 'S' and 'N' -> 'P'
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
@emco bCompany = null, @equipment bEquip = null, @matlgroup bGroup=0, @partno varchar(30)=null, @defum bUM=null,
@inco bCompany=null, @inloc bLoc=null, @stdum bUM output, @stockingstatus char(1) output,
@price bUnitCost output, @taxcode bTaxCode output, @hqmatl bMatl output, @msg varchar(255) output
 
as
 
set nocount on
 
declare @category varchar(10),@matlvalid char(1),@numrows int,@rcode int,@stocked bYN
 
/* Default @stockingstatus to 'P' and change it later to 'S' if bHQMT.Stocked = 'Y' */
select @rcode=0, @stockingstatus = 'P'
 
if @emco is null
begin
 	select @msg='Missing EM Company', @rcode=1
 	goto bspexit
end
if IsNull(@equipment,'')=''
begin
 	select @msg='Missing Equipment', @rcode=1
 	goto bspexit
end
if @matlgroup is null
begin
 	select @msg='Missing HQ Material Group', @rcode=1
 	goto bspexit
end
if IsNull(@partno,'')=''
begin
 	select @msg='Missing Part No', @rcode=1
 	goto bspexit
end
--Needs to allow a null UM tv 03/27/03
if IsNull(@defum,'')=''
begin
 	select @msg='Missing Default UM', @rcode=1
 	goto bspexit
end

/* Validate Material against EMEP and/or HQMT */
exec @rcode = bspEMEquipPartVal @emco, @equipment, @matlgroup, @inco, @inloc, 
@partno, null, @hqmatl output, @stdum output, @price output, @stocked output, 
@category output,@taxcode output, @msg output
 
/* Translate bHQMT.Stocked to EM stocking status */
select @stockingstatus = case when @stocked = 'Y' then 'S' else 'P' end
 
--Needs to allow a null UM tv 03/27/03
--need to undo per Carol TV 06/02/03
/* If no StdUM found in bHQMT, return default UM passed in. */
if IsNull(@stdum,'')=''
begin
	select @stdum=@defum
end
 
/* If bspEMEquipPartVal has returned a null Desc in @msg, assign the incoming @partno so
it won't blank out the input on the form. */
--Needs to allow a null UM tv 04/8/03
--need to default the bad partno
if @msg is null 
begin
	select @msg = @partno
end

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMHQMatlValReturnValidUM] TO [public]
GO
