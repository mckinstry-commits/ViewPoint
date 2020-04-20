SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspSLAddSLIT    Script Date: 9/21/2004 9:37:58 AM ******/
CREATE             PROCEDURE [dbo].[vspSLAddSLIT]
/************************************************************************
* CREATED:	DC 02/07/07    
* MODIFIED:    DC 8/14/08  #128435 - Add Tax to SL
*				DC 1/4/2010 #130175 - SLIT needs to match POIT
*				GF 06/26/2010 - issue #135318 expanded SL to varchar(30)
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* Purpose of Stored Procedure
*
*	Add SLIT record from SLAddItem
*    
*
*           
* Used In:
*	SLAddItem
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
    (
      @co bCompany,
      @sl VARCHAR(30),
      @slitem bItem,
      @jcco bCompany,
      @job bJob,
      @phasegrp bGroup,
      @phase bPhase,
      @jcctype bJCCType,
      @desc bItemDesc,
      @um bUM,
      @glco bCompany,
      @glacct bGLAcct,
      @wcret bPct,
      @smret bPct,
      @vendorgrp bGroup,
      @supplier bVendor,
      @notes VARCHAR(MAX),
      @taxgroup bGroup,
      @taxcode bTaxCode,
      @taxtype TINYINT,--DC #128435
      @taxrate bRate,
      @gstrate bRate, --DC #130175
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INT

    SELECT  @rcode = 0
    
    INSERT  SLIT
            ( SLCo,
              SL,
              SLItem,
              ItemType,
              AddonPct,
              JCCo,
              Job,
              PhaseGroup,
              Phase,
              JCCType,
              Description,
              UM,
              GLCo,
              GLAcct,
              WCRetPct,
              SMRetPct,
              VendorGroup,
              Supplier,
              OrigUnits,
              OrigUnitCost,
              OrigCost,
              CurUnits,
              CurUnitCost,
              CurCost,
              StoredMatls,
              InvUnits,
              InvCost,
              InUseMth,
              InUseBatchId,
              Notes,
              TaxGroup,
              OrigTax,
              CurTax,
              InvTax,
              TaxCode,
              TaxType, --DC #128435
              TaxRate,
              GSTRate
            )  --DC #130175
    VALUES  ( @co,
              @sl,
              @slitem,
              '2',
              '0',
              @jcco,
              @job,
              @phasegrp,
              @phase,
              @jcctype,
              @desc,
              @um,
              @glco,
              @glacct,
              @wcret,
              @smret,
              @vendorgrp,
              @supplier,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              NULL,
              NULL,
              @notes,
              @taxgroup,
              0,
              0,
              0,
              @taxcode,
              @taxtype,  --DC #128435
              @taxrate,
              @gstrate
            )  --DC #130175
   			
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @msg = 'SQL ERROR:  Could not insert records into SLIT',
                    @rcode = 1
            GOTO bspexit
        END
    
    
    bspexit:
    IF @rcode <> 0 
        SELECT  @msg = @msg + CHAR(13) + CHAR(10) + '[vspSLAddSLIT]'
    RETURN @rcode
    
    
    
   
   
   
   
   
  
 





GO
GRANT EXECUTE ON  [dbo].[vspSLAddSLIT] TO [public]
GO
