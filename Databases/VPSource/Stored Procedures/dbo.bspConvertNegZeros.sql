SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspConvertNegZeros    Script Date: 9/18/2001 8:57:35 AM ******/
   /****** Object:  Stored Procedure dbo.bspConvertNegZeros    Script Date: 8/28/99 9:34:18 AM ******/
   CREATE   procedure [dbo].[bspConvertNegZeros]
   
   /***********************************************************
    * CREATED BY  : JM 11/24/98
    * MODIFIED By : bc 02/01/98
    *		JM 09/18/01 - Changed 'select * into bARTLSave' to discrete columns from bARTL.
    *
    * USAGE:
    * 	Converts any negative zeros in bARTL bDollar columns to
    *	'regular' zero.
    * 
    * INPUT PARAMETERS
    *	Table name
    *
    * OUTPUT PARAMETERS
    *	None	
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/ 
   (@tablename varchar(15) = null, @errmsg varchar(255) output)
   
   as
   set nocount on
   declare @rcode int, @NoNegZero bDollar, @tablenameok char(1),
   	@backuptablename varchar(20), @triggername varchar(20)
   
   select @rcode = 0, @NoNegZero = 1, @tablenameok = 'N'
   
   /* Verify table name has been passed. */
   if @tablename is null
   	begin
   	select @errmsg = 'Missing table name!', @rcode = 1
   	goto bspexit
   	end
   
   if @tablename = 'bARTL'
   	begin
   	if object_id('dbo.bARTLSave') is not null
   		begin
   		  drop table dbo.bARTLSave
   		end
   	select @backuptablename = 'bARTLSave', @triggername = 'btARTLu'
   	select ARCo, Mth, ARTrans, ARLine, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, 
   		Amount, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered, TaxDisc, DiscTaken, ApplyMth, 
   		ApplyTrans, ApplyLine, JCCo, Contract, Item, ContractUnits, Job, PhaseGroup, Phase, CostType, 
   		UM, JobUnits, JobHours, ActDate, INCo, Loc, MatlGroup, Material, UnitPrice, ECM, MatlUnits, CustJob, 
   		CustPO, EMCo, Equipment, EMGroup, CostCode, EMCType, Notes, CompType, Component, PurgeFlag
   	into bARTLSave from bARTL
   	update bARTL
   	set Amount = Amount * @NoNegZero, 
   		TaxBasis = TaxBasis * @NoNegZero, 
   		TaxAmount = TaxAmount * @NoNegZero, 
   		Retainage = Retainage * @NoNegZero, 
   		DiscOffered = DiscOffered * @NoNegZero, 
   		DiscTaken = DiscTaken * @NoNegZero, 
   		ContractUnits = ContractUnits * @NoNegZero, 
   		JobUnits = JobUnits * @NoNegZero, 
   		JobHours = JobHours * @NoNegZero, 
   		UnitPrice = UnitPrice * @NoNegZero 
   	select @tablenameok = 'Y'
   	end
   
   if @tablenameok <> 'Y'
   	begin
   	select @errmsg = 'Table Name ' + @tablename + ' not found.', @rcode = 1
   	goto bspexit
   	end
   else
   	begin
   	select @errmsg = 'Conversion on ' + @tablename + 
   		' successful. Please verify data in ' +
   		@tablename + ', delete backup table ' + 
   		@backuptablename + ', and recompile trigger ' + 
   		@triggername + '.', @rcode = 0
   	goto bspexit
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspConvertNegZeros] TO [public]
GO
