SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         procedure [dbo].[bspEMEquipValForMilesByState]
     
     /***********************************************************
      * CREATED BY: JM 8/5/02
      * MODIFIED By : TV 02/11/04 - 23061 added isnulls	
      *				--TV 10/20/04 25770 - Pulls wrong begin odometer reading after reset
	  *               Dan So 03/14/08 - 127082 - @IFTAState bState output TO @IFTAState varchar(4) output,
      *				  TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
	  *
      * USAGE:
      *	Validates EMEM.Equipment and returns Equip info from bEMEM and bEMMS
      *
      * INPUT PARAMETERS
      *	@emco		EM Company
      *	@equip		Equipment to be validated
      *
      * OUTPUT PARAMETERS
      *	@IFTAState -- IFTAState from bEMEM for this Equipment
      *	@LastReadingDate -- Last ReadingDate from bEMMS from this Equipment
      *	@LastOdo -- Last EndOdo from bEMMS for this Equipment
      *	@msg  -- error or Description
      *
      * RETURN VALUE
      *	0 success
      *	1 error
      ***********************************************************/
     (@emco bCompany = null,
     @equipment bEquip = null,
     @IFTAState varchar(4) output,
     @LastReadingDate bDate output,
     @LastOdo bHrs output,
     @DefBeginOdo bHrs output,
     @msg varchar(255) output)
     
     as
     
     set nocount on
     declare @rcode int, @status char(1), @numrows int
     select @rcode = 0
     
     if @emco is null
     	begin
     	select @msg = 'Missing EM Company!', @rcode = 1
     	goto bspexit
     	end
     if @equipment is null
     	begin
     	select @msg = 'Missing Equipment!', @rcode = 1
     	goto bspexit
     	end
     
	--Return if Equipment Change in progress for New Equipment Code
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

     /* Validate Equipment and get Status and IFTAState */
     select @msg=Description, @status = Status, @IFTAState = IFTAState
     from bEMEM where EMCo = @emco and Equipment = @equipment
     select @numrows = @@rowcount
     if @numrows = 0
     	begin
     	select @msg = 'Equipment invalid!', @rcode = 1
     	end

     /* Reject if Status inactive. */
     if @status = 'I'
        begin
        select @msg = 'Equipment Status = Inactive!', @rcode = 1
        goto bspexit
        end
   
      /*Get last ReadingDate and EndOdo from bEMMS for this Equipment*/
    	--TV 10/20/04 25770 - Pulls wrong begin odometer reading after reset
     select @LastReadingDate = max(ReadingDate), @LastOdo = max(EndOdo) 
     from bEMSM
     where Co = @emco and Equipment = @equipment and 
    		EndOdo = (select max(EndOdo) From bEMSM m2 where m2.Co = @emco and m2.Equipment = @equipment and m2.ReadingDate =
    	   	((select max(ReadingDate) From bEMSM m where m.Co = @emco and m.Equipment = @equipment)))
    	  
    
     
     /* Set default BeginOdo to @LastOdo */
     select @DefBeginOdo = @LastOdo
     
     /* Convert null @LastOdo to zero */
     --if isnull(@LastOdo) select @LastOdo = 0
     
     bspexit:
     	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipValForMilesByState]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForMilesByState] TO [public]
GO
