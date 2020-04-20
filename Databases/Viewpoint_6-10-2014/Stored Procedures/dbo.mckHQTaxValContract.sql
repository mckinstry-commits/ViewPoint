SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/3/2014
-- Description:	Normal Validation plus added validation to prevent changes after interface.

   /***********************************************************
    * CREATED BY: SE   10/2/96
    * MODIFIED By : GG 04/29/97
    *
    * USAGE:
    * validates HQ Tax Code
    * an error is returned if any of the following occurs
    * no tax code passed, or tax code doesn't exist in HQTX
    *
    * INPUT PARAMETERS
    *   @taxgroup		TaxGroup assigned in bHQCO
    *   @taxcode		TaxCode to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      		Tax code description or error message 
    *
    * RETURN VALUE
    *   @rcode			0 = success, 1 = error
    *   
    *****************************************************/ 
-- =============================================
CREATE PROCEDURE [dbo].[mckHQTaxValContract] 
	-- Add the parameters for the stored procedure here

   	(@taxgroup bGroup = null, @taxcode bTaxCode = null, @JCCo TINYINT, @Contract bContract, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   select @msg = Description
   from bHQTX
   where TaxGroup = @taxgroup and TaxCode = @taxcode
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Tax code not setup in HQ!', @rcode = 1
   	goto bspexit
   	end
   
   IF EXISTS(SELECT 1 FROM JCCM WHERE @JCCo = JCCo AND @Contract = Contract AND ContractStatus <> 0)
   BEGIN
	SELECT @msg = 'This contract has already been interfaced.  Contact accounting to make changes.', @rcode = 1
	GOTO bspexit
   END

   bspexit:
   	return @rcode

GO
