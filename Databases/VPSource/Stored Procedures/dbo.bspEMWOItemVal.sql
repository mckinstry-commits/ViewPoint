SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOItemVal    Script Date: 4/25/2002 2:10:15 PM ******/
   CREATE     proc [dbo].[bspEMWOItemVal]
      /***********************************************************
       * CREATED BY: JM  10/11/98
       * MODIFIED By : JM 11/9/98 - Added return of:
       *			OdoReading
       *			OdoDate
       *			ReplacedOdoReading
       *			ReplacedOdoDate
       *			HourReading
       *			HourDate
       *			ReplacedHourReading
       *			ReplacedHourDate
       *		JM 12/28/98 - Added return of:
       *			CostCode
       *		JM 12/29/98 - Added return of:
       *			EMEM.Type (E = Equipment or C = Component)
       *			ComponentTypeCode
       *		JM 1/6/99 - Removed @comptypecode return. Added return of:
       *       @lastequiptotdo = @equipodo + @equipreplodo
       *		  	@lastequiptthrs = @equiphrs + @equipreplhrs
       * 		@lastcompttodo = @compodo + @compreplodo
       * 		@lastcomptthrs = @comphrs + @compreplhrs
       *		bc 02/22/99 - allowed outputs to be nullable for batch validation purposes
       *    JM 2/3/00 Changed definition of @EMGroup to bHQCO.EMGroup from bEMCO.EMGroup.
       *    JM 2/14/00 Added verification that @outsiderprct is linked to @costcode in EMCX
       *    JM 2/15 Removed verification that @outsiderprct is linked to @costcode in EMCX
       *       per DH request when InHseSubFlag = 'O'. Added instead direct read of GLTransAcct
       *       from EMDO or EMDG.
       *    JM 2/15/00 Added error condition if bEMWI.StatusCode reads as 'F' in bEMWS.StatusType
       *       and bEMCO.WOPostFinal = 'N'. Ref Issue 5872.Applies to all modules per DH.
       *    EN 3/17/00 Changed error message which is displayed for the 2/15/00 fix described above to make it more user friendly
       *	 TV 02/11/04 - 23061 added isnulls 
   	 *		TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
    	*
       * USAGE:
       * 	Validates an EM WorkOrder Item for an EMCo/WorkOrder and
       *	    returns various info. An error is returned if any of the
       *	    following occurs:
       * 		no EMCo, WO or WOItem passed
       *		no WOItem found
       *        bEMWI.DateCompl not null for WOItem
       *
       * INPUT PARAMETERS
       *   	EMCo
       *   	WorkOrder
       *   	WOItem to validate
       *
       * OUTPUT PARAMETERS
       *	@equiptype (Equipment or Component)
       *	@equip
       *	@equipdesc
       *	@equipodo
       *	@equipreplodo
       *	@equiphrs
       *	@equipreplhrs
       *	@comp
       *	@compdesc
       *	@compodo
       *	@compreplodo
       *	@comphrs
       *	@compreplhrs
       *	@costcode
       *	@lastequiptotodo
       *	@lastequiptothrs
       *	@lastcomptotodo
       *	@lastcomptothrs
       *    @outsiderprct (Outside Repair CostType from bEMCO)
       *   	@msg      error message if error occurs otherwise Description returned
       *
       * RETURN VALUE
       *   0         success
       *   1         Failure
       *****************************************************/
   
      (@emco bCompany = null,
      @workorder varchar(10) = null,
      @woitem smallint = null,
      @equiptype char(1) = null output,
      /* equip return params */
      @equipment varchar(10) = null output,
      @equipdesc varchar(30) = null output,
      @equipodo bHrs = null output,
      @equipreplodo bHrs = null output,
      @equiphrs bHrs = null output,
      @equipreplhrs bHrs = null output,
      /* comp return params */
      @comp varchar(10) = null output,
      @compdesc varchar(30) = null output,
      @comptypecode varchar(10) = null output,
      @compodo bHrs = null output,
      @compreplodo bHrs = null output,
      @comphrs bHrs = null output,
      @compreplhrs bHrs = null output,
      /* other outputs */
      @costcode bCostCode = null output,
      @lastequiptotodo bHrs = null output,
      @lastequiptothrs bHrs = null output,
      @lastcomptotodo bHrs = null output,
      @lastcomptothrs bHrs = null output,
      @outsiderprct bEMCType = null output,
      @gltransacct bGLAcct = null output,
      @msg varchar(255) output)
   
      as
   
      set nocount on
   
      declare @rcode int, @numrows int, @inhsesubflag char(1), @emgroup bGroup,
        @statuscode varchar(10), @department bDept, @wopostfinal bYN
   
      select @rcode = 0, @numrows = 0, @equiptype = 'E' /* default Type to Equipment */
   
      if @emco is null
      	begin
      	select @msg = 'Missing EM Company!', @rcode = 1
      	goto bspexit
      	end
      if @workorder is null
      	begin
      	select @msg = 'Missing WorkOrder!', @rcode = 1
      	goto bspexit
      	end
      if @woitem is null
      	begin
      	select @msg = 'Missing Workorder Item!', @rcode = 1
      	goto bspexit
      	end
   
      /* Validate WOItem. */
      select @msg = Description, @equipment = Equipment, @comp = Component, @costcode = CostCode, 
   	@inhsesubflag = InHseSubFlag, @statuscode = StatusCode
      from EMWI where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem
      select @numrows = @@rowcount
      if @numrows = 0
      	begin
      	select @msg = 'WO Item not on file!', @rcode = 1
      	goto bspexit
      	end
   
      if (select StatusType from bEMWS where EMGroup = (select EMGroup
            from bHQCO where HQCo = @emco) and StatusCode = @statuscode) = 'F'
         and (select WOPostFinal from bEMCO where EMCo = @emco) = 'N'
      	begin
      	select @msg = 'EMCo is not flagged to allow posting to completed WO Items!', @rcode = 1
      	goto bspexit
      	end
   
      /* Get info for Equipment from EMEM. */
      select @equipdesc = Description,
      	@equipodo = OdoReading,
      	@equipreplodo = ReplacedOdoReading,
      	@equiphrs = HourReading,
       	@equipreplhrs = ReplacedHourReading
      from bEMEM
      where EMCo = @emco
      	and Equipment = @equipment
   
      /* Get info for Component from EMEM. */
      if @comp is not null
      	begin
      	select @equiptype = 'C'
      	select @compdesc = Description,
      		@comptypecode = ComponentTypeCode,
      		@compodo = OdoReading,
      		@compreplodo = ReplacedOdoReading,
      		@comphrs = HourReading,
      	 	@compreplhrs = ReplacedHourReading
      	from bEMEM
      	where EMCo = @emco and Equipment = @comp
      	end
   
      /* Calculate Last Totals. */
      	select @lastequiptotodo = @equipodo + @equipreplodo,
      		@lastequiptothrs = @equiphrs + @equipreplhrs,
      		@lastcomptotodo = @compodo + @compreplodo,
      		@lastcomptothrs = @comphrs + @compreplhrs
   
      /* Get OutsideRprCT from bEMWO if bEMWI.InHseSubFlag = 'O'. */
      if @inhsesubflag = 'O'
          begin
          /* Get Outside Repair EMCostType. */
          select @outsiderprct = OutsideRprCT
          from bEMCO
          where EMCo = @emco
          /* Get GLTransAcct for Outside Repair per EMCostType = @outsiderprct.
          Ref Issue 5873 1/26/00 rejection. */
          /* First need EMGroup. */
          select @emgroup = EMGroup
          from bHQCO
          where HQCo = @emco
          /* Now pull GLTransAcct from EMDO or EMDG. Per DH request dont run
          bspEMCostTypeValForCostCode as that will produce an error msg if
          the ct is not setup for the costcode. */
          /* Step 1 - Get Department for @equipment from bEMEM. */
         select @department = Department
         from bEMEM
         where EMCo = @emco
         	and Equipment = @equipment
         /* Step 2 - If GLAcct exists in bEMDO, use it. */
         select @gltransacct = GLAcct
         from bEMDO
         where EMCo = @emco
         	and isnull(Department,'') = isnull(@department,'')
         	and EMGroup = @emgroup
         	and CostCode = @costcode
         /* Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG. */
         if @gltransacct is null or @gltransacct = ''
         	select @gltransacct = GLAcct
         	from bEMDG

         	where EMCo = @emco
         		and isnull(Department,'') = isnull(@department,'')
         		and EMGroup = @emgroup
         		and CostType = convert(tinyint,@outsiderprct)
         /* Step 4 - return an error if @gltransacct still not found. */
         if @gltransacct is null or @gltransacct = ''
         	begin
         	select @msg = 'Outside Repair GLTransAcct not found in EMDO or EMDG!', @rcode = 1
         	goto bspexit
         	end
         end
   
      bspexit:
      	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOItemVal]'
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOItemVal] TO [public]
GO
