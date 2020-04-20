SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSDiscTemplateCopy]
   /****************************************************************************
   * Created By:	GF 03/02/2000
   * Modified By:	
   *
   * USAGE:
   * 	Copies Discount Template Header MSDH and Discount Template
   *   Detail MSDD. Restricts to company and discount template.
   *
   * INPUT PARAMETERS:
   *	FromCompany, FromTemplate, ToCompany, ToTemplate, Description,
   *   CopyNotes, return msg
   *
   * OUTPUT PARAMETERS:
   *	None
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@frommsco bCompany = null, @fromtemplate smallint = null, @tomsco bCompany = null,
    @totemplate smallint = null, @description bDesc, @copynotes bYN = null,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode integer, @initcount int, @validcnt int, @sequence int,
           @opencursor tinyint, @locgroup bGroup, @fromloc bLoc, @matlgroup bGroup,
           @category varchar(10), @material bMatl, @um bUM, @paydiscrate bUnitCost
   
   select @rcode=0, @initcount=0, @validcnt=0, @opencursor=0
   
   -- validate From MS Company
   if @frommsco is null
   	begin
   	select @msg = 'Missing From MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from bMSCO where @frommsco = MSCo)
   	begin
   	select @msg = 'From Company not set up in MS Company file!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate To MS Company
   if @tomsco is null
   	begin
   	select @msg = 'Missing To MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from bMSCO where @tomsco = MSCo)
   	begin
   	select @msg = 'To Company not set up in MS Company file!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate From Template
   if @fromtemplate is null
   	begin
   	select @msg = 'Missing From Discount Template', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from bMSDH where MSCo=@frommsco and DiscTemplate=@fromtemplate)
       begin
       select @msg = 'Not a valid From Discount Template', @rcode = 1
       goto bspexit
       end
   
   -- validate To Template
   if @totemplate is null
       begin
       select @msg = 'Missing To Discount Template', @rcode = 1
       goto bspexit
       end
   
   if @copynotes is null
       begin
       select @copynotes='N'
       end
   
   -- start copy Template process
   begin transaction
   -- only insert MSDH record if doesn't already exist
   select @validcnt = count(*) from bMSDH
     where MSCo=@tomsco and DiscTemplate=@totemplate
     if @validcnt = 0
        begin
        if @copynotes='N'
           begin
           insert into bMSDH(MSCo, DiscTemplate, Description, Notes)
           select @tomsco, @totemplate, @description, null
           from bMSDH d where MSCo=@frommsco and DiscTemplate=@fromtemplate
           if @@rowcount = 0
              begin
              select @msg = 'Unable to insert MSDH record, copy aborted!', @rcode=1
              rollback
              goto bspexit
              end
           select @initcount = @initcount + 1
           end
        Else
           begin
           insert into bMSDH(MSCo, DiscTemplate, Description, Notes)
           select @tomsco, @totemplate, @description, Notes
           from bMSDH d where MSCo=@frommsco and DiscTemplate=@fromtemplate
           if @@rowcount = 0
              begin
              select @msg = 'Unable to insert MSDH record, copy aborted!', @rcode=1
              rollback
              goto bspexit
              end
           select @initcount = @initcount + 1
           end
       end
   
   -- declare cursor for all rows in bMSDD matching From MS Company and From Template
   declare bcMSDD cursor LOCAL FAST_FORWARD
   	for select LocGroup, FromLoc, MatlGroup, Category, Material, UM, PayDiscRate
       from bMSDD where MSCo=@frommsco and DiscTemplate=@fromtemplate
   
       -- open cursor, set cursor flag
       open bcMSDD
       set @opencursor = 1
   
       -- loop through each row in cursor
       process_loop:
       fetch next from bcMSDD into @locgroup, @fromloc, @matlgroup, @category, @material,@um,@paydiscrate
   
   
       if (@@fetch_status <> 0) goto process_loop_end
   
       -- check if row in destination template
       select @validcnt = count(*) from bMSDD
       where MSCo=@tomsco and DiscTemplate=@totemplate and LocGroup=@locgroup and FromLoc=@fromloc
       and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
   
       if @validcnt <> 0 goto process_loop
   
       -- insert row into MSDD for destination template
       select @sequence = 0
       select @sequence = isnull(Max(Seq),0)+1 from bMSDD
       where MSCo=@tomsco and DiscTemplate=@totemplate
   
       insert into bMSDD(MSCo, DiscTemplate, Seq, LocGroup, FromLoc, MatlGroup, Category,
               Material, UM, PayDiscRate)
   
       values (@tomsco, @totemplate, @sequence, @locgroup, @fromloc, @matlgroup, @category,
               @material, @um, @paydiscrate)
   
       select @initcount=@initcount + 1
       goto process_loop
   
   process_loop_end:
       commit transaction
       select @msg = convert(varchar(5),@initcount) + ' entries copied.', @rcode=0
   
   bspexit:
       if @opencursor=1
           begin
           close bcMSDD
           deallocate bcMSDD
           end
   
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSDiscTemplateCopy] TO [public]
GO
