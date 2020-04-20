SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspMSPriceTemplateCopy]
   /****************************************************************************
   * Created By:   GF 03/02/2000
   * Modified By: 	GG 08/09/02 - #17811 - added effective date and new prices
   *
   * USAGE:
   * 	Copies Price Template Header MSTH and Price Template
   *   Detail MSTP. Restricts to company and price template.
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
           @category varchar(10), @material bMatl, @um bUM, @oldrate bRate,
           @oldunitprice bUnitCost, @oldecm bECM, @oldminamt bDollar, @newrate bRate,
           @newunitprice bUnitCost, @newecm bECM, @newminamt bDollar
   
   select @rcode=0, @initcount=0, @validcnt=0, @sequence=0, @opencursor=0
   
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
   	select @msg = 'Missing From Price Template', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from bMSTH where MSCo=@frommsco and PriceTemplate=@fromtemplate)
       begin
       select @msg = 'Not a valid From Price Template', @rcode = 1
       goto bspexit
       end
   
   -- validate To Template
   if @totemplate is null
       begin
       select @msg = 'Missing To Price Template', @rcode = 1
       goto bspexit
       end
   
   if @copynotes is null
       begin
       select @copynotes='N'
       end
   
   -- start copy Template process
   begin transaction
   -- only insert MSTH record if doesn't already exist
   select @validcnt = count(*) from bMSTH
     where MSCo=@tomsco and PriceTemplate=@totemplate
     if @validcnt = 0
        begin
        if @copynotes='N'
           begin
           insert into bMSTH(MSCo, PriceTemplate, Description, Notes, EffectiveDate)
           select @tomsco, @totemplate, @description, null, EffectiveDate
           from bMSTH d where MSCo=@frommsco and PriceTemplate=@fromtemplate
           if @@rowcount = 0
              begin
              select @msg = 'Unable to insert MSTH record, copy aborted!', @rcode=1
              rollback
              goto bspexit
              end
           select @initcount = @initcount + 1
           end
        Else
           begin
           insert into bMSTH(MSCo, PriceTemplate, Description, Notes, EffectiveDate)
           select @tomsco, @totemplate, @description, Notes, EffectiveDate
           from bMSTH d where MSCo=@frommsco and PriceTemplate=@fromtemplate
           if @@rowcount = 0
              begin
              select @msg = 'Unable to insert MSTH record, copy aborted!', @rcode=1
              rollback
              goto bspexit
              end
           select @initcount = @initcount + 1
           end
       end
   
   -- declare cursor for all rows in bMSTP matching From MS Company and From Template
   declare bcMSTP cursor LOCAL FAST_FORWARD
   	for select LocGroup, FromLoc, MatlGroup, Category, Material,
       UM, OldRate, OldUnitPrice, OldECM, OldMinAmt, NewRate, NewUnitPrice, NewECM, NewMinAmt
       from bMSTP where MSCo=@frommsco and PriceTemplate=@fromtemplate
   
       -- open cursor, set cursor flag
       open bcMSTP
       select @opencursor = 1
   
       -- loop through each row in cursor
       process_loop:
       fetch next from bcMSTP into @locgroup, @fromloc, @matlgroup, @category, @material,
                                   @um, @oldrate, @oldunitprice, @oldecm, @oldminamt,
   								@newrate, @newunitprice, @newecm, @newminamt
   
       if (@@fetch_status <> 0) goto process_loop_end
   
      -- check if row in destination template
       select @validcnt = count(*) from bMSTP
       where MSCo=@tomsco and PriceTemplate=@totemplate and LocGroup=@locgroup and FromLoc=@fromloc
       and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
   
       if @validcnt <> 0 goto process_loop
   
       -- insert row into MSTP for destination template
       select @sequence = 0
       select @sequence = isnull(Max(Seq),0)+1 from bMSTP
       where MSCo=@tomsco and PriceTemplate=@totemplate
   
       insert into bMSTP(MSCo, PriceTemplate, Seq, LocGroup, FromLoc, MatlGroup, Category,
               Material, UM, OldRate, OldUnitPrice, OldECM, OldMinAmt, NewRate, NewUnitPrice,
   			NewECM, NewMinAmt)
       values (@tomsco, @totemplate, @sequence, @locgroup, @fromloc, @matlgroup, @category,
               @material, @um, @oldrate, @oldunitprice, @oldecm, @oldminamt, @newrate, @newunitprice,
   			@newecm, @newminamt)
   
       select @initcount=@initcount + 1
       goto process_loop
   
   process_loop_end:
   
       commit transaction
       select @msg = convert(varchar(5),@initcount) + ' entries copied.', @rcode=0
   
   bspexit:
   
       if @opencursor=1
           begin
           close bcMSTP
           deallocate bcMSTP
           end
   
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPriceTemplateCopy] TO [public]
GO
